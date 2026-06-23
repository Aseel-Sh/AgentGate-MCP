# ADR 007: PostgreSQL-Backed Execution Worker

## Status
Accepted.

## Context
Approved calls must survive restarts and execute safely, but the MVP does not need a separate message broker.

## Decision
Represent executable work as durable ToolCall rows. Background workers lease approved calls using PostgreSQL row locks and `FOR UPDATE SKIP LOCKED`, persist an ExecutionAttempt before dispatch, and apply tool-specific retry classifications.

## Alternatives
- RabbitMQ or Kafka: useful across services, but unnecessary operational cost for one modular monolith.
- In-memory queue: loses work on restart and cannot coordinate multiple workers.
- Execute inside the approval HTTP request: couples human interaction to long-running side effects.

## Tradeoffs
PostgreSQL becomes both the system of record and the work coordination mechanism. Polling, indexes, and contention must be measured.

## Revisit when
Adopt a broker only after the worker becomes a separate deployment or measured database contention justifies it.