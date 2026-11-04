# Programming readiness report

[Русская версия](READINESS.ru.md) · [Implementation plan](IMPLEMENTATION_PLAN.md) · [Database schema](SCHEMA.md) · [API](API.md) · [Modules](MODULES.md) · [Technical design](TECHNICAL_DESIGN.md) · [Decisions](DECISIONS.md) · [Status](../STATUS.md)

Snapshot: 2026-11-04, Europe/Moscow, after PLAN-024. Prepared by agent-02 under the owner's condition (ADR-015): programming starts only after the structure is fully worked out and this report is issued. Real-world checks — the voice assistant, microphone, task tracking and others — are carried out after programming.

## 1. Summary

**The structure is worked out to the level from which code for phase P0 and onward can be written according to the plan.** For every component there is: what it does, what data it works with, which commands it accepts, who it communicates with and through which interface, how it handles errors, and how it is verified. There are no blocking technical questions.

One action remains for the owner: read and approve the four structure documents (§4). After that — permission to start P0.

## 2. What is ready

| Area | Document | State |
| --- | --- | --- |
| Product: all required features | [PRODUCT](../PRODUCT.md) | agreed by the owner |
| Visual design | [DESIGN](../DESIGN.md), local briefs v2.1 and v1.0 | agreed |
| Product and technology decisions | [DECISIONS](DECISIONS.md), ADR-001…016 | approved |
| Components CP01–CP20 | [COMPONENT_PLAN](COMPONENT_PLAN.md), FOUNDATION, PLANNER_CORE, ASSISTANT, DELIVERY | detailed designs |
| Feasibility on CPU | [FEASIBILITY](FEASIBILITY.md) | model, speech, recognition, PostgreSQL, Python verified on the owner's machine |
| Technical decisions | [TECHNICAL_DESIGN](TECHNICAL_DESIGN.md), T1–T6 | approved (ADR-015) |
| Architecture and phases | [IMPLEMENTATION_PLAN](IMPLEMENTATION_PLAN.md) | being read by the owner |
| Database schema v1: 45 tables | [SCHEMA](SCHEMA.md) | new; the SQL runs in PostgreSQL 18 |
| API catalog: commands, queries, events, errors, assistant tools | [API](API.md) | new |
| Modules: responsibilities, dependencies, background jobs, interface | [MODULES](MODULES.md) | new |
| Structural questions Q1–Q5 | SCHEMA §12, ADR-016 | resolved by the owner |

## 3. How the structure itself was verified

- **Requirements coverage.** Every required feature from PRODUCT is mapped to schema tables, API commands and a module (§5). There are no uncovered features.
- **Schema.** All the SQL from SCHEMA was run in a temporary PostgreSQL 18 cluster: 63 statements, 45 tables, no errors. The cluster was deleted. It was separately verified that the database itself rejects violations of product rules: a task without a priority, a deadline without a time, a second occurrence of a one-off task, a second running timer, a block whose end is earlier than its start, a permission to delete files, a repeat of the same habit mark. All 13 cases behaved as intended.
- **Consistency.** Command names in the API match the names in the schema and modules; links between documents were checked; both language versions were compared for structure.
- **What this verification does not prove:** that the program will work. That will be shown by the tests in each phase and the real-world checks after programming.

## 4. What awaits the owner's decision

| № | Action | Impact |
| --- | --- | --- |
| 1 | Read and approve the [IMPLEMENTATION_PLAN](IMPLEMENTATION_PLAN.md) | order of phases and acceptance criteria |
| 2 | Approve [SCHEMA](SCHEMA.md), [API](API.md), [MODULES](MODULES.md) | become the basis of the P0–P1 code |
| 3 | Allow P0 to start | start of programming |

## 5. Mapping of requirements to structure

| Requirement (PRODUCT, ADR) | Tables | Commands and queries | Module |
| --- | --- | --- | --- |
| Task: title and explicit priority, optional fields, start marker | `task`, `task_occurrence` | `CreateTask`, `EditTask`, `EditOccurrence` | `domain.tasks` |
| Multi-level subtasks, "Close / Finish", deleting and moving a branch | `task.parent_id`, `parent_occurrence_id` | `CompleteOccurrence`, `DeleteTask`, `MoveTask`, `GetTaskTree` | `domain.tasks` |
| Repetitions with the original anchor, debt, missing day of the month, zone | `recurrence_rule`, `recurrence_exception` | `CreateTask`, `EditTask(scope)` | `domain.recurrence` |
| Checklists, tags, attachments, hiding advanced fields without deleting them | `checklist_*`, `tag`, `task_tag`, `attachment`, `setting.advanced_fields` | `SetChecklist*`, `SetTags`, `AddAttachment` | `domain.tasks`, `storage` |
| Day auto-plan: deadline → priority, locked blocks, splitting by consent, breaks per settings, 06:00–22:00 window | `schedule_placement`, `day_plan_*`, `planning_guard`, `availability_window`, `setting.breaks` | `BuildDayPlan`, `ApplyDayPlan`, `GetDayView` | `domain.planner` |
| Overdue and missed are different states; announcing a miss | computed; `task.announce_missed` | `GetDayView`, job `placement_missed` | `domain.time`, `reminders` |
| Habits of 4 types, schedules, pauses, streaks, backdated corrections | `habit*`, `habit_entry` | `RecordHabitEntry`, `CorrectHabitEntry`, `GetHabitStats` | `domain.habits` |
| Timer across sleep and shutdown, splitting at midnight | `timer_session` | `Start/Pause/Resume/StopTimer`, `ResolveTimerClock` | `domain.habits` |
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

## 6. Technical rules fixed by this report

Minor rules that were previously listed as open in CP05–CP07 and are now closed at the structure level (changed only by agreement):

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
- Price, license issuance, payment — deferred by the owner.
- Android direction (DD10) — after the first Windows release; the API contract is already designed for a second client.
