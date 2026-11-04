# P0 — skeleton plan for discussion

[Русская версия](P0_PLAN.ru.md) · [phases and criteria](IMPLEMENTATION_PLAN.md) · [modules](MODULES.md) · [API](API.md) · [technical choices](TECHNICAL_DESIGN.md) · [readiness](READINESS.md)

Status: **proposal for discussion**, PLAN-038, 2026-11-05. Phases, architecture, schema, API and modules are approved (ADR-018, ADR-022, ADR-024–026). The owner asked not to write code yet. This document does not authorize P0.

## 1. P0 outcome

A verifiable Windows application skeleton: the Flutter UI starts a separate Python core from an embedded runtime; the core creates or opens only its private PostgreSQL cluster, exposes a local API with a fresh token, the UI shows the version and status, and a full exit cleanly stops processes owned by the app. Closing the window leaves the UI in the tray. The development build runs without manually installing Python or PostgreSQL. This is the already approved P0 acceptance criterion from IMPLEMENTATION_PLAN §3; domain functions arrive in later phases.

## 2. Work order and files

| Step | Changes after separate authorization | Verifiable result |
| --- | --- | --- |
| 1. Scaffold and dependencies | Create approved `core/`, `ui/`, `scripts/` roots and needed parts of `packaging/`; pin dependency versions and hashes, ruff/mypy/pytest and Dart analysis settings; set up Windows pull-request CI before main (ADR-027) | Clean Windows build; tools run from pinned dependencies |
| 2. Embedded runtimes | Build scripts download verified embedded Python and PostgreSQL archives into a local build cache and assemble a working app folder without committing binaries or user data | Embedded Python and PostgreSQL binaries run from the working folder without system installations; core startup is checked after step 3 |
| 3. Private database | `core/djarvis_core/db/` and `host/`: one instance per Windows account, private folders/ACLs, identify the app-owned cluster, `initdb` only when absent, start, readiness check and clean stop | Relaunch joins the same core; a foreign database process is not stopped |
| 4. Local contract | `core/djarvis_core/contract/`, `api/`, `host/`: minimal real `GetSystemStatus`/`RequestExit`, local HTTP and WebSocket, versioning, token, `Host`/HTTP `Origin` checks, protected endpoint file; matching Dart type generation | UI receives status/version; bad token and origin are denied; protocol comes from one source |
| 5. Empty UI | `ui/lib/app`, `ui/lib/data`, `ui/lib/generated`: launch/reconnect, status screen with core version, tray icon, reopen and full-exit action | Window hides to tray; core keeps running; full exit stops it and its database |
| 6. Verify and record | `core/tests`, `ui/test`, Windows CI, bilingual README/docs and shared log | Linters, analysis, contract and startup checks pass; owner sees a P0 demonstration |

Step 1 CI choice: checks run in pull requests before main (ADR-027). In P0 the check set includes ruff, strict mypy, pytest for code that exists, dart analyze, contract-generation consistency and available Windows smoke checks; checks are added as the relevant modules appear rather than faked with empty tests. Blocking failed merges requires branch rules, which are configured only after P0 authorization.

Step 2 is accepted by the owner (ADR-028): embedded Python/PostgreSQL are in the build, source archives have pinned checksum verification, AI models download separately on first launch, and program files are separate from user data.

Step 3 is accepted by the owner with a condition (ADR-029): the app manages its private database in the background without a console window or manual action. The UI shows normal loading or a clear recovery error; data remains after exit.

The full layout remains in IMPLEMENTATION_PLAN §2. P0's contract is limited to real system status and lifecycle; the full command catalog and `0001_initial` migration follow in P1. P0 scripts assemble a minimal working folder; the full installer and signing belong to P7.

## 3. Startup and shutdown

1. The UI finds a live core for the current Windows account through a mutex and verifiable endpoint file; if absent, it launches the embedded Python host.
2. Without a console window, the host checks private folders and rights, verifies ownership of an existing cluster, initializes only a new cluster and starts only its own PostgreSQL. It then opens an API on `127.0.0.1` with a random port and fresh token.
3. The UI connects by token, checks the protocol version and shows `GetSystemStatus`. After connection failure, it shows a recoverable state with Retry; a second window does not create another core/cluster.
4. Closing the window hides it in the tray. Full Exit calls `RequestExit`: the core stops the API, closes connections and cleanly stops only its PostgreSQL; the UI exits.

Full domain-command idempotency, revisions, planner, schema migrations, voice and external integrations belong to the approved later phases. P0 creates real boundaries and lifecycle without fake domain-command handlers.

## 4. Failures and data safety

- Core startup waits at most 15 seconds; database readiness at most 10 seconds (TECHNICAL_DESIGN §§1–2). The UI shows an error with Retry and local diagnostics, without endless automatic restart.
- If a port is occupied, the core chooses another free loopback port. A foreign cluster, owner mismatch or corrupt state file yields a recoverable state; the core does not delete or overwrite foreign data.
- P0 checks use a separate temporary private cluster. Any future change to existing user data needs a backup with verifiable restore. Existing local project materials are neither moved nor cleared.
- Tokens/passwords do not enter logs or publication. The endpoint file and database folder are restricted to the owning Windows account; PostgreSQL listens on limited local addresses and uses SCRAM authentication (TECHNICAL_DESIGN §2).

## 5. P0 acceptance

1. On Windows 10/11, the working build starts without system Python/PostgreSQL or administrator rights; the core from the embedded runtime starts and stops its database.
2. The UI connects with the fresh token and shows core version and DB state. Bad token, `Host`, HTTP `Origin` and protocol version have defined handling.
3. A second UI launch creates no second core/cluster; closing the window leaves tray and core, full exit stops them. Reconnect after a UI crash works.
4. Python/Dart checks, contract generation and Windows CI pass. The owner receives a demonstration; P1 follows P0 acceptance under the approved plan.

## 6. Next decision

The owner is now reviewing P0 scope and order. At the owner's explicit request, no code is being written yet. This plan can be refined through discussion; separate permission to start P0 is needed only when the owner decides to move to implementation.
