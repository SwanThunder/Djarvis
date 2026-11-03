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
