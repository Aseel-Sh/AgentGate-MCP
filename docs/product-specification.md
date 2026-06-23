# Product Specification

## Executive assessment

AgentGate MCP is a tool-governance gateway for AI agents. It sits between an upstream agent and one or more downstream MCP servers, evaluates every requested tool call against deterministic policies, pauses risky calls for human approval, executes approved calls, and records the full decision and execution history.

The project is valuable because MCP standardizes tool discovery and invocation, but teams still need consistent application-level controls for agent identity, acting-user identity, tenant scope, tool risk, argument restrictions, approvals, retries, and audit evidence.

AgentGate does not claim that MCP lacks authorization. MCP authorization protects access to HTTP resources and servers. AgentGate adds action-level governance: whether a specific principal may invoke a specific tool with specific arguments in a specific context.

## Primary user

The MVP is designed for a developer or platform engineer connecting an internal AI agent to tools that can read sensitive information or perform side effects.

They need:

- one controlled MCP endpoint for the agent;
- a reviewed catalog of downstream tools;
- deterministic allow, deny, transform, and approval decisions;
- safe handling of retries and asynchronous approvals;
- an understandable record of what happened;
- reproducible tests proving that unsafe actions are blocked.

Secondary users are human approvers, security engineers, and engineering leads reviewing actions.

## Product category

AgentGate is an **MCP tool-governance gateway and policy enforcement point**. It may also be described as an agent action firewall or tool-use authorization broker, but the project should avoid broad claims such as “complete AI security platform.”

## Product boundary

AgentGate is:

- an MCP server exposed to upstream agents;
- an MCP client connecting to registered downstream MCP servers;
- a deterministic policy enforcement point;
- a durable approval coordinator;
- a controlled execution worker;
- an audit and trace system;
- a small management UI.

AgentGate is not:

- an LLM provider;
- an agent framework;
- a chatbot;
- an OAuth authorization server;
- a general workflow platform;
- a general-purpose policy language;
- a malware sandbox;
- a guarantee that a downstream tool behaves honestly;
- a replacement for authorization inside downstream services.

## Request lifecycle

1. An authenticated agent opens an MCP session with AgentGate.
2. AgentGate publishes only reviewed tools available to that agent.
3. The agent submits a tool call.
4. AgentGate resolves the agent, acting user, tenant, session, downstream server, tool definition, and tool schema version.
5. Arguments are schema-validated, normalized, and converted to canonical JSON.
6. A durable ToolCall record is created using an idempotency key.
7. The deterministic policy engine evaluates the complete request context.
8. The result is Allow, Deny, RequireApproval, or a bounded Transform followed by reevaluation.
9. Allowed calls execute through the downstream MCP client.
10. Denied calls never reach the downstream server.
11. Approval-required calls create a durable approval request bound to the exact agent, user, tool schema, and canonical argument hash.
12. Approved calls are leased and executed by a background worker.
13. Results, attempts, policy evidence, approvals, traces, and audit events are persisted.

## MVP success criteria

The MVP is complete when a seeded demo proves all of the following:

- a safe read succeeds through AgentGate;
- a cross-tenant read is denied before downstream execution;
- a destructive action enters the approval queue;
- the approved action executes exactly once;
- changed arguments invalidate the old approval;
- duplicate requests do not create duplicate side effects;
- direct downstream access is unavailable to the agent;
- the full call timeline is visible;
- the deterministic evaluation suite passes the required security scenarios.

## Product value

The project is useful rather than purely technical when it demonstrates a workflow that a team could actually adopt:

- the agent receives one MCP connection;
- platform engineers register and review downstream tools;
- security-sensitive rules are centrally expressed;
- approvers see exact action details instead of a vague model summary;
- developers can trace failures and prove expected behavior in CI.

## Credibility requirements

Recruiters should be able to find evidence of:

- precise scope control;
- protocol-correct MCP client and server behavior;
- state machines and concurrency handling;
- authentication and role-based authorization;
- policy versioning and deterministic explanations;
- approval binding and idempotent execution;
- realistic threat modeling;
- protocol, security, integration, UI, fault, and load tests;
- measured results without invented production claims.

## Limitations

AgentGate cannot guarantee that:

- an agent is safe outside tools routed through AgentGate;
- a malicious downstream server performs the action it claims;
- a human approval decision is correct;
- a privileged administrator cannot alter configuration;
- every external side effect can be reversed;
- a lost response proves that an external action did not happen;
- sensitive data remains safe after an authorized tool sends it elsewhere;
- direct bypass is prevented unless deployment and credentials enforce the network boundary.

These limitations must remain visible in the final README and demo.