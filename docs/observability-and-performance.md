# Observability and Performance

## Observability goals

AgentGate should make it possible to answer:

- who requested the action;
- which policy facts and versions produced the decision;
- whether approval was required and who decided it;
- whether the downstream tool was invoked;
- how many attempts occurred;
- where latency was spent;
- whether retries, timeouts, schema drift, or duplicate requests occurred;
- whether the final audit record is complete.

Operational telemetry is not the same as the authoritative domain audit. OpenTelemetry helps diagnose behavior; AuditEvent records prove important application decisions and state changes.

## Correlation identifiers

Every request should carry or receive:

- `TraceId`
- `ToolCallId`
- `AgentSessionId`
- `AgentId`
- `TenantId`
- `ApprovalRequestId`, when applicable
- `ExecutionAttemptId`, when applicable
- downstream server ID
- idempotency-key hash

Raw secrets, request bodies, customer data, and full idempotency keys must not be placed in telemetry.

## Structured log events

Recommended event names:

- `AgentAuthenticated`
- `McpSessionInitialized`
- `ToolCallReceived`
- `ToolSchemaValidationFailed`
- `PolicyEvaluationCompleted`
- `ToolCallDenied`
- `ApprovalRequested`
- `ApprovalGranted`
- `ApprovalRejected`
- `ApprovalExpired`
- `ExecutionLeased`
- `DownstreamCallStarted`
- `DownstreamCallCompleted`
- `ExecutionOutcomeUnknown`
- `DuplicateRequestDetected`
- `ToolSchemaDriftDetected`
- `AuditChainVerificationFailed`

Logs should use stable fields and reason codes rather than unstructured prose.

## Metrics

### Counters

- tool calls received;
- calls allowed;
- calls denied;
- calls requiring approval;
- approvals granted, rejected, and expired;
- executions succeeded and failed;
- duplicate requests;
- downstream timeouts;
- schema-drift detections;
- evaluation scenarios passed and failed.

### Histograms

- policy evaluation duration;
- total gateway duration;
- approval waiting duration;
- downstream execution duration;
- database operation duration;
- audit append duration;
- result payload size.

### Gauges

- pending approvals;
- active sessions;
- unhealthy downstream servers;
- leased execution jobs;
- calls in `OutcomeUnknown` or `NeedsReview`.

## Trace structure

```text
agentgate.tool_call
  agentgate.authenticate
  agentgate.resolve_tool
  agentgate.validate_arguments
  agentgate.policy_evaluate
  agentgate.persist_decision
  agentgate.execute
    mcp.downstream.call
  agentgate.persist_result
  agentgate.audit_append
```

A human approval may take minutes, so AgentGate must not leave one span open for the entire waiting period. The initial request, human decision, and later execution use separate traces linked by `ToolCallId` and OpenTelemetry trace links.

## MVP stack

Use:

- built-in `ILogger` structured logging;
- OpenTelemetry instrumentation and OTLP export;
- an Aspire Dashboard or another lightweight OTLP-compatible local viewer;
- PostgreSQL-backed domain audit records.

Prometheus and Grafana are valuable later for durable dashboards and alerts, but should not block the first complete demo.

## Alerts

Local or demonstration alerts should include:

- audit chain verification failure;
- calls stuck beyond execution lease expiry;
- repeated downstream failures;
- repeated authentication failures;
- approval-required execution without a valid approval, which should be impossible;
- abnormal growth in duplicate requests;
- calls entering `OutcomeUnknown`;
- evaluation pass rate below the required threshold.

## Performance test environment

Every published result must include:

- processor and core count;
- RAM;
- operating system;
- Docker version;
- PostgreSQL version;
- .NET version;
- commit SHA;
- database size;
- downstream stub latency configuration.

Local Docker Compose is the first test environment. A small cloud VM may be added later for reproducibility.

## Initial targets

These are targets, not claimed results.

| Test | Initial target |
|---|---|
| Concurrent MCP sessions | 100 active sessions |
| Sustained tool-call throughput | 20 calls/second for 10 minutes |
| Policy-only throughput | 500 evaluations/second |
| Policy p95 latency | Under 15 ms with warm policy cache |
| Gateway p95 overhead | Under 100 ms excluding downstream execution |
| Pending approvals | 1,000 |
| Approval queue p95 query | Under 300 ms |
| Audit ingestion | 100 events/second without loss |
| Concurrent duplicate submissions | 100 requests, one execution |
| Database growth | 1 million synthetic audit events |
| Recent-call page p95 | Under 500 ms at the tested size |
| Worker restart test | No unsafe duplicate writes across 100 mixed calls |

Targets should be revised only after a baseline is measured and the reason is documented.

## Load scenarios

### Concurrent sessions

Establish 10, 25, 50, and 100 sessions. List tools and submit periodic safe reads. Measure initialization failures, memory, connection reuse, and latency.

### Policy evaluation

Run fixed request facts against 10, 50, 100, and 500 active policies. Measure parsing, policy selection, and evaluator duration separately.

### Pending approvals

Seed 100, 1,000, and 10,000 pending approvals. Test list, filter, detail, expiry, and decision queries.

### Audit ingestion

Generate realistic call paths with multiple events. Verify no missing chain links and measure transaction contention.

### Downstream latency

Use a configurable stub MCP server with:

- 0 ms latency;
- 50 ms latency;
- 250 ms latency;
- 2 second latency;
- timeout;
- connection reset;
- malformed response.

### Database growth

Seed:

- 100,000 ToolCalls;
- 1 million AuditEvents;
- multiple tenants;
- mixed statuses and dates.

Measure recent-call, approval queue, call-detail, and audit-verification queries with `EXPLAIN ANALYZE`.

## Tooling

Recommended tools:

- a custom C# MCP load driver using the official SDK;
- NBomber or a small dedicated load host for scheduling;
- PostgreSQL `EXPLAIN ANALYZE`;
- OpenTelemetry traces and .NET runtime metrics;
- Docker resource statistics.

## Likely bottlenecks

- audit writes in high-contention transactions;
- JSON serialization, canonicalization, encryption, and hashing;
- loading active policies from PostgreSQL for every request;
- downstream MCP connection management;
- unbounded audit and call-detail queries;
- idempotency and lease locks;
- large tool results;
- high-cardinality telemetry labels.

## Honest reporting

Use wording such as:

> On a local [hardware description] using Docker Compose, AgentGate sustained [X requests/second] across [Y] concurrent sessions with [Z ms] p95 gateway overhead. These are synthetic results and do not represent production usage.

Do not convert synthetic throughput into estimated users, customers, or business impact.