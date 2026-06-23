# ADR 003: Asynchronous Approval Contract

## Status
Accepted.

## Context
Human approval may take minutes. Holding an MCP HTTP request open is fragile, while stable cross-client support for durable MCP task semantics cannot be assumed for the MVP.

## Decision
An approval-required tool call returns a structured pending result containing the ToolCall identifier, reason, and expiry. The demo agent retrieves the eventual result using `agentgate.get_call_status`.

Approval is bound to the tenant, agent, acting user, tool definition, schema hash, canonical argument hash, policy decision, and expiry.

## Alternatives
- Keep the request open: vulnerable to disconnects and infrastructure timeouts.
- Depend on experimental task semantics: stronger protocol fit later, but unnecessary risk now.
- Put approval inside the agent: not an independent enforcement boundary.

## Tradeoffs
Generic MCP clients may not automatically understand the pending-result contract. The repository must document this limitation clearly.

## Revisit when
Adopt standard task behavior when the specification, official C# SDK, and target clients support it reliably.