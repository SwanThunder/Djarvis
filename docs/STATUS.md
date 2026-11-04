# Project status

[Русская версия](STATUS.ru.md) · [Product](PRODUCT.md) · [Design](DESIGN.md) · [Decisions](architecture/DECISIONS.md) · [Component plan](architecture/COMPONENT_PLAN.md) · [Work log](../Plan/WORK_LOG.md)

Snapshot: 2026-11-04, Europe/Moscow, after PLAN-022. This is a navigation summary; the linked canonical documents and the shared work log remain the source of truth. Update or replace this snapshot when status changes materially.

## 1. Overall

- Stage: design. No application code exists and programming is not authorized.
- Done: product requirements, mandatory visual design (plus local briefs v2.1 and layout v1.0), fourteen narrow ADRs, and detailed proposals for all 20 components (CP01–CP20).
- Feasibility (PLAN-021): local model, speech synthesis, private PostgreSQL and embedded Python work on CPU; 8 GiB memory is tight — see [feasibility checks](architecture/FEASIBILITY.md).
- Recognition (PLAN-022): Vosk small for wake phrase and turns (≈ 0.2 GB, WER ≈ 5 % on synthetic speech); wake phrase uses a grammar with decoys plus a "start of utterance only" rule; Vosk TTS 0.9 is too heavy for 8 GiB; English synthesis works without espeak-ng (GPL).
- Prepared for approval: [technical details](architecture/TECHNICAL_DESIGN.md) and the [final architecture and implementation plan](architecture/IMPLEMENTATION_PLAN.md).
- Next gate: explicit owner approval of the implementation plan; then programming from phase P0.

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
| Foundations CP01–CP04 | Loopback HTTP + WebSocket with token; tray icon owned by the core; PostgreSQL 18 zip, asyncpg, own migration runner; schema v1 ([TECHNICAL_DESIGN](architecture/TECHNICAL_DESIGN.md) §1–2) | Approval of T1–T2; final DDL written in P1 |
| Domain CP05–CP07 | Deterministic planner; local intent stored separately from resolved instants; immutable attachments | Tie-break, started-placement boundary, segment size/buffers, project/note fields, timer timezone/clock handling, branch move/deletion |
| Assistant CP08–CP11 | Model proposes, typed tool registry executes; one audio state machine; durable reminders; llama.cpp on demand; Vosk small; misaki → Kokoro without GPL | Live microphone test, **voice licenses**, real 8 GiB machine, proactive cooldowns |
| External CP12–CP14 | Provider adapters with local outbox; scoped Windows grants | Search/weather providers and costs, OAuth details, app identity and argument validation |
| Trust CP15–CP16 | DJB1 format: tar → AES-256-GCM-STREAM, DPAPI-wrapped key; Ed25519 signed license | Approval of T3; **price, issuer, payment (deferred)** |
| Delivery CP17–CP20 | Per-user Inno Setup without admin rights; models on first run; 8 GB / 16 GB+ profiles; diagnostics without telemetry | Approval of T4–T5, code-signing certificate, Android direction (DD10) |

## 4. Open owner questions

1. Commercial: price, license issuer and payment deferred by the owner; future BYOK 50% plan.
2. Release checks: voice provenance/licenses, Tavily and MET Norway terms (ADR-014).

## 5. Remaining work

1. Approve the [implementation plan](architecture/IMPLEMENTATION_PLAN.md) and technical decisions T1–T6.
2. Live wake-phrase test on the owner's microphone (`cache/feasibility/mic_wake_test.py`) and Vosk 0.9 listening (`cache/feasibility/samples/vosk09_*`).
3. Resolve section 4; acceptance on a real 8 GiB machine happens in phase P7.
4. After approval — programming from P0.
