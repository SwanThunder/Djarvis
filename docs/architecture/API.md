# Core API catalog, version 1

[Русская версия](API.ru.md) · [Technical design](TECHNICAL_DESIGN.md) · [Database schema](SCHEMA.md) · [Modules](MODULES.md) · [Foundation CP01–CP02](FOUNDATION_DESIGN.md)

Status: proposal by agent-02 (PLAN-024), 2026-11-04. Under owner review. The complete list of commands, queries and events between the interface, the voice assistant and the core. Names are final for v1 unless the owner asks otherwise. No code is written until approval.

## 1. Conventions

- Transport and protection — [technical design](TECHNICAL_DESIGN.md) §1 (ADR-015): `127.0.0.1`, launch token, `Host` and `Origin` checks.
- Command: `POST /v1/commands/<Name>`. Read query: `POST /v1/queries/<Name>` (JSON body; queries change nothing and do not invoke the model). Events: WebSocket `/v1/events`.
- Command envelope (CP01 §2.3): `protocol_version`, `request_id`, `action_id` (stable on retry), `origin` (`ui`, `voice`, `assistant`, `proactive`, `sync`), `expected_revisions`, `reference` (instant and zone for interpreting "tomorrow"), `payload`, `approval_id`.
- A command result is one of the states: `AppliedLocal`, `QueuedExternal`, `NeedsClarification`, `NeedsConfirmation`, `NeedsInput`, `Conflict`, `Denied`, `Unavailable`, `Failed`. It comes with `action_id`, the new revisions and, if needed, a read model.
- `NeedsConfirmation` returns `approval_id` and the exact content to display. Confirmation is the `Approve` command with that `approval_id`; changing any significant field requires a new confirmation.
- By default, confirmation is required for task changes made by the assistant; it is overridden by revocable permissions (`capability_grant`). The 🔒 marker below means confirmation is **always** required; a permission does not override it.
- Voice: the "Assistant" column marks the commands available to the model as tools (§14). The rest run only from the interface.

## 2. System and session

| Name | Type | Purpose |
| --- | --- | --- |
| `GetSystemStatus` | query | core and protocol version, state of the database, resources, microphone, access (trial/license), memory profile |
| `GetBootstrap` | query | everything for the first screen in one response: profile, settings, status, notification counters |
| `RequestExit` | command | full exit: stop capture, worker processes, database (CP01) |
| `CompleteFirstRun` | command | mark the first-time setup as completed (language, name, persona, initiative, quiet hours) |

## 3. Profile and settings

| Name | Type | Assistant | Purpose |
| --- | --- | --- | --- |
| `UpdateProfile` | command | name, city | name/form of address, language, zone, city and how it is determined, persona |
| `UpdateSetting` | command | — | one key of the `setting` registry (appearance, breaks, quiet hours, initiative, voice, history, backups, autostart) |
| `SetAvailability` | command | — | available hours by day of the week (replaces the whole set) |
| `GetSettings` | query | — | all settings with revisions |

## 4. Tasks and occurrences

| Name | Type | Assistant | Purpose and important fields |
| --- | --- | --- | --- |
| `CreateTask` | command | yes | `title`, `priority` (required; if absent — `NeedsInput`), optionally `description`, `project_id`, `parent_id`, `estimate_min`, `planning_date`, `deadline` (date + time + zone; a date without a time — `NeedsInput`), `start_marker`, `recurrence`, `reminders`, `tags`, `split_allowed`, `announce_missed` (Q5). For a subtask, the parent's project and priority are suggested and require confirmation (ADR-009) |
| `EditTask` | command | yes | task fields (not occurrences); for a recurring task — `scope`: `this`, `this_and_future`, `series` |
| `EditOccurrence` | command | yes | deadline, planning day, start marker of a specific occurrence |
| `CompleteOccurrence` | command | yes | complete one occurrence; the current block is trimmed at the moment of completion, future ones are released (Q3). If there are unclosed subtasks — a `NeedsClarification` response with the choice "Close task" / "Finish subtasks" (ADR-008), even when a permission has been granted |
| `ReopenOccurrence` | command | yes | return a completed occurrence to open |
| `CancelOccurrence` | command | yes | cancel an occurrence (for a series — only that one) |
| `DeleteTask` | command | yes | delete a task; if there are subtasks — `NeedsClarification`: `children = delete` (the whole branch) or `lift` (lift one level up) ([Q1](SCHEMA.md#12-owner-decisions-plan-024)) |
| `MoveTask` | command | — | change the parent or project; under any task except its own descendants; the children's project does not change ([Q4](SCHEMA.md#12-owner-decisions-plan-024)) |
| `ReorderTasks` | command | — | order in the list |
| `SetChecklist` | command | yes | checklist items of an occurrence: add, rename, mark, delete, reorder |
| `SetChecklistTemplate` | command | — | checklist template of a recurring task; applied to new occurrences and, depending on the chosen scope, to open ones (Q2) |
| `ListTasks` | query | yes | filters: state, project, tag, deadline, overdue, no deadline, text; paginated output |
| `GetTask` | query | yes | task, occurrences, placements, subtasks (with lazy loading of branches), checklist, attachments, notes |
| `GetTaskTree` | query | — | one branch of subtasks to a given depth |

## 5. Placements and the day plan

| Name | Type | Assistant | Purpose |
| --- | --- | --- | --- |
| `PlaceOccurrence` | command | yes | manually put an occurrence or habit at a time (a manual one is locked) |
| `MovePlacement` | command | yes | move a block; a locked one only with explicit permission in the same command |
| `RemovePlacement` | command | yes | remove a block (the task is not deleted) |
| `CheckOffSegment` | command | yes | mark a part of a split task — progress only |
| `SetPlacementLock` | command | — | lock or unlock a block |
| `BuildDayPlan` | command | yes | build a proposal for a date; the response is `DayPlanProposal` or `NeedsInput` (no duration) |
| `ApplyDayPlan` | command | yes | apply the proposal; if the planning revision has changed — `Conflict` and the proposal is `stale`. Requires confirmation or the `plan.apply` permission |
| `RejectDayPlan` | command | yes | reject the proposal |
| `GetDayView` | query | yes | the day: blocks, events, habits, overdue, missed, top 3, free time — the source for the Today screen and the spoken plan |
| `GetWeekView` | query | — | the week for the calendar |
| `GetDayPlanProposal` | query | — | the proposal with reasons for what is unplaced |

## 6. Projects, notes, tags, attachments

| Name | Type | Assistant | Purpose |
| --- | --- | --- | --- |
| `CreateProject` / `EditProject` / `ArchiveProject` / `DeleteProject` | commands | create and edit | projects; deleting a project does not delete its tasks but unlinks them |
| `ListProjects` / `GetProject` | queries | yes | projects with counters and progress |
| `CreateNote` / `EditNote` / `DeleteNote` | commands | create and edit | notes; link to a project and tasks |
| `ListNotes` / `GetNote` | queries | yes | notes, text search |
| `CreateTag` / `RenameTag` / `DeleteTag` / `SetTags` | commands | `SetTags` | tags and their assignment to tasks and notes |
| `AddAttachment` | command | — | the file is chosen by the interface in a Windows dialog; the core copies it into storage by sha256 |
| `RemoveAttachment` | command | — | remove an attachment (the user's original file is not touched) |
| `OpenAttachment` | command | — | open the copy with the default program |
| `Search` | query | yes | global search across tasks, notes, projects, events |

## 7. Habits and timers

| Name | Type | Assistant | Purpose |
| --- | --- | --- | --- |
| `CreateHabit` | command | yes | type, unit, quantity mode, schedule (days or times per week), goal, zone and its policy |
| `EditHabit` | command | yes | title, color, unit; changing the quantity mode comes with a preview of the current day's recalculation (ADR-009) |
| `ChangeHabitSchedule` | command | — | a new version of the goal/schedule from a date; from the assistant — only through a proposal 🔒 |
| `PauseHabit` / `ResumeHabit` | commands | yes | pause from a date to a date |
| `ArchiveHabit` / `DeleteHabit` | commands | archive | archiving keeps the statistics; deletion 🔒 |
| `RecordHabitEntry` | command | yes | a mark: done, portion, daily total, duration, "complied", "violated"; may be backdated within the habit's lifetime |
| `CorrectHabitEntry` | command | yes | correct or cancel an entry; history is preserved |
| `StartTimer` / `PauseTimer` / `ResumeTimer` / `StopTimer` | commands | yes | duration timer; on stop — entries per day |
| `ResolveTimerClock` | command | — | the user's answer if the clock was set back during a timer |
| `ProposeHabitGoalChange` | command | yes | an assistant proposal (not applied by itself) |
| `DecideHabitGoalProposal` | command | — 🔒 | accept or reject a proposal; only the user accepts |
| `ListHabits` / `GetHabit` | queries | yes | habits with day and week progress |
| `GetHabitStats` | query | yes | streaks, percentages, misses, pause weeks — against the goals in effect at the time |

## 8. Calendar and synchronization

| Name | Type | Assistant | Purpose |
| --- | --- | --- | --- |
| `CreateEvent` / `EditEvent` / `DeleteEvent` | commands | yes | own events, including recurring ones; editing a series — with a scope, as for tasks |
| `GetCalendarRange` | query | yes | events, blocks, habits for a period |
| `ConnectProvider` | command | — | start Google or Microsoft sign-in (system browser, PKCE); the token goes to the Windows store |
| `DisconnectProvider` | command | — | disconnect an account; local data remains |
| `SetProviderCalendar` | command | — | what to synchronize: events, task blocks, habit blocks (off by default) |
| `SyncNow` | command | yes | synchronize now |
| `ListSyncConflicts` | query | — | open conflicts with both versions |
| `ResolveSyncConflict` | command | — | keep your own, keep the other, or delete the local one |
| `ListOutbox` | query | — | external actions and their states |
| `ResolveUnknownOutbox` | command | — | decide the fate of an action with an unknown outcome (for example, a message): retry or mark as failed |

## 9. Mail, search, weather, Windows

| Name | Type | Assistant | Purpose |
| --- | --- | --- | --- |
| `SearchMail` / `GetMail` | queries | yes | search and read Gmail on demand (no mailbox mirror) |
| `DraftMail` | command | yes | draft |
| `SendMail` | command | yes 🔒 | sending; the exact recipients, text and attachments are confirmed |
| `WebSearch` | query | yes | Tavily with the user's key; without a key — `Unavailable` with an offer to open the browser |
| `OpenInBrowser` | command | yes | open a link or a search in the user's browser |
| `GetWeather` | query | yes | MET Norway for the profile's city |
| `SetSearchKey` | command | — | save the Tavily key in the secret store |
| `AddLaunchTarget` / `RemoveLaunchTarget` | commands | — | list of allowed programs (path, publisher, sha256) |
| `LaunchApplication` | command | yes | launch a program from the list; no arbitrary arguments |
| `CloseApplication` | command | yes 🔒 | close a program (ADR-013) |
| `SetVolume` / `SetBrightness` | commands | yes | no confirmation (ADR-013) |
| `LockWorkstation` / `Sleep` | commands | yes 🔒 | ADR-013 |
| `Shutdown` / `Restart` / `SignOut` | commands | yes 🔒 | always confirmation |
| `ReadSelectedFile` | command | yes | read a file the user chose in a Windows dialog |
| `WriteFile` | command | yes | a new file in the chosen folder; overwriting an existing one 🔒 |
| `DeleteUserFile` | command | yes 🔒 | deleting a user's file; the task permission does not cover it |

## 10. Permissions and confirmations

| Name | Type | Purpose |
| --- | --- | --- |
| `Approve` | command | confirm an `approval_id`; the core rechecks revisions and content |
| `Reject` | command | reject |
| `ListPendingApprovals` | query | everything awaiting a decision (for the notification list) |
| `GrantCapability` / `RevokeCapability` | commands | "no confirmation" permissions: tasks, plan, launching programs, Gmail, calendars, automatic city detection |
| `ListCapabilities` | query | current permissions |

## 11. Reminders and initiative

| Name | Type | Assistant | Purpose |
| --- | --- | --- | --- |
| `SetReminders` | command | yes | reminder rules of a target (task, occurrence, habit, event) |
| `SnoozeReminder` / `DismissReminder` | commands | yes | postpone or dismiss a reminder |
| `SetQuietMode` | command | yes | manual quiet mode for a period or until cancelled |
| `ListNotifications` | query | — | reminders, summary of what was missed, confirmations |
| `GetCatchUpSummary` | query | yes | one summary of what was missed after sleep or shutdown |

## 12. Voice and dialogue

| Name | Type | Purpose |
| --- | --- | --- |
| `SetMicrophoneMuted` | command | instantly turn capture off or on (wake phrase and dialogue) |
| `StartListening` | command | microphone button: listen immediately, without the wake phrase (all capture conditions apply) |
| `StopDialogue` | command | «Хватит»/“Stop” from the interface — return to waiting for the phrase |
| `SendTextTurn` | command | a text turn to the assistant (the same path as recognized speech) |
| `InterruptSpeech` | command | interrupt speech output |
| `GetAudioState` | query | state: waiting for the phrase, listening, thinking, speaking, mute, unavailable (with a reason) |
| `ListConversations` / `GetConversation` | queries | history within the retention period |
| `DeleteHistory` | command 🔒 | delete history; shows the affected backups and offers to recreate or delete them |
| `PreviewVoice` | command | listen to the persona's voice in settings |

## 13. Data protection, access, resources, updates

| Name | Type | Purpose |
| --- | --- | --- |
| `CreateBackupNow` | command | on-demand backup |
| `ListBackups` | query | backups with dates, size, state |
| `PreviewRestore` | command | verify the archive and show what will be restored (ADR-006) |
| `Restore` | command 🔒 | full restore after the preview and a backup of the current data |
| `DeleteAllData` | command 🔒 | delete the user's data (available even after access has expired) |
| `ImportLicense` | command | import a signed license file; offline verification |
| `GetEntitlement` | query | trial, license, term, devices, clock lock (ADR-005, ADR-010) |
| `GetResourceStatus` | query | models and voices: loaded, downloading, error, size |
| `RetryResourceDownload` / `PauseResourceDownload` | commands | control of the first download |
| `CheckForUpdates` | command | check whether an update is available (notification only) |
| `DownloadUpdate` / `InstallUpdate` | commands | only on the user's command (DD07) |
| `ExportDiagnostics` | command | assemble a local report without data content |

While access is expired, the core accepts only: `GetSystemStatus`, `GetBootstrap`, `ImportLicense`, `GetEntitlement`, backups, `DeleteAllData`, `RequestExit`, appearance settings. Everything else is `Denied` with the reason `access_expired` (ADR-005).

## 14. Assistant tools

The model is given not an HTTP API but a registry of typed tools. Each tool is a wrapper around one command or query from the tables above with `origin = assistant` and a trimmed field schema (only what can be said by voice). Rules:

1. The model proposes a call; the core checks the schema, target, permissions and confirmations, as for the interface. The model's answer is not an authority.
2. An ambiguous target ("move the meeting" when there are two meetings) is always `NeedsClarification`, even with permissions.
3. Facts in the reply (time, count, success) come from the command result, not from the model's text.
4. Data from mail, search and files is passed to the model as untrusted text and cannot invoke tools by itself.
5. To save context on the 8 GB profile, the model is given tools in groups by intent (tasks, habits, calendar, information, device) rather than all at once.

## 15. Events

All events are a hint to re-read data: `{"type", "revision", "resources"}`; a skipped revision means a full snapshot (CP01 §2.4).

| Type | When |
| --- | --- |
| `changed` | any command has been committed; `resources` — affected types and identifiers |
| `audio_state` | audio state change (for the assistant circle and the microphone button) |
| `transcript` | interim and final recognition text of the current turn |
| `assistant_text` | reply text sentence by sentence, in sync with synthesis |
| `notification` | a reminder fired, a confirmation appeared, a summary arrived |
| `approval_requested` | the assistant is waiting for confirmation |
| `resource_progress` | model download progress |
| `entitlement` | access changed (expired, license imported) |
| `maintenance` | backup, migration or restore: writing is temporarily unavailable |
| `shutdown` | the core is shutting down |

## 16. Error codes

A closed list of `error.code` values (the user-facing text is in the interface language): `validation_failed`, `missing_field`, `not_found`, `revision_conflict`, `action_reused`, `stale_plan`, `ambiguous_target`, `confirmation_required`, `permission_denied`, `access_expired`, `clock_rollback`, `resource_unavailable`, `memory_insufficient`, `network_unavailable`, `provider_error`, `provider_reauth`, `maintenance`, `db_unavailable`, `unsupported_protocol`, `internal`.
