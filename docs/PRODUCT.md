# Product definition

[Русская версия](PRODUCT.ru.md)

Status: requirements captured from the owner's responses on 2026-11-03. Open questions and proposals below are not approved decisions. This document does not approve an architecture or authorize programming.

## Purpose and audience

A commercial personal task and habit tracker with a conversational, voice-controlled butler/secretary. Initial customers are individual users managing personal responsibilities and professionals with busy schedules. Team, family, and organization workspaces are not part of the current stated audience.

The central value is simpler planning: users create and update tasks and habits by voice, hear their daily plan at a chosen time or situation, and ask for weather or internet information.

## Platforms and scope

Develop for Windows first. Subsequently design Android and cross-device synchronization. User data is stored on the device; cloud storage and cross-device synchronization are later capabilities, and their design is open. AI inference in the current release must be local only; cloud AI inference is excluded. Offline planner behavior has not been explicitly decided.

The application can start locally without an account. An account is needed to obtain a subscription and will support future synchronization. Subscription licensing and the seven-day full-product trial must work fully offline: there is no activation or subscription server and no entitlement registration with a server. The trial is per device, and the application remembers the device to prevent repeated trials through alternate accounts. This is not a claim to uniquely identify a person or to provide unbypassable local licensing. No device fingerprint was collected during environment preparation. The offline process for issuing and renewing licenses, and the device-trial design, remain open; no particular implementation is selected. After the trial or a subscription ends, application features are unavailable. This does not mean user data is deleted; data retention and recovery remain unresolved.

The owner wants the entire requested product designed without a deadline or arbitrary feature cuts. Implementation order will follow dependencies and explicit approval; an implementation sequence does not remove features from the target scope.

## Required capabilities

### Tasks and planning

- Basic task fields: title, description, project, priority, deadline, scheduled time, duration, recurrence, and reminders; completion is tracked. Users can toggle advanced subtasks, checklists, tags, and attachments; whether this is a global or per-task toggle is unresolved.
- Calendar, recurring tasks, and projects.
- Automatic day planning.
- Voice creation and modification of tasks, habits, and their records.
- Daily spoken plans triggered by user-configured times or situations.

The automatic day planner considers meetings, deadlines, priorities, durations, habits, breaks, and the user's available hours. It proposes a plan and applies it after confirmation or remembered permission. A missed task is highlighted and announced aloud; its date is not changed automatically. Whether a per-task override is available remains unresolved. Recurrence can be calendar-fixed or relative to completion; missed occurrences remain outstanding debt. Conflict handling and the distinction between a deadline and a scheduled work period still need design.

### Habits

- Four habit types: yes/no completion, quantity, duration, and abstaining from an undesired behavior.
- Both fixed-day schedules and flexible frequency schedules, such as three times per week.
- Completion tracking and statistics. Missed occurrences remain misses in statistics and do not accumulate as task-like debt.
- Personalized plans, analysis of missed habits, and gradual goal increases or workload changes proposed by the assistant. The assistant never applies goal or load changes without user approval; the task-change no-confirmation preference does not override this restriction.
- Users choose and configure which of these behaviors are active.

Pause and correction rules, the cutoff for counting a flexible weekly schedule as missed, and streak rules still need design.

### Assistant and interface

- Main screen: a futuristic circular visualization of the assistant, inspired by the cinematic JARVIS presentation, and a day dashboard below it.
- Full spoken conversations with voiced responses. When the main window is closed, the assistant continues waiting in the background for its wake phrase. Window close therefore differs from explicitly quitting the assistant; tray controls and startup behavior still need design.
- General conversation, internet information search, and weather lookup.
- Multiple selectable personalities using the exact named characters and recognizable voices requested by the owner; original substitute characters are not the target. References include JARVIS, Rick Sanchez, and Sebastian from *Black Butler* (the Sebastian identification is inferred from the owner's series reference; the precise voice actor and language version are unconfirmed). The supplied MP3 remains local. Commercial usage permissions have not been verified. The anime reference is [Black Butler (2008)](https://rutube.ru/plst/510981/); [WIPO copyright material](https://www.wipo.int/documents/d/copyright/docs-en-wo_inf_108.pdf) is background for a later rights review, not a legal conclusion.
- Proactive behavior is configurable: morning plans, daytime reminders, and evening reviews can be enabled or disabled. Triggers include the first entry each day, an approaching meeting, a missed habit, and returning after an absence. Defaults and exact timing remain to be designed.
- The user chooses the time and/or situation for spoken updates, including the listed triggers.

### Connections and capabilities

A settings area called "Connections and capabilities" lets users connect services and grant permissions for calendar, mail, notes, files, program launching, and device control as needed.

Initial integrations include Google Calendar, Outlook, and Gmail. The product also has its own calendar, notes, and projects that work independently; Google Calendar synchronization is optional. Sync direction, conflict handling, and Outlook synchronization details require design. Permission boundaries, revocation, and action history also require design. By default, the assistant proposes task changes for confirmation. If an application user explicitly asks to skip confirmations for task changes, remember and honor that user's preference. Its scope, persistence, and revocation require design. This task-specific opt-out does not settle confirmation rules for email, file deletion, or device control.

### Personalization and memory

The assistant remembers the user's name or nickname and location. Location source, precision, updates, timezone behavior, conversation history, additional memory, any future cloud processing, retention, export, and deletion are not decided.

### Commercial model and localization

- Subscription-based product.
- English and Russian application languages.
- Intended audience is not restricted to one region; actual distribution, payment, and service availability require validation later.
- The current release uses local AI only; cloud inference is not allowed. The owner authorized downloading and evaluating a local model separately from application programming. API-key support is a separate future capability excluded from the current local-only release. The earlier requirement for a BYOK subscription at 50% of the standard subscription price is retained as a future pricing requirement for that capability. Current subscription amounts and plan structure have not been selected. The full-product trial lasts seven days per device. After trial or subscription expiry, application features become unavailable.

## Existing application reference

Read-only reference: `W:\DVORETSKI`.

Evidence inspected in `Jarvis/README.md`, lines 84–122, and `Jarvis/jarvis/facts.py`, lines 36–52:

- Top-three priorities, an hourly plan, remaining/completed/overdue tasks, habit progress, and period-of-day briefings.
- The documented assistant reads today's planner information; requests to create, edit, or delete tasks are rejected and redirected to the planner.
- Frontend source was not found in the inspected installation. Backend contracts and documentation were reviewed; the actual UI was not visually assessed and no claim about all installed UI capabilities is made.

Use this as a product reference rather than an approved technology choice. Voice-driven changes are an intended capability of the new product beyond the documented reference behavior. No reference files were modified or copied into this repository.

## Voice preparation

The supplied local sample exists at `Vois/join-5tracks.mp3`. Only its presence was checked; audio quality, suitability, and usage permissions have not been evaluated. It is not included in this documentation commit or uploaded to the public repository.

The owner explicitly wants recognizable voices for the exact named characters, not original substitutes. Specific dub actors, language versions, production providers, and commercial usage permissions remain unverified. The linked WIPO material provides general background for the usage-rights review and is not a legal conclusion about this product.

## Decisions needed before architecture

1. Current subscription price and plan structure; future API-key support with the previously requested 50% BYOK pricing; offline license issuance and renewal, device-trial design, licensing security, retention, reinstalls, and hardware changes. Online entitlement registration is excluded. The seven-day per-device trial and feature unavailability after expiry are set.
2. Future cloud storage/synchronization, offline planner behavior, and user-data retention/recovery/export/deletion. Current-version AI inference is local only.
3. Supported Windows versions, baseline hardware, tray controls, explicit quit, and startup behavior; background wake listening when the main window is closed is required.
4. Microphone indicators, voice interruption, whether proactive triggers are enabled by default, and exact trigger timing and absence detection.
5. Character presentation and implementation of recognizable exact-character voices; identify the intended voice actor and language versions, and assess usage permissions.
6. How remembered permission for task plan changes is scoped and revoked; whether a per-task missed-date override is available. Keep separate confirmation rules for email, file deletion, and device control.
7. Calendar sync direction and conflict handling, Outlook sync details, and notes/projects integration needs.
8. Whether the advanced task-fields toggle is global or per-task; detailed scheduling and conflict rules; habit pause/correction rules, flexible-schedule miss cutoff, and streak semantics.

Next: resolve these product questions, review full user journeys, and then propose an architecture for explicit owner approval.
