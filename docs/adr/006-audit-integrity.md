# ADR 006: Tamper-Evident Audit Records

## Status
Accepted.

## Context
AgentGate must reconstruct security-sensitive decisions and detect unauthorized modification without claiming impossible immutability guarantees.

## Decision
Store append-only AuditEvents in PostgreSQL. Each event contains a payload hash, previous-event hash, and event hash. The application database role cannot update or delete audit rows, and a verification process checks chain continuity.

## Alternatives
- Ordinary mutable history table: simple but weak evidence.
- External immutable ledger: stronger isolation, but unnecessary infrastructure for the MVP.
- OpenTelemetry traces only: useful for operations but not an authoritative domain record.

## Tradeoffs
A privileged database or host administrator could still alter data and recompute hashes. The system is tamper-evident within the stated trust model, not absolutely immutable.

## Revisit when
Add externally signed or independently stored checkpoints when the project needs stronger evidence across administrative boundaries.