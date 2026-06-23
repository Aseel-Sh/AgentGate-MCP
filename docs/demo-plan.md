# Demo Plan

## Goal

Demonstrate the product in five minutes without relying on live external services, manual database edits, or nondeterministic model behavior.

## Seed data

### Tenants

- `Acme`
- `Globex`

### Human users

- `Aseel Admin` — Administrator and PolicyAuthor.
- `Sam Approver` — Approver.
- `Vera Viewer` — Viewer.

### Agent

- `acme-repo-assistant`

### Downstream MCP servers

- Workspace MCP server.
- Business MCP server.

### Seed resources

- Repository containing `docs/architecture.md`.
- Sandbox file `sandbox/temp.txt` with a known SHA-256 hash.
- Acme and Globex customer records.
- Empty fake mailbox.
- Empty mock issue tracker.
- Active policy versions for the five demonstration tools.

## Required scripts

```text
scripts/start-demo
scripts/reset-demo
scripts/seed-demo
scripts/run-demo-agent
scripts/run-evaluations
scripts/run-load-tests
scripts/verify-audit-chain
```

The reset script must:

- restore deleted sandbox files;
- clear fake mail and issues;
- clear tool calls, approvals, attempts, and evaluation runs;
- reseed both tenants and users;
- restore known tool schema versions;
- activate the expected policy versions;
- verify that downstream services are healthy.

## Five-minute storyline

### 0:00–0:40 — Explain the boundary

Show the component diagram and explain:

- the agent connects only to AgentGate;
- AgentGate holds the downstream server registrations and credentials;
- every call passes through validation, policy, approval, execution, and audit.

### 0:40–1:10 — Safe read succeeds

Ask the demo agent to read `docs/architecture.md`.

Show:

- `workspace.read_file` is allowed;
- the downstream server executes once;
- the response is returned;
- the trace contains validation, policy, execution, and audit spans.

### 1:10–1:40 — Unauthorized access is denied

Submit `customers.search` for Globex while authenticated as the Acme agent.

Show:

- `TENANT_MISMATCH`;
- the matched policy version;
- zero downstream executions;
- a denied audit timeline.

### 1:40–2:30 — Destructive action enters approval

Request deletion of `sandbox/temp.txt` with its expected hash.

Show:

- `approval_required` result;
- approval request in the queue;
- agent, acting user, path, current hash, reason, risk, policy evidence, and expiry;
- no downstream deletion yet.

### 2:30–3:15 — Human approves and exact action executes

Log in as Sam Approver and approve.

Show:

- approval bound to the canonical argument and schema hashes;
- worker lease and execution attempt;
- file deleted exactly once;
- agent retrieves the completed result through `agentgate.get_call_status`.

### 3:15–3:45 — Tampering is blocked

Attempt to reuse the previous approval while changing the path or expected hash.

Show:

- old approval rejected because the binding does not match;
- zero execution under the old approval;
- a new call and approval would be required.

### 3:45–4:15 — Direct bypass is blocked

From the demo-agent environment, attempt to reach the workspace MCP server directly.

Show:

- network or authentication failure;
- no downstream credential present in the agent environment;
- AgentGate remains the only usable tool path.

### 4:15–5:00 — Show evidence

Open:

- complete tool-call timeline;
- audit-chain verification status;
- deterministic evaluation results;
- unauthorized-action prevention rate;
- approval-bypass rate;
- duplicate-execution rate;
- current measured latency numbers, once available.

## Determinism requirements

- The core demo does not require a paid LLM API.
- A scripted MCP client can produce every request.
- Optional Microsoft Agent Framework behavior is shown separately.
- Every seed identifier and expected file hash is stable.
- Fake downstream services expose deterministic failure modes.
- Reset returns the environment to a known state.
- Evaluation output includes the commit SHA and fixture version.

## Screenshots required for the README

- Overview dashboard.
- Approval queue.
- Approval detail with exact argument binding.
- Denied cross-tenant call.
- Complete execution timeline.
- Evaluation results.
- OpenTelemetry trace.

## Demo failure fallback

If the optional live-model agent behaves unexpectedly, switch immediately to the deterministic MCP client. The product demonstration is AgentGate's enforcement behavior, not whether a model chooses the expected tool on one run.