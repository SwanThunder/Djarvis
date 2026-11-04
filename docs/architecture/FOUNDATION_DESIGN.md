# Foundation design proposal — CP01–CP07

[Русская версия](FOUNDATION_DESIGN.ru.md) · [Product requirements](../PRODUCT.md) · [Planner core](PLANNER_CORE.md) · [Component plan](COMPONENT_PLAN.md)

Date: 2026-11-03. Status: detailed technical proposal for review. The limited choices in ADR-001 through ADR-008 are approved; the complete architecture, protocol, schema, algorithm, and component behavior below are not. No implementation, database schema, package, or performance result is claimed.

This document develops CP01–CP07 as a coherent foundation for later design. “Recommendation” means a reviewable proposal. “Owner choice” identifies a product behavior that must stay open until the owner answers. An exact API or column name is illustrative and may change.

## 1. Scope and boundaries

CP01 defines process ownership and local communication. CP02 defines commands, queries, results, permissions, and commit behavior. CP03 describes a logical PostgreSQL data model and integrity rules without SQL DDL. CP04 describes lifecycle and migrations for the approved private local PostgreSQL instance. CP05 proposes deterministic day-plan construction. CP06 specifies temporal, recurrence, and habit semantics. CP07 covers projects, notes, tags, attachments, and local search.

Approved foundation used here:

- Flutter is selected for the UI; Python for planner-core/background logic with an app-managed runtime.
- An app-managed isolated PostgreSQL instance runs on the user's Windows computer. User data stays local; no remote application backend or cloud user database is selected.
- A local profile and offline signed-license import are selected. Trial and expired-state behavior follow ADR-005. Protected backup-key handling and full-snapshot restore policy follow ADR-006.
- Local planner, reminders, voice, and conversation are intended to work offline when access and required local resources are valid. Search, live weather, and external providers need a network connection.
- Product rules for task priority, explicit deadline-time clarification, start-only markers, recurrence, habits, task completion, permissions, split opt-in, overdue-task eligibility, explicit abstinence reporting, parent/subtask choices, and no automatic breaks are constraints on these proposals.

## 2. CP01 — process model and local protocol

### 2.1 Options and recommendation

| Option | Strengths | Costs and risks |
| --- | --- | --- |
| Versioned loopback HTTP request/response API plus WebSocket events | Clear typed boundary; easy request inspection; reconnect can fetch snapshots; common client shape for later Android | Must bind only to loopback, authenticate each client, prevent port/token exposure, and validate origins; persistent event stream needs reconnection rules |
| Windows named pipes with a restricted security descriptor | Local IPC with Windows access-control lists; no listening TCP port | Native transport and Flutter/Python interop need design; package/session scope and reconnect framing need explicit handling; Android needs a different adapter |

Recommendation: use a versioned local API owned by one per-user Python host. Use HTTP for commands and queries, and a WebSocket only for transient notifications that prompt a fresh read. Bind the listener to loopback only. Generate a per-run capability token, pass it over a protected local handoff, keep it out of URLs/logs, and reject non-loopback or unauthenticated clients. These measures are a design recommendation, not a security guarantee against another process running as the same Windows user.

The alternative named-pipe path remains technically reasonable if a prototype establishes a reliable Flutter-to-Python client and the owner prefers it. Windows lets a named-pipe creator supply a security descriptor; its default descriptor can grant broader read access, so an explicit ACL is necessary. [Microsoft named-pipe security](https://learn.microsoft.com/en-us/windows/win32/ipc/named-pipe-security-and-access-rights). HTTP is a stateless request/response protocol, while WebSocket is a separate two-way framed channel; reconnect behavior therefore belongs in the application contract. [RFC 9110](https://www.rfc-editor.org/rfc/rfc9110.html), [RFC 6455](https://www.rfc-editor.org/rfc/rfc6455.html).

### 2.2 Ownership and process boundaries

Proposed responsibilities:

- **Flutter UI process:** screens, input, accessibility, local state display, question/confirmation presentation, and rendering returned read models. It has no database credential and cannot decide business mutations locally.
- **Python host:** the single authority for domain commands, permissions, planning, local transactions, scheduler state, and worker/database lifecycle. It exposes the versioned local protocol.
- **Private PostgreSQL process:** durable application records only. The host starts, monitors, and stops its own isolated cluster; it must identify the cluster before management operations.
- **Model/speech workers:** isolated, disposable compute processes. They return candidate text/audio or structured inference results; they cannot directly update domain tables or grant permissions.
- **External-service adapters:** called only by the host after capability checks. A provider result is stored separately from a local queued intention.

Recommended launch sequence: establish a per-user host mutex/ownership record; validate current entitlement and app-owned data paths; start or connect only to the app's identified PostgreSQL instance; verify schema version/readiness; initialize workers lazily; then expose the UI protocol. Audio capture starts only after valid entitlement, required local voice resources, and OS microphone permission are confirmed. OS microphone denial disables capture and voice input/output that depends on it; it does not by itself block entitled manual planner use or text interaction. This reflects product constraints and needs future lifecycle design; it is not implemented.

Closing the main window does not stop the host or wake listener. Full Exit requests orderly cancellation, disables capture, stops disposable workers, flushes completed local work, and then stops only the owned database instance. Sleep, shutdown, power loss, OS denial, and expiry can interrupt work; do not promise background delivery while the host/OS is unavailable.

### 2.3 Illustrative protocol envelope

All envelopes are examples, not generated code or approved wire names. Serialize dates and instants explicitly; do not serialize an untyped local-time string and guess its zone later.

```json
{
  "protocol_version": 1,
  "request_id": "client-generated-id",
  "action_id": "stable-id-for-retry",
  "profile_id": "local-profile-id",
  "command": "CreateTask",
  "expected_revisions": [{"entity_id": "...", "revision": 4}],
  "reference": {"instant": "...Z", "timezone": "Area/City"},
  "payload": {"title": "...", "priority": "high"},
  "approval_id": null
}
```

The response must distinguish an applied local mutation from a pending external effect:

```json
{
  "request_id": "...",
  "action_id": "...",
  "state": "AppliedLocal",
  "committed_revision": 5,
  "read_model": {},
  "questions": [],
  "external_effects": []
}
```

Proposed result states: `AppliedLocal`, `QueuedExternal`, `NeedsClarification`, `NeedsConfirmation`, `NeedsInput`, `Conflict`, `Denied`, `Unavailable`, and `Failed`. A result carries a stable action ID and relevant revisions. `QueuedExternal` means durable intent only. The UI reconnects by asking for a current snapshot; it must not treat a missed WebSocket event as a lost command or replay an event as a command.

### 2.4 Event and reconnection rules

Events are hints containing a monotonically changing read-model revision and affected resource identifiers, not the authoritative record. They may be coalesced. On reconnect or a revision gap, the client requests a fresh snapshot. The host persists commands before publishing success. If the host stops after commit and before the response, a retry with the same action ID returns the recorded result; a different ID is a new intent.

Keep long-running inference and provider requests outside database transactions. A cancellation stops waiting or requests worker cancellation; it cannot undo a command that already committed. Explicitly report each state transition rather than emitting a premature “done.”

## 3. CP02 — command, query, policy, and commit contract

### 3.1 Command lifecycle

Recommended command path:

1. Parse an authenticated, versioned request and validate required fields.
2. Resolve the user's intended target. If more than one target remains plausible, return `NeedsClarification` even if task-change confirmations are disabled.
3. Load current records and expected revisions; reject a stale target or stale approval.
4. Check entitlement, capability grants, and confirmation policy for the exact operation and its current payload.
5. If data is missing, return `NeedsInput`; do not invent priority, duration, date, recipient, or target.
6. Validate domain invariants and any planning snapshot. Return a reviewable proposal if changes are not yet accepted.
7. In one short PostgreSQL transaction, write related domain state, action-idempotency result, minimal audit metadata, and any required outbox row.
8. Publish the new revision only after commit. Provider success or failure is a separate later state.

No classifier/model output is authority. It may suggest a typed command, but it cannot bypass target resolution, permission checks, validation, or required confirmation.

### 3.2 Illustrative command/result types

| Command family | Example request content | Success boundary |
| --- | --- | --- |
| Task | title, explicitly chosen priority, optional fields, expected revisions | Local task/occurrence and any placement commit |
| Habit | habit ID, observation/measurement, local period reference | Local log commit; no inferred success from silence |
| Plan | date/timezone, captured input revision, proposed placements | Only user acceptance plus fresh validation commits placements |
| File | selected source and destination, exact operation | Always confirmation before deletion or overwrite; execution result after filesystem work |
| Email | recipients, body, attachments, permission context | Always confirmation before send; “submitted” only after provider confirmation |
| Calendar sync | local/provider IDs, provider revision, cursor | Local conflict or queued intent is not provider confirmation |

An applied command result should include `action_id`, committed entity revisions, and a concise outcome code. A clarification response carries candidate identifiers and display-safe facts. A confirmation request is bound to exact recipients/content/attachments or task IDs/changes/revisions; if any material field changes, issue a new confirmation request.

### 3.3 Idempotency and concurrency

Use a client-generated action ID scoped to a profile and command origin. Store a unique processed-action key and the final local result in the same transaction as the mutation. Reuse of an action ID with a different normalized request body is a conflict, not a second mutation. External effects get their own stable operation key and state machine; action idempotency alone cannot make a provider operation exactly once.

For plan acceptance, compare captured revisions and recheck all planning-affecting records inside the acceptance transaction. Proposed approach: a short per-profile planning-state row/guard updated by every task, calendar, availability, recurrence, and relevant habit change. Unrelated note changes do not advance that revision. This is an application-level serialization recommendation, not a PostgreSQL single-writer rule. Exact locking/isolation remains for review.

### 3.4 Policy and permissions

Separate four concepts: user intent, capability grant, optional confirmation preference, and mandatory confirmation. A remembered no-confirm grant applies only to its selected task-operation scope, is revocable, and is rechecked at execution. It never grants file deletion/overwrite, email send, habit-goal changes, or Windows power/logoff actions. Ambiguity always needs clarification. Sending mail, deleting/overwriting user files, and the confirmed Windows shutdown/restart/logoff actions require an exact confirmation each time. Habit goal/load changes remain proposals until separately accepted.

An integration permission may be denied or revoked while a queued item waits. Recheck the current grant and operation body immediately before dispatch. Never treat web/email content, model output, or a source label as a permission grant.

## 4. CP03 — logical PostgreSQL data model

This is a conceptual relational model only. It intentionally names no final SQL, PostgreSQL version, driver, enum encoding, migration framework, or connection pool.

### 4.1 Entity groups

| Entity group | Proposed records and important relationships |
| --- | --- |
| Profile/configuration | One local profile; timezone, locale, availability and chosen behavior settings are explicit records with revisions |
| Tasks | `Task` template/identity; `TaskOccurrence` execution instance; `SchedulePlacement` zero or more time segments; separate deadlines, completion action, and split-progress marks |
| Recurrence | `RecurrenceRule` with original local anchor, cadence, named timezone, missing-month-day policy and version; `RecurrenceException` for skipped/moved/cancelled original instances |
| Habits | `Habit`, effective-dated `HabitSchedule` versions, pauses, `HabitPeriod`, and dated measurements/check-ins |
| Calendar | Internal `CalendarEvent`, recurrence identity, selected external mapping, provider revision, sync cursor, and conflict snapshots |
| Planning | `DayPlanProposal`, captured planning revision, proposal items, and accepted result revision |
| Project/content | `Project`, `Note`, tags and explicit association tables; attachment metadata references files under app-managed storage |
| Actions | Processed action/result, capability grants, approval requests, audit metadata, provider outbox, reminder definitions/delivery records |

Occurrence identity must not be a task title or current placement time. Moving a placement preserves the original recurrence key. A completed occurrence remains historical; completion of one instance never completes another. A manual start-only marker is distinct from a reserved `SchedulePlacement` because it has no validated end.

### 4.2 Integrity rules and rationale

Proposed database constraints should enforce, where representable:

- Every child belongs to an existing profile/parent; use foreign keys for ownership and association integrity.
- Required task title and explicitly selected priority are present; there is no silent normal-priority default.
- Stored placement durations are positive; time intervals use an exclusive end. A start-only marker cannot be used as a busy interval.
- A recurrence occurrence has a stable original key unique within its recurrence version; exceptions cannot regenerate the same occurrence twice.
- One habit measurement has a stable action/source key for retry protection; multiple genuine same-day quantity/duration measurements may remain separate while flexible-frequency counting deduplicates by local success date.
- One action ID is processed once per profile; a provider operation key is unique within its adapter/account scope.
- A task completion record is separate from split check-offs. Every segment checked does not auto-complete the task; explicit completion is allowed without all check-offs.
- A provider mapping identifies provider/account/calendar/object IDs separately from local IDs and retains the last synchronized base needed for conflict review.

Foreign keys protect relationships; unique constraints protect durable identities; check constraints protect row-local values. Cross-row temporal overlap rules and policy checks should remain domain/transaction logic unless a precisely scoped PostgreSQL exclusion constraint is later selected. Avoid duplicating derived “overdue” flags when they can be calculated from deadline, current time, and completion state.

### 4.3 Index plan and rationale

Indexes are proposals to be validated from real query shapes and representative data, not a performance claim:

- Unique primary identifiers and occurrence keys: stable lookup and prevention of duplicate recurring instances.
- `(profile_id, state, deadline_date)` and `(profile_id, scheduled_local_date, state)`: task list/day view filtering; exact columns depend on chosen date representation.
- `(profile_id, target_id, start_instant)` on placements and `(profile_id, habit_id, local_period_key)` on logs: assemble a day and compute periods.
- Provider mapping uniqueness on `(provider, account_id, calendar_id, provider_object_id)` and sync cursor lookup by selected account/calendar.
- Outbox by `(state, next_attempt_at)` and reminder queue by `(state, due_at)`: resume only due work after restart.
- Tag joins by both `(tag_id, resource_id)` and `(resource_id, tag_id)` only if both query directions are needed.
- Search indexes on approved local text fields, with per-language configuration and a separate permission filter before results are returned. PostgreSQL full-text search uses normalized vectors/queries and can use a GIN index; it does not make Russian/English stemming, ranking, or memory costs automatic. [PostgreSQL full-text search](https://www.postgresql.org/docs/current/textsearch-intro.html), [search indexes](https://www.postgresql.org/docs/current/textsearch-indexes.html).

Do not index every column speculatively: each index costs disk and adds write work. Index review should map each index to a concrete query and include profile isolation in access paths.

PostgreSQL documents primary/foreign/unique/check/exclusion constraints and transactional behavior. The final design must choose the actual constraints after the domain schema is approved. [PostgreSQL constraints](https://www.postgresql.org/docs/current/ddl-constraints.html), [CREATE TABLE constraints](https://www.postgresql.org/docs/current/sql-createtable.html), [transactions](https://www.postgresql.org/docs/current/tutorial-transactions.html).

## 5. CP04 — private PostgreSQL lifecycle and migrations

### 5.1 Instance ownership

The application-managed PostgreSQL instance is private to this product and to the current user. Keep immutable runtime files separate from its durable data directory, logs, attachment store, backup archive and disposable model cache. Put durable user data in an application-data location, not the install directory or source checkout. Exact paths, Windows architecture, PostgreSQL distribution/version, port, role/authentication method and resource settings remain undecided.

Before starting, acquire a per-user host ownership lock. Read a product-owned instance manifest, validate the canonical data path, cluster identity and expected major version, and confirm the endpoint belongs to that cluster. Never adopt, initialize, migrate, stop, or delete an arbitrary local PostgreSQL service. Do not fall back to a public or remote database.

Recommend a loopback-only endpoint, a dedicated least-privilege application role, credentials protected outside normal logs, and a random available port recorded in app-owned state. Do not assume that “localhost” alone authenticates a client. The final transport/authentication design needs platform-specific review.

### 5.2 Lifecycle state machine

Proposed states: `Absent`, `Initializing`, `Starting`, `WaitingForReady`, `Migrating`, `Ready`, `Stopping`, `Stopped`, `RecoveryRequired`, `IncompatibleVersion`.

| Transition | Required checks and action | Failure result |
| --- | --- | --- |
| First run → initializing | Check disk, app-owned target, binary signature/version, and data path is empty | Show actionable setup failure; do not initialize an ambiguous/nonempty directory |
| stopped → starting | Verify manifest and ownership lock; start only owned instance | Preserve data and report startup failure |
| starting → ready | Probe expected cluster/database/role and schema version with bounded retries | Stop retrying; mark unavailable or recovery required |
| ready → migration | Make required recoverable pre-migration snapshot; exclusive app maintenance gate; apply one versioned migration transaction where possible | Preserve prior copy; mark recovery required if partial work cannot safely roll back |
| ready → stopping | Stop accepting new commands; finish/abort safe work; checkpoint/close clients; stop only owned instance | Report incomplete shutdown; do not delete data |
| any → incompatible | Compare manifest and supported binary/schema versions | Refuse destructive downgrade; route to recovery or reviewed upgrade |

Use PostgreSQL lifecycle utilities only as part of a controlled app-owned operation; document exact launch arguments, permissions, exit codes, logs, and repair steps after versions are selected. No installer/build method or Windows service policy is chosen here. [PostgreSQL pg_ctl](https://www.postgresql.org/docs/current/app-pg-ctl.html).

### 5.3 Migration contract

Each migration has a stable ID, from/to schema version, preconditions, transaction requirements, data transformation, postconditions, and recovery note. The host checks disk and cluster identity, takes the required pre-migration backup, blocks new domain writes, applies the migration, validates critical constraints/read models, then publishes the new schema version. If the process dies, startup detects an incomplete migration and follows its explicit resume/restore path; it must not guess based only on binary version.

Forward-only schema migration is safer than assuming old binaries can run on a changed schema. A downgrade requires a separately designed reverse transformation or restore. Major PostgreSQL upgrades are a distinct operation from application schema migration.

### 5.4 Private database failure and recovery

If PostgreSQL is unavailable, queries that need it return `Unavailable`; commands that mutate planner state do not claim success. Do not silently keep a second mutable in-memory copy or write to a file fallback. Preserve idempotent requests only if their processing status can be recovered safely. Offer local repair/restore guidance without exposing credentials or implying data loss before diagnosis.

Any backup/restore operation must comply with ADR-006: protected local key, full snapshot after preview and a fresh backup of current data, no restore of entitlement/OAuth credentials/Windows image, history deletion rules, seven-day default archive retention. CP15 owns the detailed backup design. PostgreSQL `pg_dump` provides a consistent snapshot of one database, but attachments and application metadata require coordinated treatment. [pg_dump](https://www.postgresql.org/docs/current/app-pgdump.html), [backup formats](https://www.postgresql.org/docs/current/backup-file.html).

## 6. CP05 — deterministic day-plan construction

### 6.1 Inputs and invariants

The planner is a deterministic domain service that accepts a captured input snapshot. It does not need a loaded language model. A model may translate the user's intent or explain a result, but cannot supply missing durations, change dates, invent availability, or commit a plan.

Required snapshot: planning date and named timezone; configured user availability; accepted blocks and external busy intervals with normalized start/end/free-busy state; manually locked placements; eligible open task occurrences and deadlines; duration estimates; habit schedule needs; configured breaks only when both duration and frequency are set; split opt-in and any reviewed split limits; current settings and input revision.

If a task lacks duration, return `NeedsInput` for that item before automatic scheduling. It may exist as a task and, if manually entered, as a start-only marker, but the marker reserves no interval. If a meeting/busy event has an unknown end or ambiguous all-day/free-busy meaning, do not treat the interval as known free; return an input/conflict reason or exclude that portion from schedulable time pending normalization.

Hard constraints: manually placed items remain locked unless the user explicitly permits changing them; meetings and unavailable periods are not moved by the planner; no placement extends user availability or changes a deadline; a date-only task uses the 06:00–22:00 placement window with its own duration, not an assumed 16-hour task or global workday. An overdue task remains eligible for an automatic proposal; keep its original deadline and overdue flag, and apply only through the existing confirmation/grant.

### 6.2 Proposed algorithm

1. Validate the chosen date/timezone and input revision. Read all planning records from one consistent local snapshot.
2. Resolve missing inputs. Ask for duration, unclear target, or uncertain busy/free semantics rather than dropping the item or inventing a value.
3. Build free intervals from configured availability minus meetings, unavailable windows, locked placements and accepted blocks. Treat interval ends as exclusive so adjacent tasks can meet.
4. Add automatic breaks only after the user has configured both break duration and frequency. Otherwise, insert none.
5. Build the candidate set. Include eligible open tasks and habit needs without converting habit misses into task debt. Preserve each recurring task occurrence separately.
6. Rank candidates by the accepted policy: tasks with explicit deadlines come first, earliest deadline first and higher priority as the next ordering key. Tasks without a deadline follow, ordered by priority. Do not add numeric weights or slack scores. Tie-breaking among otherwise equal candidates and fairness across repeated planning remain technical questions.
7. For each candidate, find a feasible interval that fits its known duration and constraints. Use a stable deterministic start-time tie-breaker in the technical proposal, but expose the selected block and reason in the preview. Never claim that this greedy method is globally optimal.
8. Split only a task that explicitly opted in. Do not invent segment limits or minimums. Until those settings are decided, ask for the needed configuration or return an unplaced reason. A segment check-off is progress only; the selected occurrence completes only through its separate explicit completion action.
9. Return additions, moves, unchanged locked items, unplaced items, deadline feasibility, and the input revisions used. Do not write placements yet.
10. On acceptance, re-read revisions and all constraints in a short transaction. If any relevant input changed, return `Conflict` and require a fresh preview. Otherwise commit the placements and action result together.

### 6.3 Ranking recommendation and owner choice

Accepted product policy: deadline-first, then priority; tasks without a deadline are ordered by priority. Do not combine deadlines and priority into a hidden weighted score or use unapproved slack calculations. Proposed deterministic tie-break for equal deadline/priority: original scheduled date, then stable occurrence key. For undated tasks, use priority then a stable occurrence key. These tie-breaks are technical proposals, not owner-selected product behavior.

The plan can still be infeasible. Report a missed/unsatisfied deadline and the reason; never move its date, silently widen working hours, or call an overloaded day solved. A due date and a scheduled placement are separate facts.

Accepted product policy (FD14): overdue tasks remain eligible for automatic plan proposals. Preserve the original deadline and overdue flag; the existing confirmation/grant applies when the proposal is accepted. Do not rewrite the deadline.

### 6.4 Completing split work

Accepted behavior: the user opts into splitting per task; checking segments records progress but never completes the task; the selected occurrence completes only through a separate task-completion action, even if not all segments are checked. Completion does not affect sibling or future occurrences. Exact API naming remains unapproved.

Accepted product policy: after explicit completion, release only the remaining future blocks for the selected occurrence and preserve history; do not change sibling or future occurrences. Proposed technical handling: mark those future placements as released/cancelled and preserve their prior values in history. A placement whose start is already before the completion instant but whose end is still later is an unresolved boundary case. Reminder cancellation rules for these blocks also need detail.

## 7. CP06 — temporal, recurrence, and habit semantics

### 7.1 Temporal values

Use distinct logical concepts:

- **Calendar date:** a date-only planning date, or an incomplete deadline input awaiting the required time clarification; it is not a persisted complete deadline and is never midnight UTC by implication.
- **Local date-time:** wall time plus an explicit named timezone for recurring personal intent.
- **Instant:** a point on the global timeline, stored separately from the named timezone used to interpret future local recurrence.
- **Placement interval:** start and exclusive end instants plus the intended local-zone context; duration is positive and independent of deadlines.
- **Start-only marker:** local date/time request with no known duration; visible but not reserved as an interval.

PostgreSQL `timestamp with time zone` stores an instant and normalizes it; it does not retain the original named zone. Store a zone identifier and local recurrence anchor separately. Date-only values should remain date values, not be cast to UTC midnight. [PostgreSQL date/time types](https://www.postgresql.org/docs/current/datatype-datetime.html).

For each habit and personal recurrence, the user chooses follow-current-local-time or retain-original-fixed-timezone. If this choice is unset when the profile timezone changes, ask. Do not apply that preference to externally scheduled meetings and do not retime historical records.

### 7.2 Daylight-saving transition decision

Accepted product policy: for a requested local time in a DST gap, offer a nearest valid local time and require confirmation; for a repeated local time in a DST fold, show both possible instants and require the user to choose and confirm one. Never silently shift a time or silently choose an occurrence. The exact timezone implementation, schema mechanics, and how a generated recurring occurrence is held while clarification is pending remain technical design details.

Store both the user's local intent and the resolved instant for an actual placement. If timezone rules later change, preserve past instants and regenerate future recurrence under the selected zone/policy; re-preview affected future placements rather than rewriting history.

### 7.3 Recurrence identity and debt

Each recurrence has a rule version, original local anchor, named timezone, cadence, selected local/fixed-zone policy, and a stable original-instance key. Moving an occurrence changes its placement, not its original recurrence identity. For standards-based interchange, RFC 5545 distinguishes recurrence rules, timezone references, and the original recurrence identifier for an instance. [RFC 5545](https://www.rfc-editor.org/rfc/rfc5545).

Fixed interval rules calculate from the original anchor, not completion time. Example: due 2026-11-01 every seven days, completed 2026-11-03; next occurrence stays 2026-11-08. Missed occurrences remain separate open debt. Monthly missing-date behavior is configured per rule; default is last day, with skip as the alternate. January 31, 2027 → February 28 → March 31, not March 28.

Regeneration must be idempotent: a unique occurrence key prevents duplicate materialization. A moved or cancelled instance remains associated with its original key so later sync/regeneration does not create a second copy. Which historical occurrences are materialized, rule-edit scope (this, this-and-following, whole rule), and exception-retention policy remain unresolved.

### 7.4 Habit periods and statistics

Represent measurement observations separately from assessed schedule periods. The four accepted types are yes/no, quantity, duration, and abstinence. A log must identify its local date/period, value/unit when applicable, and correction provenance. For abstinence, count success only on an explicit user report of “complied”; no mark is not success.

Week boundaries begin Monday in the selected habit timezone. Flexible frequency counts distinct successful days; multiple same-day quantity/duration logs can contribute to measurement totals but at most one success for weekly quota. If a pause leaves fewer eligible days than the weekly quota, mark that flexible week paused: no miss, no streak break, no automatic goal reduction. Fixed streaks count consecutive successful scheduled days; flexible streaks count consecutive successful weeks; paused time freezes the applicable streak. Habit misses remain statistics, not task debt.

Corrections may target any past date during the habit's lifetime, never before creation or as a future actual success. Preserve correction history and recalculate with the goal effective on the corrected date. Exact storage/audit representation and recomputation mechanics are technical proposals.

Proposed measurement contract: quantity observations carry a typed unit and numeric amount; duration observations carry an elapsed duration in a declared unit. In the accepted portion-sum mode, preserve individual portions and sum compatible units only. In daily-total mode, use the entered total rather than adding it to prior totals. Switching modes takes effect immediately for the habit after a recalculation preview, recalculating the current day while leaving earlier days unchanged and retaining correction history. Duration sessions are summed for the day; timer with pause and manual entry are accepted. Do not sum incompatible units. A yes/no success is an explicit report. For abstinence, only an explicit “complied” report counts as success; a lapse or no mark is not success. This accepted rule does not define the storage encoding. Owner decisions still needed: unit catalog/conversion, thresholds, exact quantity-mode recalculation mechanics and duration boundary handling, exact abstinence record representation, correction reason/authorization, rate calculations across paused periods, and the moment an unfinished flexible week becomes a miss. Existing any-past-date correction policy still applies; its audit representation remains open. Do not add automatic make-up tasks or apply a suggested goal change without acceptance.

## 8. CP07 — projects, notes, tags, attachments, and search

### 8.1 Logical records

Propose profile-owned projects with stable IDs and revisions. Archiving should hide a project from active views while preserving linked tasks, notes, attachments and history; deletion should require an impact review and explicit confirmation, with exact cascade/retention behavior left for owner review. Tasks may optionally reference a project. Notes have stable IDs, title/body, created/updated revisions and optional project association; propose plain text or a constrained safe rich-text format, and never render active HTML/script content. Tags are user-managed labels with normalized display text and a many-to-many association to supported records. Exact fields, nesting, note format and which record types may be tagged are proposals, not new product requirements.

Advanced task fields must keep distinct meanings: a checklist is progress metadata and does not complete the task; subtasks are separate task records with their own status and may be explicitly related to a parent. When a parent has unfinished subtasks, show “Close task” and “Finish subtasks”. “Finish subtasks” returns to the child-task list and leaves the parent incomplete. “Close task” completes only the parent; child tasks remain active and linked. Multi-level nesting without a fixed product depth limit and collapsible branches is accepted (PLAN-014). For a new child, propose the parent's project and priority and require explicit confirmation; set the child's deadline independently, with no propagation from future parent changes. Archive/delete behavior remains open. Hidden advanced fields retain their values under the accepted product rule.

Attachments are metadata records linked to an owner record and an app-managed file object. The database stores a stable attachment ID, relative opaque storage key, original display name, media type if known, byte count, hash, created timestamp, and lifecycle state. Do not use arbitrary user-supplied paths as storage keys or expose an attachment as an unrestricted executable action.

### 8.2 File and transaction boundary

The filesystem and PostgreSQL cannot participate in one ordinary database transaction. Recommended add flow:

1. Validate that the user selected a readable source and an allowed target record.
2. Copy bytes into an app-owned staging area; enforce reviewed size/type limits; compute a content hash and verify the copy.
3. Atomically rename the staged file into an immutable app-owned content location on the same volume where supported.
4. In a short database transaction, insert attachment metadata and the owner association.
5. On database failure, leave a recoverable orphan marker or remove the unreferenced staged object after safe verification; never leave a broken visible attachment reference.

A crash can occur between file placement and metadata commit. Startup reconciliation should identify unreferenced staged/final objects without deleting anything that may be in an active operation. Backup capture coordinates a database snapshot with referenced attachment content and a manifest. Deleting or overwriting a user-selected original file is a separate action and always requires confirmation; attaching a copied file does not grant permission to alter the original.

### 8.3 Search and privacy boundary

Global search first queries authorized local records. Search results carry record type/ID and a safe preview; opening a result rechecks current access and revision. Search indexes are derived data and can be rebuilt from the source records. Do not copy conversation history, email contents, or attachment text into a durable index unless the owner explicitly includes that content and defines its retention/access policy.

PostgreSQL full-text search is a candidate for notes/tasks/projects. Keep language configuration explicit for English and Russian; do not imply stemming or ranking quality without evaluating actual text. A GIN full-text index is a candidate for frequently searched normalized text, but the final index and query plan require representative data. [PostgreSQL text search](https://www.postgresql.org/docs/current/textsearch-intro.html), [index types](https://www.postgresql.org/docs/current/textsearch-indexes.html).

Internet search is a separate explicit assistant capability and may transmit the user's query. It is not the same as local record search and must use its own permission/network disclosure. Local weather-independent notes/projects remain available offline under valid access.

## 9. Cross-component interaction examples

### Create a task and request a plan

1. User supplies a title and explicit priority; if priority is absent, ask before creation. Other fields remain optional unless the requested action needs them.
2. User may save the task without duration. `BuildDayPlan` later returns `NeedsInput` for duration instead of inventing one.
3. User accepts a requested start-only marker. It is stored as a marker, not a reservation.
4. Planner loads a revisioned snapshot, respects a manual lock and only configured breaks, then returns a preview with unplaced reasons.
5. User accepts; the host verifies revisions and commits placements atomically. If a meeting, availability, or task changed, return conflict and rebuild the preview.

### Record a habit and correct history

1. User records a measurement for a chosen habit-local date. Validate its type/unit against the effective schedule version.
2. A flexible success is counted once per distinct local success date, even if multiple logs are retained.
3. If the date is in a paused week or is a backdated correction, update its audit trail and recompute the historical period using that date's goal.
4. A proposed goal change stays pending until accepted; a task no-confirm grant cannot accept it.

### Attach a note and file

1. Create/update note content in a local transaction and return its revision.
2. Stage, verify, move, then commit file metadata; if metadata commit fails, mark for safe cleanup/reconciliation.
3. Search finds note text through the local index and revalidates permission at read time.
4. Backup includes snapshot metadata and referenced attachment objects consistently; restoration follows full-snapshot policy and preview.

## 10. Failure and recovery matrix

| Failure | Required behavior |
| --- | --- |
| UI loses host connection | Show offline/unavailable state; retry read snapshot; do not repeat a command with a new action ID automatically |
| Host dies before local commit | No success claim; recover or safely retry using the same action ID |
| Host dies after commit before response | Return the stored result for the same action ID; do not duplicate the mutation |
| Database fails readiness/migration | Block mutations, preserve owned data, enter recovery state; never connect to an unrelated database |
| Plan snapshot is stale | Return `Conflict`; rebuild and show a fresh preview |
| Duration or busy interval is unknown | Return `NeedsInput`/unplaced reason; do not invent free time or duration |
| Split configuration is incomplete | Keep the task unsplit/unplaced and explain the missing settings; never split silently |
| DST local time is missing/repeated | Apply only after the owner-approved clarification rule; never silently shift/select |
| Attachment copy or metadata commit fails | Keep no broken visible reference; reconcile staged/orphan files safely |
| Search index unavailable/stale | Search source data or report a recoverable search issue; never return unauthorized stale content |
| Permission revoked before dispatch | Stop provider/file/device action and leave a visible denied/cancelled state |
| Provider outcome is unknown | Preserve `unknown`, reconcile before retry, and do not claim success/failure without evidence |
| Expired entitlement | Block planner/assistant functions; stop all microphone capture and proactive speech; preserve approved renewal, deletion, and backup paths |
| OS microphone denial | Disable capture and dependent voice interaction; preserve entitled manual planner and text interaction |

## 11. Future acceptance cases

These are later design/implementation acceptance cases, not tests run for this document:

- A duplicate action ID returns the original result; a changed body under the same ID is rejected.
- An ambiguous target is clarified even when a task no-confirm grant exists; email/file/power confirmations remain mandatory.
- A stale plan is rejected after a calendar insertion, changed task duration, changed availability, or changed planning timezone.
- Deadline-bearing tasks sort by earliest deadline then priority; tasks without deadlines sort by priority; equal inputs produce identical proposals under the selected technical tie-break.
- A manual start-only marker does not occupy a slot. Missing task duration is requested before planning.
- Manual placements remain locked; splitting and automatic breaks occur only under their explicit settings.
- Completing one split occurrence releases only its remaining future blocks and preserves history; siblings remain unchanged. Check the started-but-not-ended boundary case against the eventual rule.
- Weekly recurrence preserves original anchor and missed debt; monthly Jan-31 rule follows the selected missing-date setting.
- Fixed/local timezone behavior is explicit after travel; DST gaps offer a nearby valid time and folds show two instants, with confirmation required in each case.
- Flexible habit same-day logs count once for frequency; pause below quota is neither miss nor streak break; corrections recalculate with historical goal.
- A failed migration, process crash, or disk-full attachment copy retains a recoverable state and does not expose partial records.
- Search indexes rebuild without including unauthorized conversations, mail, or attachment contents.
- Local planner works offline with valid access/resources; external providers/search/weather are unavailable without implying remote execution.

No application code, SQL schema, database, package, runtime measurement, or test was executed for this proposal.

## 12. Decision register

| ID | Topic | Recommendation / owner choice | Status |
| --- | --- | --- | --- |
| FD01 | UI/core transport | Versioned loopback HTTP API plus event stream; named pipe remains alternative | Technical proposal; not approved |
| FD02 | Process ownership | One per-user Python command host owns domain writes and the private database lifecycle | Technical proposal under ADR-003/004 scope; process details open |
| FD03 | Command/result envelope | Stable action ID, revisions, typed result states, transactional local result | Technical proposal; exact wire schema open |
| FD04 | Logical schema and constraints | Separate task, occurrence, placement, deadline, completion, and split progress | Technical proposal; no DDL approved |
| FD05 | Planner rank | Deadline-first then priority; no-deadline tasks by priority | Product choice accepted; tie-break is technical proposal |
| FD06 | DST gap/fold | Offer nearest valid time for a gap; show two instants for a fold; require confirmation | Product choice accepted; timezone implementation open |
| FD07 | Remaining split placements | Release only remaining future blocks of the explicitly completed occurrence; preserve history | Product choice accepted; started-but-not-ended boundary and reminder details open |
| FD08 | Daylight and timezone data representation | Store local intent/named zone separately from resolved instants | Technical proposal grounded in PostgreSQL docs; schema open |
| FD09 | Recurrence and habit storage | Stable original occurrence keys; dated logs and effective-goal versions | Technical proposal; exact audit/statistics mechanics open |
| FD10 | Content/attachments/search | App-managed immutable attachment objects with staged metadata commit; local permission-checked search | Technical proposal; content fields/limits/index choices open |
| FD11 | PostgreSQL runtime | Private app-managed cluster, no adoption of unrelated installations | Lifecycle direction approved; binary/version/auth details open |
| FD12 | Planning lock | Short per-profile revision/guard for plan-affecting writes | Technical proposal; transaction implementation open |
| FD13 | Unspecified product details | Keep date-time conflict, segment size/buffer and project/note fields as explicit open items | Owner review where behavior changes; do not infer defaults |
| FD14 | Overdue task eligibility | Keep overdue tasks eligible for automatic proposals; preserve original deadline and overdue flag; use existing confirmation/grant | Product choice accepted; ranking/tie-break mechanics remain as separately specified |
| FD15 | Parent with unfinished subtasks | Show “Close task” (parent completes; children remain active and linked) or “Finish subtasks” (return to child list; parent remains incomplete) | Product choice accepted; exact interaction details remain proposal |
| FD16 | Abstinence success | Only an explicit user report of “complied” counts as success; no mark is not success | Product choice accepted; stored record/metrics remain proposal |

FD05–FD07 are narrow accepted product policies. FD14, explicit abstinence success, and parent/subtask choice behavior are accepted product rules. Remaining technical proposals require review; none grants permission to program, install, migrate, download, or benchmark.

## Accepted measurement and nesting choices (PLAN-014, updated by PLAN-015)

- Quantity habits have a per-habit choice: sum individual portions (default), or enter the daily total. A daily-total entry is not an additional portion; corrections retain history. A mode change takes effect immediately for that habit after showing a recalculation preview; recalculate the current day under the new mode, leave earlier days unchanged, and retain correction history. Unit/threshold details and exact recalculation mechanics remain to be designed.
- Duration habits support both a timer with pause and manual duration entry. Multiple sessions are summed for the day. A running timer continues through sleep, full application exit, and computer shutdown until explicitly paused/stopped; on resume, show elapsed time. Split duration at local midnight between the corresponding days. Timestamp reconciliation, clock/timezone changes, overlap between manual entries and timer sessions, and crash recovery remain technical questions; prevent duplicate counting.
- Subtasks support multiple levels without a fixed product depth limit; the interface can collapse branches. This is not a promise of infinite device capacity. Cycle prevention and scalable tree loading are technical design requirements to review. For a new child, propose the parent's project and priority with explicit confirmation; set the child's deadline independently and do not propagate future parent changes. Cycle prevention, scalable tree loading, moving branches and deletion semantics remain technical questions. Existing parent-completion behavior remains unchanged.
