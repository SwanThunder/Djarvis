# Project status

[Русская версия](STATUS.ru.md) · [Product](PRODUCT.md) · [Design](DESIGN.md) · [Decisions](architecture/DECISIONS.md) · [Component plan](architecture/COMPONENT_PLAN.md) · [Work log](../Plan/WORK_LOG.md)

Snapshot: 2026-11-04, Europe/Moscow, after PLAN-020. This is a navigation summary; the linked canonical documents and the shared work log remain the source of truth. Update or replace this snapshot when status changes materially.

## 1. Overall

- Stage: design. No application code exists and programming is not authorized.
- Done: product requirements, mandatory visual design (plus local briefs v2.1 and layout v1.0), fourteen narrow ADRs, and detailed proposals for all 20 components (CP01–CP20).
- Next gate: final architecture and implementation plan for explicit owner approval.

## 2. Accepted decisions

| Area | Decision | Source |
| --- | --- | --- |
| Technology | Flutter UI (Dart only for UI); Python core/background with app-owned runtime; app-managed isolated local PostgreSQL; no terminal or manual installs for users | ADR-001…004 |
| Data location | Local only; no own remote backend or cloud user data; local-only AI inference in the current version | PRODUCT, ADR-002 |
| Access | Local profile, no mandatory account; signed license file verified offline; monthly and annual subscriptions; 7-day per-device trial from first use of any function; on expiry planner/assistant lock, data kept, renewal/deletion/backups remain, microphone and proactive speech stop | ADR-005 |
| License terms | Up to 3 devices per license (PCs and future Android); file not hardware-bound; clock rollback over 48 h blocks paid functions until corrected; payment deferred | ADR-010 |
| Personas and voices | Original personas inspired by archetypes; licensed local synthesis or consented recordings; no third-party characters or actor voices | ADR-011 |
| Search and weather | Search with a user-owned API key, browser handoff without it; MET Norway weather | ADR-012 |
| Personas, navigation, device, backups | Edward, Professor Volt, Nova; sidebar Today…Notes + Settings; closing programs/sleep/lock confirmed; backups in Documents\Djarvis Backups | ADR-013 |
| Engines and protection | Vosk TTS (ru) + Kokoro (en); Tavily search with user key; Windows ACL + BitLocker hint for live data | ADR-014 |
| Backups | Daily and pre-migration; 7-day default retention, configurable; Windows-protected key, no extra password or recovery key; full-snapshot restore after preview and current-data backup; 30-day default history retention, configurable/disableable | ADR-006 |
| Planner | Deadline first, then priority; DST gap/fold require confirmation; completion releases only that occurrence's future placements; overdue tasks stay eligible; parent close offers "Close task" / "Finish subtasks" | ADR-007, ADR-008 |
| Habits and subtasks | Abstinence success only by explicit mark; quantity mode per habit; timer plus manual duration, timer runs through sleep/exit/shutdown and splits at midnight; multi-level subtasks with confirmed parent defaults | ADR-008, ADR-009 |
| Design | Midnight Electric + Glass, compact uncrowded density, v2.1 visual rules; assistant circle above the day panel; day panel follows layout brief v1.0 grid | DESIGN |
| Microphone button | Floating, hideable; press = overlay plus immediate listening; right-click/menu key = mute/unmute; visible unavailable state with reason | PLAN-016/017, DESIGN |
| Main screen | Top bar: day selector, search, quick create, notifications (no profile); card contents accepted | PLAN-017, DESIGN |
| Other | Updates notify only, install on user command; raw microphone audio RAM-only, never written to disk; sending mail, deleting or overwriting files always need confirmation | PRODUCT |

## 3. Components: proposed direction and open items

All directions below are unapproved technical proposals unless listed in section 2.

| Group | Proposed direction | Open |
| --- | --- | --- |
| Foundations CP01–CP04 | Loopback HTTP API plus event stream (named pipe alternative); one Python host owns writes and the database; typed commands with revisions | Transport, wire schema, DDL, PostgreSQL version/distribution, driver, migrations, crash recovery |
| Domain CP05–CP07 | Deterministic planner; local intent stored separately from resolved instants; immutable attachments | Tie-break, started-placement boundary, segment size/buffers, project/note fields, timer timezone/clock handling, branch move/deletion |
| Assistant CP08–CP11 | Model proposes, typed tool registry executes; one audio state machine; durable reminders | Model runtime, ASR, wake detection, TTS, **voice licenses**, CPU/8 GiB performance unverified, proactive cooldowns |
| External CP12–CP14 | Provider adapters with local outbox; scoped Windows grants | Search/weather providers and costs, OAuth details, app identity and argument validation |
| Trust CP15–CP16 | AES-256-GCM archives with DPAPI-wrapped keys; Ed25519 signed license | Archive format, **price, issuer, payment (deferred)** |
| Delivery CP17–CP20 | Signed EXE or MSIX; local diagnostics without telemetry | Installer format, Android direction (DD10), test and performance plan |

## 4. Open owner questions

1. Commercial: price, license issuer and payment deferred by the owner; future BYOK 50% plan.
2. Release checks: voice provenance/licenses, Tavily and MET Norway terms (ADR-014).

## 5. Remaining work

1. Resolve section 4 in small batches.
2. Authorized feasibility checks: local model on CPU/8 GiB, ASR/TTS, PostgreSQL and Python packaging.
3. Agent-side technical finalization: transport, schema, cryptography, migrations.
4. Final architecture and implementation plan → owner approval → programming.
