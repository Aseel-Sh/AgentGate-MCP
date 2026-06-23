# ADR 001: Use a Modular Monolith

## Status
Accepted.

## Context
AgentGate needs MCP transport handling, policy evaluation, approvals, background execution, persistence, audit, and a small UI. Splitting these into services would create distributed transactions and deployment overhead before the core behavior is proven.

## Decision
Build one ASP.NET Core deployable with explicit internal modules and one PostgreSQL database.

## Alternatives
- Microservices: stronger deployment isolation, but too much coordination and operational work for the MVP.
- Unstructured single project: faster initially, but encourages transport, domain, and persistence logic to mix.

## Tradeoffs
The first deployment shares process and resource boundaries. Module dependencies must be kept explicit through interfaces and tests rather than network calls.

## Revisit when
Split the execution worker only if it needs independent network permissions, measured scaling, or failure isolation.