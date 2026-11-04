# Process architecture and repository layout — review package

[Русская версия](ARCHITECTURE_REVIEW.ru.md) · [full plan](IMPLEMENTATION_PLAN.md) · [technical details](TECHNICAL_DESIGN.md) · [decisions](DECISIONS.md) · [readiness report](READINESS.md)

Status: owner review proposal, PLAN-033, 2026-11-05. Phases P0–P7 and their criteria are already approved (ADR-018); T1–T6 are already approved (ADR-015). The current decision concerns only architecture §1 and repository layout §2 of the full plan. Database schema, API, modules and P0 authorization are separate decisions.

## 1. Processes and ownership

| Process | Owns | Starts and stops |
| --- | --- | --- |
| Flutter interface (Djarvis.exe) | Window, input, tray icon, status display; no direct database or secret access | At sign-in or manually; closing the window hides it in the tray, Full Exit initiates shutdown of the entire application |
| Python core (djarvis-core.exe) | Commands, permissions, planner, reminders, audio, connections; one instance per Windows account | The interface finds a running instance or starts it; the core manages child processes and stops them on Full Exit |
| Private PostgreSQL 18 | Local data for one Windows account | Started and stopped by the core; readiness failures produce a recoverable state, not a second database |
| Local language model and speech workers | Computation only; database writes go through the core | The core starts the model on demand and releases it when idle; speech workers belong to the audio session |

If the window process crashes, the core remains separate; the interface reconnects at next launch. If the core is unavailable, the interface checks the connection file and process, attempts one core launch and waits up to 15 seconds for readiness (TECHNICAL_DESIGN §1.1); it then shows an error with a Retry action. There is no endless automatic restart loop. On a new start, the core checks an existing PostgreSQL cluster and attaches only to a verified app-owned instance; ambiguous ownership or corruption yields RecoveryRequired rather than creating a second database. A single process/database owner prevents competing launches. These recovery details are proposed for approval with the architecture.

## 2. Transport and data flow

The interface sends commands and queries to the core over HTTP on 127.0.0.1; WebSocket gives a hint to reread changed data. A protected per-user connection file contains a random port, one-time token and instance ID. The core checks the token, Host, Origin and protocol version. Pydantic models define the contract and generate Dart types. Screen and assistant commands pass the same permission, revision, confirmation and idempotency checks. The model never writes to PostgreSQL directly. External providers and network failures do not block the local planner.

## 3. Proposed code layout

The full directory list is in [IMPLEMENTATION_PLAN §2](IMPLEMENTATION_PLAN.md#2-repository-structure). Main boundaries:

- core/djarvis_core: api, contract, app, domain, storage, db, assistant, audio, reminders, integrations, safety, host;
- ui: Flutter app, design system, screens, contract client and tray icon;
- packaging: installer, Python/PostgreSQL packaging and model manifest;
- scripts: contract generation and builds; docs and Plan: documentation and shared work log.

The current src/ is an organizational scaffold without application code; data/, cache/, logs/ and tmp/ are local working folders and may contain preparation artifacts. After approval, P0 creates core/ + ui/. Installed user data belongs in a private Windows-account location, not the repository. The old empty folders do not define future code architecture; this decision does not move or delete local data.

## 4. Rationale and approval boundary

Flutter remains the sole UI and tray owner. The Python core provides one rule boundary shared by window, voice and background jobs. PostgreSQL is hidden behind the core; schema and migrations are reviewed separately. Loopback HTTP/WebSocket and generated types preserve one contract for the UI and a future client, but Android and synchronization are outside this decision.

The proposed architecture is checked in P0 by starting embedded Python and private PostgreSQL, connecting the UI with a token, reopening the window, second launch and Full Exit. P1 checks idempotency, revisions, events and crash recovery. Real 8 GiB acceptance is in P7. These criteria are already approved; this summary does not expand the phases.

**Decision now:** accept or revise only the process architecture and repository layout in §§1–2 of the full plan. Then follow the previously chosen order: schema → API → modules, followed by a separate P0 decision.
