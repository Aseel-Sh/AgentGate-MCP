# ADR 004: Typed JSON Policy Engine

## Status
Accepted.

## Context
AgentGate needs deterministic decisions, bounded argument transformations, approval requirements, and explanations. A general policy language would create a second major product.

## Decision
Implement a small typed JSON format with a fixed operator set, explicit precedence, versioned policies, default deny, and registered safe transformations. No LLM participates in authorization.

## Alternatives
- OPA/Rego: mature and expressive, but adds a runtime and does not remove AgentGate-specific approval logic.
- Cedar: strong authorization model, but approval orchestration and transformations remain custom.
- Hard-coded rules: simple initially, but difficult to configure, audit, and evaluate.

## Tradeoffs
AgentGate owns schema validation, migrations, semantics, and tests for the policy format. The DSL must remain deliberately limited.

## Revisit when
Reconsider OPA or Cedar when policies must be shared across products, require relationship graphs, or exceed the bounded operator model.