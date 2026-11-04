# Core API v1 — review for approval

[Русская версия](API_REVIEW.ru.md) · [full catalog](API.md) · [approved schema](SCHEMA.md) · [decisions](DECISIONS.md) · [modules](MODULES.md)

Status: API proposal review, PLAN-036, 2026-11-05. The logical schema and archive contents are approved (ADR-024). **The API is not yet approved; P0 is unauthorized.**

## 1. Boundary and shape

The Flutter UI sends commands and queries to the Python core over local HTTP; events arrive over WebSocket. The model has no direct HTTP access: it sees only limited typed tools executed by the same core. A command carries an action ID for safe retries, expected revisions and time context. Its result explicitly says applied locally, queued externally, needs input/clarification/confirmation, conflict, denied or failed.

## 2. User flows

| Flow | Main commands and queries | Guarantee |
| --- | --- | --- |
| Tasks and subtasks | `CreateTask`, `EditTask`, `CompleteOccurrence`, `DeleteTask`, `GetTask` | Priority is required; ambiguous targets and child handling require clarification |
| Day plan | `BuildDayPlan`, `EditDayPlanDraft`, `ApplyDayPlan`, `GetDayView` | The draft is edited before accepting it as a whole; revisions guard against stale plans |
| Habits | `RecordHabitEntry`, `CorrectHabitEntry`, `StartTimer`…`StopTimer`, `GetHabitStats` | Correction history remains; the user applies goal-change proposals |
| Calendar and mail | `CreateEvent`, `SyncNow`, `ResolveSyncConflict`, `SendMail` | The user resolves calendar conflicts; sending mail always requires confirmation |
| Voice and permissions | `SetMicrophoneMuted`, `StartListening`, `Approve`, `GrantCapability` | The core checks access and exact confirmation independently of model proposals |
| Data safety | `PreviewRestore`, `Restore`, `DeleteHistory` | Preview and current-data backup precede restore; old rights and queues do not return |

The [API catalog](API.md) contains the full command list, fields, events and error codes. Events are hints to reread data after changes; a missed revision triggers a full screen refresh.

## 3. Clarifications after review

1. The core assigns `origin` based on the caller and internal execution path; it is not accepted as authority from a request body. Otherwise a client could claim `sync` or `assistant` and bypass distinct confirmation policies.
2. `approval_id` is bound to the original action, exact content and revisions. Changing a message or target requires new confirmation; replaying approval cannot execute another action.
3. `ResolveUnknownOutbox` cannot resend email without fresh exact-content confirmation and a warning that the first attempt may have succeeded.
4. `Restore` returns the approved user-data set under ADR-023–024; grants, connections and old queues do not return.

These clarifications are in the **proposed** API. They do not change the approved schema, project rules or programming authorization.

## 4. Decision boundary

Approving the catalog would fix v1 command/query names, result classes, main fields, events and access rules. Detailed JSON schemas, client generation, implementation, contract tests and real PostgreSQL verification follow separate programming authorization. Modules are the next separate decision after the API; P0 requires its own explicit authorization.
