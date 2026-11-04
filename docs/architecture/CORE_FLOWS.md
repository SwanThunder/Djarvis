# Djarvis critical user flows — component integration proposal

[Русская версия](CORE_FLOWS.ru.md) · [Phase plan](IMPLEMENTATION_PLAN.md) · [Planner core](PLANNER_CORE.md) · [API](API.md) · [Modules](MODULES.md)

Status: proposal for joint review, PLAN-030, 2026-11-04. Phases and acceptance criteria are approved (ADR-018); architecture, schema, API and modules are not yet approved, and P0 is withheld. This document connects the main user flows without adding approved product rules.

## 1. Product center

The user sees the assistant orb and day panel. The core value is to capture a task or habit quickly, get a feasible plan, and learn about changes in time. Voice is a second way to work with the same data and discuss the day. The manual planner must continue working if the local model fails. External connections extend the product but are not the source of truth for Djarvis's independent sections.

| Design priority | Components | Observable result |
| --- | --- | --- |
| 1. Capture and change | UI, voice, core commands, tasks and habits (CP02, CP06, CP17) | The same operation has the same result from a form or dialog; ambiguous targets are clarified |
| 2. Day plan | Tasks, meetings, availability, algorithm, plan draft (CP05–CP06) | The user understands why a task was or was not placed |
| 3. Assistant actions and reminders | Local model, tool registry, speech, background jobs (CP08–CP11) | The assistant proposes and executes only authorized precise commands; important items arrive on time |
| 4. Durability | Private database, history, backups, restore and access (CP03–CP04, CP15–CP16) | Data survives restarts, crashes and upgrades without duplicate actions |
| 5. Connections | Calendars, mail, search, weather and Windows (CP12–CP14) | A network failure does not break the local plan; the user resolves calendar conflicts |

## 2. End-to-end command: a new task or habit

1. A form or recognized utterance produces a typed intent. An ordinary task requires title and priority; other fields are optional. A date-only deadline prompts for its time. A habit specifies measurement type, goal and schedule.
2. The core identifies the exact target and checks permissions, access state and expected revision. Ambiguity returns a clarification before any change. The model never writes to the database directly.
3. One short transaction stores the record, action ID, audit entry and event for projections/reminders. A repeated command returns its previous result. A revision conflict shows current data and offers to retry against it.
4. The day and list screens refresh from the result or event. If the voice chain fails, the form still works. Voice reports successful saving only after commit.

UI proposal: after creation, show a compact card with explicit “Add to plan”, “Edit” and, if needed, “Set duration”. Creating a task does not by itself accept a new schedule.

## 3. End-to-end day plan

The planner takes a consistent snapshot of the selected day, available hours, meetings, pinned blocks, unfinished task occurrences, habits, durations and break settings. Its algorithm does not depend on the model. Meetings and manually pinned blocks stay fixed. Remaining tasks are ordered first by nearest deadline, then by priority; unplaced tasks are displayed with reasons. If a required duration is missing, the planner asks for it before producing a proposal.

The output is a proposal rather than a hidden calendar write: blocks, placement reasons, free windows and items that did not fit. Before applying it, the core checks input revisions: a changed meeting or task requires a fresh proposal. Acceptance stores blocks with one command, schedules or updates reminders and refreshes the day. Saved permission to apply without confirmation only applies within its scope; habit goal changes always need a separate acceptance.

**Proposal for owner review:** the plan draft can be edited before application, with constraints rechecked after each edit. After an unexpected meeting or missed block, the app suggests replanning but does not move pinned items without explicit consent. These two UX policies are not yet owner-approved.

## 4. End-to-end assistant and reminders

A wake phrase or button opens the audio session; local recognition passes the utterance to the model. The model receives narrow context for the current goal and a limited set of typed tools. Every command uses the same gateway as the UI; mail sending, file deletion/overwrite and critical Windows actions always need confirmation. The response is spoken after the command result. Interrupting speech stops playback but does not undo an already committed action; undo needs a separate command.

Accepted records create durable reminder jobs. After sleep or restart, current missed reminders arrive as one digest. Quiet hours, calls, games and manual silence suppress proactive speech while leaving an ordinary notification according to settings. If the model or speech resource is unavailable, screens, plans, manual marks and notifications still work. Muting the microphone stops capture immediately.

## 5. Data, connections and responsibility boundaries

Each Windows account has one private profile and local database. A verified backup precedes migrations; routine backups run on a schedule. Restore previews contents and first preserves current data. Conversation history follows its retention and explicit deletion policies. License and trial state live separately from restorable user data.

The Djarvis calendar is independent. Google/Outlook adapters turn external changes into explicit sync operations. If a record changed on both sides, both versions are retained for the user's choice; an external deletion needs confirmation before deleting locally. A network failure leaves the local operation queued without falsely claiming provider acceptance. Search and weather use the network only on request or according to settings; the local AI does not send conversations to a cloud inference service.

## 6. Main-path checks

- One task created from the form and from voice has the same required fields and permission checks.
- A repeated command or restart after commit creates neither a second task nor a second reminder.
- Planning does not hide unplaced tasks, explains their status and rejects acceptance of a stale snapshot.
- A new meeting, quiet mode, missing model and missing network produce clear states without data loss.
- Restoring user data does not extend the trial or replace an external connection token.

Next product review: task capture/editing, plan proposal and changes during the day. Then voice and reminders, then calendar connections and data safety. Timers and rare time cases stay in their separate specification.
