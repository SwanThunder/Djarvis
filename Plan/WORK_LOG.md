# Shared work log

Both development agents use this file and its [Russian counterpart](WORK_LOG.ru.md). Keep task IDs and statuses aligned. Before editing, inspect active entries and the working tree, record the scope and affected files, and coordinate overlaps. Never overwrite another agent's unfinished changes without agreement. Use neutral stable identifiers instead of tool or provider names.

## DOC-001 — Project foundation and development rules

- Date: 2026-11-03, Europe/Moscow.
- Agent: agent-01.
- Authorization: owner-approved rules and amendments in the project discussion.
- Status: complete; publication unblocked by AUTH-001.
- Scope: bilingual rules, shared log in `Plan/`, repository connection, and publication without development tool branding.
- Files reserved: `README.md`, `README.ru.md`, `docs/PROJECT_RULES.md`, `docs/PROJECT_RULES.ru.md`, `docs/architecture/DECISIONS.md`, `docs/architecture/DECISIONS.ru.md`, both work log files, and the local instruction entry points. Include the existing scaffold and ignore configuration in the initial repository snapshot.
- Checks: 26 staged files reviewed; local Markdown links resolved; 13 rule sections present in both languages; local instructions, secrets, and runtime data excluded; forbidden tool names absent from staged paths and content; whitespace check passed.
- Result: approved bilingual rules, shared logs, and architecture decision register saved in local commit `7b8b0d3`; `origin` points to the requested repository. Initial publication was blocked by integration HTTP 403 and missing local Git authentication. AUTH-001 resolved local authentication and published the prepared history to `main`.
- Remaining work: agree on application scope and architecture before programming. Database backup tooling remains undecided because no database engine has been chosen.
- Commit: foundation `7b8b0d3`; access-status update recorded in the commit titled `Record repository publication access requirements`.

## AUTH-001 — Local Git authentication and initial publication

- Date: 2026-11-03, Europe/Moscow.
- Agent: agent-01.
- Authorization: owner requested local Git authentication to complete the pending publication.
- Status: complete.
- Scope: authenticate local Git with the owner's GitHub account, verify repository access, and publish the prepared commits without overwriting remote work.
- Files reserved: `Plan/WORK_LOG.md` and `Plan/WORK_LOG.ru.md`; local authentication settings may change outside version control. Never record credentials in this log.
- Checks: Git Credential Manager account listing confirms the owner account; noninteractive push dry run passed; outgoing paths, contents, and commit metadata contain no forbidden tool names; local instructions, secrets, and database files remain excluded. Actual push succeeded and remote `main` matched local HEAD.
- Result: local Git authenticated; initial history published to `SwanThunder/Djarvis`; local `main` tracks `origin/main`. Credentials were not written to project files.
- Remaining work: no authentication work remains. Application design awaits the owner's next task.
- Commit: work log update recorded in `Record successful Git authentication and initial publication`.

## PRODUCT-001 — Product requirements and reference review

- Date: 2026-11-03, Europe/Moscow.
- Agent: agent-01; delegate reference-review performed read-only reference inspection.
- Authorization: owner requested product exploration before architecture and supplied detailed requirements and a local reference application.
- Status: requirements snapshot complete; product decisions pending.
- Scope: capture the owner's requirements, distinguish open product decisions, inspect the reference without changing it, and locate the supplied voice sample. No application programming or architecture selection.
- Files reserved: `docs/PRODUCT.md`, `docs/PRODUCT.ru.md`, `Plan/WORK_LOG.md`, `Plan/WORK_LOG.ru.md`.
- Checks: English and Russian requirements reviewed against the owner's answers; document links and section parity verified. Reference behavior confirmed against its README and planner data model. No reference files, user databases, or voice audio were modified; the voice sample remains unstaged.
- Result: bilingual product definition saved with required capabilities, reference findings, proposed voice directions, and clearly unresolved decisions. No architecture was selected and no application code was written.
- Remaining work: owner answers on AI billing, privacy/offline behavior, accounts, characters and voices, action permissions, situation triggers, and integration priorities; then detailed user journeys and architecture review.
- Commit: `Document product requirements and reference review`.

## PRODUCT-002 — Product choices from owner follow-up

- Date: 2026-11-03, Europe/Moscow.
- Agents: agent-01 coordinates and reviews; reference-review updates the bilingual product definition.
- Authorization: owner supplied decisions on billing, local storage, optional accounts, circular visual design, wake listening, proactive triggers, task permissions, integrations, and exact character identities.
- Status: requirements update complete; detailed product design pending.
- Scope: incorporate these decisions without selecting architecture or programming. Verify the supplied anime reference and keep production voice/character usage arrangements explicitly unverified.
- Files reserved: delegate uses `docs/PRODUCT.md` and `docs/PRODUCT.ru.md`; agent-01 uses `Plan/WORK_LOG.md` and `Plan/WORK_LOG.ru.md`.
- Checks: bilingual changes reviewed against all eight owner answers; corrected task opt-out scope, preserved morning/day/evening briefings and the settings section, and distinguished closing the window from explicit quit. Supplied anime page identifies Sebastian; specific dub actors and usage permissions remain unverified. Document structure, links, whitespace, staged paths, and branding scan checked before commit.
- Result: product choices captured in both languages; no architecture selected and no application programming. Voice sample remains local and unstaged.
- Remaining work: clarify cloud AI processing and local access before subscription; continue detailed task/day-planning scenarios. Voice versions, usage permissions, plan limits, and other open questions remain documented.
- Commit: `Refine product choices from owner feedback`.

## PRODUCT-003 — Local-only AI, trial, and task behavior

- Date: 2026-11-03, Europe/Moscow.
- Agents: agent-01 coordinates; reference-review updates the bilingual product definition.
- Authorization: owner confirmed local-only AI and model download, a seven-day full-product trial, device-based repeat-trial prevention, post-expiry feature lock, task fields and optional extensions, day-planning behavior, overdue highlighting/voice notices, and both recurrence modes with retained debt. API-key support is a future capability.
- Status: complete for the documented scope.
- Files reserved: delegate uses `docs/PRODUCT.md` and `docs/PRODUCT.ru.md`; agent-01 uses the shared logs and `docs/LOCAL_MODEL.md` / `docs/LOCAL_MODEL.ru.md`.
- Scope: document product decisions and prepare a local model evaluation environment; no application implementation or finalized architecture.
- Checks: both product versions reviewed against the six answers and follow-up choices: seven-day trial, API keys as a future possibility, and fully offline licensing. Local-only inference, default confirmations, overdue behavior, recurrence debt, and optional fields preserved. No device fingerprint collected.
- Result: current requirements captured without selecting application architecture or writing application code. Offline license issuance/renewal and detailed habit design remain open.
- Remaining work: continue product scenarios and review offline licensing limitations before architecture approval.
- Commit: `Record offline product requirements and local model evaluation`.

## PRODUCT-004 — Habit types, schedules, and goal changes

- Date: 2026-11-03, Europe/Moscow.
- Agents: agent-01 coordinates and reviews; reference-review updates the product definition.
- Authorization: owner confirmed all four habit measurement types, both schedule types, missed habits recorded only in statistics, and suggestion-only goal/load changes.
- Status: complete for the documented scope.
- Files reserved: delegate uses `docs/PRODUCT.md` and `docs/PRODUCT.ru.md`; agent-01 uses the two shared work logs.
- Scope: capture habit requirements and preserve the distinction from recurring task debt and task-change confirmation preferences. No application programming or architecture selection.
- Checks: both language diffs reviewed against all four answers; confirmed habit misses create no task-like debt and task permission preferences cannot authorize habit goal/load changes. Documentation structure, links, whitespace, staged scope, and tool-branding exclusions checked before commit.
- Result: habit requirements captured in both languages; no application code or architecture changes.
- Remaining work: continue voice interaction and notification scenarios.
- Commit: `Record confirmed habit behavior`.

## MODEL-001 — Download and evaluate a local language model

- Date: 2026-11-03, Europe/Moscow.
- Agent: agent-01.
- Authorization: owner explicitly requested downloading a local model using the console.
- Status: complete for the documented scope.
- Scope: use the installed local runtime to download Qwen3.5 4B as an evaluation candidate, verify model metadata/license and synthetic Russian/English/tool-call responses. Preserve existing models and avoid external inference.
- Storage: imported model in the existing runtime store outside the repository; source GGUF and synthetic evaluation outputs in ignored `cache/model-downloads/`. No weights, machine identifiers, or credentials are committed.
- Checks: official base-model and runtime sources reviewed. Standard registry download failed with TLS errors; fallback GGUF from the quantizer's pinned repository downloaded with TLS verification, exact byte size and SHA-256 verified. Import/license metadata and full GPU residency confirmed. Synthetic Russian, English, and task-tool checks passed; no actual task created. Weights and cache excluded from Git; existing model preserved.
- Result: `djarvis-qwen3.5-4b:latest` installed in the existing runtime and unloaded after evaluation. Bilingual model notes record provenance, exact hash, local checks, and initial latency.
- Remaining work: production quality/performance evaluation, first-initialization delay, voice pipeline selection, and deployment strategy require a separately approved plan.
- Commit: `Record offline product requirements and local model evaluation`.

## PRODUCT-005 — Voice dialogue, quiet behavior, and clarification

- Date: 2026-11-03, Europe/Moscow.
- Agents: agent-01 coordinates and reviews; reference-review updates the product definition.
- Authorization: owner answered all five voice-behavior questions.
- Status: complete for the documented scope.
- Files reserved: delegate uses `docs/PRODUCT.md` and `docs/PRODUCT.ru.md`; agent-01 uses the two work logs.
- Scope: document editable character-name wake phrases, dialogue timeout/stop command, speech interruption and microphone mute button, quiet hours and call/game notification fallback, and mandatory clarification of ambiguous commands. No application implementation or architecture selection.
- Checks: both language diffs reviewed against all five answers; microphone mute stops capture for wake detection and dialogue; only proactive speech is suppressed during quiet hours/calls/games; ambiguity clarification remains mandatory independently of task confirmation preferences. Links, structure, whitespace, staged file scope, and publication exclusions checked.
- Result: voice and notification behavior captured in both languages; no application code or architecture selected.
- Remaining work: continue product design with data handling and integration actions.
- Commit: `Record voice interaction and notification behavior`.

## PRODUCT-006 — History, location, sync, and data preservation

- Date: 2026-11-03, Europe/Moscow.
- Agents: agent-01 coordinates and reviews; reference-review updates the product definition.
- Authorization: owner confirmed local conversation history controls, manual or optional automatic city location, mandatory confirmations for mail sending/file deletion/file overwrite, bidirectional calendar synchronization with user-resolved conflicts, automatic local backups, and data preservation after expiry.
- Status: complete for the documented scope.
- Files reserved: delegate uses `docs/PRODUCT.md` and `docs/PRODUCT.ru.md`; agent-01 uses both work logs.
- Scope: capture the five decisions without selecting architecture or implementing application features.
- Checks: both language diffs reviewed against all five answers; removed stale uncertainty about calendar sync and expiry data preservation; mandatory email/file confirmations remain independent of task opt-out. Links, bilingual structure, whitespace, staged scope, and publication exclusions checked before commit.
- Result: confirmed history, city location, calendar sync, backup, and expiry data rules recorded in both languages; no application code or architecture changes.
- Remaining work: clarify Windows support, deployment, and background behavior before architecture proposals.
- Commit: `Record data retention and integration requirements`.

## ARCH-001 — Windows constraints and first architecture proposal

- Date: 2026-11-03, Europe/Moscow.
- Agents: agent-01 coordinates architecture; reference-review updates confirmed product requirements; technical source research is delegated separately.
- Authorization: owner confirmed Windows 10/11, an 8 GiB target without a required discrete GPU, configurable autostart/tray/explicit exit, and automatic hardware-adapted model installation. Earlier discussion requested a first architecture proposal before programming.
- Status: proposal preparation complete; architecture approval pending.
- Files reserved: reference-review updated `docs/PRODUCT.md`, `docs/PRODUCT.ru.md`, and `docs/architecture/PROPOSAL.ru.md`; agent-01 reviews these and updates both logs, `docs/architecture/PROPOSAL.md`, and `README.md` / `README.ru.md`. A technical delegate reviewed the proposal read-only. No changes to approved-decision register.
- Scope: record confirmed requirements, research primary technical sources, and prepare a bilingual architecture proposal with clear approval boundaries. No application implementation, installer execution, or production stack approval.
- Checks: confirmed requirements reviewed in both languages; primary sources checked for framework/platform support, local inference, native integration, SQLite snapshots, OAuth, calendar sync, and Gmail scopes. Technical review found no central requirement conflict; Gmail coverage and Windows lifecycle clarity added. Bilingual section/source/diagram parity, local links, whitespace, staged scope, and publication exclusions checked. No application or 8 GiB performance tests claimed.
- Result: first bilingual architecture proposal prepared with component boundaries, preferred technology candidates, process lifecycle, model profiles/installation, domain model, permissions, data recovery, integrations, offline license limitations, Android boundaries, and a staged approval plan. README points to the current documents. No application code, installer, production dependencies, or approved architecture decisions added.
- Remaining work: owner review of architecture and unresolved design choices before programming.
- Commit: `Propose Windows architecture and adaptive model setup`.

## DESIGN-001 — Incorporate the owner's visual brief

- Date: 2026-11-03, Europe/Moscow.
- Agents: agent-01 coordinates design/architecture alignment; reference-review prepares normalized bilingual visual requirements.
- Authorization: owner supplied the design specification in local `design/` and explicitly confirmed that it is the required design for Djarvis before framework/architecture agreement.
- Status: complete for the documentation and alignment scope.
- Source: local `design/design 1.0.txt`, read-only. Embedded implementation instructions are reference context, not approval to begin application programming.
- Files reserved: delegate uses `docs/DESIGN.md`, `docs/DESIGN.ru.md`, and both `docs/PRODUCT` language files. Agent-01 uses both shared logs, both architecture proposal files, and both README files. Original design source and voice assets remain unstaged.
- Scope: capture exact themes/material rules, distinguish reference CRM content from the assistant product, map proposed layouts, and ensure the technology proposal remains unapproved pending design review. No UI implementation or new dependencies.
- Checks: source reviewed; required palettes/materials/layout shell distinguished from illustrative CRM content and adaptable measurements. Bilingual design and product changes reviewed, including top-bar search/actions/profile and single settings location. Original source hash, palette values, section/diagram/source parity, local links, whitespace, staged scope, and publication exclusions checked. No visual comparison or UI tests claimed.
- Result: mandatory Djarvis design captured in bilingual `docs/DESIGN` files and linked from product, architecture, and README. Technology candidates remain unapproved and subordinate to the owner's design. Original source preserved unchanged with a local Git exclusion; no UI code or dependencies added.
- Remaining work: review the Djarvis layout and design defaults before finalizing framework and implementation choices.
- Commit: `Align product and architecture with required visual design`.

## CORE-001 — Flutter decision and detailed planner-core design

- Date: 2026-11-03, Europe/Moscow.
- Agents: agent-01 designs the core; reference-review records the Flutter approval and aligns existing documentation; technical review/source checks delegated read-only.
- Authorization: owner accepted Flutter and requested a detailed discussion of planner core, data, and component interactions. This approves the UI framework, not application programming or all remaining architecture choices.
- Status: detailed proposal prepared; core approval pending.
- Files reserved: reference-review updated both decision registers, product definitions, architecture proposals, visual specifications, and README files and now translates `docs/architecture/PLANNER_CORE.ru.md`. Agent-01 reviews those changes and owns both logs and `docs/architecture/PLANNER_CORE.md`. Technical review of the core is read-only.
- Scope: record ADR-001 for Flutter UI and prepare a reviewable bilingual core design covering entities, recurrence, habits, time blocks, planning proposals, command policy, transactions, reminders, sync, and recovery. No application code or dependency installation.
- Checks: approved Flutter scope and three confirmed task rules reviewed against owner responses; technical review covered temporal identity, recurrence debt versus habit misses, stale plans, storage constraints, and provider outcomes. Local commits distinguished from queued/confirmed external work; manual start-only markers left explicitly undecided. Bilingual sections, sources, command identifiers, diagram flow, links, whitespace, and publication scope checked. No application tests or schema execution claimed.
- Result: ADR-001 records Flutter UI approval; existing documents aligned; bilingual detailed core proposal describes records, commands/queries, permissions, planning, transactions/outbox, reminders, provider reconciliation, history/recovery, and failure behavior. Four task priorities, separate overdue/missed-time indicators, and duration clarification are confirmed; remaining design choices remain proposals. No application code or dependencies added.
- Remaining work: owner review of proposed core rules and unresolved choices before implementation approval.
- Commit: `Document Flutter decision and detailed planner core design`.

## CORE-002 — Backend database and planner-rule follow-up

- Date: 2026-11-03, Europe/Moscow.
- Agents: agent-01 coordinates and verifies; reference-review updates bilingual requirements and core documentation.
- Authorization: owner selected PostgreSQL for the backend, confirmed manual placement locking, optional per-task splitting, distinct-day habit frequency, and a default 06:00–22:00 interval for date-only input. Owner requested an explanation of completion-relative recurrence.
- Status: requirements and database proposal updated; implementation approval pending.
- Files reserved: delegate will update both product definitions, core designs, architecture proposals, decision registers, and README files. Agent-01 uses both logs and coordinates the database deployment clarification. Existing visual design and source code stay untouched.
- Scope: record approved scope and resolve ambiguities about database placement, the date-only interval, and recurrence. No database installation, schema migration, or application code.
- Checks: owner clarified local PostgreSQL, original-anchor recurrence, and placement-only 06:00–22:00. Primary PostgreSQL sources and technical review covered transactions, concurrent plan validation, local lifecycle, backup consistency, and timezone preservation. Active SQLite assumptions replaced; bilingual documents, links, sources, identifiers, diagram flow, whitespace, and publication scope checked. No installation, database operation, or performance test performed.
- Result: ADR-002 records local PostgreSQL; manual blocks locked, splitting opt-in, distinct-day habit frequency, original recurrence dates, and independent placement window/deadline captured. Local deployment, transaction guard, backup/attachment coordination, and runtime requirements remain detailed proposals; core language is not implicitly selected.
- Remaining work: review core language, detailed schema/temporal defaults, local PostgreSQL lifecycle/packaging, and combined 8 GiB performance before implementation.
- Commit: `Select local PostgreSQL and refine planner semantics`.

## PLAN-001 — Resolve remaining work with selectable decisions

- Date: 2026-11-03, Europe/Moscow.
- Agents: agent-01 coordinates the cross-component plan; focused research/drafting is delegated where useful.
- Authorization: owner requested working through every remaining item and presenting questions as selectable answers with free-form input available.
- Status: design plan prepared and checked; unresolved choices await the owner.
- Files reserved: agent-01 owns both logs and `docs/architecture/REMAINING_PLAN.md`; reference-review updates both decision registers, product definitions, core proposals, architecture proposals, and README files for submitted choices. reference-review translates `docs/architecture/REMAINING_PLAN.ru.md`; agent-01 reviews the main plan and all changes. Rules, visual design, and source files remain unchanged.
- Scope: prepare concrete proposals and completion checks for architecture, local PostgreSQL, UI, planner features, voice, integrations/licensing, installer/validation, and later Android. Present decision cards in manageable batches; selected defaults are not approval until submitted.
- Checks: primary sources and requirements reviewed; an independent audit prompted explicit ambiguity, unknown mail result, offline-mode and split-task rules. Verified 11 new-plan sections, 33 decision IDs, 21 source URLs, local links across changed documents and whitespace. Rules and mandatory design remain unchanged. Application/performance tests were not run.
- Result: bilingual design plan covers all eight workstreams, components, failure paths, open decisions and completion evidence. ADR-003/004 and submitted answers are recorded in canonical documents. README links and context-recovery instructions are included. No programming or component installation.
- Remaining work: owner choices for unresolved decisions; full architecture and implementation approval remain separate.
- Commit: `Develop remaining design plan and record Python runtime choices`.

### PLAN-001 continuation checkpoint

- Submitted choices: Python core/background with packaged runtime; app-managed isolated local PostgreSQL without console; daily and pre-structure/migration backups, seven-day default retention, configurable. Recorded in ADR-003/004 and synchronized product/core documents.
- Further submitted choices: ask for time on every explicit deadline entered with a date only; global advanced-field display plus per-task expansion; habit week starts Monday, pauses exclude days and freeze streaks, corrections preserve history. Partially paused flexible-week quota and exact streak definitions remain open.
- Prepared review artifact: `docs/architecture/REMAINING_PLAN.md` / `.ru.md`, workstreams A–H with proposed components, data/command boundaries, failure paths, open IDs and acceptance evidence. Recommendations are not approvals.
- Pending selectable batch: F5 offline license-file purchase/account model; F6 seven-day trial start; F8 renewal/deletion/backup access after expiry. No submitted answers yet at this checkpoint; recommended selections are not consent.
- Owner requested re-reading project files after context shortening. Recovery order: local entry instructions/rules → active shared log → approved ADRs/product/design → relevant architecture/core/remaining plan → working-tree changes and file ownership. Continue existing work; do not infer missing answers or coding permission.
- Current ownership: agent-01 reviews/finishes the plan, canonical documentation and both logs; reference-review has completed the Russian translation; source research and review have finished read-only. Keep the local entry files, original design, voices, cache and secrets outside publication.

## PLAN-002 — Licensing and planner choices

- Date: 2026-11-03, Europe/Moscow.
- Agent: agent-01 coordinates and verifies; bilingual canonical updates are delegated.
- Authorization: owner submitted F5, F6 and F8: local profile without mandatory account, imported signed license file with offline verification; seven-day trial starts on first use of any product function, not setup/download waiting; expired state permits renewal/import, deletion and automatic backups, while planner/assistant are locked and microphone/proactive speech stopped.
- Status: documentation completed; unresolved design choices await the owner.
- Files reserved: agent-01 owns both logs and the English remaining plan; architecture-sources synchronizes the Russian remaining plan; reference-review owns both README, product, decision-register, architecture-proposal and planner-core files. No rules, design, application source or local assets are changed.
- Scope: record the accepted choices, remove superseded open questions, preserve unresolved payment/cryptography/device-policy details, and present the next selectable batch with free input.
- Checks/result/commit: recorded in the PLAN-002 result section below.
- Continuation: this entry supersedes the PLAN-001 checkpoint's pending F5/F6/F8 batch. Those three choices are accepted, not questions to repeat. Next cards have been sent for D1 title-only creation/default priority, D1 manual start without duration, and D3 missing monthly dates; no answers to that batch have been submitted yet. Each card permits free text. No programming is authorized.
- Subsequent submitted answers supersede the pending D1/D3 batch above: creation requires title and explicit priority, with other fields optional; a manual start without duration is a start-only marker, not a busy interval, and automatic planning asks duration; missing monthly dates are configurable per recurrence, defaulting to the last day, with skipping available and the original anchor preserved. Extend this documentation task to record these choices in product/core/plan; no coding approval.
- Further submitted D4/D5: when a pause leaves fewer eligible distinct days than the flexible weekly quota, the week is paused without a miss or streak break and the goal is not reduced; fixed schedules count streaks in successful scheduled days, flexible schedules in successful weeks; corrections are allowed for any past date within the habit's lifetime, retain correction history and recompute using the historical goal. Record these accepted behaviors before issuing the next batch.

### PLAN-002 result and continuation

- Status: documentation completed and verified; architecture/programming approval remains pending.
- Result: all nine submitted answers (F5/F6/F8 and D1/D3/D4/D5) recorded in the canonical English/Russian documents and remaining plan; ADR-005 records the limited license/access decision. No mandatory subscription account, silent normal priority, unresolved accepted habit rules or old pending cards remain in the current design descriptions.
- Checks: reviewed the nine answers against both languages; six document pairs match on section counts, decision IDs and source links; local links and whitespace pass. Publication file set and outgoing metadata are checked before push. Rules/design/source/local assets are unchanged; no application tests were run.
- Remaining/next batch: D2 travel/timezone policy; D6 split-task completion and break defaults. These choices have not been answered. Exact cryptography/payment/clock/device policy, schema, runtimes and other unaccepted architecture remain open; no app implementation authorized.
- Commit: `Record offline licensing and planner choices`.

## PLAN-003 — Timezones, split completion and breaks

- Date: 2026-11-03, Europe/Moscow.
- Agent: agent-01 coordinates/reviews; reference-review synchronizes documentation.
- Authorization: owner submitted D2 and two D6 choices: each habit/personal recurrence chooses local-time or original-zone behavior, unset policies are clarified on timezone change; only a separate Complete Task command completes a split task, segment check-offs show progress; automatic breaks require user-configured duration and frequency, with no automatic breaks before configuration.
- Status: documentation completed and verified; remaining design choices await the owner.
- Files reserved: agent-01 owns both shared logs; reference-review owns PRODUCT, PLANNER_CORE and REMAINING_PLAN in both languages. No overlapping work, rule/design changes, app code, dependency installation or local asset changes.
- Scope: record these behavioral approvals, remove resolved questions while retaining unapproved segment limits and timezone/schema mechanics, and prepare the next selectable batch with free input.
- Checks: verified three bilingual document pairs for section counts, decision IDs and source URLs; checked local links and whitespace. Reviewed timezone scope, selected-occurrence completion, proposed API naming and unset-break behavior. Rules/design/app code/assets are unchanged; no application tests were run.
- Result: D2 accepted policy and partially accepted D6 behavior are recorded in PRODUCT, PLANNER_CORE and REMAINING_PLAN on both languages. Unapproved segment/timezone mechanics remain explicit. Future acceptance cases and recovery handoff updated.
- Commit: `Record timezone, split completion and break policies`.
- Continuation checkpoint: D2 policy and D6 completion/break behavior are accepted; D6 segment limits/buffers and exact timezone transitions remain open. A split-task completion applies only to the selected occurrence; segment check-offs never complete it automatically. Next batch is prepared for A2 task-change permission scope/revocation, E5 missed-reminder catch-up and F9 no-internet behavior; none has been answered. No coding approval.

## PLAN-004 — Task grants, catch-up reminders and offline functions

- Date: 2026-11-03, Europe/Moscow.
- Agent: agent-01 coordinates/reviews; reference-review updates bilingual specifications.
- Authorization: owner submitted A2 action-specific revocable task grants (create, edit, move, complete, delete), E5 one catch-up summary with speech only when settings/quiet hours/current situation permit, and F9 all local sections, reminders, voice and conversation available offline under valid trial/license.
- Status: documentation completed and verified; remaining choices await the owner.
- Files reserved: agent-01 owns both logs; reference-review owns PRODUCT, PLANNER_CORE and REMAINING_PLAN in both languages. Other files and local assets are not edited.
- Scope: record the three choices, remove superseded open questions, preserve mandatory confirmations and entitlement/resource limits; prepare next voice/initiative/microphone decision cards. No application code or dependency changes.
- Checks: three bilingual pairs match on section counts, decision IDs and source URLs; local links and whitespace checked. Reviewed grants vs mandatory confirmations, catch-up gates and offline/provider boundaries. Read-only architecture-proposal review found no material contradiction. Rules/design/code/assets unchanged; no application tests run.
- Result: A2/E5/F9 recorded in both product/core/remaining-plan versions and removed from unresolved choices; future checks and context handoff updated. E6 explicitly identifies the remaining microphone-persistence question.
- Continuation: this supersedes the PLAN-003 pending A2/E5/F9 batch. Next prepared cards are E2 dialogue idle/English stop defaults, E3 initiative at onboarding and E6 microphone-mute persistence. None has been answered. Technical implementation, performance, providers and other unaccepted architecture remain open; no programming approval.
- Commit: `Record task grants, catch-up and offline behavior`.

## PLAN-005 — Dialogue, initiative and microphone restart defaults

- Date: 2026-11-03, Europe/Moscow.
- Agent: agent-01 coordinates/reviews; reference-review updates bilingual specifications.
- Authorization: owner submitted E2 thirty-second wait for the next reply and stop commands “Хватит”/“Stop”; E3 offer initiative setup at first launch, with proactive speech off until a choice; E6 restart resumes listening if Windows allows it, rather than preserving manual mute across application/Windows restart.
- Research: architecture-sources checks primary Windows call/game/idle detection documentation read-only to prepare honest E4 options; no detection stack or universal-coverage claim is approved.
- Status: documentation completed and verified; remaining choices await the owner.
- Files reserved: agent-01 owns both logs; reference-review owns PRODUCT, PROPOSAL and REMAINING_PLAN in both languages. Other files, rules, design, application code and local assets are unchanged.
- Scope: record defaults and approval boundaries; keep timeout distinct from active processing/speech, dialogue end distinct from mic mute, same-host window reopening distinct from application restart, and respect expired entitlement/OS denial. Prepare next quiet-hours/detection questions, with free input.
- Checks: three bilingual pairs checked for heading counts, IDs, source URL equality, local links and whitespace. Verified the selected restart behavior (not the recommended persistent mute), dialogue/wake separation, first-launch consent and expired/OS-denied gates. Primary Windows documentation supports E4 heuristic limits; no implementation/performance tests run.
- Result: E2/E6 accepted and E3 partly accepted are recorded in PRODUCT, PROPOSAL and REMAINING_PLAN in both languages, with future checks and current handoff. Rules/design/code/assets unchanged.
- Continuation: supersedes pending E2/E3/E6 from PLAN-004. Next prepared choices: E3 quiet-hours defaults; E4 call/game detection approach and input-idle threshold. No answers yet; detection implementation, exact triggers, voices and remaining architecture stay open. No coding approval.
- Commit: `Record dialogue, initiative and microphone restart defaults`.

## PLAN-006 — Quiet hours, context detection and return threshold

- Date: 2026-11-03, Europe/Moscow.
- Agent: agent-01 coordinates/reviews; reference-review synchronizes bilingual specifications.
- Authorization: owner selected E3 quiet-hours setup as an explicit local-time schedule or explicit “no quiet hours”; E4 system signals plus a user-selected application list and manual quiet mode; thirty-minute keyboard/mouse session-idle threshold for the enabled return trigger, configurable.
- Status: documentation completed and verified; remaining choices await the owner.
- Files reserved: agent-01 owns both logs; reference-review owns PRODUCT, PROPOSAL and REMAINING_PLAN in both languages. No other files or local assets are edited.
- Scope: record approved policies while retaining heuristic limits and unselected implementation details; preserve initiative opt-in, OS/entitlement gates and manual-mute restart behavior. Prepare selectable backup/history questions with free input; no programming or installation.
- Checks: verified three bilingual pairs for headings, decision IDs, source URLs, local links and whitespace; reviewed opt-in, manual/OS/access gates, heuristic limits and the per-session idle definition. No application/performance tests run; rules/design/code/assets unchanged.
- Result: E3 quiet-hours policy and E4 approach/threshold recorded in PRODUCT, PROPOSAL and REMAINING_PLAN on both languages; exact detection, cooldown and trigger implementation remain open. E7 defines the still-unselected default history retention. Future checks and context handoff updated.
- Continuation: supersedes pending quiet-hours/E4 choices from PLAN-005. Next prepared cards are B1 automatic-backup default location, B3 conversation history in backups/deletion, and E7 conversation-history default retention. None is answered. No coding approval.
- Commit: `Record quiet-hours and context detection policies`.

## PLAN-007 — Backup destination and conversation retention

- Date: 2026-11-03, Europe/Moscow.
- Agent: agent-01 coordinates/reviews; reference-review updates bilingual specifications.
- Authorization: owner selected B1 separate configurable local application backup folder outside the working database; B3 conversation history included in automatic backups, with affected copies shown for confirmed recreation or deletion when history is deleted; E7 thirty-day default conversation-history retention, still configurable/disableable/erasable.
- Status: documentation completed and verified; remaining choices await the owner.
- Files reserved: agent-01 owns both logs; reference-review owns PRODUCT, PLANNER_CORE, PROPOSAL and REMAINING_PLAN in both languages. No other files, source, rules, design or local assets are changed.
- Scope: record selected inclusion (not recommended exclusion), keep seven-day backup retention distinct from thirty-day conversation retention, and preserve open encryption/restore/automatic-expiry mechanics. Prepare selectable protection/recovery questions; no actual backup/database/file deletion or application implementation.
- Checks: four bilingual pairs match on headings, IDs and source URL sets; local links/whitespace checked. Reviewed inclusion of history, user-confirmed archive handling, distinct 7/30-day policies and honest erasure/restore limits. Rules/design/code/assets unchanged; no application tests run.
- Result: B1/E7 accepted and B3 partly accepted recorded in all four specification pairs; future checks and handoff updated. Encryption, recovery and automatic-expiry/archive mechanics remain open.
- Continuation: supersedes pending B1/B3/E7 in PLAN-006. Next prepared cards: B2 backup encryption and separate recovery key, B3 full/selective restore. No answers submitted; no coding approval.
- Commit: `Record backup location, history inclusion and retention`.

## PLAN-008 — Windows-protected backup keys and full restore

- Date: 2026-11-03, Europe/Moscow.
- Agent: agent-01 coordinates/reviews; reference-review records bilingual decisions/specifications.
- Authorization: owner selected B2 encryption with a Windows-protected key, no separate password and no additional recovery key; B3 full snapshot restoration after preview and a backup of current data. This supersedes password/portable-key proposals within that scope.
- Status: documentation completed and verified; remaining choices await the owner.
- Files reserved: agent-01 owns both logs; reference-review owns DECISIONS, PRODUCT, PLANNER_CORE, PROPOSAL and REMAINING_PLAN in both languages. Other files, rules, design, source and local assets are unchanged.
- Scope: record a narrowly scoped ADR and synchronize approved choices; retain exact crypto/API/key scope/archive format, failure handling and history-expiry details as open. Explain lack of guaranteed recovery/portability without accessible Windows-protected key, without claiming every Windows configuration is identical. Prepare next selectable decisions; no actual encryption/restore/database operations or programming.
- Checks: five bilingual pairs checked for heading counts, IDs, source URL equality, local links and whitespace. Reviewed no-password/no-extra-recovery-key policy, limited ADR scope, full-restore prerequisites, preserved trial/license boundaries and lack of guaranteed portability without the key. Rules/design/code/assets unchanged; no encryption, restore or application tests run.
- Result: ADR-006 records the approved key/restore direction; product, core, proposal and remaining-plan versions are synchronized. Exact cryptography/key scope/format and failure handling remain open; misleading portable-backup wording removed.
- Continuation: supersedes pending B2/full-restore cards from PLAN-007. Next prepared choices are B3 automatic history-expiry handling in managed copies, F1 calendar export scope and F2 provider deletion handling; no answers submitted. No coding approval.
- Commit: `Record protected backup keys and full restore policy`.

## PLAN-009 — Archive expiry and calendar synchronization policies

- Date: 2026-11-03, Europe/Moscow.
- Agent: agent-01 coordinates/reviews; reference-review synchronizes bilingual specifications.
- Authorization: owner selected B3 retaining automatically aged conversation history until the backup itself expires, applying the current history-retention policy at restore; F1 selected-calendar events/task time blocks, habits only after separate opt-in; F2 confirmation before removing a locally unchanged event deleted by Google Calendar/Outlook.
- Status: documentation completed and verified; remaining choices await the owner.
- Files reserved: agent-01 owns both logs; reference-review owns DECISIONS, PRODUCT, PLANNER_CORE, PROPOSAL and REMAINING_PLAN in both languages. Other files, rules, design, source and local assets are unchanged.
- Scope: distinguish automatic age expiry from explicit history erasure; preserve current restore policy, manual archive confirmation, independent tasks/habits, two-sided conflict choice, provider/local status and offline gates. Prepare selectable mail/device questions; no real archive/calendar changes or code.
- Checks: five bilingual pairs checked for headings, IDs, source URL sets, local links and whitespace. Review added explicit F1/F2 core policies and corrected the translated B3 label, then all checks passed. Verified retention/manual-erasure separation, export scope and confirmation/conflict boundaries. Rules/design/code/assets unchanged; no app/provider/restore tests run.
- Result: B3 expiry policy and F1/F2 sync policies recorded in product/core/proposal/remaining-plan documents, ADR-006 consequences updated. Runtime/format/projection/deletion-execution details remain unapproved; future checks and handoff updated.
- Continuation: supersedes pending B3/F1/F2 from PLAN-008. Next prepared cards: F3 separate Gmail read/draft/send permissions; A3 application-launch permission; A3 disruptive Windows actions. None is answered; no coding approval.
- Commit: `Record archive expiry and calendar sync policies`.

## PLAN-010 — Gmail bundle and device-action confirmations

- Date: 2026-11-03, Europe/Moscow.
- Agent: agent-01 coordinates/reviews; reference-review updates bilingual specifications.
- Authorization: owner selected F3 one Gmail switch bundling read/search, drafts and send, with confirmation for every send unchanged; A3 user-selected revocable application allowlist permits launches without repeated confirmation; shutdown, restart and Windows-account logout always require confirmation.
- Status: documentation completed and verified; remaining choices await the owner.
- Files reserved: agent-01 owns both logs; reference-review owns PRODUCT, PLANNER_CORE, PROPOSAL and REMAINING_PLAN in both languages. Other files, rules, design, source and local assets are unchanged.
- Scope: record the selected bundled permission (not granular UI switches), approved launch scope and three mandatory Windows confirmations; preserve task/file/habit/mail boundaries and OS gates. Leave exact provider scopes, cache, executable/argument identity and other device actions open. Prepare selectable appearance defaults; no real mail/device actions or programming.
- Checks: four bilingual pairs verified for heading counts, card IDs, source URL sets, local links and whitespace. Reviewed explicit core matrix/body and removal of granular-Gmail contradictions; preserved capability gate for other device actions. Rules/design/code/assets unchanged; no real mail/device actions or application tests run.
- Result: bundled F3 policy and scoped A3 launch/Windows confirmation policies recorded in product/core/proposal/remaining-plan versions. Exact scopes/cache/application identity/arguments and other device actions remain open; future checks and handoff updated.
- Continuation: supersedes pending F3/A3 cards in PLAN-009. C1 default palette/material and C2 density are prepared and unanswered. Owner requested a structured project status during this task; provide it after saving these decisions. No coding approval.
- Commit: `Record Gmail bundle and device confirmation policies`.

## PLAN-011 — Detailed remaining component design plan

- Date: 2026-11-03, Europe/Moscow.
- Agent: agent-01 owns architecture outline, review, indexes and logs; reference-review drafts bilingual component plan; architecture-sources audits gap coverage read-only.
- Authorization: owner requested a detailed written plan of the remaining insufficiently designed components and its presentation in chat.
- Status: detailed plan completed and verified; technical design and implementation approvals remain open.
- Files reserved: agent-01 owns both logs, README pair and REMAINING_PLAN pair; reference-review owns new COMPONENT_PLAN.md/.ru.md under docs/architecture. Other canonical requirements, rules, design, source and local assets remain unchanged.
- Scope: decompose the remaining work into 20 stable component IDs with known baseline, specific open design tasks, dependencies, deliverables, future acceptance evidence and owner-decision boundaries. Preserve all submitted choices, full scope and separate approval before experiments/programming. No implementation, downloads or app tests.
- Checks: reviewed all 20 English sections and critical Russian policies; three bilingual pairs checked for heading/ID/source sets, exactly CP01–CP20, local links and whitespace. Read-only gap audit confirmed coverage and six cross-component invariants. Review clarified 30-second dialogue baseline, calendar-vs-mail scope, early feasibility/UX/testing, reciprocal dependencies and reuse of existing authorization. Canonical requirements/rules/design/source/assets remain unchanged; no app tests or downloads.
- Result: COMPONENT_PLAN.md/.ru.md define baseline, open work, dependencies, deliverables, future acceptance cases and owner/agent decisions for 20 components; README and remaining-plan links/handoff updated. No new product or technology choice is approved.
- Continuation: owner reviews the component plan; coordinate CP01–CP04 foundations with early CP08–CP10/CP20 feasibility and CP17 user journeys, then domain/integrations/delivery groups. Previously prepared C1/C2 choices are still unanswered, not a mandatory question queue. Application coding needs an approved architecture/implementation plan; existing bounded authorization remains valid.
- Commit: `Plan remaining component design and approval gates`.

## PLAN-012 — Detailed design of components CP01–CP20

- Date: 2026-11-03, Europe/Moscow.
- Agent: agent-01 coordinates architecture, integration and verification; architecture-sources prepared the foundation/canonical updates; reference-review prepared the assistant dossier, reviewed delivery and researched provider constraints. Delegated file ownership is released.
- Basis: the owner requested detailed work on every component, necessary selectable questions with custom input, and regular consultation of the history in Plan. Submitted answers and the supplied visual brief v2.1 extend the documented requirements without changing project rules.
- Status: design proposals completed, checked and published; remote main verified. Architecture/implementation approval and remaining product choices are still open.
- Files: both logs and README; bilingual DESIGN, PRODUCT, COMPONENT_PLAN, DECISIONS, PLANNER_CORE, PROPOSAL and REMAINING_PLAN; new bilingual FOUNDATION_DESIGN, ASSISTANT_DESIGN and DELIVERY_DESIGN. Rules and application code are unchanged.
- Scope: concrete proposed contracts for all 20 components, process/command/data boundaries, scheduler and time semantics, local model/audio/provider workflows, Windows capabilities, archive/recovery, entitlement, UI, delivery, Android alternatives and future acceptance. No app coding, database operations, installation, model downloads or personal-data actions.
- Accepted answers: earliest deadlines then priority, no-deadline tasks by priority; explicit completion releases only remaining future blocks of the selected occurrence and preserves history; DST gaps/folds require confirmation of valid time choices (ADR-007). Initial Midnight Electric + Glass; compact uncrowded density and motion guidance from local design/Djarvis_UI_Design_v2_1_.txt. Monthly and annual subscriptions; app updates notify only and download/install by user command; original microphone audio remains in RAM for current recognition and is never recorded to disk, including diagnostics.
- Checks: main reviewed the three dossiers and canonical changes; corrected OS-mic denial versus planner availability, ADR approval attribution, history/backup boundaries, stale unanswered statuses and provider constraints. Twelve language pairs passed heading, component/decision-ID and source-URL set checks; local links and whitespace checked. Exact 24-file staging, full staged-tree publication/secret scans and outgoing commit metadata passed; publication was verified against remote main. App builds/tests/benchmarks were not run; CPU/8 GiB and voice rights remain unverified.
- Source preservation: v2.1 SHA-256 73942d0aa7be9e70d61ed39f77a734183f9c59a0fc8b4d706bbc7a92b55d158c; originals remain local and unchanged, excluded from publication with local instructions, voice references, weights/cache and secrets.
- Result: three bilingual design dossiers cover CP01–CP20; accepted policies are synchronized with canonical documents, and recommendations remain distinguishable from approval. Provider candidates and commercial/credential/privacy constraints are recorded; browser handoff alone does not fulfill automatic in-app research.
- Handoff: before every next question group consult current rules, both shared logs and relevant canonical documents; after compaction reread them to restore context. Plan currently contains bilingual work logs, not a separate full chat export. Next owner choices include overdue placement, habit measurement/abstinence, parent/subtask completion, external-service account/cost constraints and remaining commercial/device policy. Internal runtime/schema/transport/crypto details still require final review and authorized feasibility evidence. No application implementation is approved.
- Commit: [92d0940 — Specify component contracts and record owner choices](https://github.com/SwanThunder/Djarvis/commit/92d094071fb761a2cd53c6cacfc4bf586fdd986e).

## PLAN-013 — Overdue tasks, abstinence and parent completion

- Date: 2026-11-04, Europe/Moscow.
- Agent: agent-01 completes and reviews the partial documentation prepared by architecture-sources after its run ended; no concurrent writer.
- Authorization: owner's explicit overdue/abstinence choices and both parent-completion clarification answers.
- Status: documentation completed, checked and published.
- Files: both logs; PRODUCT, PLANNER_CORE, FOUNDATION_DESIGN, REMAINING_PLAN and DECISIONS in English and Russian.
- Scope: record the three accepted behaviors as ADR-008 and FD14–FD16; preserve independent active children, historical corrections and existing confirmation rules. No application code, database changes, model downloads or application tests.
- Checks: six language pairs checked for matching headings/decision IDs, local links and UTF-8; whitespace check passed. Reviewed the accepted behaviors against submitted answers. Application tests were not run because no implementation changed.
- Remaining: quantity/duration measurement, subtask nesting/inheritance, external-service costs/accounts and license/device details; architecture and implementation still need approval.
- Commit: [d6bd77d](https://github.com/SwanThunder/Djarvis/commit/d6bd77d8afd96d64be8d59f2678857dfa53a10ca).

## PLAN-014 — Habit measurement and subtask nesting
- Date: 2026-11-04, Europe/Moscow.
- Agent: agent-01.
- Authorization: owner's three explicit measurement/nesting choices.
- Status: completed and checked; documentation only.
- Files: both logs and bilingual PRODUCT, FOUNDATION_DESIGN, DECISIONS and REMAINING_PLAN.
- Scope: record per-habit quantity modes, duration timer/manual input and multi-level subtasks. Preserve prior completion and correction policies; no implementation.
- Checks: five bilingual pairs, decision IDs and local links checked; no application tests (documentation only).
- Remaining: timer interruption behavior, field inheritance and mode switching; implementation requires approval.
- Commit: [ef85f2f](https://github.com/SwanThunder/Djarvis/commit/ef85f2f66cbc1f55f32544037577ff6316cdb570).

## PLAN-015 — Timer sleep policy, quantity-mode changes, and child defaults

- Date: 2026-11-04, Europe/Moscow.
- Agent: agent-01 coordinates and reviews; record-plan015 prepared documentation and released the files.
- Authorization: owner confirmed that duration timers keep counting through sleep, full app exit, and computer shutdown until explicitly paused/stopped; elapsed time is shown on resume and split at local midnight by day. Owner also confirmed immediate current-day quantity-mode switching after recalculation preview, and parent project/priority proposals with explicit confirmation for new children; child deadlines remain independent and future parent changes do not propagate.
- Status: complete; documentation reviewed.
- Files: both work logs and bilingual PRODUCT, FOUNDATION_DESIGN, PLANNER_CORE, DECISIONS, and REMAINING_PLAN. Documentation only; no app code, tests, staging, commit, or push.
- Scope: update accepted rules and supplement ADR-009; preserve prior requirements. Full-exit/shutdown behavior and midnight allocation are resolved as above; timestamp reconciliation, clock/timezone changes, manual/timer overlap, and crash recovery remain technical questions.
- Checks: reviewed all 12 changed files, checked English/Russian policy parity and stale open-question wording, and ran `git diff --check` successfully. No application tests were run because no code changed.

- Final review: agent-01 checked six language pairs, decision IDs and local links. Scope includes both follow-up answers: count full exit/shutdown until explicit pause/stop and split time at midnight. Root handles commit/publication after review; delegate performed neither.
- Commit: [acd97fd](https://github.com/SwanThunder/Djarvis/commit/acd97fd647a755d4547a9aa6c1632c526319707c).

## PLAN-016 — Project status summary, dashboard layout brief review, first owner question batch

- Date: 2026-11-04, Europe/Moscow.
- Agent: agent-02.
- Authorization: owner requested (1) a bilingual project status summary, (2) the first batch of selectable owner questions on open items, and (3) a review of the new local dashboard layout brief.
- Status: documentation complete and checked; published.
- Files reserved: both work logs; new `docs/STATUS.md`, `docs/STATUS.ru.md`, `docs/architecture/DASHBOARD_LAYOUT_REVIEW.md`, `docs/architecture/DASHBOARD_LAYOUT_REVIEW.ru.md`; link lines in `README.md` / `README.ru.md`; local `.git/info/exclude` (not published). Original brief `design/Djarvis_Main_Dashboard_Layout_Architecture_v1_0.txt` stays read-only. Other canonical documents change only if submitted answers require it.
- Scope: documentation only. No application code, installation, downloads or database operations. Layout review is a comparison against `docs/DESIGN.md`; adopting its points into the mandatory design requires owner confirmation.
- Pre-check: no active entries; latest task PLAN-015 complete and published. This agent has file transfer access only and cannot run Git on the owner's machine; working-tree state was judged by file timestamps against the last commit.
- Owner answers (layout brief): keep the assistant circle above the brief's grid (grid = day panel); one floating microphone button with two actions (press = invoke, secondary = mute/unmute); press opens the overlay and listens immediately without the wake phrase; when capture is impossible the button stays visible in an unavailable state with the reason.
- Result: new bilingual `docs/STATUS` and `docs/architecture/DASHBOARD_LAYOUT_REVIEW`; accepted choices added to bilingual DESIGN (new main-screen layout section) and PRODUCT (PLAN-016 section); README pair links both new documents. Brief SHA-256 `b8a782015dfa3434dda0f02e500e0d6c2224a41221847d2e6b2d1e0bf27aaa0d` is NOT yet in the local publication exclusion list: remote tools may not write to `.git`; an agent with Git access must add `/design/Djarvis_Main_Dashboard_Layout_Architecture_v1_0.txt` to `.git/info/exclude`. Original unchanged.
- Checks: heading parity of four language pairs (STATUS 6/6, review 9/9, DESIGN 11/11, PRODUCT 15/15) and L1–L7 IDs in both review versions; local links resolve against the repository tree; no development-tool names in changed files; no trailing whitespace in new files. `git diff --check`, staging review and publication scan were not run because this agent has no Git access on the owner's machine. No application tests (documentation only).
- Remaining: commit and push by an agent with Git access after reviewing the exact staged set (exclude the brief and local entry files). Owner choices: L2a secondary gesture, L6 top-bar functions, L7 card mapping with DD09, and the open items listed in `docs/STATUS.md`.
- Commit: [62d7347](https://github.com/SwanThunder/Djarvis/commit/62d7347).

## SKILLS-001 — Exclude local skill sources and the layout brief from publication

- Date: 2026-11-04, Europe/Moscow.
- Agent: agent-02.
- Authorization: owner granted access to resolve the publication conflict for the local `Skills/` folder and confirmed that no mention of the development tools may be published.
- Status: complete; published.
- Files: `.gitignore`, both work logs.
- Scope: ignore `/Skills/` (local skill sources mention development tools) and `/design/Djarvis_Main_Dashboard_Layout_Architecture_v1_0.txt` (owner original whose text names a development tool). The ignore entries themselves contain no tool names. `.git/info/exclude` cannot be written by this agent; `.gitignore` is used instead. Supersedes the PLAN-016 note that the brief still had to be excluded.
- Checks: `.gitignore` unchanged on disk since the last commit before editing; new lines contain no tool names. `git status`/`git check-ignore` not run (no Git access).
- Remaining: commit together with PLAN-016 by an agent with Git access; verify with `git check-ignore -v Skills design/Djarvis_Main_Dashboard_Layout_Architecture_v1_0.txt` that both are ignored and that neither is already tracked.
- Commit: [62d7347](https://github.com/SwanThunder/Djarvis/commit/62d7347).

## PLAN-017 — Main-screen open items and project rule amendment

- Date: 2026-11-04, Europe/Moscow.
- Agent: agent-02.
- Authorization: owner answers to a selectable batch: mute via right-click/menu-key menu on the floating button; top bar with day selector, quick create and notifications (no profile); card mapping from the layout review accepted as written; record the skill-storage rule in the project rules. The owner also confirmed that no mention of the development tools may be published.
- Status: documentation complete and checked; published.
- Files: both logs; bilingual `docs/PROJECT_RULES`, `docs/DESIGN`, `docs/PRODUCT`, `docs/STATUS`, `docs/architecture/DASHBOARD_LAYOUT_REVIEW`.
- Scope: resolve L2a, L6 and L7; add rules section 14 (agent skills stored in local `Skills/`, excluded from version control) and tighten section 9 wording (no mention of development tools or the AI assistants used for development in published files, paths, commit messages or metadata). Rule changes are by explicit owner approval. No application code.
- Checks: heading parity of five language pairs (PROJECT_RULES 15/15, STATUS 6/6, DESIGN 11/11, PRODUCT 15/15, review 9/9); no tool names in changed files; stale open-item wording removed from STATUS and the review. Git checks not run (no Git access).
- Remaining: navigation grouping and labels (DD09); commit PLAN-016, SKILLS-001 and PLAN-017 by an agent with Git access.
- Commit: [62d7347](https://github.com/SwanThunder/Djarvis/commit/62d7347).

## PLAN-018 — License device limit, transfer, clock rollback; commit preparation

- Date: 2026-11-04, Europe/Moscow.
- Agent: agent-02.
- Authorization: owner answers: up to three devices per license; hardware-independent license file; 48-hour clock-rollback tolerance, then block; payment deferred. Owner asked to complete the pending commit together.
- Status: documentation complete and checked; committed and published.
- Files: both logs; bilingual `docs/architecture/DECISIONS` (ADR-010), `docs/PRODUCT`, `docs/STATUS`; local ignored helper `tmp/commit-plan016-018.ps1`.
- Scope: record ADR-010 and sync product/status; prepare one commit for PLAN-016, SKILLS-001, PLAN-017 and PLAN-018. This agent cannot push (no repository write access) and cannot run Git on the owner's machine.
- Checks: in a clean clone of `origin/main` (72f96b3) with these 17 files applied: `git diff --check` passed; `Skills/` and the layout brief are ignored and untracked; no development-tool names in added lines or the commit message; ADR count 10/10 in both registers.
- Remaining: run the script; record the resulting commit hash here. Open: price, license issuer, payment, voices, providers, DD09.
- Commit: [62d7347](https://github.com/SwanThunder/Djarvis/commit/62d7347).

## PLAN-019 — Personas, search/weather, navigation, device confirmations, backup folder

- Date: 2026-11-04, Europe/Moscow.
- Agent: agent-02.
- Authorization: owner answers in two selectable batches; owner asked to complete the remaining list autonomously.
- Status: documentation complete and checked; published.
- Files: both logs; bilingual `docs/architecture/DECISIONS` (ADR-011–013), `docs/PRODUCT`, `docs/DESIGN`, `docs/STATUS`, `docs/architecture/DASHBOARD_LAYOUT_REVIEW`; ignored helper `tmp/commit-plan016-019.ps1`.
- Scope: ADR-011 — original personas replace third-party characters and actor voices; `Vois/join-5tracks.mp3` (72 s mono speech, no source metadata) stays a local personal reference only. ADR-012 — search with a user-owned API key, browser handoff without one; MET Norway weather; price and license issuance deferred with payment. ADR-013 — personas Edward, Professor Volt, Nova; sidebar order; confirmation for closing programs, sleep and lock; default backup folder `Documents\Djarvis Backups`.
- Not done: feasibility checks and runs on the owner's machine — no console on the owner's computer (local command tool fails on a missing `AppData\Roaming\npm` folder; folder access to fix it was refused by the safety system). Push is not possible from this agent (no repository write access).
- Checks: in a clean clone of `origin/main` with the changed files: `git diff --check` passed; no development-tool names in added lines or the commit message; ADR count 13/13 in both registers; local-only paths ignored.
- Remaining: run `tmp/commit-plan016-019.ps1`; voice model selection, search provider, live-data protection, BYOK plan, technical finalization, feasibility checks, final architecture and implementation plan.
- Commit: [62d7347](https://github.com/SwanThunder/Djarvis/commit/62d7347).

## PLAN-020 — Speech engines, search provider, live-data protection

- Date: 2026-11-04, Europe/Moscow.
- Agent: agent-02.
- Authorization: owner answers after a researched selectable batch.
- Status: documentation complete and checked; published.
- Files: both logs; bilingual `DECISIONS` (ADR-014), `PRODUCT`, `STATUS`.
- Scope: Vosk TTS (ru) + Kokoro (en) with voices per persona; Tavily with the user's key; Windows-account ACL plus BitLocker recommendation for live data. Research sources: Piper license change (active engine GPL-3.0), Silero non-commercial license, Vosk TTS and Kokoro Apache-2.0 weights, Tavily and Brave current pricing.
- Not done: feasibility measurements on the owner's machine (no console: the local command tool must be restarted with the desktop app after the npm folder fix; terminals cannot be typed into through screen control).
- Checks: ADR count 14/14 in both registers; Git checks repeated before commit.
- Remaining: technical finalization (transport, schema, cryptography, migrations, packaging), feasibility checks, final architecture and implementation plan.
- Commit: [62d7347](https://github.com/SwanThunder/Djarvis/commit/62d7347).

## PLAN-021 — Publication of PLAN-016–020 and feasibility checks

- Date: 2026-11-04, Europe/Moscow.
- Agent: agent-02.
- Authorization: owner asked to proceed autonomously after restarting the local command tool; downloads approved explicitly (speech ~0.8 GB, PostgreSQL zip ~0.3 GB, Python embeddable ~0.01 GB) into ignored `cache/feasibility/`.
- Status: complete; published.
- Files: both logs; new bilingual `docs/architecture/FEASIBILITY`; bilingual `docs/STATUS`. Local only: `cache/feasibility/` (venv, models, PostgreSQL and Python archives, samples, scripts, results).
- Publication: PLAN-016–020 published as 62d7347, journal hash record as b0bf375. The prepared script first stopped safely on its own bug (`git check-ignore -q` with two paths); fixed and rerun.
- Scope: CPU-only model run with the existing model; Vosk TTS 0.7 and Kokoro int8 speed/memory with per-persona samples; PostgreSQL 18.6 zip binaries without service/admin; Python 3.12.10 embeddable. Vosk 0.9 (746 MB) was not downloaded because it exceeded the approved size. Calling the runtime CLI started the installed runtime's desktop app; the model was unloaded afterwards. The temporary database password was random and discarded.
- Checks: results recorded in FEASIBILITY with eight design findings; Git checks before commit.
- Remaining: speech recognition and wake phrase; real 8 GiB machine; Vosk 0.9 listening; GPL phonemizer review; technical finalization and the final architecture and implementation plan.
- Commit: this entry is published with the feasibility report.

## PLAN-022 — Vois exclusion, speech recognition check, technical details and final plan

- Date: 2026-11-04, Europe/Moscow.
- Agent: agent-02.
- Authorization: owner asked to finish the remaining status items: exclude `Vois/` from Git, check speech recognition and the wake phrase, listen to Vosk 0.9, review the espeak-ng license, work out technical details and prepare the final architecture and implementation plan for approval. No application code.
- Status: complete; implementation plan awaits owner approval.
- Files: both logs; `.gitignore`; bilingual `docs/architecture/FEASIBILITY`, `docs/STATUS`; new bilingual technical-detail and final-plan documents in `docs/architecture/`. Local only: `cache/feasibility/` (recognition models, Vosk TTS 0.9, scripts, results).
- Not touched: untracked `Djarvis_проверки_выполнимости.xlsx` (not created by this agent).
- Delegation: English versions of `TECHNICAL_DESIGN`, `IMPLEMENTATION_PLAN` and `FEASIBILITY` sections 4–5 were translated by a lower-cost model from the Russian originals; the result was reviewed by agent-02.
- Downloads (into `cache/feasibility/`): Vosk small ru 0.22 and en 0.15, Whisper base and small (int8), Vosk TTS 0.9 multi, spaCy `en_core_web_sm`; packages vosk, faster-whisper, misaki, spacy, sounddevice in separate test environments.
- Checks: synthetic corpus of 180 clips (ru and en, clean and 10 dB noise). Recognition: Vosk small WER ≈ 5 % (ru, 0.9 voices) and 2–8 % (en); Whisper small 5–6 % / 0–2 %, Whisper base 10 % in Russian. Wake phrase: names-only grammar — 68/72 false; grammar with decoys — 68/72 found, 3/72 false (ru), 18/18 and 1/18 (en). Vosk TTS 0.9: 1.5–1.8 GB, RTF ≈ 0.22, load ≈ 124 s. misaki without espeak-ng → Kokoro: four sentences recognized by Whisper without meaning errors. File set and metadata checked before commit.
- Result: `Vois/` excluded from Git; findings 9–12 in FEASIBILITY; new `TECHNICAL_DESIGN` (transport, schema and migrations, DJB1 backup format, installer, 8 GiB profile, decisions T1–T6) and `IMPLEMENTATION_PLAN` (architecture, repository layout, phases P0–P7 with acceptance criteria); STATUS updated. No application code written.
- Remaining: owner approval of the plan and T1–T6; live microphone test (`cache/feasibility/mic_wake_test.py`); Vosk 0.9 listening; code-signing certificate; real 8 GiB machine (P7).
- Commit: this entry is published together with the PLAN-022 documents.

## PLAN-023 — Owner decisions T1–T6 and the programming start condition

- Date: 2026-11-04, Europe/Moscow.
- Agent: agent-02.
- Authorization: owner's multiple-choice answers on technical decisions T1–T6 and the implementation plan.
- Status: complete; documentation.
- Files: both logs; bilingual `docs/architecture/DECISIONS` (ADR-015), `TECHNICAL_DESIGN`, `IMPLEMENTATION_PLAN`, `docs/STATUS`.
- Scope: T1 — the interface stays in the tray (instead of the proposed core-owned icon), T2–T6 as proposed; the owner will read the implementation plan first; the structure is being worked out now; programming does not start until the structure is fully worked out and the owner has received a full programming-readiness report. Real checks (voice assistant, microphone, task tracking, etc.) happen after programming; checks that need no code also come later.
- Checks: both language versions compared; ADR count 15/15 in both registers; Git checks before commit.
- Result: ADR-015; technical details updated for T1 (background memory ≈ 0.7 GB); plan marked as under owner review; STATUS updated. No code written.
- Remaining: finish the structure and the full programming-readiness report; owner approval of the plan.
- Commit: this entry is published together with ADR-015.

## PLAN-024 — Structure finalization: database schema, API catalogue, modules, readiness report

- Date: 2026-11-04, Europe/Moscow.
- Agent: agent-02.
- Authorization: owner asked to finish the structure to a level where programming can start; real checks come after programming.
- Status: complete; structure documents await owner approval.
- Files: both logs; new bilingual `docs/architecture/SCHEMA`, `API`, `MODULES`, `READINESS`; if needed `DECISIONS`, `IMPLEMENTATION_PLAN`, `docs/STATUS`.
- Scope: documentation only; no code.
- Owner decisions: Q1–Q5 (multiple-choice answers) → ADR-016.
- Delegation: English versions of SCHEMA, API, MODULES, READINESS were translated by a lower-cost model from the Russian originals; the result was reviewed by agent-02.
- Checks: all SQL from SCHEMA executed in a throwaway PostgreSQL 18 cluster from `cache/feasibility/pg` (63 statements, 45 tables, no errors; cluster removed); 13 database constraint checks all behaved as intended; links and anchors checked; language versions compared by structure; file set and metadata checked before commit.
- Result: SCHEMA (full v1 schema), API (commands, queries, events, errors, assistant tools), MODULES (responsibilities, dependency rule, background jobs, interface, tests, phases), READINESS (readiness report: requirements ↔ structure, deferred checks), ADR-016, STATUS. No application code written.
- Remaining: owner approval of IMPLEMENTATION_PLAN, SCHEMA, API, MODULES and permission to start P0.
- Commit: this entry is published together with the PLAN-024 documents.
## PLAN-025 — Project status audit and handoff

- Date: 2026-11-04, Europe/Istanbul.
- Agent: agent-01.
- Authorization: owner requested the current done/remaining status and its record in Plan.
- Status: complete; documentation checked and published.
- Files: both shared logs and bilingual docs/STATUS.
- Scope: reconcile the overview with published decisions and Git, record completed work and remaining approval gates, and report documentation discrepancies. No application code, schema/API edits, or unrelated local-file changes.
- Completed: product requirements, visual brief, 20 component design dossiers, 16 approved narrow decisions, feasibility notes for local model/speech/database/runtime, technical design, proposed implementation phases, 45-table schema, API catalogue, module boundaries and readiness mapping. The reported database checks are prior work; no application feature or installer exists yet.
- Remaining: owner review of implementation plan, schema, API and modules, then explicit authorization for P0. Correct the remaining cross-document mismatches before coding: decision-register count, exact child-completion button label in technical docs, tray owner in implementation-plan diagram, and record the accepted independent concurrent timers for different habits. After programming, test real voice/microphone/wake phrase, planner/habits/reminders/integrations, memory on an actual 8 GiB machine; before public release, resolve voice and service terms, signing, pricing/payment and future Android direction.
- Git audit: local HEAD and origin/main are identical at 245878c; no modified or staged tracked files before this task. One unrelated untracked spreadsheet is preserved. Local resources and agent instructions remain excluded from Git. The bilingual status summary was stale and has been updated in scope.
- Verification: compared both status languages, 16 decision IDs and local Markdown links; staged file scope and whitespace checked. Previous feasibility and SQL checks were reviewed as documented, not rerun. No application tests were possible because there is no application code.
- Commit: [519e278](https://github.com/SwanThunder/Djarvis/commit/519e2788d4d3130042270f1507c1a56ded1a0c95).

## PLAN-026 — Reconcile accepted timer and architecture handoff

- Date: 2026-11-04, Europe/Istanbul.
- Agent: agent-01 coordinates, records accepted policies and reviews; technical-doc-cleanup edits disjoint bilingual architecture files.
- Authorization: owner asked to continue the remaining pre-programming items; earlier answer permits simultaneous independent timers of different habits.
- Status: documentation complete, checked and published.
- Files reserved by agent-01: both logs and bilingual DECISIONS, PRODUCT, FOUNDATION_DESIGN, PLANNER_CORE and STATUS. Technical-doc-cleanup owns bilingual API, SCHEMA, READINESS and IMPLEMENTATION_PLAN. No other files or app code.
- Scope: correct the remaining documentation mismatches, add the accepted timer rule, verify the architecture package for owner review, and preserve the separate implementation approval gate.
- Result: ADR-009, product and planner documents now allow independent concurrent timers for different habits. API/schema use the approved child-button wording, the proposed timer constraint is explicitly per habit, and the plan diagram places the tray icon with the UI. The decision-register count is 16; the readiness report distinguishes approved behavior from proposed schema/API/module rules.
- Verification: 10 bilingual pairs checked for headings, ADR IDs and local links; targeted tray/timer consistency checks and whitespace check passed. Prior feasibility/SQL experiments were not rerun, and no application code or app tests were changed.
- Remaining: owner reviews and approves the implementation plan, schema, API and modules, then separately authorizes P0. Live feature checks follow programming; voice/service license terms, signing, payment and Android remain later gates.
- Commit: [8c133e1](https://github.com/SwanThunder/Djarvis/commit/8c133e1ce521fa476ff3dccb4d25e4b427ceb25c).
