# Programming readiness report

[Русская версия](READINESS.ru.md) · [Implementation plan](IMPLEMENTATION_PLAN.md) · [Database schema](SCHEMA.md) · [API](API.md) · [Modules](MODULES.md) · [Technical design](TECHNICAL_DESIGN.md) · [Decisions](DECISIONS.md) · [Status](../STATUS.md)

Snapshot updated 2026-11-05, Europe/Istanbul, PLAN-040; the original report was prepared by agent-02 in PLAN-024. Phases P0–P7 and criteria are approved (ADR-018); architecture/repository layout is approved (ADR-022), schema and archive contents are approved (ADR-024), API and modules are approved (ADR-025–026); P0 is authorized by the owner (ADR-028) and step 1 is done (PLAN-040). Real-world component checks occur as components are implemented per the owner decision.

## 1. Summary

Component, data, interaction, error and verification designs are documented. On this basis the owner authorized P0 within the [P0 plan](P0_PLAN.md) (ADR-028): step 1 is done (PLAN-040), next is step 2. Steps run in order, each verified; P1 begins only after P0 acceptance. Changes after ADR-019–021 and the revised schema are taken into account during implementation.

## 2. What is ready

| Area | Document | State |
| --- | --- | --- |
| Product: all required features | [PRODUCT](../PRODUCT.md) | agreed by the owner |
| Visual design | [DESIGN](../DESIGN.md), local briefs v2.1 and v1.0 | agreed |
| Product and technology decisions | [DECISIONS](DECISIONS.md), ADR-001…028 | approved |
| Components CP01–CP20 | [COMPONENT_PLAN](COMPONENT_PLAN.md), FOUNDATION, PLANNER_CORE, ASSISTANT, DELIVERY | detailed designs |
| Feasibility on CPU | [FEASIBILITY](FEASIBILITY.md) | model, speech, recognition, PostgreSQL, Python verified on the owner's machine |
| Technical decisions | [TECHNICAL_DESIGN](TECHNICAL_DESIGN.md), T1–T6 | approved (ADR-015) |
| Architecture and phases | [IMPLEMENTATION_PLAN](IMPLEMENTATION_PLAN.md) | P0–P7 and criteria approved (ADR-018); architecture/repository structure approved (ADR-022); P0 authorized (ADR-028), step 1 done |
| Database schema v1: 46 tables | [SCHEMA](SCHEMA.md), [summary](SCHEMA_REVIEW.md) | schema and archive contents approved (ADR-024); revised SQL has not been executed |
| API catalog: commands, queries, events, errors, assistant tools | [API](API.md) | approved (ADR-025) |
| Modules: responsibilities, dependencies, background jobs, interface | [MODULES](MODULES.md) | approved (ADR-026) |
| Structural questions Q1–Q5 | SCHEMA §12, ADR-016 | owner decisions recorded; schema approved (ADR-024) |

## 3. How the structure itself was verified

- **Requirements coverage.** Every required feature from PRODUCT is mapped to schema tables, API commands and a module (§5). There are no uncovered features.
- **Schema.** All the SQL from SCHEMA was run in a temporary PostgreSQL 18 cluster: 63 statements, 45 tables, no errors. The cluster was deleted. It was separately verified that the database itself rejects violations of product rules: a task without a priority, a deadline without a time, a second occurrence of a one-off task, a second live timer for the same habit (live timers for different habits are allowed), a block whose end is earlier than its start, a permission to delete files, a repeat of the same habit mark. All 13 cases behaved as intended. This verified the former 45-table draft. The revised 46-table draft with persisted timer intervals has not been executed; the owner deferred further checks until programming.
- **Consistency.** Command names in the API match the names in the schema and modules; links between documents were checked; both language versions were compared for structure.
- **What this verification does not prove:** that the program will work. That will be shown by the tests in each phase and the real-world checks after programming.

## 4. What awaits the owner's decision

| № | Action | Impact |
| --- | --- | --- |
| 1 | Architecture and layout in [IMPLEMENTATION_PLAN](IMPLEMENTATION_PLAN.md) §§1–2 | approved (ADR-022) |
| 2 | Discuss the [P0 plan](P0_PLAN.md) | discussed; the plan is in progress |
| 3 | Allow P0 to start | authorized (ADR-028); step 1 done (PLAN-040), next is step 2 |
| 4 | Confirm the `app.djarvis` application identifier | before Android work starts |
| 5 | Main branch protection with a required check and approval of CI runs for outside contributors | separate decision; without protection CI does not block a failed merge (ADR-027) |

## 5. Mapping of requirements to structure

| Requirement (PRODUCT, ADR) | Tables | Commands and queries | Module |
| --- | --- | --- | --- |
| Task: title and explicit priority, optional fields, start marker | `task`, `task_occurrence` | `CreateTask`, `EditTask`, `EditOccurrence` | `domain.tasks` |
| Multi-level subtasks, "Close / Finish", deleting and moving a branch | `task.parent_id`, `parent_occurrence_id` | `CompleteOccurrence`, `DeleteTask`, `MoveTask`, `GetTaskTree` | `domain.tasks` |
| Repetitions with the original anchor, debt, missing day of the month, zone | `recurrence_rule`, `recurrence_exception` | `CreateTask`, `EditTask(scope)` | `domain.recurrence` |
| Checklists, tags, attachments, hiding advanced fields without deleting them | `checklist_*`, `tag`, `task_tag`, `attachment`, `setting.advanced_fields` | `SetChecklist*`, `SetTags`, `AddAttachment` | `domain.tasks`, `storage` |
| Day auto-plan: deadline → priority, locked blocks, splitting by consent, breaks per settings, 06:00–22:00 window | `schedule_placement`, `day_plan_*`, `planning_guard`, `availability_window`, `setting.breaks` | `BuildDayPlan`, `ApplyDayPlan`, `GetDayView` | `domain.planner` |
| Plan draft, shift preview, meeting conflict and proposal after a miss (ADR-020–021) | `day_plan_proposal`, `day_plan_item`, `schedule_placement`, `planning_guard` | `EditDayPlanDraft`, `BuildDayPlan`, `ApplyDayPlan`, `GetDayView` | `domain.planner`, `app.commands` |
| Overdue and missed are different states; announcing a miss | computed; `task.announce_missed` | `GetDayView`, job `placement_missed` | `domain.time`, `reminders` |
| Habits of 4 types, schedules, pauses, streaks, backdated corrections | `habit*`, `habit_entry` | `RecordHabitEntry`, `CorrectHabitEntry`, `GetHabitStats` | `domain.habits` |
| Timer across sleep and shutdown, splitting at midnight | `timer_session`, `timer_interval`, `habit_entry` | `Start/Pause/Resume/StopTimer`, `ResolveTimerClock` | `domain.habits` |
| Goal change — only with consent | `habit_goal_proposal` | `ProposeHabitGoalChange`, `DecideHabitGoalProposal` | `domain.policy` |
| Calendar, projects, notes | `calendar_event`, `project`, `note` | API sections 6 and 8 | `app`, `storage` |
| Voice dialogue, wake phrase, 30 s wait, «Хватит», barge-in, mute | `setting.voice` | API section 12, `audio_state` events | `audio`, `assistant` |
| Personas Edward, Professor Volt, Nova | `profile.persona` | `UpdateProfile`, `PreviewVoice` | `assistant` |
| Initiative, quiet hours, summary of what was missed | `setting.proactive`, `setting.quiet_hours`, `scheduled_job` | API section 11 | `reminders` |
| Confirmations and revocable permissions; always — mail, files, shutdown | `approval_request`, `capability_grant` | `Approve`, `Grant/RevokeCapability` | `domain.policy`, `app.approvals` |
| Google Calendar, Outlook, Gmail; conflicts; queue | `provider_*`, `sync_conflict`, `outbox` | API sections 8–9 | `integrations.*` |
| Tavily search, MET Norway weather | — (key in the secret store) | `WebSearch`, `GetWeather` | `integrations` |
| Windows actions | `launch_target` | API section 9 | `integrations.windows` |
| Dialogue history 30 days, deletion | `conversation*`, `history_watermark` | `DeleteHistory` | `assistant` |
| Backups daily and before a migration, restore | `meta.backup_record`, `meta.operation_marker` | API section 13 | `safety.backup` |
| Trial, license, clock rule, restrictions after expiry | outside the database | `ImportLicense`, `GetEntitlement` | `safety.entitlement` |
| Ru/en, appearance, accessibility | `profile.locale`, `setting.appearance` | `UpdateProfile`, `UpdateSetting` | `ui` |
| Installation without a terminal, models on first launch, updates on command | — | API section 13 | `host`, `packaging` |

## 6. Proposed technical rules pending owner approval

Minor structural proposals from CP05–CP07 for the owner's review; this report does not lock them:

1. Tie-break in the auto-plan: with equal deadline and priority, the task created earlier goes first (`uuidv7` order). The plan is deterministic.
2. Occurrences of recurring tasks are created 60 days ahead; the `generated_until` cursor does not lose debt during a long absence.
3. Series edit: "only this", "this and future" (the rule is closed and a new one is created), "the whole series"; completed occurrences do not change.
4. The timer stores segments rather than ticking in the background; setting the clock back produces a question to the user.
5. Habit statistics are computed by queries; a cache only if measurements show slow performance.
6. Calendar synchronization — every 15 minutes and on command; weather is cached for 30 minutes.

## 7. Deferred to after programming (owner's condition)

- Live checks: voice assistant, microphone and wake phrase (`cache/feasibility/mic_wake_test.py`), task tracking, reminders, synchronization.
- Checks without code, postponed by the owner: listening to Vosk 0.9, Flutter interface memory.
- Acceptance on a real machine with 8 GiB, CPU only — in phase P7.

## 8. Does not block programming, but is needed before a public release

- Origin and licenses of the chosen voices; terms of Tavily and MET Norway (ADR-014).
- Code-signing certificate (ADR-015).
- Price and license issuance remain open; payment activation follows software implementation and manual tests (ADR-017).
- Android direction (DD10) — after the first Windows release; the API contract is already designed for a second client.
