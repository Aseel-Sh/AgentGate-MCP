# ADR 005: MVP Authentication

## Status
Accepted for MVP.

## Context
AgentGate needs trustworthy human and machine principals, but implementing a complete identity provider or OAuth authorization server would overwhelm the first release.

## Decision
Use ASP.NET Core Identity with secure cookies for human users. Use randomly generated agent credentials displayed once and stored as secure hashes. Bind every MCP session to the authenticated agent and tenant.

## Alternatives
- Full OAuth and OIDC from the first feature: better interoperability, but high setup and conformance cost.
- Shared development token: insufficient for identity, rotation, revocation, and audit testing.
- Framework-provided identity only: couples enforcement to one agent framework.

## Tradeoffs
The MVP must not claim complete public MCP OAuth conformance. Agent credentials require rotation, revocation, rate limiting, and careful log redaction.

## Revisit when
Move to standardized OAuth/OIDC before public deployment or external-client interoperability claims.