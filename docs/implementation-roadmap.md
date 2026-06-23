# Implementation Roadmap

The project should begin with a thin, working MCP path before adding policies, approvals, or a dashboard. Each phase ends with a demonstrable checkpoint and a strict definition of done.

## Phase 0 — Research and architecture decisions

### Goal

Remove major ambiguity before production code begins.

### Tasks

- Pin the MCP specification and official C# SDK versions.
- Confirm Streamable HTTP upstream and downstream.
- Write and accept the initial ADRs.
- Finalize the five demonstration tools.
- Define the approval pending-result contract.
- Define tenant and acting-user semantics.
- Define idempotency metadata.
- Create the first threat-model and evaluation fixtures.

### Tests

Disposable SDK connection spikes only. No application implementation.

### Definition of done

- All critical ADRs are accepted.
- State diagrams and request flows agree with each other.
- The MVP and exclusions are explicit.
- The first 15 backlog issues are ready.

### Demo checkpoint

Walk through one allowed, one denied, and one approval-required request on the architecture diagrams.

### Main risk

Research expanding into speculative enterprise features.

---

## Phase 1 — Minimal MCP vertical slice

### Goal

Forward one safe tool call through AgentGate.

### Functionality

- Workspace sample MCP server.
- `workspace.read_file`.
- AgentGate upstream MCP endpoint.
- Downstream MCP client.
- Static tool mapping.
- Minimal demo client or agent.

### Dependencies

Phase 0.

### Tasks

- Implement the sample MCP server.
- Connect AgentGate using the official C# SDK.
- List one downstream tool.
- Republish the tool upstream.
- Forward arguments and return the result.
- Add correlation identifiers.

### Tests

- MCP initialization.
- Tool listing.
- Successful read.
- Unknown tool.
- Downstream unavailable.

### Definition of done

A demo client reads a seeded file only through AgentGate.

### Demo checkpoint

Agent → AgentGate → workspace MCP server → result.

### Main risk

Using SDK abstractions without understanding protocol and failure behavior.

---

## Phase 2 — Durable registrations and call state

### Goal

Replace static configuration with durable, inspectable state.

### Functionality

- PostgreSQL and EF Core.
- Tenants, agents, sessions, servers, tools, and ToolCalls.
- Server registration and manual discovery refresh.
- Tool review and schema drift detection.
- ToolCall state machine.
- Idempotency records.
- Initial audit events.

### Dependencies

Phase 1.

### Tests

- Migrations and constraints.
- Registration.
- Tool schema persistence.
- Invalid state transitions.
- Duplicate idempotency keys.
- Changed tool schema.
- Restart persistence.

### Definition of done

Restarting AgentGate preserves registrations, reviewed tool versions, and call history.

### Demo checkpoint

Register a server, discover a tool, approve its schema, invoke it, restart, and view the call.

### Main risk

Overdesigning the data model before policy behavior is proven.

---

## Phase 3 — Authentication and application authorization

### Goal

Create trustworthy principals before complex policy evaluation.

### Functionality

- ASP.NET Core Identity for human users.
- Roles and authorization policies.
- Agent API keys.
- Agent suspension, revocation, and rotation.
- Tenant context.
- Session-to-agent binding.

### Dependencies

Phase 2.

### Tests

- Invalid and revoked keys.
- Role-restricted routes.
- Tenant boundary.
- Forged metadata.
- Session reuse by another agent.
- Credential rotation.

### Definition of done

Every MCP and management request is authenticated or rejected, and all tenant-sensitive paths have authorization tests.

### Demo checkpoint

Two agents see different published tool catalogs.

### Main risk

Accidentally building an identity platform instead of a focused MVP.

---

## Phase 4 — Deterministic policy enforcement

### Goal

Implement allow, deny, transformations, and default-deny behavior.

### Functionality

- Policy schema and validator.
- Versioning and activation.
- Fact extraction.
- Evaluation precedence.
- Safe transformation library.
- Deterministic explanations.

### Dependencies

Phases 2 and 3.

### Tests

- Every supported operator.
- Deny precedence.
- No-policy default deny.
- Transformation conflicts.
- Tenant checks.
- Path restrictions.
- Integer clamping.
- Determinism across repeated runs.

### Definition of done

Versioned policy fixtures produce identical decisions, transformations, reason codes, and matched-policy evidence.

### Demo checkpoint

Safe read allowed, cross-tenant lookup denied, customer limit transformed.

### Main risk

Allowing the custom policy format to become a general programming language.

---

## Phase 5 — Approval and durable execution

### Goal

Pause and resume high-risk actions safely.

### Functionality

- ApprovalRequest and ApprovalDecision.
- Approval expiration.
- Exact argument and schema hash binding.
- PostgreSQL-backed worker leases.
- ExecutionAttempt.
- `agentgate.get_call_status`.
- Result persistence.

### Dependencies

Phase 4.

### Tests

- Approve, reject, expire, and double-decision races.
- Changed arguments after approval.
- Schema drift after approval.
- Worker restart.
- Duplicate submission.
- Lease recovery.
- Ambiguous downstream outcome.

### Definition of done

No approval-required tool can execute without one valid, unexpired, correctly bound approval.

### Demo checkpoint

Delete-file request → approval queue → approval → one deletion.

### Main risk

Unsafe retries after an ambiguous external outcome.

---

## Phase 6 — Tamper-evident audit and traces

### Goal

Make every important action reconstructable.

### Functionality

- Append-only AuditEvent table.
- Database protections.
- Chained event hashes.
- Verification process.
- Redacted payloads.
- OpenTelemetry correlation.
- Complete call timeline.

### Dependencies

Phases 2 through 5.

### Tests

- Event ordering.
- Missing or modified event detection.
- Secret redaction.
- Trace correlation.
- Audit failure before and after dispatch.

### Definition of done

Every terminal ToolCall can be reconstructed and its audit chain verified.

### Demo checkpoint

Open a call and follow request, policy, approval, execution, and result.

### Main risk

Calling a database-only hash chain immutable rather than accurately describing it as tamper-evident.

---

## Phase 7 — Management UI

### Goal

Make the backend behavior understandable without database access.

### Functionality

- Overview.
- Approval queue.
- Tool-call detail and timeline.
- Agents.
- MCP servers and reviewed tools.
- Policy list and validated JSON editor.
- Evaluation results.

### Dependencies

Stable core workflows.

### Tests

- Playwright critical paths.
- Role-specific access.
- Approval races.
- Redacted data display.
- Normal desktop responsiveness.

### Definition of done

A reviewer can complete the full demo using the UI and demo agent.

### Demo checkpoint

Run the safe, denied, and approval-required paths without direct database or API manipulation.

### Main risk

Spending time on visual complexity instead of core evaluations.

---

## Phase 8 — Evaluation and security suite

### Goal

Make proof of control behavior a first-class project feature.

### Functionality

- Versioned evaluation scenarios.
- Deterministic runner.
- Adversarial fixtures.
- Metrics calculation.
- CI artifacts and dashboard display.

### Dependencies

Phases 4 through 7.

### Tests

All required scenarios in `evaluation-and-testing.md`, including direct bypass, prompt injection, cross-tenant access, tampering, replay, malformed inputs, timeouts, and explanation claims.

### Definition of done

One command runs the suite and produces a report tied to the current commit SHA.

### Demo checkpoint

Run the full deterministic suite and open its results.

### Main risk

Relabeling ordinary unit tests as AI evaluations without agent-specific scenarios.

---

## Phase 9 — Reliability, observability, and performance

### Goal

Validate failure behavior and quantify gateway overhead.

### Functionality

- Fault-injecting MCP server.
- Timeouts and retry classifications.
- Circuit breaker.
- Runtime metrics and traces.
- Load tests.
- Database-growth tests.
- Worker recovery tests.

### Dependencies

Stable evaluation suite.

### Tests

- Connection failures.
- Downstream timeouts.
- Response loss after side effect.
- Worker termination.
- PostgreSQL restart.
- Malformed result.
- Audit-write failure.
- Concurrent sessions and calls.

### Definition of done

Every documented failure has an observed result and every performance claim includes environment and methodology.

### Demo checkpoint

Trigger a timeout and show the safe or reviewable final state and correlated trace.

### Main risk

Optimizing before a baseline exists.

---

## Phase 10 — Deployment, documentation, and demo polish

### Goal

Make the repository independently reviewable.

### Functionality

- Docker Compose.
- Seed and reset scripts.
- CI workflows.
- Screenshots and demo recording.
- Generated evaluation report.
- Measured performance report.
- Limitations and roadmap.

### Dependencies

All prior phases.

### Tests

- Fresh clone and setup.
- Clean CI environment.
- Demo reset.
- Documentation commands.
- Secret scanning.

### Definition of done

A fresh environment can run the deterministic demo using only documented commands.

### Demo checkpoint

Final five-minute recording.

### Main risk

Discovering environment assumptions only after implementation is considered complete.