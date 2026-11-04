# Module structure — approved decision overview

[Русская версия](MODULE_REVIEW.ru.md) · [full specification](MODULES.md) · [architecture and phases](IMPLEMENTATION_PLAN.md) · [approved API](API.md) · [schema](SCHEMA.md) · [decisions](DECISIONS.md)

Status: approved module-structure overview, PLAN-038, 2026-11-05. Architecture, schema, API and modules are approved (ADR-022, ADR-024–026). **P0 remains unauthorized; no code is being written.**

## 1. Responsibility owners

| Layer | Modules | Responsibility |
| --- | --- | --- |
| Pure domain | `domain.tasks`, `.recurrence`, `.time`, `.planner`, `.habits`, `.policy` | Task, recurrence, time, day-plan, habit and access rules without database, network, files or system clock |
| Application use cases | `app.commands`, `.queries`, `.approvals`, `.ports` | One mutation path, screen read models, exact approvals and interfaces to external capabilities |
| Data and local database | `storage`, `db` | Transactions/repositories/attachments and the separate lifecycle of private PostgreSQL |
| Entrypoints | `api`, `assistant`, `audio`, `reminders` | HTTP/WebSocket, limited model tools, single microphone owner, reminders and proactive speech |
| Adapters and trust | `integrations.*`, `safety.backup`, `safety.entitlement` | Service/Windows connections, archive and restore, local entitlement checks |
| Composition and UI | `host`, Flutter `ui/app`, `ui/data`, `ui/features/*` | Start and connect components; screens display core results |

## 2. Dependency rule

`api`, `assistant` and `reminders` call `app`; all mutations traverse its pipeline. `app` uses pure `domain` and `app.ports` interfaces. `storage`, `integrations`, `audio` and `safety` implement those interfaces; only `host` composes their concrete classes. The Flutter UI does not decide access or task completion. CI checks import directions.

One Python process runs an `asyncio` loop; recognition and synthesis run outside it, while the language model has a separate process. Transactions do not wait for a person, model or network. After a voice failure, the planner and UI continue working; on exit the core stops capture, jobs, model and private PostgreSQL in order.

## 3. Check against approved contracts

- `api` assigns command origin from caller identity; `app.approvals` binds approval to the action, caller, exact content and revisions (ADR-025).
- `safety.backup` exports only tables in SCHEMA §13. Old grants/connections/queues do not resume after restore (ADR-023–024).
- `integrations.google` owns Gmail; both calendar adapters use a local queue. Email with an unknown outcome is not retried automatically, and a manual retry needs fresh confirmation.
- `assistant` and `reminders` obtain data and execute actions through `app`; neither writes around it. A 50 ms event-loop delay is a development target, with watchdog violations recorded.

These clarifications are approved under ADR-026 and included in MODULES. They do not alter the approved API or schema.

## 4. Checks and implementation order

P0 creates the `host`, `db`, `api`, `contract` scaffold and UI connection. P1 implements the `app`/`storage` transaction path; P2 the pure planner; P3 screens; P4 backup/access; P5 voice; P6 external connections; P7 delivery. Phase dependencies and acceptance criteria were approved separately (ADR-018). Planned module checks include unit/property, contract, real PostgreSQL integration, widget/golden and manual voice tests after programming.

## 5. Decision boundary

The approved MODULES fixes responsibility owners, dependency direction, runtime interaction, background jobs and phase allocation. It would not imply that code exists or authorize P0. The next decision is separate explicit authorization to start P0; the owner asked not to write code yet.
