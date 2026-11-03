# Component design plan

[Русская версия](COMPONENT_PLAN.ru.md) · [Product requirements](../PRODUCT.md) · [Approved architecture decisions](DECISIONS.md) · [Planner core](PLANNER_CORE.md) · [Architecture proposal](PROPOSAL.md) · [Remaining design work](REMAINING_PLAN.md) · [Required visual design](../DESIGN.md)

Status: planning map for the detailed work still needed before an implementation plan. The product requirements and narrow ADRs are the current baseline; this document does not approve new technology, architecture, code, installation, or product behavior. It organizes design work already identified across the linked documents. The 20 component IDs are a navigation and dependency map, not 20 new decisions or a default decision queue.

Flutter for UI, Dart only for necessary UI code, Python for planner/background logic, app-managed isolated local PostgreSQL, current-version local-only inference, offline signed-license import, the mandatory visual design, and the accepted product policies remain the baseline. There is no own remote application backend, cloud user-data store, or current cloud inference. Future Android is a later design. The Win10/11, 8 GiB, CPU-capable target is not validated; do not claim current full-stack performance.

The plan distinguishes a required product policy from an unresolved contract and from a proposed technical method. Owners choose user-facing, privacy, commercial, and other product tradeoffs. Agents should investigate and recommend technical details, with alternatives and consequences; the owner need not choose individual columns, indexes, or internal classes. No stated requirement is silently cut to create an MVP.

## Component overview

| ID | Component | Main dependency | Reviewable deliverable |
| --- | --- | --- | --- |
| CP01 | Process supervision and Flutter/Python IPC | ADR-001/003/004 | lifecycle and transport contract |
| CP02 | Commands, policy, idempotency and revisions | CP01 | typed command and result contract |
| CP03 | PostgreSQL schema and read models | CP02, CP06, CP07, CP15 | reviewed logical/physical data model |
| CP04 | Private PostgreSQL lifecycle and migrations | ADR-004, CP01, CP03, CP15 | packaging, lifecycle and recovery design |
| CP05 | Deterministic planner | CP02, CP03, CP06, CP11 | planner inputs, ranking and explanations |
| CP06 | Time, recurrence and habit math | CP02, CP03, CP05 | exact temporal/domain rules |
| CP07 | Projects, notes, attachments and local search | CP03, CP14, CP15 | independent local content contract |
| CP08 | Local model orchestration and memory | CP01, CP02, CP09, CP10 | local inference and context contract |
| CP09 | Microphone, wake phrase and dialogue | CP01, CP08, CP11, CP16 | audio state machine and permissions |
| CP10 | Speech output, personas and voice assets | CP08, CP09 | voice/asset/rights plan |
| CP11 | Reminders and proactive behavior | CP02, CP05, CP06, CP09, CP16 | durable reminder and trigger contract |
| CP12 | Calendar and Gmail integrations | CP02, CP03, CP14, CP15 | provider-specific sync/action contracts |
| CP13 | Web search and weather | CP08, CP14 | external-provider and privacy contract |
| CP14 | Windows application, file and device adapters | CP02, CP07, CP09, CP12 | scoped capabilities and confirmation design |
| CP15 | Conversation history, privacy and backups | CP03, CP04, ADR-006 | retention, archive and recovery contract |
| CP16 | Offline trial and license lifecycle | ADR-005, CP04, CP15 | entitlement and offline recovery design |
| CP17 | Screens, routes, states and accessibility | ADR-001, CP03, CP05–CP16 | user-journey and screen-state specification |
| CP18 | Installer, assets and updates | CP04, CP08–CP10, CP15, CP16 | packaging/update/rollback design |
| CP19 | Future Android boundary | CP01–CP03, CP06, CP12, CP15–CP18 | platform-neutral contracts and alternatives |
| CP20 | Acceptance, performance and support | CP01–CP19 | measurable future verification plan |

## Component plans

### CP01 — Process supervision and Flutter/Python IPC

**Known baseline:** Flutter UI and Python planner/background host are approved directions; the app manages a private local PostgreSQL instance. Window close keeps background wake behavior; Full Exit stops workers and capture. Exact process model and transport are unselected.

**Open design work:** define owner/supervisor responsibilities and startup/ready/degraded/stopping states; specify UI-to-host authentication, versioning, reconnect and backpressure; define worker lifetimes, single-host ownership, crash recovery and graceful Full Exit. Do not assume FastAPI, named pipes, a socket, or a particular process count.

**Dependencies:** CP02, CP04, CP08–CP11, CP16. **Deliverable:** lifecycle diagram, IPC threat boundary, contracts, failure matrix and alternatives with resource costs.

**Future acceptance cases (not run):** window reopen attaches to the running host; second launch does not create a second DB owner; host/worker restart recovers safely; Full Exit stops capture and processes; stale or oversized IPC messages are rejected.

**Owner chooses:** visible lifecycle/exit behavior and any material privacy prompt. **Agent proposal:** transport, process split, authentication handoff and recovery mechanics, supported by feasibility evidence.

### CP02 — Typed commands, policy, idempotency and concurrency state

**Known baseline:** commands share one policy gate; ambiguous intent always needs clarification. Task no-confirm grants are separate/revocable; mail send and file delete/overwrite always confirm; habits change goals only after acceptance. Gmail is one general read/search-draft-send toggle; its sends still confirm exact recipients/body/attachments. Selected-app launches are allowlisted; Windows shutdown/restart/logout always confirm individually.

**Open design work:** finalize typed request/result envelopes and validation boundaries; define action IDs, deduplication, revisions and retry semantics; specify confirmation binding/staleness/revocation for local and queued actions; design the short planning-state guard against concurrent planning-affecting writes. Never wait for the user/model/provider while holding DB locks.

**Dependencies:** CP01, CP03, CP05, CP11–CP16. **Deliverable:** command catalog, permission/state transitions, idempotency and conflict contracts, error taxonomy.

**Future acceptance cases (not run):** duplicate action returns prior result; revoked grant blocks execution; ambiguous target asks even with no-confirm enabled; Gmail toggle does not bypass per-send confirmation; an inserted meeting invalidates a stale plan; unknown external outcome is not reported as success.

**Owner chooses:** any user-visible confirmation and remembered-grant scope. **Agent proposal:** typed contracts, validation, serialization and state model.

### CP03 — PostgreSQL schema, constraints, indexes and read models

**Known baseline:** PostgreSQL is the approved local backend; user data stays on-device. No final DDL/schema or driver is approved. Product distinctions—task occurrence vs placement, deadlines vs scheduled time, habit periods vs logs, local vs provider state—must remain representable.

**Open design work:** map product entities and lifecycle to normalized records and stable IDs; specify integrity constraints, indexes, revisions, deletion/tombstone policy and migration compatibility; design read models for day/task/habit/calendar/project/note/history views; identify attachment and provider-reference boundaries.

**Dependencies:** CP02, CP04–CP07, CP11–CP12, CP14–CP16. **Deliverable:** ER diagram, candidate DDL, constraints/index rationale, query/read-model catalogue and migration examples.

**Future acceptance cases (not run):** invalid references and duplicate logical IDs are rejected; recurrence instances preserve identity when placements move; task completion does not complete neighboring occurrences; provider conflict/history/audit states are queryable; migration preserves supported records.

**Owner chooses:** only product semantics that alter stored meaning or retention. **Agent proposal:** schema alternatives, constraints, indexes and migration strategy; exact DDL remains proposed until reviewed.

### CP04 — Private PostgreSQL packaging, lifecycle and migrations

**Known baseline:** app-managed, isolated local PostgreSQL is approved; no Docker, global service, version, binary package, driver, installer dependency or connection protocol is selected. Full Exit stops the app-owned host/database cleanly.

**Open design work:** compare private runtime distribution and supported versions; define private data directory, ACLs, loopback/credential boundary and readiness checks; specify start/stop, lock ownership, upgrade/rollback and backup-before-migration; define corruption, disk-full, partial-upgrade and unavailable-database recovery. Do not silently install a global service.

**Dependencies:** CP01–CP03, CP15–CP18. **Deliverable:** lifecycle/packaging alternatives, threat/permissions model, migration and recovery runbooks, dependency inventory.

**Future acceptance cases (not run):** simultaneous launch preserves one data-directory owner; interrupted migration restores a recoverable state; low disk and corrupt cluster produce actionable status; clean uninstall does not silently delete user data; Full Exit releases owned processes.

**Owner chooses:** installation, data-retention and recovery UX. **Agent proposal:** runtime packaging, ACLs, lifecycle and upgrade mechanics; no binaries are selected here.

### CP05 — Deterministic scheduler, ranking, splits and explanations

**Known baseline:** planner considers meetings, deadlines, priority, duration, habits, breaks and available hours; proposes a plan and applies only after confirmation or a remembered applicable grant. Manual placements remain locked unless explicitly permitted. Splitting requires per-task opt-in; completing all segments is not completion. A date-only planning window is 06:00–22:00 with task duration; an explicit deadline lacking time always prompts.

**Open design work:** define feasible-interval construction and hard/soft constraint semantics; propose reviewable priority/deadline ranking and tie-breaking; specify plan explanations, unplaced work and overload reporting; model opt-in segment placement bounds and behavior after explicit occurrence completion; define preview/stale-plan handling.

**Dependencies:** CP02–CP04, CP06, CP11–CP12, CP17. **Deliverable:** deterministic planner specification, worked examples, ranking alternatives and explainability contract.

**Future acceptance cases (not run):** locked blocks never move; infeasible tasks are surfaced; missing duration is requested before automatic scheduling; split is absent without task opt-in; all segment check-offs do not complete the occurrence; explicit completion targets only the selected occurrence; stale input is revalidated.

**Owner chooses:** what is a hard constraint, plan presentation and acceptable tradeoffs. **Agent proposal:** deterministic algorithm and ranking options, without claiming global optimality.

### CP06 — Timezones, DST, recurrence, backlog and habit calculations

**Known baseline:** task recurrence stays anchored to original schedule; missed occurrences remain task debt. Monthly missing-day default is last day, with per-rule skip option. Habits support four measurement types, fixed and flexible schedules, Monday-based weeks, pause rules, historical correction, separate streak definitions and no task-like debt. Each habit/personal recurrence chooses local-following or original fixed timezone; ask on timezone change if unset. Meeting events must not inherit that policy.

**Open design work:** define instants vs civil dates and DST gap/overlap behavior; specify interval generation, exception/edit scope and backlog cutoffs; calculate pause, flexible quota, streak and correction math on partial weeks; define timezone-change behavior and date-only deadline input around zone transitions; keep historical records on their original timestamps.

**Dependencies:** CP02, CP03, CP05, CP11, CP12, CP17. **Deliverable:** temporal glossary, recurrence/habit state tables and worked calendar examples.

**Future acceptance cases (not run):** Jan 31 → Feb 28 → Mar 31 with original anchor; late completion leaves next original due date; travel follows chosen habit policy or asks if unset; DST gap/overlap is explicit; paused week below flexible quota is neither miss nor streak break; backdated corrections preserve history and recompute with then-current goal.

**Owner chooses:** user-facing recurrence/exception and habit interpretation where not already fixed. **Agent proposal:** exact temporal representation and algorithms for review.

### CP07 — Independent projects, notes, attachments and local search

**Known baseline:** internal calendar, notes and projects work independently of optional Google sync. User data stays local. Advanced task fields already include optional subtasks/checklists, tags and attachments; a global setting can hide advanced fields while each task may expand them independently, without deleting hidden data. File deletion/overwrite always confirms exact target. No source decision approves Markdown, hierarchy depth, semantic embeddings, or any particular attachment format.

**Open design work:** define project/note relationships and search scope; compare content formats without assuming Markdown or nested project trees; specify attachment import, preview, link, rename/delete and backup consistency; define local text indexing, permission filters, stale-index repair and privacy behavior. For task subtasks/checklists, tags and attachments, decide whether nesting has a depth limit, whether fields inherit, how parent/checklist completion behaves, how child estimates/scheduling avoid double counting, and how subtasks differ from opt-in split segments. Do not invent cascade-completion semantics.

**Dependencies:** CP03, CP14–CP15, CP17. **Deliverable:** entity/workflow options, attachment lifecycle, local-search contract and archive-consistency design.

**Future acceptance cases (not run):** disconnected Google leaves internal records intact; file overwrite asks for exact path; attachment references survive backup/restore; search respects access and excludes deleted/private content; unsupported formats fail visibly without data loss.

**Owner chooses:** note/project workflows, supported file types and user-facing search scope. **Agent proposal:** storage/index alternatives and consistency mechanisms; avoid unapproved content formats.

### CP08 — Local LLM intent, tools, context, model choice and memory

**Known baseline:** current release permits local inference only; no cloud AI. With valid access and local resources, local planner, reminders, voice and conversation work offline. API keys are future-only. The assistant remembers name/nickname; conversation history is separately controllable; additional inferred persistent memories are not approved. Model selection is hardware-profile based, separate from trial identity.

**Open design work:** define intent extraction vs deterministic command validation; create narrow tool schemas and untrusted-input boundaries; compare local model candidates/context budgets under target hardware; specify cancellation, model failure and fallback to manual planner; separate session context, retained history and explicitly approved preferences.

**Dependencies:** CP01–CP03, CP07, CP09–CP10, CP13, CP16. **Deliverable:** local inference boundary, evaluation protocol, context/memory policy and failure behavior.

**Future acceptance cases (not run):** model cannot mutate data outside typed tools; untrusted email/web/file content grants no permission; model crash leaves manual planner usable; no hidden long-term inferred memory; offline local requests never silently invoke a cloud model.

**Owner chooses:** conversational memory/retention UX and acceptable assistant initiative. **Agent proposal:** model/runtime shortlist and evaluation method; no default or performance claim is approved.

### CP09 — Microphone, wake phrase, recognition, turns and mute

**Known baseline:** wake phrase defaults to the selected character name, user may change it; no repeat phrase during dialogue. «Хватит»/“Stop” ends dialogue and returns to wake listening unless muted/gated. After each assistant answer, the default wait for the next reply is 30 seconds, configurable; it does not limit active user speech, inference or TTS. New speech interrupts TTS. Instant mute stops capture for wake and dialogue, lasts the app session and resets after genuine app/Windows restart only when OS/access/resources permit. Window close keeps background wake; Full Exit stops capture.

**Open design work:** compare local wake/ASR strategies and measure false accepts/rejects; define microphone-state machine, indicator, permission denial, device switch and echo handling; specify timer reset/suspension and barge-in races under the approved configurable 30-second wait; test mute/restart/OS hardware-mute interaction without overriding OS gates.

**Dependencies:** CP01, CP08, CP10–CP11, CP16–CP18. **Deliverable:** audio state diagram, privacy indicator/permission flows, candidate pipeline and failure matrix.

**Future acceptance cases (not run):** mute prevents all capture; expired access or OS denial prevents capture; restart re-enables only when allowed; reopen-window is not restart; Stop returns to wake state rather than global mute; speech interruption cancels output; echo does not retrigger itself.

**Owner chooses:** wake phrase, visible mute/status behavior and dialogue UX. **Agent proposal:** local detection/ASR pipeline and robustness plan; no always-listening implementation is approved here.

### CP10 — TTS, personas, production voices and rights

**Known baseline:** owner wants exact named characters and recognizable voices (JARVIS, Rick Sanchez, Sebastian), not generic substitutes. Supplied MP3 stays local. Exact character/dub/language asset and commercial-use permission are unverified; model-weight license alone is not character/recording permission.

**Open design work:** identify intended actor/dub/language variants with owner; inventory voice/model/recording licenses and commercial rights; evaluate appropriately licensed local TTS options and resource costs; define persona presentation without changing permissions, facts or business rules; document fallback if rights or technical quality are unavailable.

**Dependencies:** CP08–CP09, CP16, CP18, CP20. **Deliverable:** voice identity/rights register, licensed asset options, TTS evaluation plan and product fallback decision.

**Future acceptance cases (not run):** only approved assets ship; requested identities are not silently replaced; persona never alters authorization or facts; TTS interruption/latency and offline behavior are measured after approval.

**Owner chooses:** exact voice actor/dub/language identity and acceptable rights path. **Agent proposal:** lawful technical candidates and evaluation criteria; no substitute or rights claim is presumed.

### CP11 — Reminders, background jobs, proactive speech and Windows context

**Known baseline:** persistent local reminders and one catch-up summary after sleep/restart, subject to valid access and OS notification permission. Quiet hours are explicitly set or explicitly none; no default schedule. Proactive speech remains off until setup choice. Call/game suppression uses system heuristics, selected-app list and manual quiet; 30-minute input-idle trigger is configurable and opt-in. These heuristics do not prove physical absence.

**Open design work:** define durable job identity, rescheduling and stale-target cancellation; set cooldown/max catch-up policy; specify ordinary notification vs voice gates and Windows notification failures; design selected-app/system-signal heuristics and manual override; ensure offline planner and expiry rules are respected.

**Dependencies:** CP02, CP05–CP06, CP09, CP14, CP16–CP17. **Deliverable:** reminder state machine, trigger precedence, delivery/cooldown policy and recovery scenarios.

**Future acceptance cases (not run):** one summary rather than replay flood; cancelled/completed targets excluded; quiet/call/game suppresses proactive voice but does not mute mic; no trigger activation without consent; Full Exit/sleep/OS denial limits are communicated.

**Owner chooses:** initiative prompts, quiet-hours and trigger defaults. **Agent proposal:** durable scheduler and Windows context signal handling, with heuristic limits stated.

### CP12 — Google/Outlook calendar and Gmail adapters

**Known baseline:** bidirectional sync covers user-selected Google Calendar/Outlook events and task time blocks; habits are a separate opt-in, default off. Calendar synchronization excludes Google Tasks API, notes/projects/attachments/mail mirroring and every-calendar export. Same-event conflicts ask the user; provider deletion of locally unchanged event also asks. Removing a block does not delete task/habit. Gmail has one general toggle for read/search, draft and send; every send confirms exact recipients/body/attachments. No incremental OAuth promise or scope/SDK choice.

**Open design work:** specify OAuth public-client flows, scopes and verification with provider requirements; define event/task-block projection, update ownership and recurrence mapping; model cursors/base/revisions/conflicts/deletion propagation; define disconnected state, cache and local outbox; specify unknown send outcomes/reconciliation without blind retry.

**Dependencies:** CP02–CP03, CP06–CP07, CP14–CP16, CP20. **Deliverable:** separate provider contracts, permission matrix, conflict/deletion diagrams and unknown-outcome policy.

**Future acceptance cases (not run):** selected scope only; habit off until opt-in; two-sided edits keep user choice; remote deletion asks before removing unchanged local data; no implicit task deletion from block removal; send always confirms and unknown result never triggers blind resend.

**Owner chooses:** calendar selection/habit opt-in and user-facing conflict experience. **Agent proposal:** provider-specific auth/sync mechanisms and failure recovery after current requirements review.

### CP13 — Web search, weather and external information providers

**Known baseline:** search, live weather and external providers require network; local inference remains local. City can be entered manually or detected with permission; precise GPS is not required. Search query and weather city are disclosed only as needed. Provider choice, attribution and cost are open.

**Open design work:** compare providers and terms/availability without embedding commercial secrets in the client or assuming an own proxy/backend; define minimal request fields and consent; specify result freshness, provenance, attribution and cache expiry; treat remote results as untrusted and separate them from deterministic planner facts; design offline/error states.

**Dependencies:** CP08, CP14–CP17, CP20. **Deliverable:** provider shortlist and privacy/data-flow comparison, response provenance and cache policy.

**Future acceptance cases (not run):** offline mode never claims live result; stale weather is labeled or withheld; city-only request avoids precise GPS; remote prompt injection cannot grant actions; attribution/terms are visible as required.

**Owner chooses:** user-facing provider/consent tradeoffs and supported markets. **Agent proposal:** provider comparison and bounded data flow; no provider is selected by this plan.

### CP14 — Windows file/device adapters, allowlists and confirmations

**Known baseline:** no unrestricted shell. File delete/overwrite and email send always confirm. A revocable allowlist grant may launch user-selected applications without repeated confirmation; it does not grant generic SQL/shell/scripts/arbitrary arguments, file deletion/overwrite or OS-consent bypass. Shutdown/restart/account logout always confirm each action. Other device actions remain open.

**Open design work:** define stable application identity, argument validation and user-maintained allowlist; specify file path scope, reparse/link and race handling; enumerate device actions separately with capability and confirmation policy; handle OS consent/permission denials and secure presentation; ensure task/Gmail grants never expand into device/file authority.

**Dependencies:** CP02, CP07, CP09, CP11–CP13, CP17. **Deliverable:** capability catalogue, threat boundary, per-action confirmation matrix and Windows adapter contract.

**Future acceptance cases (not run):** only allowlisted app launches; malformed/extra arguments rejected; every shutdown/restart/logout asks; task/Gmail grants cannot bypass; exact file target confirmed; OS refusal remains authoritative.

**Owner chooses:** allowed application categories, file/device operations and confirmation UX. **Agent proposal:** Windows APIs, identity/argument validation and path-safety design; no generic command runner.

### CP15 — History, privacy, backup keys, archives and restore failures

**Known baseline:** local history defaults to 30 days; user can change, disable or delete it. Daily and pre-migration local backups retain seven days by default, include history and live in a separate configurable folder. Windows-protected backup key, no separate password/recovery key; full snapshot restore only after preview and backup of current data. Age expiry does not rewrite archives; restore uses current retention; manual delete shows affected archives for confirmation. License/trial, OAuth secrets and Windows image are outside restore scope. The selected encryption policy concerns backups; it does not approve encryption of the live database, logs or caches.

**Open design work:** choose archive format and database/attachment consistency; compare exact cipher/KDF/protection API and key scope/storage/rotation; specify history redaction/audit boundaries, expiry/archive interaction and backup deletion/availability; define restore preview, validation, failure, rollback and missing-key behavior; keep secret/model weights out of ordinary backups.

**Dependencies:** CP03–CP04, CP07–CP08, CP12, CP14, CP16–CP18. **Deliverable:** data classification, archive format alternatives, key/recovery threat model and restore/error state machine.

**Future acceptance cases (not run):** age expiry leaves archives unchanged until their own expiry; restore uses current retention; explicit deletion cannot silently purge unrelated files or resurrect deleted history; no claim of physical erasure across copies; key unavailable gives honest recovery limitation; restore preserves license/OAuth scope boundaries.

**Owner chooses:** user-facing history/backups/privacy policy already recorded; any new retention/export change needs discussion. **Agent proposal:** cryptographic/archive/restore details with portability and failure limitations stated.

### CP16 — Offline entitlement, trial, license issuance and renewal

**Known baseline:** local profile, no mandatory account or own activation server; signed license file imported and checked offline. Seven-day device trial starts at first use of any product function; expiry locks planner/assistant but preserves data, allows renewal/import, deletion and backups, and stops microphone/proactive speech. No claim of unique-person or unbypassable trial.

**Open design work:** determine commercial issuer, purchase, price/plan and renewal period; specify signed artifact, key custody/verification and offline renewal; define device-binding, clock rollback, reinstall/hardware-change and recovery policy; separate license state from user archives and account/cloud-future discussion.

**Dependencies:** CP04, CP09–CP10, CP15, CP17–CP18, CP20. **Deliverable:** licensing lifecycle, trust boundaries, renewal/recovery scenarios and commercial decision brief.

**Future acceptance cases (not run):** setup/download waiting does not start trial; manual planner use does; expiry locks paid features without data deletion; no microphone capture under expired access; import works offline; reinstall/clock behavior is described honestly.

**Owner chooses:** price/plan, issuer/purchase/renewal user journey and commercial constraints. **Agent proposal:** offline verification and recoverability options; do not promise anti-tamper guarantees.

### CP17 — Screens, routes, states, themes, accessibility and localization

**Known baseline:** mandatory dark glass/Bento design with sidebar/top bar and circular assistant above day panel; exact palette values and independent Glass/Solid modes; all six combinations required; no background image. AA contrast, focus, reduced motion, non-color status, responsive behavior and opaque fallback are required. Default palette/material, density and some route grouping remain undecided.

**Open design work:** map approved tasks/calendar/habits/projects/notes to routes and page-level groupings; design every empty/loading/offline/denied/conflict/model-preparing/license-expired state; settle default palette/material/density only through owner choices; specify navigation, responsive breakpoints, localization text expansion, focus and accessibility review.

**Dependencies:** CP03, CP05–CP16, ADR-001, required design. **Deliverable:** screen/route inventory, wireflow, design-token/state matrix and prototype review package.

**Future acceptance cases (not run):** six palette/material combinations; default does not remove alternatives; status is not color-only; keyboard/focus/reduced motion/contrast; loading and no-data states are real; no invented CRM entities; baseline visual effects are measured, not presumed valid.

**Owner chooses:** still-open defaults and user-facing navigation/density tradeoffs. **Agent proposal:** route grouping and detailed state layouts under mandatory design constraints.

### CP18 — Installer, adaptive assets, updates, rollback and build matrix

**Known baseline:** compact installer; first launch downloads hardware-appropriate local model assets with visible in-app progress. Installation is automatic/background from the user's perspective, not covert system installation. Win10/11 targets; exact versions/packages/dependencies are unselected. Current 8 GiB/full-stack performance is unvalidated.

**Open design work:** separate signed app/runtime payload from models; design manifest, source trust, hashes, resumable download and atomic activation; compare update channels, backup-before-migration, rollback and uninstall/data retention; build a Win10/11 architecture/dependency/license matrix and low-disk/interrupted-setup recovery.

**Dependencies:** CP04, CP08–CP10, CP15–CP17, CP20. **Deliverable:** packaging options, asset manifest contract, update/rollback lifecycle, supported-build matrix and installer UX.

**Future acceptance cases (not run):** corrupt download never activates; interruption resumes; prior working assets remain recoverable; migration backup precedes update; uninstall behavior preserves data unless user chooses otherwise; supported clean systems install without terminal/global runtime setup.

**Owner chooses:** distribution channel and user-visible update/uninstall behavior. **Agent proposal:** packaging/signing/manifest/version strategy and matrix; no specific stack version is selected.

### CP19 — Future Android boundary and synchronization

**Known baseline:** Windows first, Android and cross-device synchronization later. No mobile database, Android Python host, cloud backend or sync identity is approved. The Windows host/PostgreSQL must not be assumed to run unchanged on Android. Local-only inference and offline licensing remain current constraints.

**Open design work:** identify platform-neutral domain/command/read contracts; compare Android-local storage/runtime vs connecting to a Windows host, and separately define any future cloud only after approval; account for background mic, battery, entitlement, data export, conflict and deletion propagation; separate calendar-provider sync from Djarvis device sync.

**Dependencies:** CP01–CP03, CP06, CP12, CP15–CP18. **Deliverable:** platform boundary, alternative comparison and future sync decision brief; no implementation selection.

**Future acceptance cases (not run):** no shared live database files; Windows-specific adapter is isolated; logical IDs/revisions can be exchanged; offline ownership, conflicts, deletion and license behavior are explicit before any sync build.

**Owner chooses:** whether/when to enable account/cloud sync and expected device UX. **Agent proposal:** boundary and alternatives without assuming own cloud service.

### CP20 — Acceptance, full-stack performance, fault recovery and support

**Known baseline:** Windows 10/11 and 8 GiB CPU-capable target are desired but unvalidated. No automatic product telemetry is assumed. No application test suite/performance result is claimed. Verification includes the whole local stack, not planner-only correctness.

**Open design work:** define reproducible end-to-end scenarios and fault injection; measure startup, memory, disk, inference/audio latency and responsiveness on representative Win10/11 hardware; cover permission denial, license expiry, offline use, database/worker/provider failures, backup/restore and update rollback; design privacy-preserving diagnostics, support bundle and retention without assuming telemetry consent.

**Dependencies:** CP01–CP19. **Deliverable:** verification matrix, benchmark protocol, recovery/support runbooks and release criteria proposals.

**Future acceptance cases (not run):** planner correctness and voice/TTS together under load; CPU-only 8 GiB constraints measured rather than asserted; interrupted install/update/restore recovers; no silent cloud fallback; diagnostics exclude secrets/content by default; release thresholds are chosen from evidence.

**Owner chooses:** acceptable release tradeoffs, diagnostic consent and any support data collection. **Agent proposal:** measurement, fault-injection and recovery methods; no percentages, deadlines or achieved metrics are invented.

## Cross-component invariants to review together

- Microphone capture at startup, wake detection and active dialogue requires valid trial/license access, required local resources and OS permission. If access expires, all capture and proactive speech stop; only license renewal/import, user-initiated data deletion and automatic backup maintenance remain available. No paid assistant jobs continue in the background.
- The future acceptance plan must show a capability matrix: local planner, reminders, voice and conversation work offline when access/resources permit; search, live weather and provider operations need a network. Locally queued remote intent is not provider confirmation. No network failure may silently trigger cloud inference or an own remote proxy/backend.
- Task splitting is per-task opt-in. Segment check-offs are progress only; the selected occurrence completes only through the separate completion action, even when segments remain unchecked. Effects on remaining future placements/slots stay open for design.
- Calendar scope remains selected events and task time blocks, with habits separately opt-in and off by default. Do not add Google Tasks API, all-calendar export, mail/notes/projects/attachments sync, or implicit task deletion from removing a block.
- Backup key protection and restore policy apply to archives. They do not automatically select protection for the live PostgreSQL data directory, logs, or caches. Full-snapshot restore does not restore/reset license/trial or OAuth secrets; backup maintenance remains available after paid-feature expiry.
- Software/model runtime licenses and character/actor/recording rights are separate. The requested recognizable character voices are not replaced by generic substitutes; no voice ships without its own rights review.

## Review sequence and decision boundaries

Review in dependency groups rather than presenting all 20 components as user questions:

1. **Foundations:** CP01–CP04 (process, commands, schema, PostgreSQL lifecycle).
2. **Domain behavior:** CP05–CP07 (planning, time/habits, local workspaces/files).
3. **Assistant behavior:** CP08–CP11 (local model, speech, voices, reminders).
4. **External capabilities and trust:** CP12–CP16 (providers, Windows adapters, history/recovery, offline license).
5. **User experience and delivery:** CP17–CP20 (screens, installer, Android boundary, full-stack verification).

In parallel with foundations, start CP20 acceptance/budget design and CP08–CP10 model, voice and rights feasibility review. Execute separately scoped, authorized feasibility checks early enough for their results to shape the final architecture. Review the main user journeys in CP17 alongside the command contracts rather than postponing all UX work until delivery.

Dependencies are design inputs and coordination links, not a strict acyclic build order. Mutually dependent contracts, especially CP03/CP04/CP15 and CP05/CP06, are reviewed together. Test design begins with foundations and continues through every group; CP20 is not a final-only testing stage.

Within each group, research and documentation can proceed without asking the owner to choose each internal implementation detail. Present only unresolved user-facing, privacy, commercial or irreversibility tradeoffs that need an owner decision; keep proposed technical alternatives explicit and trace them to the requirements. Previously accepted choices remain the baseline.

**Approval gates:** reading, research, and documentation planning are allowed by this task. Feasibility code, downloads, benchmarks and environment installation must stay within an explicitly approved scope. Reuse existing valid authorization within that scope; obtain approval for work beyond it. This documentation task executes none of those actions. Before application programming, provide the final architecture and implementation plan—including component contracts, data/recovery, failure behavior and verification—for explicit owner review and approval. Nothing in this plan claims a component is implemented or the application is built.

## Baseline references

- [Product requirements](../PRODUCT.md) and [approved decisions](DECISIONS.md) define current behavior and the narrow decisions.
- [Planner core](PLANNER_CORE.md) records the proposed data/command/scheduling contracts and confirmed domain rules.
- [Architecture proposal](PROPOSAL.md) and [remaining design work](REMAINING_PLAN.md) provide current alternatives, constraints, and unresolved areas.
- [Required visual design](../DESIGN.md) is a mandatory UI constraint, not an optional theme direction.
