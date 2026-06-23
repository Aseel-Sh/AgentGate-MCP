# Demonstration Workflows

The MVP uses five sandboxed tools. Together they demonstrate low-risk reads, sensitive reads, medium-risk writes, high-risk external actions, destructive actions, transformations, approvals, tenant isolation, argument binding, and idempotency.

## 1. `workspace.read_file`

### Purpose

Read a file from a seeded repository workspace.

### Input schema

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": ["path"],
  "properties": {
    "path": { "type": "string", "minLength": 1, "maxLength": 300 },
    "maxBytes": { "type": "integer", "minimum": 1, "maximum": 100000 }
  }
}
```

### Risk and permissions

- Risk: Low read.
- Required permission: `workspace.read`.

### Example policies

- Allow only paths below the approved repository root.
- Deny `.env`, `.git`, secret files, and path traversal.
- Clamp `maxBytes` to 20,000.

### Audit evidence

- Requested path.
- Safely resolved path.
- Original and transformed argument hashes.
- Output byte count and content hash.
- Matched policy versions.

### Safe demo

Read `docs/architecture.md`. The full file body is not written to normal logs or audit metadata.

---

## 2. `customers.search`

### Purpose

Query a mock customer database containing two tenants.

### Input schema

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": ["tenantId", "query"],
  "properties": {
    "tenantId": { "type": "string" },
    "query": { "type": "string", "maxLength": 100 },
    "limit": { "type": "integer", "minimum": 1, "maximum": 100 },
    "includeEmail": { "type": "boolean" }
  }
}
```

### Risk and permissions

- Risk: Sensitive read.
- Required permission: `customers.read`.

### Example policies

- Requested tenant must match the authenticated tenant.
- Clamp `limit` to 10.
- Force `includeEmail=false` unless the acting user has `CustomerPIIReader`.

### Audit evidence

- Tenant identifier.
- Query hash rather than raw search text when it may contain PII.
- Original and transformed argument hashes.
- Result count.
- Sensitivity tags.

### Safe demo

An Acme agent successfully searches Acme records, then receives `TENANT_MISMATCH` when requesting Globex data. The denied call must produce zero downstream executions.

---

## 3. `issues.create`

### Purpose

Create an issue in a mock issue tracker. A real GitHub sandbox implementation can be added after MVP.

### Input schema

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": ["repository", "title", "body"],
  "properties": {
    "repository": { "type": "string" },
    "title": { "type": "string", "maxLength": 200 },
    "body": { "type": "string", "maxLength": 5000 },
    "labels": {
      "type": "array",
      "maxItems": 10,
      "items": { "type": "string" }
    }
  }
}
```

### Risk and permissions

- Risk: Medium write.
- Required permission: `issues.create`.

### Example policies

- Allow without approval only for `acme/agentgate-sandbox`.
- Require approval for other registered repositories.
- Deny unregistered repositories.
- Filter labels to an approved list.

### Audit evidence

- Repository.
- Issue title.
- Body hash.
- Requested and accepted labels.
- Resulting issue identifier.

### Safe demo

Create an issue in the in-memory or PostgreSQL-backed mock tracker and show the exact downstream arguments.

---

## 4. `communications.send_email`

### Purpose

Send an email to a fake mailbox service.

### Input schema

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": ["to", "subject", "body"],
  "properties": {
    "to": {
      "type": "array",
      "minItems": 1,
      "maxItems": 10,
      "items": { "type": "string", "format": "email" }
    },
    "cc": {
      "type": "array",
      "maxItems": 10,
      "items": { "type": "string", "format": "email" }
    },
    "subject": { "type": "string", "maxLength": 200 },
    "body": { "type": "string", "maxLength": 10000 }
  }
}
```

### Risk and permissions

- Risk: High external side effect.
- Required permission: `email.send`.

### Example policies

- Always require approval.
- Deny external recipient domains unless the approver has `ExternalCommunicationsApprover`.
- Deny or redact configured sensitive-data patterns.

### Audit evidence

- Recipient domains.
- Recipient hashes.
- Subject.
- Body hash.
- Sensitivity detections.
- Fake delivery identifier.

### Safe demo

The approved message appears only in the fake mailbox UI. The MVP never sends real email.

---

## 5. `workspace.delete_file`

### Purpose

Delete a file from a disposable sandbox directory.

### Input schema

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": ["path", "expectedSha256", "reason"],
  "properties": {
    "path": { "type": "string", "maxLength": 300 },
    "expectedSha256": { "type": "string", "minLength": 64, "maxLength": 64 },
    "reason": { "type": "string", "maxLength": 500 }
  }
}
```

### Risk and permissions

- Risk: High destructive action.
- Required permission: `workspace.delete`.

### Example policies

- Deny any path outside the sandbox deletion directory.
- Deny protected files.
- Require approval for every valid deletion.
- Require the current file hash to equal `expectedSha256` immediately before execution.

### Audit evidence

- Requested and resolved path.
- Expected hash.
- Actual pre-delete hash.
- Reason.
- Approver identity.
- Deletion result.

### Safe demo

Delete `sandbox/temp.txt`, then restore it with the deterministic reset script.

## Combined demo value

These tools prove that AgentGate can:

- allow a safe action;
- deny unauthorized tenant access;
- transform arguments without relying on an LLM;
- gate external and destructive side effects;
- bind approval to exact arguments;
- verify state immediately before execution;
- prevent duplicate side effects;
- produce understandable evidence for every path.