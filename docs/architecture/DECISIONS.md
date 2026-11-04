# Architecture decision register

[Русская версия](DECISIONS.ru.md)

Twenty-one narrowly scoped decisions are approved: ADR-001 selects Flutter for UI and necessary Dart UI code; ADR-002 selects PostgreSQL as the local backend database; ADR-003 selects Python for planner-core/background logic with an app-owned runtime; ADR-004 selects an application-managed isolated local PostgreSQL instance; ADR-005 selects local-profile access with imported offline signed licenses and defines trial/expiry behavior; ADR-006 selects Windows-protected backup-key handling without a separate password/recovery key and full-snapshot restore safeguards; ADR-007 records three planner policies for priority order, DST ambiguity, and remaining split placements. ADR-008 records overdue eligibility, explicit abstinence success and parent/child completion choices. ADR-009 records habit measurement modes and multi-level subtasks. ADR-010 records license device limit, transfer and clock-rollback behavior. ADR-011 replaces third-party characters with original personas. ADR-012 selects user-owned search keys and MET Norway weather. ADR-013 names the personas and sets navigation, device-action confirmations and the default backup folder. ADR-014 selects the speech engines, the search provider and live-data protection. ADR-015 approves the selected technical directions T1–T6; ADR-016 approves five task and planner behavior choices. ADR-017 records payment timing and the loaded-model response criterion. ADR-018 approves implementation phases and their acceptance criteria only. ADR-019 selects one local profile per Windows account and user review of uncertain timer intervals. ADR-020 approves an editable day-plan draft and replanning proposal for a new meeting. ADR-021 approves help after a missed block and a preview of shifts to unpinned draft blocks. Architecture/repository structure, schema, API and module specifications remain under owner review; programming is not approved. Existing folders remain an organizational scaffold.

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

Exact schema, API names, child nesting/inheritance and handling of already-started placements remain open at this decision date. Child nesting/inheritance was later narrowed by ADR-009; handling of already-started placements remains open. These product choices do not authorize implementation.

- Approval basis: Owner’s submitted choices and both parent-completion clarification answers, recorded in PLAN-013.

## ADR-009 — Habit measurement and multi-level subtasks

- Date: 2026-11-04, Europe/Moscow.
- Status: APPROVED (product behavior only).
- Context and options: The owner selected per-habit quantity modes instead of one universal mode, timer plus manual duration instead of either alone, and multi-level subtasks instead of a fixed depth cap.
- Decision and consequences:

- Quantity habits have a per-habit choice: sum individual portions (default), or enter the daily total. A daily-total entry is not an additional portion; corrections retain history. A mode change takes effect immediately for that habit after a recalculation preview; recalculate the current day under the new mode, leave earlier days unchanged, and retain correction history. Unit/threshold details and exact recalculation mechanics remain to be designed.
- Duration habits support both a timer with pause and manual duration entry. Multiple sessions are summed for the day. Timers of different habits may run concurrently and operate independently; a second live timer for the same habit remains disallowed by the proposed schema. A running timer continues counting through computer sleep, full application exit, and computer shutdown until the user explicitly pauses or stops it; on resume, show elapsed time. Split elapsed duration at local midnight so each day receives its own portion. Timestamp persistence/reconciliation, clock changes, timezone travel, overlap between manual entries and timer sessions, and crash recovery remain technical questions. Prevent duplicate counting.
- Subtasks support multiple levels without a fixed product depth limit; the interface can collapse branches. This is not a promise of infinite device capacity. Cycle prevention and scalable tree loading are technical design requirements to review. For a new child, propose the parent's project and priority and require explicit confirmation; set the child's deadline independently. Future parent changes do not propagate to existing children. Cycle prevention and scalable tree loading remain technical questions; moving branches and deletion were subsequently selected in ADR-016. Existing parent-completion behavior remains unchanged.

- Approval basis: Three owner answers recorded in PLAN-014, subsequent clarifications in PLAN-015 and the separate concurrent-timer answer recorded in PLAN-026 (2026-11-04). No schema, runtime algorithm or implementation is approved.

## ADR-010 — License device limit, transfer and clock rollback

- Date: 2026-11-04, Europe/Moscow.
- Status: APPROVED (product behavior only).
- Context: ADR-005 left device count, reinstall/hardware-change behavior and clock tolerance open. There is no activation server.
- Considered options: one, two or three devices; a hardware-independent license file, a device-bound file reissued on request, or device binding with limited self-service transfer; for clock rollback, a 48-hour tolerance then block, warning only, or immediate block.
- Decision: One license covers up to three devices, counting current Windows PCs and the future Android app. The license file is not bound to hardware: it works on any device, so reinstalling Windows or changing PCs needs no reissue; the device limit is set by the license terms, not technically enforced. If the system clock moves back by more than 48 hours relative to the latest trusted time the application has seen, paid functions are blocked with a "check the date and time" status until the clock is corrected; smaller shifts and timezone changes are tolerated. The block follows ADR-005 expired-state behavior: data, renewal/import, deletion and backups remain available. Payment is out of scope for now and will be designed later.
- Consequences: A shared license file cannot be prevented technically; this is an accepted tradeoff of the offline, hardware-independent model. The per-device seven-day trial remains as in ADR-005. Exact trusted-time storage, the license format/signature, issuer tooling, payment provider and price remain open. No implementation is authorized.
- Approval basis: Owner's answers in PLAN-018 (2026-11-04).

## ADR-011 — Original personas instead of third-party characters

- Date: 2026-11-04, Europe/Moscow.
- Status: APPROVED (product behavior only); supersedes the requirement for the named third-party characters and their recognizable voices.
- Context: The previously requested characters and their voices belong to rights holders and voice actors; a commercial release cannot use them without licenses.
- Considered options: license the original characters and voices while developing on a neutral voice; create original personas inspired by the archetypes; postpone voices.
- Decision: Djarvis ships its own original personas inspired by archetypes (for example a butler, a scientist, an AI assistant), with their own names and voices, without third-party character names, likenesses or actor voices. Voices come from locally running speech synthesis whose voice and model licenses allow commercial use, or from recordings made with written consent. The local file `Vois/join-5tracks.mp3` stays local as a personal reference only; it is not used as a product voice or as material for voice synthesis.
- Consequences: Persona names, characters and voice selection are open owner choices. The rights review in CP10 now covers model/voice licenses and recording consent. Wake phrases default to the persona names. No implementation is authorized.
- Approval basis: Owner's answer in PLAN-019 (2026-11-04).

## ADR-012 — Web search with a user-owned key; MET Norway weather

- Date: 2026-11-04, Europe/Moscow.
- Status: APPROVED (product behavior only).
- Context: There is no own server, and commercial search APIs need a confidential key that must not be embedded in the client.
- Considered options: user-owned key; browser handoff only; own proxy server (would violate the no-own-backend rule). For weather: MET Norway, paid Open-Meteo, user-owned key.
- Decision: In-app web search uses a search API key that the user enters in settings and that is stored locally protected; without a key, search opens in the user's browser and Djarvis does not read the results. Weather uses MET Norway Locationforecast with attribution and an identifying User-Agent; the city comes from the user's setting and a local city catalog. Price and license issuance are deferred together with payment.
- Consequences: The concrete search provider, key storage, provider terms and attribution, city catalog and traffic limits remain to be verified before release. Only the explicit query and the configured city are sent. No implementation is authorized.
- Approval basis: Owner's answers in PLAN-019 (2026-11-04).

## ADR-013 — Personas, navigation, device-action confirmations, backup folder

- Date: 2026-11-04, Europe/Moscow.
- Status: APPROVED (product behavior only).
- Context: ADR-011 left persona names open; DD09 navigation, device-action confirmations beyond shutdown/restart/logout, and the backup path were open.
- Decision:
  - Personas (names are also the default wake phrases): «Эдвард» / Edward — a courteous butler with dry humor; «Профессор Вольт» / Professor Volt — an eccentric, ironic but never rude scientist; «Нова» / Nova — a calm AI assistant with concise answers. Voices are selected to match each character under ADR-011.
  - Sidebar, top to bottom: Today, Tasks, Calendar, Habits, Projects, Notes; Settings separately in the bottom service area.
  - Closing programs and putting the PC to sleep or locking it require confirmation, in addition to the existing always-confirmed shutdown, restart, logout, file deletion and file overwrite. Launching user-selected programs and changing volume or brightness run without confirmation.
  - Default backup folder: `Documents\Djarvis Backups`, changeable in settings.
- Consequences: Exact voice models, persona style guidance, app identity/argument validation and backup-folder failure handling remain technical work. No implementation is authorized.
- Approval basis: Owner's answers in PLAN-019 (2026-11-04).

## ADR-014 — Speech engines, search provider, live-data protection

- Date: 2026-11-04, Europe/Moscow.
- Status: APPROVED (product and technology direction; versions not selected).
- Context: ADR-011–013 require commercially licensed offline voices, a user-key search provider and a live-data protection level. Research on 2026-11-04: the active Piper engine moved to GPL-3.0 (the MIT repository is archived) and voice licenses vary per voice; Silero models are non-commercial; Vosk TTS (Russian, multi-speaker) and Kokoro-82M (English and other languages, no Russian) publish Apache-2.0 weights.
- Considered options: Vosk TTS + Kokoro; Piper for both languages; contracted voice actors. Tavily, Brave or both. Windows ACL with a BitLocker hint, field-level encryption, or ACL only.
- Decision: Russian speech uses Vosk TTS synthetic voices (prefer voices not trained on a named real speaker); English speech uses Kokoro. Edward — low male voice (British in English); Professor Volt — second male voice, faster and higher; Nova — synthetic female voice. In-app web search supports Tavily with the user's own key. The live PostgreSQL data folder is restricted to the user's Windows account, and the application recommends enabling Windows BitLocker device encryption; archives remain encrypted per ADR-006.
- Consequences: Before release, verify each selected voice's provenance and license, the exact model versions and any GPL-licensed phonemizer dependency (for example espeak-ng) and how it is shipped; measure CPU real-time factor and memory on the 8 GiB target. Tavily terms, attribution and request limits are verified before release. No implementation is authorized.
- Approval basis: Owner's answers in PLAN-020 (2026-11-04).

## ADR-015 — Technical decisions T1–T6: connection, database, backups, installer, memory, voice

- Date: 2026-11-04, Europe/Moscow.
- Status: APPROVED (technical decisions; the implementation plan is under owner review).
- Context: PLAN-022 closed the open technical questions of CP01–CP04, CP15 and CP18 and put six decisions to the owner ([technical details](TECHNICAL_DESIGN.md) §6), based on the [feasibility checks](FEASIBILITY.md).
- Considered options: T1 — the core owns the icon and the interface unloads when the window closes; the interface stays in the tray; closing the window = exit. T2 — forward-only migrations with a backup, or with reverse migrations. T3 — Windows-protected key without a password, or with an extra password. T4 — signing later, cloud signing now, or an EV certificate. T5 — unload the model after 1, 5 or 15 minutes. T6 — Vosk TTS 0.7 and 0.9.
- Decision:
  - T1: the interface and the core communicate over loopback HTTP + WebSocket with a per-run token and `Host`/`Origin` checks. Closing the window hides the interface to the notification area; the interface owns the icon; the core is a separate process.
  - T2: private PostgreSQL 18, asyncpg driver, own forward-only migration runner; an automatic backup before every migration, rollback by restoring that backup.
  - T3: DJB1 backup format — tar, AES-256-GCM in streamed chunks, archive key under DPAPI without a password (within ADR-006).
  - T4: Inno Setup per-user installer without admin rights; unsigned during development and closed testing; a code-signing certificate before public release.
  - T5: in the 8 GiB profile the model and synthesis unload after 5 minutes idle; the value is configurable.
  - T6: Russian synthesis uses Vosk TTS 0.7 in all profiles; 0.9 is a possible later higher-quality option for 16 GB+.
- Consequences: Background memory in the 8 GiB profile is ≈ 0.7 GB including the tray interface; interface memory must be measured. Without signing, Windows SmartScreen warns during installation on test machines. Programming does not start until the structure is fully worked out and the owner has received a full programming-readiness report. Real checks (voice assistant, microphone, task tracking, etc.) happen after programming; checks that need no code also come later (owner's condition, PLAN-023).
- Approval basis: Owner's answers in PLAN-023 (2026-11-04).

## ADR-016 — Subtasks, recurrence, blocks and missed-time announcement (Q1–Q5)

- Date: 2026-11-04, Europe/Moscow.
- Status: APPROVED (product behavior; schema and API are under owner review).
- Context: While working out the [database schema](SCHEMA.md), five behavior questions remained that affect the data structure: deleting and moving a subtask branch, subtasks of a recurring task, completion in the middle of a block, and announcing missed time.
- Considered options: Q1 — ask every time, always delete the branch, always lift the children. Q2 — a copy in each occurrence, one list per series, not allowed. Q3 — truncate the block, keep it whole. Q4 — under any task, only within its project, under any task with project inheritance. Q5 — a per-task switch, one general rule.
- Decision:
  - Q1: when a task with subtasks is deleted, the core asks every time: "Delete all" or "Keep subtasks" (lift them one level up).
  - Q2: subtasks and the checklist of a recurring task are a template; each occurrence gets its own copy, and check marks do not carry over between repetitions.
  - Q3: completion in the middle of a planned block truncates the block at the completion moment; the remaining time is freed.
  - Q4: a branch can be moved under any task and into any project except its own descendants; the children's project does not change by itself.
  - Q5: a task has a "Don't announce the miss aloud" switch; the missed highlight in the list always remains.
- Consequences: The schema adds `task.announce_missed`, `task_occurrence.parent_occurrence_id`, `checklist_template_item`; the API adds `DeleteTask(children)`, `SetChecklistTemplate`. These decisions do not authorize programming before the plan is approved.
- Approval basis: Owner's answers in PLAN-024 (2026-11-04).

## ADR-017 — Payment timing and voice-response acceptance

- Date: 2026-11-04, Europe/Istanbul.
- Status: APPROVED (narrow timing and acceptance policy only; implementation plan still under owner review).
- Context: The proposed implementation plan called its first build a release while payment and license issuance were deferred, and set a three-second voice-response target despite a much longer recorded cold model startup.
- Considered options: Payment before a first build, after software and manual tests, or in a separate public-release step; a three-second target including cold startup, after model loading, or no numerical target. The owner selected payment after software implementation and manual tests, and the loaded-model criterion with separate cold-start evaluation.
- Decision: Activate payment only after software implementation and manual tests. Judge the proposed three-second time from end of the user utterance to start of spoken response after the required models are loaded; measure cold startup separately on the target PC. Do not infer that public paid distribution or license issuance is approved or scheduled.
- Consequences: The exact payment stage/provider, price, license issuance process and public-sale date remain open. No numeric cold-start acceptance limit is selected before target-machine measurement. This decision does not approve the overall implementation plan or authorize programming.
- Approval basis: Owner's two submitted answers during PLAN-027, 2026-11-04.

## ADR-018 — Implementation phases and acceptance criteria

- Date: 2026-11-04, Europe/Istanbul.
- Status: APPROVED (P0–P7 phase composition, order, dependencies and acceptance criteria only).
- Context: The owner reviewed the proposed implementation plan after the timing and dependency clarifications in PLAN-027.
- Considered options: Approve the plan phases and criteria while withholding P0, request further plan changes, or continue to the schema without approving the plan. The owner chose the first.
- Decision: Approve phases P0–P7 and their acceptance criteria as written in IMPLEMENTATION_PLAN. P2 and P3 may run concurrently after P1, each with separate acceptance; dependent phases start after accepted prerequisites. Do not begin P0 yet.
- Consequences: Approval does not extend to the plan's architecture diagram, repository structure, the proposed database schema, API or modules. Separate explicit authorization is required before any application programming. Substantial deviations from approved phases/criteria require owner review.
- Approval basis: Owner's explicit choice in PLAN-028, 2026-11-04.

## ADR-019 — Per-Windows-account profile and clock-rollback timer review

- Date: 2026-11-04, Europe/Istanbul.
- Status: APPROVED (product profile and timer review behavior only; schema remains proposed).
- Context: The proposed schema allowed multiple profile rows in one private cluster and described a timer clock-review state that its SQL could not store.
- Considered options: One local profile per Windows account or multiple in-app profiles; for a rolled-back system clock, confirm/correct a shown calculation, require manual duration without an estimate, or credit an estimate automatically. The owner selected one per Windows account and review before credit.
- Decision: Each Windows account has one local Djarvis profile; different Windows accounts have isolated local data. A duration timer keeps running until the user explicitly pauses/stops it. If a backward clock change makes an interval uncertain, show the calculation and ask the user to confirm or correct the interval before crediting it to habit statistics.
- Consequences: The proposed schema needs a one-profile invariant and durable representation of intervals awaiting review. A confirmed interval must be allocated by local day with an auditable, idempotent action. A timer interval uses its starting timezone; a detected timezone change leads to a displayed calculation and review before credit. Impossible estimates and interval display remain part of schema/UI review; no application implementation or database migration is approved.
- Approval basis: Owner's two submitted schema-review choices in PLAN-029, 2026-11-04.

## ADR-020 — Editable day-plan draft and a new meeting

- Date: 2026-11-04, Europe/Istanbul.
- Status: APPROVED (only the two user-facing rules; schema and API remain proposals).
- Context: An automatic day proposal needs user adjustment before application, and an accepted task block can conflict with a newly arrived meeting.
- Considered options: Edit blocks in a draft then accept the whole plan, only accept/regenerate, or confirm each block; for a new meeting, show conflict and propose replanning, move the task automatically, or leave the overlap for manual repair.
- Decision: the user may drag and edit blocks in the draft and then accepts the entire plan. If a new meeting occupies the time of an already accepted task, the app shows the conflict and proposes a new plan; it applies that plan after confirmation or under a saved grant covering this action.
- Consequences: editing a draft does not itself change the accepted schedule; constraints and source freshness are checked before application. A new meeting does not silently overwrite task placement. Proposed database fields, API commands and conflict presentation require separate review.
- Approval basis: the owner's two main-flow choices in PLAN-031, 2026-11-04.

## ADR-021 — Missed block and draft shift preview

- Date: 2026-11-04, Europe/Istanbul.
- Status: APPROVED (two user-facing policies; algorithm and API remain proposed).
- Context: an unfinished task needs attention after its scheduled time passes, and dragging a draft block can occupy other work's time.
- Considered options: for a miss, propose replanning the remaining day, only remind, or replan automatically; for a drag, preview shifts of affected unpinned blocks, stop at the conflict, or allow an overlap with a warning.
- Decision: highlight a missed block and propose replanning the remaining day; apply the new plan after confirmation or under a saved grant covering the action. If a draft block is dragged into occupied time, propose shifts of affected unpinned blocks with a preview; the user accepts the entire result together.
- Consequences: a miss does not mean completion and does not itself change a task's date or deadline. A draft shift does not change the accepted schedule; pinned blocks stay protected. The shift algorithm and behavior when not all blocks fit need separate technical review.
- Approval basis: the owner's two main day-plan choices in PLAN-032, 2026-11-04.
