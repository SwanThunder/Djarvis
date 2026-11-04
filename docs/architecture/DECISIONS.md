# Architecture decision register

[Русская версия](DECISIONS.ru.md)

Nine narrowly scoped decisions are approved: ADR-001 selects Flutter for UI and necessary Dart UI code; ADR-002 selects PostgreSQL as the local backend database; ADR-003 selects Python for planner-core/background logic with an app-owned runtime; ADR-004 selects an application-managed isolated local PostgreSQL instance; ADR-005 selects local-profile access with imported offline signed licenses and defines trial/expiry behavior; ADR-006 selects Windows-protected backup-key handling without a separate password/recovery key and full-snapshot restore safeguards; ADR-007 records three planner policies for priority order, DST ambiguity, and remaining split placements. ADR-008 records overdue eligibility, explicit abstinence success and parent/child completion choices. ADR-009 records habit measurement modes and multi-level subtasks. Exact versions, drivers, runtime/database distribution, installer dependencies, license format/issuer, payment details, schema, cryptographic/key implementation, and remaining architecture are not approved. Existing folders remain an organizational scaffold.

## ADR-001 — Flutter UI and necessary Dart UI implementation

- Date: 2026-11-03
- Status: APPROVED (limited scope)
- Context: The owner requires the supplied Djarvis visual design, Windows 10/11 first, and Android later. The owner confirmed: “Flutter Подходит; теперь подробно ядро планера, данные и взаимодействие.”
- Considered options: Flutter/Dart and .NET MAUI/C# were compared as UI directions in the initial proposal.
- Decision: Use Flutter as the UI framework and Dart only as needed to implement the UI.
- Consequences: Flutter is the selected UI direction; .NET MAUI is a historical considered alternative, not an active UI competitor. Core/background language is selected separately as Python by ADR-003. Exact Flutter SDK versions and dependencies, core/host boundaries, database driver/schema, model runtimes, process protocol, performance targets, and full architecture remain unresolved. This decision does not authorize code; implementation requires a separate reviewed plan and owner approval.
- Approval basis: Owner's explicit statement above, 2026-11-03. [Flutter supported platforms](https://docs.flutter.dev/reference/supported-platforms).

## ADR-002 — PostgreSQL backend database

- Date: 2026-11-03
- Status: APPROVED (database choice only)
- Context: The owner explicitly approved PostgreSQL “для бэкенда PostgreSQL” and clarified that it runs locally on the user's computer; no remote application backend or cloud user data.
- Considered options: PostgreSQL was selected; prior SQLite implementation proposals are superseded as the active database choice.
- Decision: Select PostgreSQL as the local backend database on the user's device.
- Consequences: This does not approve a remote/server deployment, cloud user data, a Dart backend, or any broader architecture. ADR-004 separately approves app-managed lifecycle for an isolated local copy; exact binaries/distribution, version, driver, connection/pooling model, schema/DDL, migrations, runtime packaging, installer dependencies, and full architecture remain unresolved. No implementation is authorized by these decisions.
- Approval basis: Owner's explicit statement, 2026-11-03.

## ADR-003 — Python planner core and background logic

- Date: 2026-11-03
- Status: APPROVED (language/runtime direction only)
- Context: The owner selected Python for planner-core and background logic, with its own packaged runtime. Flutter/Dart remains the UI direction in ADR-001.
- Considered options: Python selected for core/background logic; Dart remains limited to necessary Flutter UI implementation.
- Decision: Use Python for planner-core and background logic, with a separately packaged runtime owned by the application.
- Consequences: This does not select a Python version, PostgreSQL driver (including psycopg or asyncpg), local transport/framework, freezing or embedded distribution approach, or any schema/dependency/installer details. The user experience must not require a terminal, global Python installation, or manual package installation. This is a planned product requirement, not an implemented capability. No programming is authorized by this ADR.
- Approval basis: Owner's explicit approval, 2026-11-03.

## ADR-004 — Application-managed isolated local PostgreSQL instance

- Date: 2026-11-03
- Status: APPROVED (lifecycle direction only)
- Context: The owner approved an isolated private PostgreSQL copy local to the user's computer, managed by the application.
- Considered options: App-managed isolated local instance selected; remote backend/cloud user data remains excluded.
- Decision: The application manages the lifecycle of its private local PostgreSQL instance, including starting and stopping it as needed.
- Consequences: No console or manual database operation is required in the planned user experience. Exact PostgreSQL binaries/distribution, version, runtime packaging, driver, local communication mechanism, schema, migrations, installer dependencies, and recovery behavior remain proposed. This does not authorize installing or implementing the database now.
- Approval basis: Owner's explicit approval, 2026-11-03.

## ADR-005 — Offline license import and trial/access behavior

- Date: 2026-11-03
- Status: APPROVED (product access flow and states only)
- Context: The owner selected a local profile with no mandatory account, an imported signed license file verified offline, and a seven-day trial beginning at first use of any product function.
- Considered options: Local profile and license-file import selected; an in-app account requirement and own activation/entitlement server are excluded.
- Decision: The buyer imports a signed license file and the app verifies it offline. The seven-day per-device trial starts on the first use of any product function, including the manual planner; setup and waiting for downloads do not start it. When the trial or subscription expires, planner and assistant functions are locked while user data is retained. Renewal/import, user-initiated data deletion, and automatic backups remain available; all microphone capture and proactive speech stop.
- Consequences: No specific license format, signing algorithm, issuer/tooling, payment provider, price, renewal mechanics, device-binding details, or clock tolerance is selected. Backup-key and restore policy is separately narrowed by ADR-006, while its implementation remains open. This does not approve an own activation server or authorize implementation. Future cloud identity/account needs remain a separate design question.
- Approval basis: Owner's explicit choices F5, F6 and F8, 2026-11-03.

PLAN-012 clarification: the owner selected monthly and annual subscriptions; prices and renewal mechanics remain open.

## ADR-006 — Protected backup key and full-snapshot restore policy

- Date: 2026-11-03
- Status: APPROVED (key-handling and restore-policy direction only)
- Context: The owner selected Windows-protected key handling for local automatic backups, with no separate password and no additional recovery key. The owner selected full-snapshot restore after preview and a backup of current data.
- Considered options: The separate-password and additional-recovery-key paths were rejected for the selected flow. Selective restore was not selected.
- Decision: Use a Windows-protected key for backup encryption without asking for a separate password or offering/creating an additional recovery key in the selected flow. Restore a full snapshot only after showing a preview and making a backup of current data. Restore affects only contents within the backup's data scope; it does not reset trial/license state or restore OAuth credentials or a Windows image. Preserve the history-deletion confirmation and do not silently resurrect deleted history.
- Consequences: No guarantee of portability or recovery without access to the protected key. Do not claim backups always work only on the same PC, because Windows roaming behavior may vary. No DPAPI API, protection scope, flags, cipher, KDF, key storage/rotation, archive format, migrations, or restore-failure recovery mechanism is selected. B3 policy is set: expiry of 30-day-old history does not rewrite archives; aged history remains until each archive expires under its own retention (default seven days), and restore applies the current target history-retention setting. Explicit deletion still shows affected archives for user-confirmed recreation or deletion; do not claim 30-day physical erasure across all copies. Archive availability/format, rollback and exact expiry/restore mechanics remain open. Daily/pre-migration backups and seven-day configurable backup retention are unchanged; backups continue to include conversation history and exclude secrets/model weights from ordinary backup content. No implementation or OS API use is approved by this decision.
- Approval basis: Owner's explicit B2 and B3 choices, 2026-11-03.

## ADR-007 — Narrow planner behavior policies

- Date: 2026-11-03, Europe/Moscow.
- Status: Approved by the owner; product behavior only.
- Context: The planner needs explicit policy for ordering eligible work, resolving daylight-saving local-time ambiguity, and handling placements remaining after a split occurrence is completed.
- Considered options: For rank order, deadline-first then priority, priority-only, and a configurable order were presented; deadline-first then priority was selected. Silent gap shifting and silent fold selection are excluded; the owner selected confirmation of a nearby valid gap time or one of the two fold instants. For completion, the selected rule releases future placements only for the completed occurrence and preserves history.
- Decision: Order eligible tasks with explicit deadlines by earliest deadline, then priority. Order tasks without deadlines by priority. For a nonexistent local time in a daylight-saving gap, offer a nearby valid time and require confirmation; for a repeated local time in a fold, show both possible instants and require confirmation. When an occurrence is explicitly completed, release only the remaining future placements belonging to that selected occurrence and preserve placement history.
- Consequences: These policies do not define tie-breaking among equal deadline/priority inputs, the exact “nearby” DST choices or representation, behavior for a placement already started but not yet ended at completion, or reminder handling. They do not approve an algorithm, schema, code, or implementation. The completion action remains separate from segment check-offs; sibling occurrences are unaffected.
- Approval basis: Owner's submitted explicit planner-choice responses, 2026-11-03.

Record each approved decision with a stable ID, date, status, context, considered options, chosen solution, consequences, and owner approval reference. Keep IDs and statuses aligned with the Russian version. Mark proposals as proposed until approved; preserve superseded decisions and link their replacements.

## ADR-008 — Overdue eligibility, abstinence and parent completion

- Date: 2026-11-04, Europe/Moscow.
- Status: APPROVED (product behavior only).
- Context: Resolve the latest planner and habit questions without implicit cascading completion.
- Considered options: The owner selected continued overdue eligibility, explicit abstinence reporting, and retaining active children when closing the parent rather than cascading completion.
- Decision:

Overdue tasks remain eligible for automatic plan proposals without changing their original deadline or overdue status; applying the proposal follows existing confirmation/grant rules. Abstinence success requires an explicit “complied” mark; no mark is not success. Historical corrections remain allowed for any past date during the habit's lifetime, with audit history and the goal effective on that date.

When completing a parent with unfinished children, show “Close task” and “Finish subtasks”. “Finish subtasks” returns to the child list without completing the parent. “Close task” completes only the selected parent occurrence; children remain active and linked, with their own deadlines and placements unchanged. Release only the completed parent's own future placements, preserving history. Other recurrence occurrences are unaffected. This explicit choice is required even when ordinary task-change confirmations are disabled; it determines the intended action.

Exact schema, API names, child nesting/inheritance and handling of already-started placements remain open. These product choices do not authorize implementation.

- Approval basis: Owner’s submitted choices and both parent-completion clarification answers, recorded in PLAN-013.

## ADR-009 — Habit measurement and multi-level subtasks

- Date: 2026-11-04, Europe/Moscow.
- Status: APPROVED (product behavior only).
- Context and options: The owner selected per-habit quantity modes instead of one universal mode, timer plus manual duration instead of either alone, and multi-level subtasks instead of a fixed depth cap.
- Decision and consequences:

- Quantity habits have a per-habit choice: sum individual portions (default), or enter the daily total. A daily-total entry is not an additional portion; corrections retain history. Switching modes and unit/threshold details remain to be designed.
- Duration habits support both a timer with pause and manual duration entry. Multiple sessions are summed for the day. Timer behavior during sleep, full exit, crashes and midnight remains open; duplicate counting must be prevented by the proposed data contract.
- Subtasks support multiple levels without a fixed product depth limit; the interface can collapse branches. This is not a promise of infinite device capacity. Cycle prevention and scalable tree loading are technical design requirements to review. Inheritance, moving branches and deletion semantics remain open. Existing parent-completion behavior remains unchanged.

- Approval basis: Three owner answers recorded in PLAN-014. No schema, runtime algorithm or implementation is approved.
