# Data protection, product experience and delivery design

[Русская версия](DELIVERY_DESIGN.ru.md) · [Component map](COMPONENT_PLAN.md) · [Foundation](FOUNDATION_DESIGN.md) · [Assistant](ASSISTANT_DESIGN.md) · [Approved decisions](DECISIONS.md) · [Required design](../DESIGN.md)

Status: proposed concrete contracts for CP15–CP20, prepared in PLAN-012. Existing requirements and approved ADRs remain authoritative. Recommendations below are not architecture approval, a running implementation, verified cryptography or measured performance. The owner has approved Midnight Electric + Glass initially; compact, uncrowded density comes from the supplied visual brief v2.1. Other recommendations await review.

## CP15 — Data classification, encrypted archives and recovery

### Storage boundaries

| Class | Proposed storage and use | Backup / restore |
| --- | --- | --- |
| Tasks, occurrences, habits, events, projects, notes | Private PostgreSQL, owned by the host | Included in full snapshot |
| Managed attachments | Immutable application-owned blobs and database references | Include referenced committed blobs |
| Conversation history | Local records, default 30 days; history can be disabled | Included; restore applies current target retention |
| OAuth credentials, IPC secrets | Windows-protected secret store; never model context or logs | Excluded; reconnect providers after recovery |
| Trial and license state | Separate protected entitlement store | Excluded; never rolled back by user-data restore |
| Model weights and regenerable caches | Versioned resource/cache directories | Excluded; reacquire compatible resources |
| Permission grants and pending confirmations | Policy state separate from ordinary content | Do not revive previous approvals; reauthorize restored connections and sensitive access |
| Operational diagnostics | Bounded local metadata without content by design | Excluded from ordinary archives |

The approved archive encryption policy does not automatically encrypt the live database, attachment store or caches. Proposal DD01 is to use restrictive per-user permissions and Windows-protected secrets first; the desired additional at-rest protection requires an explicit product choice and a feasibility review. Do not claim protection from a compromised signed-in Windows account.

### Snapshot transaction boundary

Approved cadence: automatic daily backups and backups before structural changes/migrations, seven-day default retention, with configurable schedule and retention. Store them in a separate configurable app-managed local folder outside the working database. Conversation history is included.

Propose a versioned archive containing a single-database logical dump, managed-file manifest, referenced blobs and an encrypted metadata manifest. PostgreSQL documents a consistent single-database export; attachment coordination remains our responsibility. Use compatible bundled dump/restore tools, an allowlisted data schema and a fresh restricted staging database during recovery. Treat an imported archive as untrusted, never as instructions for the assistant. [PostgreSQL pg_dump](https://www.postgresql.org/docs/current/app-pgdump.html)

1. Acquire an application maintenance lease; announce a brief write pause. Do not hold a database transaction lock while awaiting a user or network.
2. Drain local mutating commands; prevent new commits until the snapshot boundary is captured. Finish pending attachment publication or leave it outside the committed snapshot.
3. Pin the committed immutable attachment set, capture data/schema versions and produce the dump while writes remain quiesced. No raw copying of a live PostgreSQL data directory.
4. Release the write gate after the dump and file-reference boundary are secured. Pinned blobs cannot be garbage-collected until archive completion or abort.
5. Stream referenced blobs and the dump into an encrypted temporary archive; verify counts and integrity, then atomically publish it on the same volume. An incomplete archive never appears as a successful backup.
6. Retention removes only expired, completed, app-managed archives; do not silently delete the last verified recovery point because its replacement failed. Report failure and any retained expired copy.

Long snapshot pauses must be measured. A later exported-snapshot alternative can reduce downtime, but is not assumed implemented. Disk-space preflight covers staging, the new archive, any retained recovery point and publication overhead. Failed backup before a migration stops that migration.

### Candidate cryptographic format

DD02 proposes random 256-bit data keys per archive, protected with user-scope Windows DPAPI without a password or extra recovery key. Do not use machine-scope protection by default; avoid interactive prompts for scheduled backup. DPAPI behavior depends on Windows credentials and profile configuration, so recovery without access to its key cannot be promised. [Microsoft CryptProtectData](https://learn.microsoft.com/en-us/windows/win32/api/dpapi/nf-dpapi-cryptprotectdata)

DD03 proposes a reviewed streaming format built on a maintained AEAD library, with AES-256-GCM as the candidate primitive. Each archive gets a fresh key; chunks use unique counters under that key. Authenticated associated data binds format version, archive identity, chunk index and manifest identity. An authenticated final record binds chunk count and total length so truncation or reordering cannot be accepted. Avoid whole-archive buffering. Random-key encryption needs no password-derived KDF. Library, chunk size, counter encoding, key handling and interoperability vectors must be reviewed before implementation. [Cryptography AEAD contracts](https://cryptography.io/en/latest/hazmat/primitives/aead/)

Minimal unencrypted header fields are limited to format/key-wrap identifiers and bounded parsing information; conversation text, file names and counts used for preview stay encrypted. Unsupported formats, excessive lengths, unsafe archive paths and failed authentication stop before any live-data replacement. DPAPI-wrapped archive keys are not additional user recovery keys.

### Restore and deletion states

Proposed recovery states: `Selected → Authenticated → Validated → Previewed → CurrentBackupReady → StagedRestore → Checked → Switched → Completed`. Failure before switching preserves current data. A durable operation marker records switch progress; interrupted startup enters recovery before normal writes, reminders or provider dispatch.

- Authenticate and inspect compatible versions before preview. Preview shows snapshot time, included sections and the effect of current history retention; never silently restore history already explicitly deleted.
- Obtain explicit full-snapshot confirmation; make and verify a copy of current data. If this cannot be done, do not replace current data under the normal restore workflow.
- Restore into a fresh private staging database and blob namespace. Validate schema, references, counts, history policy and absence of entitlement/secrets before activation.
- Stop provider dispatch and reconcile restored sync mappings and queues. Never replay historical email sends or other side effects. Restored external items are not authority to overwrite providers.
- Under exclusive maintenance, switch the database/blob generation together via a recoverable manifest. Check invariants before reopening writes. A crash cannot leave the database referencing another generation's missing blobs.
- On failure after switch, recover using the recorded generation and verified pre-restore copy. Exact atomic switch mechanics and disk failure handling require implementation tests.

Automatic conversation age expiry does not rewrite old archives; their own retention applies. Explicit deletion creates a deletion operation listing affected managed archives. Only after confirmation recreate or remove those archives, retaining unrelated contents where recreation was chosen. Report partial failures separately. Keep a minimal deletion watermark outside restorable history so restore cannot silently resurrect explicitly removed conversation records; its scope and metadata retention require review. This is logical deletion, not a physical secure-erasure guarantee or control of external copies.

### Failure and acceptance matrix

| Situation | Proposed response / future acceptance case |
| --- | --- |
| Backup folder unavailable or disk full | Keep prior archives; show failed job, do not migrate |
| DPAPI key inaccessible | Stop decryption; explain inaccessible backup, no recovery promise |
| Modified/truncated/reordered chunks | Reject entire archive before activation |
| Crash during switch | Recover one consistent generation before background jobs restart |
| Expired entitlement | Renewal/import, user deletion and automatic backup service remain available; paid features and all capture remain off |
| Manual history deletion partly fails | Show remaining affected archives, never claim total completion |

These are planned acceptance cases, not tests performed.

## CP16 — Offline entitlement and commercial workflow

### Entitlement model

Proposed states: `SetupOnly`, `TrialAvailable`, `TrialActive`, `Licensed`, `Expired`, `InvalidArtifact`, `ClockReviewRequired`. Setup and waiting for resources do not start the seven-day trial per device. The first actual product-function request, including manual planner use, atomically starts trial once and checks entitlement before executing that request. Pre-trial backup maintenance and license-import classification still need specification; do not invent another exception to first product use. Exact time-tamper handling is unresolved, not an approved reason to block a legitimate subscriber automatically.

The host authorizes every paid command/job; UI visibility alone is not enforcement. On expiry it closes capture, wake detection, dialogue and proactive speech; stops paid background dispatch; preserves data and allows only the agreed renewal/import, user deletion and backup functions. An in-flight provider operation may already have taken effect: retain its result state without re-dispatching it.

### Signed license proposal

DD04 proposes a bounded, versioned license artifact with an exact signed byte representation, a detached Ed25519 signature and a trusted `key_id`. Fields: product/schema ID, license ID, entitlement interval, feature set, device-binding policy/version and issuer reference. Verify the signature before interpreting entitlements; reject duplicate fields, unsupported critical versions, invalid intervals and unknown keys. Display commercial identity separately from untrusted text. Ed25519 verification is supported by maintained cryptographic APIs; an algorithm choice does not establish a complete license protocol. [Cryptography Ed25519](https://cryptography.io/en/latest/hazmat/primitives/asymmetric/ed25519/)

The private signing key belongs only to an owner-operated issuer, never to the desktop app, source repository, model or customer license file. The app ships trusted public keys; key rotation needs signed release trust and explicit issuer procedures. No own activation server is introduced. Offline clients cannot learn immediate revocations without a new signed artifact/update; do not claim otherwise.

### Purchase, renewal and device changes

Proposed flow: app displays a local request code → customer obtains a paid entitlement through an external purchase channel → the issuer produces a signed file → user imports and previews it → host verifies and atomically records acceptance. This describes an issuer process, not mandatory registration or a server queried by the app. Automated fulfillment would be a separate external-service design.

Device request codes should reveal only minimum pseudonymous binding data; hardware components, tolerance and replacement policy remain DD05. Keep device trial evidence independent of user-data snapshots. Windows reinstall, clock changes, disk replacement and copied state cannot be made unbypassable with fully offline checks; do not promise one-person identification.

Approved subscription periods are monthly and annual; price remains open. Other owner decisions: purchase markets/channel, permitted device count and transfer process, hardware-change tolerance, and clock-recovery experience. Future BYOK at half standard price remains a future requirement, never current cloud inference. Payment-provider selection follows these constraints and a separate current availability review.

Future acceptance: concurrent first use starts one trial; setup never starts it; forged/expired/wrong-device artifacts fail safely; an interrupted import preserves prior valid entitlement; restore cannot reset trial; expiry closes all capture while backups continue. No licensing tests have run.

## CP17 — Screens, view states and visual contracts

### Proposed navigation within existing product scope

| Destination | Existing content and interactions | Read model / commands |
| --- | --- | --- |
| Today / assistant | Assistant circle above day panel, tasks, habit progress, day proposal | Day snapshot; proposal review; typed task/habit actions |
| Tasks | Backlog, priority, separate deadline and missed placement, advanced fields | Filtered task/occurrence views; create/edit/complete |
| Calendar | Events and placements; unknown-duration start markers remain markers | Range view; place/move; sync conflict review |
| Habits | Four types, fixed/flexible schedules, pauses, corrections, history | Period evaluation; measurement/correction commands |
| Projects | Independent grouping and linked tasks/notes | Project view; scoped content commands |
| Notes | Local notes independent of integrations | Note view; save/search |
| Settings | Appearance, audio/initiative, permissions/connections, history, backup, resources and license | Settings snapshot; typed configuration commands |

This is a proposed grouping of already required content, not approval of route order or labels. License expiry keeps the agreed restricted access surface without exposing blocked planner screens as functional. Do not invent CRM modules, decorative KPIs, demo records or an account requirement.

### State and interaction contract

Each view separates `Loading`, `Ready`, `Empty`, `RecoverableError`, `Unavailable`, `PermissionRequired`, `Conflict` and `AccessExpired`, as applicable. Network offline is a capability attribute, not a global failure page: local views continue. Model preparation disables only unavailable model functions; a manual planner action may start trial before models are ready.

Mutation widgets show pending/result state from the command receipt. Do not display completion before the host commits it. Confirmation cards bind exact action/revision/targets and visibly expire on edits; a stale calendar conflict cannot silently resolve to the last clicked version. Recover focus after dialogs; errors attach to the affected field and have text/icons rather than color alone.

The required visual contract is [DESIGN](../DESIGN.md), incorporating local v2.1: initial `midnight-electric` + Glass, all six combinations, compact uncrowded Bento, no background image, no layout change on material switch. Flutter uses semantic tokens and logical dimensions. Frequent keyboard operations are immediate; motion is functional, short, interruptible and reduced when requested. Do not add UI content from the visual reference.

RU/EN strings use translation keys, locale-aware dates/numbers and plural rules; command/data IDs stay language-independent. Test both languages with long text, system text scaling, keyboard-only input and screen-reader semantics. Proposed geometry switches layout according to available content width; source breakpoints are guides, not a mobile-product approval. Appearance settings are local and instantly applied; failure to persist is reported without falsely claiming a saved choice.

Future acceptance: all six materials/palettes including nested dialogs; contrast on actual surfaces; keyboard/focus/Escape; 30-second dialogue-wait status distinct from active speech; mic mute and full exit visibly different; independent settings and calendar conflict states. No screen implementation or visual prototype has been tested.

## CP18 — Distribution, resources and rollback

### Packaging proposal

DD06 recommends first evaluating a signed per-user Win32 EXE bootstrapper with a packaged Python host, private PostgreSQL and managed native helpers. Compare with MSIX against private-process ownership, writable data, upgrades and uninstall behavior before selecting tooling. Avoid global Python, Docker or silently installed machine-wide services. Certificate cost and exact supported builds/architectures remain release decisions. Microsoft's distribution guidance distinguishes signing and update responsibilities by channel. [Windows distribution paths](https://learn.microsoft.com/en-us/windows/apps/package-and-deploy/choose-distribution-path)

Keep binaries, mutable user data, protected secret/entitlement state, resource versions, caches and backups in separate roots. Proposed user-data root is `%LOCALAPPDATA%\Djarvis`; backup directory is a distinct app-managed directory outside the live cluster and configurable by the user. Exact paths are proposals. Per-user install runs unelevated; a genuinely required elevation must be a separate visible OS request. [Microsoft installation guidance](https://blogs.windows.com/windowsdeveloper/2025/05/19/enhance-your-application-security-with-administrator-protection/)

### Resource manifest and first run

Proposed signed resource manifest fields: schema/release ID, component type, pinned resource revision, HTTPS URL, expected bytes/hash, runtime/platform compatibility, minimum supported app/schema, license/attribution reference and signature trust identifier. A hash alone does not authenticate a compromised download manifest; validate trusted signature and provenance before using its URLs.

Flow: inspect available resources → select a validated capability profile → show the chosen download and size → resume into staging → verify bytes/hash/signature and compatibility → atomically activate → health-check locally → retain the previous working generation until acceptance. A first-run selection is automatic, without console, while in-app progress/cancel/retry remains visible. Hardware detection is not proof of acceptable latency.

Only profiles supported by full-stack measurements qualify for automatic selection. Keep wake detection lightweight and schedule large ASR/LLM/TTS phases under a shared resource budget; unload incompatible simultaneous residents when appropriate. A device that cannot satisfy the full local experience gets an honest unsupported/resource status, not silent cloud fallback, lost features or an unapproved minimum change.

### App and database update transaction

Propose `Offered → Downloaded → Verified → BackupReady → Maintenance → Migrated → HealthChecked → Activated`. Approved DD07 behavior: notify only; both download and installation require a user command, with no automatic download or application. This concerns application updates, not the separately approved automatic first-run model provisioning. Every incompatible schema change requires a verified pre-migration snapshot and a compatible recovery path. Preserve old binaries and a compatible data generation until health checks succeed.

An old executable must never open a newer unsupported schema. Rollback after an incompatible migration restores a coherent prior data generation, not just the EXE; disclose the affected time window. Interrupted migration resumes or rolls back from its durable marker before user commands. Failed model update reverts only that resource if data schema is unaffected.

Uninstall removes application-owned binaries/resources according to explicit choices, preserves user data by default as a proposal, and separately confirms deletion of owned data/archives. Never delete unrelated external files or silently erase trial evidence to offer another trial. Source code updates, model downloads and payment/licensing are different trust domains.

Future acceptance: clean supported Windows without a terminal; non-ASCII paths, non-admin account, occupied port, denied folders, network interruption, corrupted resources, low disk, reboot mid-migration, uninstall with retained data and failed rollback. Exact Windows builds/CPU architectures and build tool versions need a compatibility matrix; Win10/11 labels alone are insufficient. These checks have not run.

## CP19 — Android boundary and future synchronization

### Contracts to preserve now

Domain IDs, original recurrence identities, time-zone intent, units, data revisions, deletion markers and command/result versions remain independent of Windows paths, Python object serialization or PostgreSQL row layout. Native capabilities sit behind adapters. UI models consume contracts rather than the private database. Share contract fixtures and domain acceptance cases even if platform implementations differ.

Flutter supports platform-specific Android integration; this is not evidence that the Python/PostgreSQL Windows host can be shipped unchanged. Android background microphone/service restrictions require a separate lifecycle and permission design. [Flutter Android integration](https://docs.flutter.dev/platform-integration/android), [Android foreground-service types](https://developer.android.com/develop/background-work/services/fgs/service-types)

| Alternative for later review | Benefit | Constraint |
| --- | --- | --- |
| Autonomous Android domain/storage adapters | Device-local planning and potential local voice | Separate storage/runtime and performance validation |
| Android client paired with Windows host | Reuses running host behavior | PC availability, secure pairing/networking; not autonomous mobile offline |
| Future explicitly approved sync service | Cross-network eventual synchronization | New account, privacy, security and service-cost decisions |

No alternative is selected by this document. Do not share active database files across devices. A future sync protocol exchanges versioned domain changes with per-device identity, tombstones, checkpoints, conflict resolution and revocation; it must not blindly replay mail sends or device actions. Calendar-provider sync is not Djarvis multi-device sync. Licenses, protected keys and raw audio do not become transferable simply because planning data synchronizes.

Future acceptance planning: independent offline edits, delete-versus-edit conflicts, recurring-instance identity across zones, reconnect after long absence, revoked device and duplicate change delivery. No Android build, cloud service or sync implementation exists.

## CP20 — Verification, performance and support

### Test layers and evidence

| Layer | Proposed meaningful evidence |
| --- | --- |
| Domain | Recurrence/month-end/DST vectors, habit periods/pauses/corrections, deterministic planning and split completion |
| Storage and commands | Constraints, concurrent planning writes, deduplication, rollback and stale confirmations |
| Host and audio | Single ownership, restart vs reopen, mute, full exit, barge-in, expiry during every capture state |
| Providers and Windows | Fake-provider faults plus sandbox accounts; no personal data; unknown-send reconciliation, file scope and mandatory confirmations |
| Snapshot/update | Corruption, missing key/blob, interruption at every persistent boundary, rollback and historical deletion |
| UI | Required six combinations, localization, accessibility and actual empty/error/offline states |
| Full product | Target CPU/8 GiB Windows 10/11 with planner + database + audio + inference + real visual effects |

Start with repeatable synthetic profiles: small personal dataset, busy recurring schedule, long habit/history window and attachment-heavy snapshot. Define exact dataset sizes before performance runs and keep machine/OS/runtime/model/hash/configuration with each report. Existing development GPU model checks are not a CPU/8 GiB full-product result.

Measure cold/warm startup, UI command latency, database/host/private working sets, peak aggregate RAM/commit, steady wake-listening CPU, first/steady ASR and TTS, time to first response, full turn latency, disk footprint and backup/restore duration. Record p50/p95 where samples justify them and distinguish cold initialization. Include contention, sleep/resume, network loss and quiet modes. Propose release thresholds only after the initial measurement baseline; do not invent achieved latency or a smaller model's quality.

### Failure gates and diagnostics

No release candidate passes if it loses committed user data, executes an unconfirmed mandatory action, silently enables cloud inference, captures while muted/expired, misreports unknown provider execution or cannot restore its verified supported snapshot. These invariants do not waive performance, accessibility, model quality or rights checks; all remain explicit gates.

DD08 recommends local bounded diagnostic metadata, automatic network telemetry disabled, and a user-initiated support bundle with preview and explicit export. Include versions, stage/error codes, durations and resource statistics. Exclude conversation text, prompts, task titles, mail, file paths, tokens, device fingerprint and raw audio by default. Redaction is tested, not assumed; logs themselves can still contain sensitive metadata and need limits. No crash-dump upload is implicit.

Recovery guidance must cover safe startup, offline use, model repair, provider reconnection, archive-key unavailability, coherent rollback and license-support request codes. Documentation must state actual tested systems and limitations. Implementation tests, builds and benchmarks have not been executed for this documentation task.

## Review register and next owner choices

| ID | Proposal / unresolved choice | Review boundary |
| --- | --- | --- |
| DD01 | Live-data protection beyond ACLs and Windows-protected secrets | Owner privacy tradeoff; encryption design requires feasibility |
| DD02 | Per-archive random data key wrapped by user-scope DPAPI | Technical proposal within ADR-006; no extra recovery key |
| DD03 | Bounded chunked authenticated archive using AES-256-GCM | Technical protocol and dependency review before code |
| DD04 | Ed25519 signed offline license and separate owner issuer | Technical proposal; commercial issuance still open |
| DD05 | Device count, transfer/hardware changes, clock review and price | Owner chooses remaining behavior; monthly/annual periods approved |
| DD06 | Signed per-user EXE versus MSIX and supported build matrix | Technical feasibility and distribution choice |
| DD07 | Notify only; download and install by user command | Product choice approved; technical update protocol remains proposed |
| DD08 | Local diagnostics and explicitly exported support bundle | Proposed privacy behavior; no telemetry approval |
| DD09 | Navigation grouping and remaining project/note interactions | Product review; visual defaults/density already answered |
| DD10 | Future autonomous Android versus PC pairing versus sync service | Future architecture choice, no current cloud implementation |

Use small batches of selectable owner questions with the UI's custom-input option. Do not repeatedly ask answered policies. Consult both [shared logs](../../Plan/WORK_LOG.md) and current canonical documents before each new group; Plan currently contains bilingual work logs, not a separate complete chat export. Technical recommendations can advance while owner choices remain pending, but dependent app implementation waits for explicit approval of architecture and implementation scope.
