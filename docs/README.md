# AgentGate Documentation

This directory contains the planning and design documents for AgentGate MCP. The repository is intentionally documentation-first; implementation should not begin until the key decisions and boundaries below are accepted.

## Core documents

1. [Product specification](product-specification.md) — problem, users, product boundary, success criteria, and limitations.
2. [Architecture](architecture.md) — components, request flow, service boundaries, and sequence diagrams.
3. [MCP compatibility baseline](mcp-compatibility.md) — pinned protocol and SDK versions, supported capabilities, and the approval-pending result contract.
4. [MVP scope](mvp-scope.md) — required features, deferred work, and explicit exclusions.
5. [Demonstration workflows](demonstration-workflows.md) — five sandboxed tools and the behavior each proves.
6. [Policy design](policy-design.md) — policy structure, precedence, transformations, and approval rules.
7. [Domain model](domain-model.md) — entities, state machines, relationships, and sensitive-data handling.
8. [Threat model](threat-model.md) — realistic attack scenarios, mitigations, tests, and limitations.
9. [Reliability model](reliability-model.md) — failure handling, idempotency, retries, leases, and recovery.
10. [Evaluation and testing](evaluation-and-testing.md) — software tests, MCP protocol tests, security tests, and agent evaluations.
11. [Observability and performance](observability-and-performance.md) — logs, metrics, traces, load tests, and honest reporting.
12. [Implementation roadmap](implementation-roadmap.md) — ordered phases, dependencies, tests, and definitions of done.
13. [Demo plan](demo-plan.md) — deterministic seed data, scripts, and a five-minute demo storyline.
14. [Architecture decision records](adr/README.md) — important choices and their tradeoffs.

## Development rule

A proposed feature belongs in the MVP only when it is necessary to prove at least one of these capabilities:

- controlled MCP tool invocation;
- deterministic policy enforcement;
- safe human approval;
- exactly-once logical execution under retries;
- traceable and tamper-evident evidence;
- security or agent-behavior evaluation.

Features that do not strengthen one of those claims should be deferred.