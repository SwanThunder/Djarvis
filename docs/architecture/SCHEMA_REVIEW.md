# Database schema v1 — approved decision overview

[Русская версия](SCHEMA_REVIEW.ru.md) · [full schema](SCHEMA.md) · [technical design](TECHNICAL_DESIGN.md) · [API](API.md) · [modules](MODULES.md) · [decisions](DECISIONS.md)

Status: approved logical-schema review, PLAN-036, 2026-11-05. Process architecture and layout are approved (ADR-022), restore policy under ADR-023, and the 46-table schema and archive contents under ADR-024. Revised SQL has not run: the owner deferred checks until programming. The former 13 checks covered the 45-table draft.

## 1. What is stored

| Group | Tables | Purpose |
| --- | ---: | --- |
| Profile and settings | 3 | One profile per Windows account; language, city, available hours, settings |
| Projects, notes, tags and attachments | 7 | Independent local sections and task links |
| Tasks, recurrences, subtasks and checklists | 6 | Task content and separate executable occurrences |
| Time blocks and day proposals | 4 | Accepted schedule, editable draft and source revision |
| Habits | 7 | Versioned goals, pauses, marks, timers and goal-change proposals |
| Calendar and synchronization | 5 | Local events, selected external calendars, mappings and conflicts |
| Actions and permissions | 6 | Duplicate protection, exact approvals, revocable grants, provider queue and audit |
| Reminders and conversations | 5 | Durable jobs, conversation history and a guard against restoring deleted history |
| Service records | 3 | Migrations, archives and interrupted operations |

Total: 46 tables. License, trial, PostgreSQL passwords and OAuth tokens are outside the user schema. Different Windows accounts have separate private clusters and file permissions.

## 2. Main planner path

`task` describes the job and priority; `task_occurrence` stores a particular completion, deadline and state; `schedule_placement` stores allocated time. Thus moving a block neither moves its deadline nor completes the task. Recurrences create separate occurrences from the original anchor. A day draft lives in `day_plan_proposal`/`day_plan_item`; `planning_guard` rejects application when meetings, tasks or available hours change after building. `draft_revision` separately protects draft edits. The user edits and accepts the whole plan, while a missed block or new meeting yields a remaining-day proposal under ADR-020–021.

A habit's goal/schedule version is separate from actual entries so backdated corrections retain history. Reminders refer to their targets, and background jobs have a logical key against duplicates. An external event does not become the sole source of a local task; provider mapping and conflicts are stored separately.

## 3. Integrity and recovery

One local profile is bounded in its private cluster. Required priority, deadline consistency, unique occurrence, one live timer per habit, unique background-job key and action ID have database constraints. Subtask cycles, exact rights and plan applicability are checked by the core in a transaction. The application role cannot change table structure; migrations use a separate role after a backup.

**Restore policy (ADR-023):** the archive contains user data and history from the closed table allowlist in [SCHEMA §13](SCHEMA.md#13-archive-contents-and-restore-adr-023). It excludes grants, connections, pending approvals and email queues; a full dump of `app` is not used. The user sets up grants and connections again after restore. Reminder jobs are rebuilt from rules; old jobs and emails are not replayed. Restore uses staging with preview and a backup of current data. This resolves the detected archive-design contradiction; execution remains untested.

**Technical correction in the schema:** `provider_mapping` now carries an object kind and a constraint preventing simultaneous references to an event and a block. After deletion of the local target both references may be empty while the row remains a reconciliation marker. This revision is approved under ADR-024, but its SQL has not run.

## 4. Current decision boundary

The schema, archive allowlist and narrow mapping correction are approved (ADR-024). Migration SQL and its checks follow in the appropriate phase after programming authorization. API and modules remain separate decisions. Schema approval does not authorize P0.
