# MCP Compatibility Baseline

## Pinned baseline

AgentGate targets the following versions for the first implementation:

| Component | Pinned version | Notes |
|---|---:|---|
| MCP specification | `2025-11-25` | Latest stable specification at the time of this decision |
| .NET target | `.NET 10` | Primary application target |
| `ModelContextProtocol` | `1.4.0` | Official C# SDK client and hosting package |
| `ModelContextProtocol.AspNetCore` | `1.4.0` | Official ASP.NET Core package for HTTP MCP servers |
| Microsoft Agent Framework | Current compatible release at implementation time | Used only by the optional demo agent, never by the enforcement core |

Package versions must be pinned through central package management rather than floating ranges.

## Protocol version policy

AgentGate will advertise and test MCP protocol version `2025-11-25`.

The SDK may perform protocol negotiation, but AgentGate will maintain an explicit supported-version allowlist. The initial allowlist contains only `2025-11-25`. A different negotiated version must be rejected until its behavior is reviewed and added deliberately.

For Streamable HTTP, subsequent requests must use the negotiated `MCP-Protocol-Version` header.

## Transport boundary

### Supported

- Streamable HTTP upstream from agents to AgentGate.
- Streamable HTTP downstream from AgentGate to registered MCP servers.
- Stateful MCP sessions.
- JSON responses and SSE responses allowed by Streamable HTTP.
- Session identifiers managed by the official C# SDK and bound to the authenticated AgentGate principal.

### Not supported in the MVP

- stdio downstream servers;
- legacy HTTP+SSE compatibility endpoints;
- WebSocket transports;
- custom transports;
- stateless upstream sessions;
- resumability and event redelivery as a product guarantee.

AgentGate must validate allowed origins, restrict host exposure, authenticate all upstream connections, and prevent the demo agent from reaching downstream servers directly.

## MCP feature matrix

| Capability or message | Upstream AgentGate server | Downstream AgentGate client | MVP status |
|---|---|---|---|
| `initialize` / `notifications/initialized` | Yes | Yes | Required |
| Capability negotiation | Yes | Yes | Required |
| `tools/list` | Yes | Yes | Required |
| Cursor pagination for tool listing | Yes | Yes | Required |
| `tools/call` | Yes | Yes | Required |
| Tool input schemas | Yes | Yes | Required |
| Tool output schemas | Not republished initially | Read and stored | Deferred pending interoperability spike |
| `notifications/tools/list_changed` | Not advertised initially | Not relied upon | Manual discovery refresh in MVP |
| Progress notifications | Not advertised as a product feature | Not relied upon | Deferred |
| Cancellation | SDK behavior only | SDK behavior only | Not an MVP guarantee |
| Logging notifications | Optional internal support | Not relied upon | Deferred |
| MCP Tasks | Not advertised | Not requested | Excluded from MVP |
| Prompts | No | No | Excluded |
| Resources | No | No | Excluded |
| Roots | No | No | Excluded |
| Sampling | No | No | Excluded |
| Elicitation | No | No | Excluded |

Tool descriptions, annotations, and retry-related claims from downstream servers are untrusted until reviewed locally.

## Tool naming

AgentGate publishes server-qualified virtual tool names to prevent collisions.

Initial format:

```text
<server-alias>.<tool-name>
```

Examples:

```text
workspace.read_file
business.customers_search
business.communications_send_email
```

Published names must remain within MCP tool-name limits and may contain only letters, digits, underscores, hyphens, and dots.

## Tool result policy

### Protocol errors

Use JSON-RPC protocol errors for:

- malformed MCP requests;
- unknown published tool names;
- unsupported protocol versions;
- invalid session identifiers;
- internal failures that prevent creation of a valid tool result.

### Tool execution errors

Return a normal `CallToolResult` with `isError: true` for:

- schema-valid requests rejected by AgentGate policy;
- business validation failures;
- downstream API or tool failures;
- expired or invalid approval references;
- idempotency conflicts.

Policy denial is represented as a tool execution error because the request is structurally valid and the response contains actionable reason codes.

## AgentGate result envelope

Until the pending-result interoperability spike is complete, AgentGate will not republish downstream `outputSchema` values upstream. Every virtual tool returns ordinary MCP `content` plus an AgentGate-owned `structuredContent` envelope.

Common envelope:

```json
{
  "status": "completed | approval_required | denied | failed | outcome_unknown",
  "callId": "01J...",
  "tool": "workspace.read_file",
  "reasonCodes": [],
  "result": null,
  "approval": null,
  "error": null
}
```

### Completed call

```json
{
  "status": "completed",
  "callId": "01JABC...",
  "tool": "workspace.read_file",
  "reasonCodes": ["POLICY_ALLOW"],
  "result": {
    "downstreamStructuredContent": {
      "path": "docs/architecture.md",
      "byteCount": 4210
    }
  },
  "approval": null,
  "error": null
}
```

`isError` is `false`.

### Approval-required call

```json
{
  "status": "approval_required",
  "callId": "01JDEF...",
  "tool": "workspace.delete_file",
  "reasonCodes": [
    "TOOL_RISK_HIGH",
    "DESTRUCTIVE_ACTION_REQUIRES_APPROVAL"
  ],
  "result": null,
  "approval": {
    "approvalRequestId": "01JAPR...",
    "expiresAt": "2026-06-23T18:30:00Z",
    "statusTool": "agentgate.get_call_status"
  },
  "error": null
}
```

`isError` is `false` because AgentGate accepted and durably recorded the request. No downstream execution has occurred.

The text content must say clearly that approval is required and that the action has not executed.

### Denied call

```json
{
  "status": "denied",
  "callId": "01JGHI...",
  "tool": "customers.search",
  "reasonCodes": ["TENANT_MISMATCH"],
  "result": null,
  "approval": null,
  "error": {
    "code": "POLICY_DENIED",
    "message": "The requested tenant is outside the authenticated agent scope."
  }
}
```

`isError` is `true`.

### Ambiguous downstream outcome

```json
{
  "status": "outcome_unknown",
  "callId": "01JKLM...",
  "tool": "communications.send_email",
  "reasonCodes": ["DOWNSTREAM_RESPONSE_LOST_AFTER_DISPATCH"],
  "result": null,
  "approval": null,
  "error": {
    "code": "OUTCOME_UNKNOWN",
    "message": "AgentGate cannot prove whether the downstream side effect completed."
  }
}
```

`isError` is `true`. AgentGate must not automatically retry a non-idempotent action in this state.

## `agentgate.get_call_status`

AgentGate publishes one control-plane tool:

```text
agentgate.get_call_status
```

Input:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": ["callId"],
  "properties": {
    "callId": {
      "type": "string",
      "minLength": 1,
      "maxLength": 64
    }
  }
}
```

Behavior:

- authenticates the same agent and tenant that created the call;
- returns the common AgentGate result envelope;
- never creates a second execution;
- returns `approval_required` while waiting;
- returns `completed`, `denied`, `failed`, or `outcome_unknown` after a terminal state;
- returns a tool execution error when the caller cannot access the call;
- does not expose raw encrypted arguments or sensitive downstream output.

## Why MCP Tasks are not used yet

MCP Tasks were introduced in specification version `2025-11-25` and are explicitly marked experimental. They are a natural future fit for deferred approval and polling, but the MVP will not depend on experimental behavior or assume support across target clients.

AgentGate's custom pending envelope is an intentional temporary compatibility choice. It must be revisited after the official C# SDK and Microsoft Agent Framework interoperability spike.

## Known assumptions requiring verification

Issue #19 must verify:

1. `structuredContent` survives the official C# SDK client/server path.
2. Microsoft Agent Framework exposes the pending envelope to the demo agent.
3. `isError: false` plus `status: approval_required` does not cause misleading automatic behavior.
4. `agentgate.get_call_status` results are usable by both clients.
5. Omitting upstream output schemas avoids validation conflicts.

If any assumption fails, update this document and ADR 003 before approval workflow implementation.

## Official references

- [MCP specification 2025-11-25](https://modelcontextprotocol.io/specification/2025-11-25)
- [MCP lifecycle](https://modelcontextprotocol.io/specification/2025-11-25/basic/lifecycle)
- [MCP Streamable HTTP transport](https://modelcontextprotocol.io/specification/2025-11-25/basic/transports)
- [MCP tools](https://modelcontextprotocol.io/specification/2025-11-25/server/tools)
- [MCP Tasks](https://modelcontextprotocol.io/specification/2025-11-25/basic/utilities/tasks)
- [Official C# SDK](https://github.com/modelcontextprotocol/csharp-sdk)
- [ModelContextProtocol 1.4.0](https://www.nuget.org/packages/ModelContextProtocol/1.4.0)
- [ModelContextProtocol.AspNetCore 1.4.0](https://www.nuget.org/packages/ModelContextProtocol.AspNetCore/1.4.0)
- [Microsoft Agent Framework MCP tools](https://learn.microsoft.com/en-us/agent-framework/agents/tools/local-mcp-tools)