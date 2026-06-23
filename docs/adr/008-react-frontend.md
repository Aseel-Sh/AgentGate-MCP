# ADR 008: Use React for the Management Application

## Status
Accepted.

## Context
AgentGate needs a management interface for approvals, tool-call timelines, policies, agents, MCP servers, and evaluation results. The original plan used Razor Pages because it minimized frontend setup, but the application benefits from richer client-side interactions and a clearer modern full-stack portfolio story.

## Decision
Use React, TypeScript, and Vite for the management application.

The browser calls an ASP.NET Core REST API under `/api`. Agents continue to use the separate MCP endpoint. During development, Vite proxies API and authentication requests to ASP.NET Core. For production, the Vite build is served by ASP.NET Core so the MVP remains one deployable artifact.

Use:

- React Router for navigation;
- TanStack Query for server state and mutations;
- React Hook Form with schema validation for forms;
- Vitest and React Testing Library for component tests;
- Playwright for end-to-end tests.

Human authentication remains owned by ASP.NET Core Identity with secure same-origin cookies and antiforgery protection. The frontend never becomes an authorization boundary.

## Alternatives

### Razor Pages

Razor Pages would reduce frontend tooling and work well for a simple form-heavy internal portal. It was rejected because AgentGate's approval queue, live status changes, timelines, filters, policy editing, and evaluation views benefit from a component-based client application.

### Blazor

Blazor would keep most development in C#, but React provides stronger alignment with the user's existing full-stack experience and produces a more broadly recognizable frontend portfolio signal.

### Separately deployed React application

A separate deployment would allow independent scaling and CDN hosting, but it would add CORS, cross-origin authentication, deployment coordination, and more infrastructure than the MVP needs.

## Tradeoffs

- The repository now requires Node/npm tooling in addition to .NET.
- CI must lint, type-check, test, and build both stacks.
- REST DTOs and frontend types must remain synchronized.
- Cookie and antiforgery behavior must work through the Vite development proxy.
- The production build pipeline must copy frontend assets into the ASP.NET Core publish output.

## Security rules

- Backend authorization is authoritative.
- Client-side route protection only improves user experience.
- Agent API keys and downstream credentials are never stored in browser storage.
- Sensitive data is redacted before reaching the browser.
- State-changing REST requests require antiforgery protection.
- The SPA fallback must never intercept MCP, API, health, or metrics routes.

## Revisit when

Deploy the React application separately only when independent release cadence, CDN delivery, organizational ownership, or measured scaling needs justify the operational complexity.