# Architecture proposal — first review

[Русская версия](PROPOSAL.ru.md) · [Product requirements](../PRODUCT.md) · [Required visual design](../DESIGN.md) · [Decision register](DECISIONS.md) · [Planner core proposal](PLANNER_CORE.md)

Date: 2026-11-03. Status: PROPOSED, not approved, except for the limited UI decision in ADR-001, local PostgreSQL decision in ADR-002, Python core/background direction in ADR-003, app-managed isolated PostgreSQL lifecycle in ADR-004, and offline license import/trial-access rules in ADR-005. This is a reviewable design, not permission to program or a claim that performance targets have been met. No application components, installer, or licensing mechanism have been implemented. Approved constraints and these narrowly scoped choices come from the product discussion; all other technology and implementation choices below remain proposed.

## 1. Design constraints

- Commercial, individual-user task/habit tracker with a voice assistant; English and Russian.
- Windows 10 and 11 first; target 8 GiB RAM without a discrete GPU. Exact builds, CPU instruction sets, x64/ARM64 coverage, performance, and minimum free disk space require validation.
- Current AI inference and application data stay local. Optional search, weather, Google/Microsoft integrations, and asset downloads use the internet; local inference does not make those services offline.
- Local profile without a mandatory in-app account; buyer imports a signed license file verified offline, with no Djarvis activation/entitlement server. A seven-day per-device trial starts on first use of any product function, including the manual planner; setup and model-download waiting do not start it. On expiry, planner/assistant features lock and data remains; renewal/import, user-initiated deletion, and automatic local backups remain available, while all microphone capture and proactive speech stop. Exact license format/signing/issuer, payment provider, price, renewal period, device binding, and clock tolerance remain open.
- Future Android and synchronization are considered at domain boundaries, without implementing a cloud backend now.
- Automatic hardware-adapted model preparation. "Hidden" is interpreted as no console or manual model commands, with an in-app preparation status; the status presentation is a proposal to review.

## 2. Logical structure

Use a modular application core with separate, replaceable local inference workers. This avoids distributing business rules across the interface, prompts, and external service adapters. Do not introduce network microservices for local business modules.

```mermaid
flowchart TD
    UI[Desktop interface and tray] --> Core[Application core]
    Audio[Local voice pipeline] --> Intent[Intent and clarification]
    LLM[Local language-model worker] --> Intent
    Intent --> Policy[Validation and permission policy]
    Policy --> Core
    Core --> DB[Local data and history]
    Core --> Jobs[Reminders and planning]
    Core --> Connect[Optional service adapters]
    Core --> License[Offline license verifier]
    Core --> Context[Scoped assistant context]
    Context --> LLM
    Assets[Model manager and memory budget] --> LLM
    Assets --> Audio
    DB --> Backup[Local backups]
```

The language model proposes typed intents. Only the application core can commit changes or invoke approved service actions. Text obtained from search, messages, and attachments is data, never authority to change permissions.

## 3. Technology candidates

The owner's [visual specification](../DESIGN.md) is the required Djarvis design, not an optional style alternative. Technology choices must implement it: Dark Glassmorphism/Bento, three exact palettes, independent Glass/Solid materials, the circular assistant above the day panel, and all six combinations. Flutter/Dart for UI is approved by ADR-001; CSS/React examples in the local brief do not select any additional production stack.

| Area | Status / candidate | Alternative / unresolved choice |
| --- | --- | --- |
| UI framework and necessary UI implementation | Flutter/Dart (selected by ADR-001) | .NET MAUI/C# was considered and not selected |
| Local language inference | Bundled llama.cpp-based worker using pinned GGUF artifacts | Exact runtime build, process protocol, and supported CPU/GPU backends |
| Voice processing | Local provider interfaces; evaluate sherpa-onnx components | Final wake, ASR, TTS, and voice assets need separate tests and licenses |
| Backend database | PostgreSQL local to the user's device (ADR-002) | Driver, version, schema, migrations, private-instance distribution/packaging, and connection/pooling model |
| Windows integration | A platform adapter for microphone, tray, startup, notifications, credentials, and device actions | Concrete plugins/native bindings selected after review |

The owner selected Flutter for the UI and necessary Dart UI implementation only (ADR-001), in the context of the required circular design, Windows-first target, and later Android support. This is not a measured RAM or speed advantage over .NET MAUI, which was considered in the initial proposal but is not an active UI alternative. Flutter currently lists Windows 10/11 and Android among supported deployment targets. Exact Flutter/Dart SDK versions and dependencies remain unselected. [Flutter support](https://docs.flutter.dev/reference/supported-platforms), [historical MAUI comparison](https://learn.microsoft.com/dotnet/maui/supported-platforms).

llama.cpp provides local CPU/GPU inference and uses GGUF; its runtime code has an MIT license. sherpa-onnx supplies offline speech-related components across desktop/mobile platforms. Runtime licenses do not grant rights to every model, voice, or character. [llama.cpp](https://github.com/ggml-org/llama.cpp), [runtime license](https://github.com/ggml-org/llama.cpp/blob/master/LICENSE), [speech project](https://github.com/k2-fsa/sherpa-onnx).

Windows application compatibility and the operating system's support lifecycle are separate. Standard Windows 10 Home/Pro support ended on 2025-10-14; LTSC releases follow their own lifecycles. The product's Windows 10 compatibility target remains, but exact builds/editions must be recorded and tested without promising OS maintenance. [Microsoft lifecycle](https://learn.microsoft.com/en-us/lifecycle/products/windows-10-home-and-pro).

## 4. Processes and lifecycle

Propose one per-user background application host, an on-demand interface, and worker processes for heavyweight inference. The host owns the database, scheduler, permission decisions, and worker lifecycle. Python is approved for planner-core/background logic in ADR-003; Flutter/Dart remains the UI. ADR-004 approves application-managed start/stop of an isolated local PostgreSQL instance. The Python version, driver, local transport/framework, runtime packaging, database distribution/binaries, and installer dependencies remain open.

The Python runtime must be packaged and managed by the application so the intended user flow needs no terminal, global Python setup, or manual package installation. The packaging mechanism and process/IPC framework remain unselected. Do not infer a Python version, driver, freezing/embedded runtime method, or installer dependencies from this requirement.

- Closing the main window leaves the host and tray active. Configurable Windows startup starts the host in the user's session.
- "Fully exit" stops the host and its workers, cancels audio work, and releases microphone capture. A supervisor must not restart an intentionally exited session.
- A crashed or out-of-memory inference worker is restarted independently; it cannot own or corrupt planner transactions.
- Prefer parent-owned process handles or access-controlled local IPC with versioned messages. Do not expose an unauthenticated local control HTTP service. Any temporary OAuth callback listener is separate and narrowly scoped.
- Microphone mute stops capture for wake detection and conversation immediately. Its visible state must be consistent in the main window and tray.
- Background actions check license and permission policy, not just whether a UI button is enabled.

## 5. Models and the 8 GiB target

The existing Qwen3.5 4B installation is a development candidate tested on a 32 GiB/GPU machine; it is not the baseline customer configuration. See [local evaluation](../LOCAL_MODEL.md).

Define a signed asset catalog with immutable versions, hashes, sizes, licenses, runtime compatibility, required CPU/backend features, language support, and measured resource profiles. Select using available RAM, CPU architecture/instruction support, optional GPU/backend availability, and free disk space, all assessed locally. Model selection must not reuse a licensing fingerprint as telemetry.

| Proposed profile | Selection goal | Required evidence before offering it |
| --- | --- | --- |
| Baseline CPU / 8 GiB target | Small quantized text model, bounded context, lightweight resident wake detection, sequential heavy workloads | Real CPU-only 8 GiB tests of end-to-end quality, responsiveness, and peak memory |
| Balanced | Larger model only if remaining memory supports the complete voice pipeline | Combined LLM/ASR/TTS measurements, including other applications |
| GPU / higher resources | Optional acceleration and higher quality | Backend/driver compatibility and recovery checks |

Qwen3.5 0.8B/2B are candidates for evaluation, not approved defaults or guaranteed replacements. Their official model cards identify Apache-2.0 licensing. [0.8B card](https://huggingface.co/Qwen/Qwen3.5-0.8B), [2B card](https://huggingface.co/Qwen/Qwen3.5-2B).

Use a memory coordinator: cap context and output, permit one heavy generation at a time on baseline devices, unload idle models, bound queues, cancel obsolete requests, and back off under memory pressure. Keep a low-cost wake path separate from a full language-model invocation. If no candidate meets quality and resource requirements, report this rather than silently using cloud inference or declaring 8 GiB support complete.

## 6. First launch and asset installation

Proposed flow: launch interface → local capability check → choose compatible asset set → display preparation status → resume downloads → verify hashes/signatures/licenses → validate runtime loading → mark assistant ready.

The installer contains the application and required runtime components, not every model. Downloads use pinned HTTPS sources and resumable temporary files, check disk requirements before transfer, verify size/hash before activation, and preserve a known working asset set on failure. No console, manual model manager, global Python setup, or automatic driver replacement is required by the proposed user flow. Runtime packaging must still be validated.

Model preparation runs automatically; its progress and recoverable errors belong in the application. Proposed behavior is to keep manual planner access available while assets prepare, subject to the trial/license rules. Cancellation and retry must not reset trial eligibility. The first-use trial trigger is confirmed: if the proposed manual planner is used during model preparation, that use starts the trial. The availability and presentation of manual planner access during preparation remain proposals.

## 7. Application modules

| Module | Responsibility |
| --- | --- |
| Tasks and projects | Task fields, task occurrences, projects, optional advanced fields, completion and debt |
| Habits | Four measurement types, fixed/flexible schedules, logs, statistics, missed occurrences without debt |
| Calendar and planner | Events, availability, priorities, deadlines, durations, breaks, proposals, and conflicts |
| Assistant orchestration | Session state, permitted context, typed tool proposals, cancellation, clarification |
| Permission policy | Scoped task preferences; mandatory mail/file confirmations; proposal-only habit goal/load changes |
| Voice and notifications | Wake, ASR, dialogue timeout/stop, TTS interruption, mute, quiet hours, calls/games |
| Connections | OAuth, provider mapping, bidirectional sync, retries, outbox, and explicit conflicts |
| Data and recovery | Transactions, migrations, history retention/deletion, local snapshots and restore |
| Entitlements and assets | Offline license checks, trial state, asset verification and resource profiles |

Dates, facts, counts, task states, and habit statistics come from deterministic domain logic, not invented model text. Automatic day planning uses explicit constraints; AI can explain a proposal, but cannot override conflicts or silently move overdue tasks.

## 8. Command execution contract

Detailed proposed entities, commands, planning rules, and transaction/provider result boundaries are specified in the [planner core design](PLANNER_CORE.md). That detailed design is not yet approved; Flutter UI approval alone does not select it.

Proposed lifecycle: recognized text or UI command → typed intent → resolve target and dates → clarify ambiguity → validate current revisions and policy → request confirmation if required → atomic commit / queued provider action → result and audit entry.

An action includes a unique ID, target IDs/revisions, proposed changes, permission scope, and confirmation state. Retry must not duplicate a task or send a message twice. Confirmations are bound to the exact proposed operation; a changed operation needs a new review. Ambiguity is resolved even when task confirmation is disabled.

Sending email, deleting files, and overwriting files always require confirmation. Habit goal/load changes always remain proposals until accepted. The model never receives a general shell, permission-editing tool, or unrestricted database access. Device actions use explicitly configured capabilities; their remaining confirmation rules require review.

## 9. Proposed data model

Core entities: Profile, Task, TaskOccurrence, Project, Note, CalendarEvent, Habit, HabitSchedule, HabitLog, Conversation, Message, Settings, CapabilityGrant, PendingAction, AuditEntry, ExternalMapping, SyncCursor, OutboxEntry, SyncConflict, InstalledAsset, LicenseState.

Task occurrences preserve debt; habit logs preserve misses without creating debt. Deadlines and planned execution time are separate. Recurrence retains its original calendar/interval anchor despite late completion. A date-only task uses a default 06:00–22:00 placement window with its own duration, without an implicit deadline. Preserve timezone, all-day-date, DST, and original occurrence identity in the detailed temporal specification.

PostgreSQL is selected as the local backend database; its driver, version, schema, migrations, private-instance distribution/packaging, and connection model remain open. Use transactions for related changes and appropriate revision checks. PostgreSQL documents MVCC and transaction isolation; implementation details remain proposed. Automatic local backups may use `pg_dump` for a consistent single-database snapshot, with coordination for attachments and restore still to be designed. Do not treat a raw database-file copy as a backup. [Transactions](https://www.postgresql.org/docs/current/tutorial-transactions.html), [MVCC](https://www.postgresql.org/docs/current/mvcc.html), [transaction isolation](https://www.postgresql.org/docs/current/transaction-iso.html), [pg_dump](https://www.postgresql.org/docs/current/app-pgdump.html), [backup file formats](https://www.postgresql.org/docs/current/backup-file.html).

Proposed production layout is under the current user's application-data directory, with distinct data, attachments, model cache, backups, and logs. Repository `data/` and `cache/` are development locations, not a requirement to put customer data beside an installed executable. The app manages an isolated local PostgreSQL instance; exact binary distribution, data-directory layout and permissions remain open.

## 10. Conversation, voice, and proactive behavior

Proposed audio states: muted → waiting for wake phrase → listening → recognizing → resolving/clarifying → executing an accepted action → speaking → listening until timeout/stop. After an assistant answer, the default wait for the user's next reply is 30 seconds and is configurable; it does not limit active user speech, inference, or TTS. «Хватит»/“Stop” ends the dialogue and returns to wake listening unless muted, access is invalid, or required local resources are unavailable. Manual mute lasts for the current application session. On genuine application/Windows restart, resume wake listening if Windows permits it and access/resources are valid; OS/hardware mute is respected and never overridden. Reopening the main window while the host is still running is not an application restart. Full Exit stops workers and capture until the next authorized launch. Show current microphone state in the main window and tray; exact labels and implementation remain proposed. A new utterance can cancel speech output. Echo handling must prevent the assistant from repeatedly recognizing its own voice.

Implement configurable wake names locally. Support custom phrases only through a validated local detection strategy; arbitrary phrases and Russian/English recognition need accuracy and false-trigger evaluation. Do not promise a particular detector can handle every phrase without tests.

Offer initiative settings during first launch. Until the user chooses, proactive speech remains off; skipping the offer is not consent. Ask the user to set quiet hours in local time or explicitly choose none; no schedule default is implied. Quiet hours, calls/games, and manual quiet suppress proactive voice and use ordinary OS notifications when permitted, without muting the microphone or changing user-requested conversation. The accepted call/game approach combines system heuristics, a user-selected application list, and manual quiet; it cannot guarantee every call/game is detected. If return-after-absence is enabled, default to 30 minutes without keyboard/mouse input in the interactive session, configurable; this is not proof of physical absence or global OS input monitoring and does not enable the trigger automatically. Exact schedule/trigger timing, detection details, and cooldowns remain open. Default conversation-history retention is 30 days; history remains user-configurable, optional, and deletable.

The circular visualization reflects defined states such as listening, thinking, speaking, muted, and preparing. Persona affects presentation and voice style, never permissions, factual state, or business rules. Exact character/voice asset rights and language versions are still unverified.

The rest of the interface follows the mandatory [Djarvis visual design](../DESIGN.md): navigation, header, Bento task/habit/calendar surfaces, menus, dialogs, lists, and statistics share semantic tokens. Exact palette values and independent transparency are requirements; spacing, blur, animation timing, and derived surface colors are adaptable guidance. No background image or unrelated CRM business entities are introduced.

Store appearance preferences locally and apply changes immediately. Solid uses opaque surface fills without backdrop blur, including nested panels. Reduced-motion settings, keyboard focus, non-color status indicators, contrast targets, and the specified opaque fallback belong to the design contract. Measure effects and circular animation together with the voice/AI workload on the 8 GiB target; do not silently replace the chosen material just because a computer is in the baseline profile. Source mockup video/images were not present locally, so visual fidelity has not been verified.

## 11. Google and Microsoft connections

Use native/public-client OAuth through the system browser and provider-approved redirect/PKCE mechanisms; do not treat an embedded client secret as confidential. Store tokens in the Windows credential/protection adapter, separate from planner data and backup archives. DPAPI is a Windows candidate with user/machine binding implications; restoring on another device may require reconnecting accounts. [Google native OAuth](https://developers.google.com/identity/protocols/oauth2/native-app), [Microsoft desktop registration](https://learn.microsoft.com/entra/identity-platform/scenario-desktop-app-registration), [Windows protection API](https://learn.microsoft.com/en-us/windows/win32/api/dpapi/nf-dpapi-cryptprotectdata).

Sync uses local external-ID mapping, a durable outbox, provider change cursors, retry/backoff, and revision history. Google Calendar offers sync tokens and resource version checks; Microsoft Graph provides calendar delta tracking. Handle invalid cursors with a controlled resync. Where a conditional write is supported, use it; never use cursor arrival order as conflict resolution. [Google sync](https://developers.google.com/workspace/calendar/api/guides/sync), [Google versions](https://developers.google.com/workspace/calendar/api/guides/version-resources), [Graph delta](https://learn.microsoft.com/graph/api/event-delta?view=graph-rest-1.0).

If the same event changes on both sides, preserve both versions and ask the user. Losing connectivity must not silently discard local edits. Approved F1 scope: bidirectionally sync user-selected calendar events and task time blocks; habits sync only with a separate opt-in, off by default. Exclude Google Tasks API, notes/projects/attachments/mail synchronization, and export of every calendar. If a provider deletes an event unchanged locally since the last sync, ask before removing it locally; if both sides changed it, retain the existing user-choice conflict rule. Removing an exported block does not implicitly delete its task or habit. Exact projections and edit mappings remain to be specified. Provider app registration, requested scopes, consent verification, recurring-event mapping, and the selected synchronization window also need a separate specification. Search results and remote message content remain untrusted inputs to the assistant.

Gmail is also an initial adapter, separate from calendar synchronization. Specify reading/searching, draft preparation, and sending as individually permissioned operations before implementation. Every send still requires confirmation tied to the recipient, content, and attachments. Choose the narrowest scopes needed for the agreed operations and establish local message-cache retention; do not assume a full mailbox copy is required. [Gmail authorization scopes](https://developers.google.com/workspace/gmail/api/auth/scopes).

## 12. History, backups, and recovery

History is local with a 30-day default retention, which users can change, disable, or delete-all. Keep conversation history separate from approved profile preferences. Do not create new long-term memories merely because a conversation exists.

Create automatic local backups daily and before data-structure or migration updates. Keep seven days by default, with configurable schedule and retention. Use a separate configurable local application backup folder outside the working PostgreSQL database; exact path remains open. Include conversation history in automatic backups. Under ADR-006, protect the backup key using Windows protection without a separate password or additional recovery key. Restore a full snapshot only after preview and a backup of current data; selective restore is not selected. Restore only data within archive scope, not license/trial state, OAuth credentials or a Windows image. Exact cipher/KDF, protection API/flags, key scope/storage/rotation, archive format/migrations and recovery-failure mechanics remain open; do not claim portability or recovery without access to the protected key, or that backups can only work on the same PC. Use versioned snapshots including database and referenced attachment metadata; exclude model weights and credentials from ordinary backups. Expiry of 30-day-old history does not rewrite archives; aged history remains until its archive expires under its own retention (default seven days). Restore applies the current target history-retention setting rather than silently overriding it with archived policy. Explicit history deletion shows affected backups for user-confirmed recreation or deletion; do not silently purge all user files. Distinguish manual deletion from age expiry and do not claim 30-day physical erasure across all copies. Do not claim complete history erasure before archive handling completes or silently restore deleted history. Archive availability/format, rollback and pending/unavailable-backup mechanics remain open. Do not promise secure physical erasure or control of external copies.

Before migrations, make a verified recoverable snapshot as part of the required pre-structure/migration backup. Expiry preserves data; renewal/import restores feature access. Renewal/import, user-initiated deletion, and automatic local backups remain available while planner/assistant functions are locked; microphone capture and proactive speech stop. Backup destination, restore authorization, and exact expiry-screen layout remain design details.

## 13. Offline trial and subscription

The approved product flow is that the buyer imports a signed license file and the app verifies it offline (ADR-005). The issuance process, license-file format, signing algorithm/library, issuer, verification-key distribution, hardware-change tolerance, purchase flow, and renewal period remain proposals or open decisions. Any signing private key would remain outside the client; no particular cryptographic implementation or issuer has been selected.

Keep local trial eligibility distinct from user data, optional accounts, model selection, and imported backups. A new account or data restore should not intentionally reset eligibility. Device binding identifies a device, not a person. With no server, clock rollback, reinstallations, administrator control, and hardware changes limit enforcement; do not claim unbypassable seven-day protection. Strict anti-abuse guarantees would require reconsidering constraints, not hiding a server in the design.

No mandatory in-app account or Djarvis activation/entitlement server is part of the current offline license flow. The buyer imports a signed license file for local verification. Future cloud identity/account needs are separate and remain unplanned. The exact license format, signing algorithm and issuer, payment provider, price, renewal period, device policy, and clock tolerance remain open; do not imply automated recurring payments or an approved issuance workflow. Renewal/import remains accessible while planner/assistant features are locked, alongside user-initiated data deletion and automatic local backups; exact screen layout remains to be designed.

## 14. Android and future synchronization

Keep domain rules, stable entity IDs, revisions, and data-format versions independent of Windows APIs and model providers. Future Android substitutes platform adapters and lifecycle management; do not assume Windows background microphone/tray behavior transfers unchanged to a phone.

Do not synchronize active database files directly between devices. Later synchronization needs an approved transport, identity model, conflict protocol, deletion rules, and encryption policy. These are future design work, not a current cloud-storage implementation.

## 15. Source organization proposal

Map the current scaffold to explicit modules before creating files: `src/core` for domain/application rules; `src/agents` for orchestration/personas; `src/tools` for typed actions and policy; `src/integrations` for provider/platform adapters; `src/memory` for context/history interfaces; `src/interfaces` for UI and voice entry points. A selected framework may require a revised package layout; discuss it before moving existing files.

Keep native workers, application assets, model manifests, schema migrations, and packaging configuration separate from user runtime data. No production dependencies are added by this document.

## 16. Verification and approval sequence

1. Map the required visual design to Djarvis screens and review component boundaries. Flutter/Dart UI, Python core/background language, local PostgreSQL, and app-managed isolated database lifecycle are selected in ADR-001–004; ADR-005 confirms only offline license import and trial/access behavior; decide remaining host boundaries and exact runtime/database packaging only after owner agreement.
2. Specify entities, commands, permission state transitions, dates/recurrence, sync conflicts, and recovery. Resolve product defaults alongside these contracts.
3. Approve isolated feasibility checks for CPU-only 8 GiB performance, voice interruption/custom wake phrases, Windows integration, and offline licensing behavior.
4. Select exact engine/model/voice versions and redistribution terms from evidence. Define measured startup, latency, memory, and accuracy acceptance targets.
5. Review the final architecture, package structure, and implementation plan; obtain owner approval before programming.

Verification must cover duplicate intents, stale confirmations, ambiguous commands, denied capabilities, trial expiry, offline clock changes, interrupted downloads, corrupt assets, low memory, inference crashes, microphone release on exit/mute, mute lasting within a session but resetting after genuine app/Windows restart, main-window reopen without host restart, no capture under expired entitlement or OS denial, stop-command return to wake listening, the 30-second post-answer wait without limiting active speech/inference/TTS, initiative remaining off when setup is skipped, restart-safe reminders, backup restoration, history deletion, recurring debt versus habit misses, and two-sided calendar conflicts. These are future cases only; no such application tests have been run.

The required visual direction is supplied by the owner; it is not being replaced by this architecture proposal. Flutter is approved for the UI, Python for core/background logic, and the app-managed isolated local PostgreSQL lifecycle is approved within the limited ADR scopes. Initial review should align Djarvis screen composition with that design, then settle the modular core/worker split and remaining packaging/runtime details. Model quality on baseline hardware, requested production voices, offline-license assurance, license issuance/payment details, future cloud identity needs, exact Windows architecture coverage, and remaining behavioral defaults stay visible as unresolved items rather than assumed approvals.
