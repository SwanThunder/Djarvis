# Technical details — proposal for approval

[Русская версия](TECHNICAL_DESIGN.ru.md) · [Decisions](DECISIONS.md) · [Foundation CP01–CP07](FOUNDATION_DESIGN.md) · [Data protection and delivery](DELIVERY_DESIGN.md) · [Feasibility](FEASIBILITY.md) · [Implementation plan](IMPLEMENTATION_PLAN.md)

Status: proposal by agent-02 (PLAN-022), 2026-11-04. Decisions T1–T6 approved by the owner in PLAN-023 (ADR-015); T1 was chosen as "interface stays in the tray" and the text below is updated. The rest of the document is under owner review. This document closes the open technical questions left in CP01–CP04, CP15 and CP18: it selects concrete tools, formats and numbers. The accepted decisions ADR-001…014 do not change. No code is written until approval.

## 1. Interface-to-core connection

### 1.1 Processes and who starts whom

| Process | What it is | Owns |
| --- | --- | --- |
| `Djarvis.exe` | Flutter interface | App windows, input, display, notification-area icon. No access to the database or secrets |
| `djarvis-core.exe` | Embedded Python 3.12 (renamed launcher of the official embeddable package, `-I` mode) | All commands, policy, scheduler, database, reminders and audio; the interface owns the notification-area icon |
| `postgres.exe` | Private PostgreSQL 18 | Data only; started and stopped by the core |
| `djarvis-llm.exe` | llama.cpp server (MIT) | Language model; started by the core on demand and unloaded when idle |
| speech workers | Core threads or subprocesses (Vosk, Kokoro, Vosk TTS) | Computation only; they do not write to the database |

Startup order. `Djarvis.exe` checks the core's named mutex for the current user. If the core is not running, the interface starts it and waits for the connection file for no more than 15 seconds, showing a startup screen. Closing the window only hides it: the interface process stays in the notification area (owner decision T1, ADR-015), and the core, wake-phrase listening and reminders keep running. The interface owns the icon (a permissively licensed Flutter tray plugin); clicking the icon shows the window again. The core is a separate process and does not depend on the interface: if the interface crashes, the core keeps working and the icon returns the next time `Djarvis.exe` starts (autostart at Windows sign-in). The "Exit" item stops everything in the order defined in CP01.

### 1.2 Transport

- HTTP/1.1 for commands and queries, WebSocket for events. The core listens only on `127.0.0.1`, on a random free port.
- Python: `aiohttp` (Apache-2.0) — one library for the HTTP and WebSocket server and for the client to the model and external services. Flutter: `http` and `web_socket_channel` (BSD).
- Connection file `%LOCALAPPDATA%\Djarvis\run\endpoint.json`: port, one-time launch token (32 random bytes), PID and the core instance identifier. File permissions are owner-only (explicit ACL, as for the database folder). The file is rewritten on every core start and deleted on exit.
- Checks on every request: `Authorization: Bearer <token>` header; `Host` strictly equal to `127.0.0.1:<port>` (DNS-rebinding protection); a request with an `Origin` header is rejected so that browser pages cannot reach the core. The WebSocket sends the token as its first message, not in the URL. The token never appears in logs.
- Versions: path `/v1/...` and a `protocol_version` field in the envelope. The core supports the current and the previous protocol version. An interface of an incompatible version receives a clear "update the application" error.

### 1.3 Message format and contract

- JSON in UTF-8; the envelope and result states are from CP01 §2.3 (`AppliedLocal`, `NeedsConfirmation`, `Conflict`, etc.).
- Time is always passed explicitly: an instant is RFC 3339 with `Z`; a local intent is a date, a time and an IANA zone name as separate fields.
- The source of truth for the contract is Pydantic v2 models (MIT) in the core. The build exports JSON Schema from them; the project script generates the Dart classes. The CI check fails if the generated code is out of date. Hand-duplicating types in Dart is forbidden.
- WebSocket events: `{"type": "changed", "revision": N, "resources": [...]}`. This is only a hint to re-read the data. On a disconnect or a skipped revision the interface requests a fresh snapshot (CP01 §2.4).
- Errors: a code from a closed list, user-facing text in the interface language, and a `request_id` for local diagnostics. Stack traces are not passed to the interface.

### 1.4 Why not a named pipe

A Windows named pipe does not open a port, but a Flutter client for it would require own native code, and a future Android version needs a different transport anyway. The risks of a loopback port are closed by the token, the `Host` and `Origin` checks and the ACL of the connection file. Neither option offers protection against a malicious program running under the same Windows account (CP01).

## 2. Database: schema and migrations

### 2.1 PostgreSQL instance

- Delivery: PostgreSQL 18.x zip binaries for Windows, only `bin`, `lib`, `share` (≈ 141 MB of 328 MB, PLAN-021).
- Cluster: `%LOCALAPPDATA%\Djarvis\db\pg18`, explicit owner-only ACL. `initdb --encoding=UTF8 --locale-provider=builtin --builtin-locale=C.UTF-8 --auth=scram-sha-256`. The built-in locale provider does not depend on ICU or Windows versions, so a system update does not break indexes. Alphabetical sorting for a screen is set by an explicit ICU collation in the specific query.
- Network: `listen_addresses = '127.0.0.1'`, random port; `pg_hba.conf` contains only `host … 127.0.0.1/32 scram-sha-256`, no `trust`.
- Roles: `djarvis_owner` owns the schema and runs migrations; `djarvis_app` receives only DML on the tables of the `app` schema. Passwords are 32 random bytes each, under per-user DPAPI; they never appear in files or logs.
- Settings for 8 GiB: `shared_buffers = 64MB`, `work_mem = 4MB`, `max_connections = 10`, `jit = off`, `autovacuum = on`.
- Start: `pg_ctl start` from the core without a visible console window, with output to a log file rather than a pipe (finding 6 of PLAN-021; ADR-029). The user sees normal loading, not database commands. Readiness is checked by connecting with retries for up to 10 seconds.

### 2.2 Driver

`asyncpg` (Apache-2.0): an asynchronous driver compatible with `aiohttp`. A pool of 2–4 connections. No ORM: SQL lives in repository modules by area and is verified by tests against a real PostgreSQL. psycopg 3 was not chosen because of its LGPL-3.0 license and an extra compatibility layer.

### 2.3 Schema (version 1)

The list below is an early conceptual illustration, not the current field and table inventory. Use [SCHEMA](SCHEMA.md) for implementation: it is the approved 46-table logical schema (ADR-024).

General rules:

- Keys are UUIDv7 (`uuidv7()` exists in PostgreSQL 18): time-ordered, suitable for future synchronization.
- Every mutable record has `profile_id`, `revision bigint` (grows on every change), `created_at` and `updated_at` (`timestamptz`).
- Instants are stored as `timestamptz`; user intents are stored as `local_date`, `local_time` and `tz text` (IANA) in separate fields (CP06).
- Enumerations are `text` with `CHECK` (easier to migrate than `ENUM`).
- Deleting user data is physical with a cascade, except where history is required by an ADR (completed occurrences, habit log).

Tables by group:

| Group | Tables |
| --- | --- |
| Profile and settings | `profile`, `setting` (key, JSON value, revision), `availability_rule` |
| Tasks | `task` (`parent_id` for multi-level subtasks, mandatory priority, `deadline_*`), `task_occurrence`, `schedule_placement`, `split_mark`, `recurrence_rule`, `recurrence_exception` |
| Habits | `habit`, `habit_schedule` (effective from a date), `habit_pause`, `habit_measurement`, `timer_session` (survives sleep and shutdown, splits at midnight — ADR-009) |
| Calendar | `calendar_event`, `provider_account`, `provider_mapping`, `sync_cursor`, `sync_conflict` |
| Day plan | `planning_guard` (one row per profile, planning revision), `day_plan_proposal`, `day_plan_item` |
| Projects and notes | `project`, `note`, `tag`, `note_tag`, `task_tag`, `attachment` (sha256, size, storage path; the file is immutable) |
| Actions and policy | `processed_action`, `approval_request`, `capability_grant`, `outbox`, `audit_event` (metadata without content) |
| Assistant | `reminder`, `reminder_delivery`, `conversation_message` (30-day retention by default), `deletion_watermark` |
| Service | `schema_migration`, `backup_record` |

Example of key tables (an illustration of the level of detail; the final DDL is written in phase 1 together with tests):

```sql
CREATE TABLE app.task (
  id            uuid PRIMARY KEY DEFAULT uuidv7(),
  profile_id    uuid NOT NULL REFERENCES app.profile(id) ON DELETE CASCADE,
  parent_id     uuid REFERENCES app.task(id) ON DELETE CASCADE,
  project_id    uuid REFERENCES app.project(id) ON DELETE SET NULL,
  title         text NOT NULL CHECK (length(btrim(title)) > 0),
  priority      text NOT NULL CHECK (priority IN ('low','normal','high','critical')),
  deadline_date date,
  deadline_time time,
  deadline_tz   text,
  estimate_min  integer CHECK (estimate_min > 0),
  state         text NOT NULL DEFAULT 'open' CHECK (state IN ('open','done','cancelled')),
  completed_at  timestamptz,
  revision      bigint NOT NULL DEFAULT 1,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),
  CHECK ((state = 'done') = (completed_at IS NOT NULL)),
  CHECK (deadline_time IS NULL OR deadline_date IS NOT NULL)
);
CREATE INDEX task_open_deadline ON app.task (profile_id, deadline_date) WHERE state = 'open';

CREATE TABLE app.processed_action (
  profile_id   uuid NOT NULL,
  action_id    text NOT NULL,
  request_hash bytea NOT NULL,
  result       jsonb NOT NULL,
  created_at   timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (profile_id, action_id)
);
```

The core checks the subtask nesting depth and the absence of cycles inside the command transaction; PostgreSQL cannot express a cross-row `CHECK`.

### 2.4 Migrations

- A small own runner instead of Alembic: Alembic pulls in SQLAlchemy for a single function.
- Files `core/migrations/NNNN_description.sql`; for data transformation, a paired `NNNN_description.py` with an `apply(conn)` function.
- Table `schema_migration(id, checksum sha256, applied_at, app_version)`. Before starting, the core compares the checksums of already applied migrations; a mismatch means `RecoveryRequired`, with no attempt to "repair".
- Order: disk space check → backup before the migration (ADR-006; a failed backup cancels the migration) → maintenance mode (new commands receive `Unavailable`) → each migration in its own transaction under `djarvis_owner` → invariant check → publication of the new schema version.
- Forward only. Rollback means restoring the backup made before the migration, together with the previous program version (CP18).
- An old program does not open a schema newer than itself: it compares the maximum migration `id` it knows.
- A major PostgreSQL upgrade (18 → 19) is a separate procedure through `pg_dump` and restore into a new cluster, not a schema migration.

## 3. Backup encryption

Accepted in ADR-006: the key is protected by Windows, with no password and no recovery key; daily and before migrations; 7-day retention. Below is the concrete format based on the DD02 and DD03 proposals.

### 3.1 Contents

The DJB1 container (T3, ADR-015) is retained; only the proposed logical payload changes. Before encryption, the archive is a tar:

- `manifest.json`: format, schema, application and export-set versions, snapshot time, row counts and attachment checksums;
- `db.data`: an allowlisted set of user rows from `app`, exported from one transactionally consistent snapshot; tables are listed in [SCHEMA §13](SCHEMA.md#13-archive-contents-and-restore-adr-023);
- `blobs/<sha256>`: attachments referenced by selected rows.

The former full `pg_dump --schema=app` **does not satisfy ADR-023**: it would capture grants, external connections, unconfirmed requests and the email queue. Export v1 uses a closed table allowlist; the staging database schema is created from the appropriate migrations before selected rows are imported. The dump omits license/trial, OAuth tokens, IPC secrets, model weights, caches, grants, external connections and queues. The exact streaming-export mechanism is chosen during implementation and checked against real PostgreSQL; the former command is not used.

### 3.2 Encrypted container "DJB1"

| Part | Contents |
| --- | --- |
| Header (plaintext) | magic `DJB1`, format version, `archive_id` (16 random bytes), chunk size, key-wrapping method identifier (`dpapi-user-v1`) |
| Wrapped key | 256-bit archive key under `CryptProtectData` (user scope, no UI prompts, with a constant additional product entropy) |
| Chunks | 1 MiB of plaintext each; AES-256-GCM (`cryptography`, Apache-2.0/BSD); nonce = 64-bit chunk counter + 32 flag bits, with the `last` flag only on the final chunk (STREAM construction); AAD = SHA-256 of the header |
| Trailer | the last chunk contains the length and the number of chunks; truncation, reordering and substitution of chunks are rejected |

- The key is new for every archive, so the counter in the nonce never repeats under one key. A password-derived key (KDF) is not needed.
- The write goes to a temporary file in the same folder and is atomically renamed after verification. An incomplete archive never looks successful.
- DPAPI is called through ctypes by own code (≈ 50 lines), without pywin32.
- Before implementation: reference vectors (encryption and decryption of a known archive), tests for truncation, reordering, header substitution and a foreign key.
- The limitation remains (ADR-006): if access to the DPAPI key is lost (for example, an administrator reset the Windows password), the archive cannot be decrypted. This is shown to the user at the first backup.

### 3.3 Restore

Sequence: `Selected → Authenticated → Verified → Preview → Current-data backup → Restore into staging → Validate → Switch → Done`. The `djarvis_restore` staging database is created in the same cluster; switching is a database rename under maintenance mode with an on-disk operation marker. Before switching, the core checks references, applies the current history-retention period and the later of the current and archived history-deletion watermarks (ADR-006).

Under ADR-023, old grants, launch targets, provider accounts/calendar maps, pending approvals, email sends and other external queues are not imported into staging. Inactive plan drafts become `stale`; accepted time blocks and completion history remain. Proactive speech and automatic wake listening are reset pending explicit setup. Reminder rules remain, but the job queue is rebuilt from current data; old jobs and emails are not replayed. Events from disconnected external calendars appear as local snapshots without automatic synchronization until reconnection and explicit mapping review. License/trial and OAuth secrets are not replaced by restore.

## 4. Installer

- **Inno Setup** (free, permissive license, allows commercial use): per-user installation without administrator rights into `%LOCALAPPDATA%\Programs\Djarvis`. MSIX was rejected: its file and registry virtualization interferes with the private PostgreSQL and the background core (DD06).
- Roots (CP18): program — `%LOCALAPPDATA%\Programs\Djarvis`; data — `%LOCALAPPDATA%\Djarvis\{db,files,run,logs,models,cache}`; backups — `Documents\Djarvis Backups` (ADR-013).
- Installer contents: the Flutter interface, embedded Python with pinned packages (`pip install --target` with hash verification from a lock file), trimmed PostgreSQL, the llama.cpp server, Vosk and onnxruntime. Expected size is 250–350 MB; to be refined in phase 7.
- Models are not part of the installer. The first launch downloads them by a signed resource manifest (CP18) with progress, pause and resume: language model ≈ 2.7 GB; Vosk small ru and en ≈ 0.16 GB; Vosk TTS 0.7 ≈ 0.13 GB; Kokoro and voices ≈ 0.12 GB. Total ≈ 3.1 GB. Without models the scheduler works, and the assistant honestly shows "resources are downloading".
- Signing: all product EXEs and DLLs and the installer. A code-signing certificate is needed — the owner's decision on cost (OV, EV or cloud signing). Without a signature Windows SmartScreen will warn during installation.
- Updates (DD07): notification only; download and installation happen on user command. In update mode the installer stops the core, keeps the previous version until a health check passes, then the core runs migrations with a backup.
- Uninstall: the program is removed; data and backups are kept by default; deleting data is a separate confirmed checkbox. Trial traces are not erased.

## 5. Profile for 8 GiB

Budget from the PLAN-021 and PLAN-022 measurements (working set; the Flutter interface has not been measured yet):

| Component | When loaded | Memory |
| --- | --- | --- |
| Python core | always | ≈ 0.1 GB |
| PostgreSQL | always | ≈ 0.2 GB |
| Vosk small for the current language (wake phrase and utterance) | while the microphone is on | ≈ 0.2 GB |
| Flutter interface (in the tray while the window is closed) | always | ≈ 0.2 GB (estimate; to be measured) |
| Language model 4B Q4_K_M, context 4096 | on demand, unloaded when idle | ≈ 3.0 GB |
| Speech synthesis for the current language: Vosk TTS 0.7 (ru) or Kokoro (en) | together with the model | 0.75 GB or ≈ 0.3 GB |
| **Peak during a dialogue (ru, window open)** | | **≈ 4.45 GB** |
| Background with the window closed | | ≈ 0.7 GB |

Profile rules:

1. In the background only the permanent components are loaded (≈ 0.7 GB including the tray interface). The language model and synthesis load on demand.
2. Model loading starts immediately when the wake phrase fires, in parallel with recording the utterance, and hides ≈ 5 seconds of load time. Weights are memory-mapped (mmap), so a reload from the Windows cache is faster.
3. The model and synthesis are unloaded after 5 minutes of idle (configurable: 1–30 minutes or "never unload"). Unloading means stopping the `djarvis-llm.exe` process.
4. Only the synthesis for the reply language is loaded; the second language is loaded only when needed.
5. Whisper and Vosk TTS 0.9 are not loaded in this profile.
6. Before loading the model the core checks free memory (`GlobalMemoryStatusEx`). If it is below 3.6 GB, the assistant replies with text and no synthesis. If it is below 3.0 GB, it honestly reports the lack of memory and suggests closing programs; there is no cloud fallback.
7. Model threads — the number of physical cores minus one; reply synthesis runs sentence by sentence as generation proceeds (finding 2 of PLAN-021).
8. The profile is chosen automatically by RAM size: ≤ 12 GiB — "8 GB"; more — "16 GB+". In "16 GB+" the model stays loaded for 30 minutes, Vosk TTS 0.9 and a second Whisper small pass are allowed.

Open: a measurement on a real 8 GiB machine (Windows 11 with a browser usually takes 3–4 GB, so the margin is about 0.5–1 GB) and the choice of a smaller fallback model (class 1.5–2 GB) with a quality check in Russian.

## 6. Decisions needed from the owner

| No. | Question | Proposal |
| --- | --- | --- |
| T1 | Transport and notification-area icon | **Approved:** loopback HTTP + WebSocket; the interface stays in the tray and owns the icon |
| T2 | Driver and migrations | **Approved:** asyncpg; own forward-only migration runner |
| T3 | Backup format | **Approved:** DJB1: tar → AES-256-GCM-STREAM, archive key under DPAPI |
| T4 | Installer and signing | **Approved:** Inno Setup, per-user install without admin rights; unsigned during development and closed testing, a code-signing certificate is bought before public release |
| T5 | 8 GiB profile | **Approved:** Unload after 5 minutes of idle; Vosk TTS 0.7 for Russian; no Whisper |
| T6 | Vosk TTS 0.9 | **Approved:** 0.7 for all profiles; 0.9 later as a higher-quality option for 16 GB+, if it sounds better and its load time can be reduced |

## 7. Sources

- [PostgreSQL 18: UUID functions (uuidv7)](https://www.postgresql.org/docs/18/functions-uuid.html), [locale providers](https://www.postgresql.org/docs/18/locale.html), [pg_dump](https://www.postgresql.org/docs/18/app-pgdump.html)
- [asyncpg](https://github.com/MagicStack/asyncpg), [aiohttp](https://docs.aiohttp.org/), [Pydantic](https://docs.pydantic.dev/)
- [cryptography AEAD](https://cryptography.io/en/latest/hazmat/primitives/aead/), [Online AE and the STREAM construction (Hoang et al., 2015)](https://eprint.iacr.org/2015/189), [CryptProtectData](https://learn.microsoft.com/en-us/windows/win32/api/dpapi/nf-dpapi-cryptprotectdata)
- [Inno Setup](https://jrsoftware.org/isinfo.php), [Inno Setup license](https://jrsoftware.org/files/is/license.txt)
- [llama.cpp server](https://github.com/ggml-org/llama.cpp/tree/master/tools/server), [Vosk](https://alphacephei.com/vosk/), [misaki](https://github.com/hexgrad/misaki)
