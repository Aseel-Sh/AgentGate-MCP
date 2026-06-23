# ADR 002: MCP Gateway Boundary

## Status
Accepted.

## Context
AgentGate must intercept tool calls without becoming an agent framework or requiring changes inside every downstream server.

## Decision
AgentGate acts as an MCP server to upstream agents and an MCP client to downstream servers. The MVP supports Streamable HTTP in both directions and governs MCP tools only.

## Alternatives
- Agent-framework middleware only: easier, but framework-specific and bypassable by another client.
- Changes inside every MCP server: duplicates policy and approval behavior.
- Arbitrary stdio support: increases process, filesystem, and command-execution risk.

## Tradeoffs
AgentGate must virtualize tool names and handle discovery, schema versioning, errors, and sessions. Prompts, resources, sampling, roots, and stdio are deferred.

## Revisit when
Add another transport or MCP capability only when a concrete integration requires it and its security boundary is defined.