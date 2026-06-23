# Reliability Model

AgentGate must fail safely because it sits between an agent and tools that may create irreversible side effects.

## Failure behavior

| Failure | Required behavior |
|---|---|
| Policy engine throws or exceeds its deadline | Fail closed. Persist an enforcement failure when possible. Do not execute. |
| Database unavailable before a decision | Reject the request. Do not invoke a downstream tool. |
| Required pre-execution audit event cannot be written | Fail closed. Do not execute. |
| Downstream MCP server times out | Mark the attempt `TimedOut` or `OutcomeUnknown` based on whether the request may have reached the server. |
| Tool succeeds but the response is lost | Mark `OutcomeUnknown`. Do not blindly retry a destructive or external-write operation. |
| Approval expires | Move the approval and call to `Expired`; later approval attempts fail. |
| Duplicate request arrives | Return the existing logical call when the payload matches; reject an idempotency conflict when it differs. |
| Agent disconnects during execution | Complete and persist the call; expose the result through status retrieval. |
| Agent disconnects while approval is pending | Keep the durable approval until it expires or is decided. |
| Tool returns malformed output | Mark failure, store bounded diagnostics, and do not pass invalid structured data onward. |
| Dashboard unavailable | Safe synchronous calls may continue; approval-required calls remain pending. |
| Completion audit write fails after a side effect | Preserve execution attempt and external operation ID; mark reconciliation required. |
| Worker crashes | Lease expires; recovery checks retry safety before any new attempt. |
| Tool schema changes | Disable the affected published version until reviewed. |
| Downstream credential is revoked | Reject new executions and fail not-yet-started leased work. |

## Fail-closed decisions

The following failures always fail closed:

- authentication or tenant resolution failure;
- policy load, parse, validation, or evaluation failure;
- unknown tool or unreviewed schema;
- approval validation failure;
- missing required audit intent;
- argument canonicalization or hash failure;
- secret-provider failure before downstream execution.

A failure after a downstream request may require `OutcomeUnknown` rather than a denial because AgentGate cannot honestly prove that the external side effect did not occur.

## Idempotency

Side-effecting requests require an AgentGate idempotency value in request metadata.

Logical uniqueness:

```text
TenantId + AgentId + IdempotencyKey
```

Behavior:

- same key and same canonical request: return the existing ToolCall and current status;
- same key and different canonical request: reject with `IDEMPOTENCY_CONFLICT`;
- concurrent duplicates: PostgreSQL unique constraint chooses one winner;
- status polling never creates a new execution;
- retries after `OutcomeUnknown` require human reconciliation unless the downstream tool supports a reliable operation-status lookup.

## Retry classification

Each reviewed tool version receives a retry classification:

- `SafeRead` — may retry after transient connection failure before a response.
- `IdempotentWrite` — may retry only when a downstream idempotency key is supported.
- `StatusCheckableWrite` — query downstream operation status before retrying.
- `NonIdempotentWrite` — no automatic retry after dispatch.
- `Destructive` — no automatic retry after dispatch.

The classification is locally reviewed and cannot be accepted from untrusted tool annotations alone.

## Retry policy

Use bounded exponential backoff with jitter for:

- initial downstream connection;
- safe read operations;
- transient database faults before execution begins;
- downstream health probes.

Do not automatically retry:

- email send without downstream idempotency;
- file deletion after request dispatch;
- issue creation without an external operation ID or idempotency support;
- any call already marked `OutcomeUnknown`.

## Timeouts

Initial configuration targets:

- policy evaluation: 100 ms hard deadline;
- downstream connection: 5 seconds;
- safe read call: 15 seconds;
- write call: 30 seconds;
- approval expiration: 30 minutes;
- worker lease: tool timeout plus a recovery margin;
- request and response bodies: bounded by endpoint and tool-specific limits.

These are initial settings and must be changed only after measured behavior.

## Circuit breaker

A circuit breaker is maintained per downstream MCP server.

When repeated connection or execution failures cross a threshold:

- the circuit opens;
- new executions fail with `DOWNSTREAM_UNAVAILABLE` before dispatch;
- approved pending calls remain queued until their own expiry;
- health probes continue at a reduced rate;
- the circuit closes only after successful probes.

The breaker does not replace tool-level retry classification.

## PostgreSQL-backed execution queue

The MVP does not require RabbitMQ, Kafka, or Redis.

Execution flow:

1. Worker queries approved, unleased ToolCalls.
2. Worker selects rows using `FOR UPDATE SKIP LOCKED`.
3. Worker writes `LeaseOwner` and `LeaseExpiresAt`.
4. Lease transaction commits.
5. Worker verifies approval, tool schema, arguments, and retry classification.
6. Worker creates an ExecutionAttempt.
7. Worker dispatches the downstream MCP call.
8. Worker persists the result and terminal state.

This design supports multiple workers later while keeping the first deployment simple.

## Lease recovery

When a lease expires:

- if no downstream dispatch occurred, the call may be leased again;
- if dispatch status is unknown, mark `OutcomeUnknown`;
- if an external operation ID exists, query status before retrying;
- if the tool is a safe read, retry within the configured budget;
- if the tool is destructive or non-idempotent, require review.

## Dead-letter and reconciliation states

AgentGate should not hide failed work in a generic queue.

A call becomes `NeedsReview` or `OutcomeUnknown` when:

- the retry budget is exhausted;
- a downstream outcome cannot be determined;
- a required completion audit event cannot be appended;
- internal state is inconsistent;
- a result cannot be safely normalized.

The dashboard surfaces these calls with the evidence needed for manual resolution.

## Database consistency

- ToolCall state and PolicyDecision are written in one transaction.
- ApprovalDecision and transition to Approved are written in one transaction.
- Work leasing is committed before network execution.
- ExecutionAttempt is created before dispatch.
- Final result, call state, and completion audit event should be committed together when possible.
- Audit intent must exist before any side effect.

## Recovery tests

The reliability suite must include:

- PostgreSQL unavailable before policy evaluation;
- worker process terminated before dispatch;
- worker terminated after dispatch;
- downstream timeout before request acceptance;
- downstream response lost after a seeded side effect;
- approval expiring during queue wait;
- 100 concurrent duplicate submissions;
- circuit opening and recovery;
- malformed downstream output;
- audit append failure;
- schema drift between approval and execution.

A test passes when AgentGate ends in the documented safe or reviewable state, not merely when it avoids throwing an exception.