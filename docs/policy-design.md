# Policy Design

## Decision

The MVP will use a **small typed JSON policy format interpreted inside AgentGate**. It will not use an LLM, arbitrary scripts, OPA, Cedar, or a general expression language.

The purpose is to demonstrate strong authorization engineering without turning the project into a policy-language product.

## Evaluation context

Policies may evaluate the following facts:

```text
Subject
  AgentId
  AgentStatus
  AgentTags
  ActingUserId
  ActingUserRoles
  TenantId

Session
  SessionId
  Environment
  StartedAt
  PreviousActionSummary

Resource
  MCPServerId
  ServerTrustStatus
  ToolDefinitionId
  ToolName
  ToolRisk
  OperationType
  SensitivityTags
  ResourceOwner

Request
  CanonicalArguments
  ExtractedArgumentFacts
  IdempotencyKeyHash
  RequestedAt
```

`ExtractedArgumentFacts` are produced by trusted, typed fact extractors registered by AgentGate. Policies do not execute user-provided code or arbitrary network/database lookups.

## Example policy

```json
{
  "name": "Require approval for outbound email",
  "version": 3,
  "priority": 200,
  "effect": "RequireApproval",
  "when": {
    "all": [
      {
        "field": "tool.name",
        "operator": "Equals",
        "value": "communications.send_email"
      },
      {
        "field": "agent.status",
        "operator": "Equals",
        "value": "Active"
      }
    ]
  },
  "approval": {
    "requiredRole": "Approver",
    "expiresAfterMinutes": 30
  },
  "reasonCode": "EMAIL_REQUIRES_HUMAN_APPROVAL"
}
```

## Supported effects

- `Deny`
- `RequireApproval`
- `Allow`
- `Transform`

A transformation is not a final authorization decision. After transformations are applied, the resulting arguments are validated, canonicalized, and evaluated again.

## Supported condition operators

Initial operators:

- `Equals`
- `NotEquals`
- `In`
- `NotIn`
- `Contains`
- `StartsWith`
- `LessThanOrEqual`
- `GreaterThanOrEqual`
- `Exists`
- `SameTenant`
- `HasRole`
- `TimeBetween`

Explicitly excluded from the MVP:

- arbitrary regular expressions;
- user-authored functions;
- embedded C# or JavaScript;
- policy-time network calls;
- policy-time SQL queries;
- model-based classifications.

## Supported transformations

Transformations come from a predefined server-side library:

- clamp an integer;
- force a value;
- remove a field;
- filter a list against an allowlist;
- restrict a path to a configured root;
- set a safe default;
- mark a result field for redaction.

Conflicting transformations cause a denial with a configuration-error reason. AgentGate must never guess which conflicting rule should win.

## Evaluation order

1. Authenticate the request and resolve trusted identity facts.
2. Enforce non-configurable system invariants.
3. Validate the input against the reviewed tool schema.
4. Normalize values and serialize canonical JSON.
5. Find active policies matching the tenant, agent, server, and tool.
6. Evaluate conditions in deterministic priority order.
7. Any system-invariant failure denies the request.
8. Any matching explicit deny wins.
9. Apply compatible transformations in priority order.
10. Revalidate and recanonicalize transformed arguments.
11. If any matching policy requires approval, return `RequireApproval`.
12. Otherwise allow only when at least one explicit allow rule matches.
13. If no allow rule matches, deny by default.

## Default behavior

AgentGate is default deny.

A newly discovered tool cannot be called until:

- its downstream server is trusted;
- the schema version is reviewed;
- risk and operation metadata are assigned;
- the tool is published;
- at least one explicit allow policy applies.

## Policy versioning

- Policies begin as `Draft`.
- Activating a policy creates an immutable version.
- Updating an active policy creates a new version rather than editing history.
- Previous versions remain available for audit explanations.
- A decision records every matched policy ID and version.
- A policy may be `Active`, `Superseded`, or `Disabled`.

## Conflict resolution

Precedence rules:

1. System invariant failure.
2. Explicit deny.
3. Transformation conflict.
4. Require approval.
5. Explicit allow.
6. Default deny.

Priority controls evaluation and transformation order, but a high-priority allow cannot override a lower-priority deny.

## Approval binding

An approval covers exactly:

```text
Tenant ID
Agent ID
Acting user ID
Tool definition ID
Tool schema hash
Canonical argument hash
Policy decision ID
Approval expiry
```

Before execution, the worker recalculates and compares every binding. Any mismatch prevents execution and requires a new call and approval.

## Decision explanation

Explanations are structured facts, not AI-generated prose:

```json
{
  "decision": "RequireApproval",
  "reasonCodes": [
    "TOOL_RISK_HIGH",
    "EMAIL_REQUIRES_HUMAN_APPROVAL"
  ],
  "matchedPolicies": [
    { "id": "policy-17", "version": 3 }
  ],
  "facts": {
    "tool": "communications.send_email",
    "riskLevel": "High",
    "externalRecipientCount": 1
  }
}
```

The UI may render this in readable language, but it must not introduce unsupported claims.

## Rate limits

The MVP uses ASP.NET Core rate limiting for:

- requests per agent;
- failed authentication attempts;
- concurrent downstream calls;
- approval actions.

Durable quotas embedded in the policy language are deferred because they require distributed counters and precise time-window semantics.

## Alternatives considered

### Open Policy Agent

OPA is established and expressive, but introduces Rego, another runtime boundary, and additional work for approval and transformation semantics. It should be reconsidered only when policies must be shared across products or the internal DSL becomes too complex.

### Cedar

Cedar provides a strong principal-action-resource authorization model, but approval orchestration and argument transformations would still live inside AgentGate. It should be reconsidered when relationship-aware authorization becomes a real requirement.

## Revisit trigger

The custom policy model should be reevaluated when any of these occur:

- more than roughly 10–12 operators are required;
- policy authors request custom computation;
- policies must be shared across multiple systems;
- policy evaluation becomes a separate scaling boundary;
- an external security team requires a standard policy language.