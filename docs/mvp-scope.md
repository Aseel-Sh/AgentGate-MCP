# MVP Scope

## Scope rule

The MVP exists to prove controlled MCP tool use, not to become a complete enterprise platform. A feature is required only when it is necessary to demonstrate policy enforcement, approval safety, durable execution, traceability, or evaluation.

## Required for MVP

- Human users with `Administrator`, `PolicyAuthor`, `Approver`, and `Viewer` roles.
- Machine-agent registration with revocable API credentials.
- Tenant context and two seeded tenants for isolation tests.
- Streamable HTTP MCP endpoint for upstream agents.
- Registration of downstream Streamable HTTP MCP servers.
- Tool discovery, schema hashing, local risk classification, and review state.
- Virtual tool catalog containing approved tools only.
- JSON Schema validation and canonical argument serialization.
- Deterministic `Allow`, `Deny`, `RequireApproval`, and bounded `Transform` decisions.
- Default-deny behavior.
- Policy versioning and deterministic reason codes.
- Human approval and rejection with expiration.
- Approval binding to agent, acting user, tenant, tool version, schema hash, and canonical argument hash.
- PostgreSQL-backed execution leases.
- Idempotency and duplicate-request protection.
- Execution attempts and safe handling of ambiguous outcomes.
- Append-only, hash-chained audit events.
- Correlated OpenTelemetry traces.
- Overview, approval queue, call detail, agents, servers/tools, policies, and evaluation-result screens.
- Deterministic integration, protocol, security, UI, reliability, and agent-behavior tests.
- Docker Compose and repeatable seed/reset scripts.

## Valuable after MVP

- Real GitHub issue creation in a dedicated sandbox repository.
- External OIDC login through Entra ID, Auth0, or Keycloak.
- Full MCP OAuth discovery and protected-resource conformance.
- Tool-list change notifications rather than manual refresh.
- Policy simulation before activation.
- External signed checkpoints for the audit hash chain.
- Durable per-policy quotas and usage limits.
- Prometheus and Grafana dashboards.
- Separate execution-worker deployment.
- A richer policy authoring UI.

## Future only

- Downstream stdio MCP servers.
- Experimental MCP task semantics for long-running approval flows.
- OPA, Cedar, or another external policy engine.
- Multiple execution regions.
- Enterprise tenant provisioning and billing.
- Pluggable external approval systems such as Slack or Teams.
- Distributed message brokers.
- Advanced policy relationship graphs.

## Unnecessary for this project

- MCP prompts, resources, roots, or sampling.
- Multi-agent orchestration.
- RAG, embeddings, vector search, or Qdrant.
- AI-generated authorization decisions.
- AI-generated policy explanations.
- A chatbot UI.
- Kafka, RabbitMQ, or Redis for the MVP queue.
- Kubernetes.
- A drag-and-drop workflow designer.
- Real email delivery.
- A custom identity provider.
- A full secrets-management product.

## Transport boundary

The MVP supports Streamable HTTP both upstream and downstream. Supporting arbitrary stdio processes would add process lifecycle, host filesystem, command injection, and credential-isolation concerns that do not strengthen the initial product claim.

## Approval contract

Approval-required calls do not hold an HTTP request open. AgentGate returns a structured pending result containing a call identifier and expiration. The demo agent retrieves the final state through `agentgate.get_call_status`.

This is reliable and implementable, but arbitrary MCP clients may require explicit handling of the pending-result contract. Full transparent interoperability is deferred.

## Authentication boundary

The MVP uses:

- ASP.NET Core Identity and secure cookies for human users;
- random agent API keys displayed once and stored as hashes;
- ASP.NET Core authorization policies for management permissions.

This is intentionally not presented as complete public MCP OAuth conformance.

## Completion gate

The MVP should be declared complete before adding real integrations when all of these are true:

1. The five sandbox tools are available through AgentGate.
2. Every tool has reviewed schemas and risk metadata.
3. Allow, deny, transform, and approval flows are demonstrated.
4. Approval tampering and duplicate execution are blocked.
5. Required audit events and traces are complete.
6. The deterministic security evaluation suite passes.
7. The documented demo runs from a clean reset.

No “nice to have” feature may block this gate.