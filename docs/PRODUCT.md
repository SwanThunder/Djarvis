# Product definition

[Русская версия](PRODUCT.ru.md)

Status: requirements captured from the owner's responses on 2026-11-03. Open questions and proposals below are not approved decisions. This document does not approve an architecture or authorize programming.

## Purpose and audience

A commercial personal task and habit tracker with a conversational, voice-controlled butler/secretary. Initial customers are individual users managing personal responsibilities and professionals with busy schedules. Team, family, and organization workspaces are not part of the current stated audience.

The central value is simpler planning: users create and update tasks and habits by voice, hear their daily plan at a chosen time or situation, and ask for weather or internet information.

## Platforms and scope

Develop for Windows first. Subsequently design Android and cross-device synchronization. Do not treat a future synchronization approach or shared architecture as selected yet.

The owner wants the entire requested product designed without a deadline or arbitrary feature cuts. Implementation order will follow dependencies and explicit approval; an implementation sequence does not remove features from the target scope.

## Required capabilities

### Tasks and planning

- Tasks with deadlines, priorities, reminders, and completion state.
- Calendar, recurring tasks, and projects.
- Automatic day planning.
- Voice creation and modification of tasks, habits, and their records.
- Daily spoken plans triggered by user-configured times or situations.

Planning rules, conflict handling, automatic rescheduling authority, recurrence details, and the distinction between a deadline and a scheduled work period still need design.

### Habits

- Completion tracking and statistics.
- Personalized plans, gradual goal increases, analysis of missed habits, and workload adjustment.
- Users choose and configure which of these behaviors are active.

Habit measurement types, schedules, pauses, corrections, and the conditions under which recommendations change a plan still need design.

### Assistant and interface

- Main screen: assistant character with a day dashboard below it.
- Full spoken conversations with voiced responses and wake-phrase activation.
- General conversation, internet information search, and weather lookup.
- Multiple selectable personalities. Owner references: a cinematic high-tech butler, Rick Sanchez, and a dark anime butler. The exact anime character, production names, visual form, voice sources, and commercial use arrangements remain unresolved.
- Reactive and proactive behavior are configurable: morning planning, daytime reminders, and evening reviews can be enabled or disabled by the user.
- The user chooses the time and/or situation for spoken updates; the supported situation triggers remain undefined.

### Connections and capabilities

A settings area called "Connections and capabilities" lets users connect services and grant permissions for calendar, mail, notes, files, program launching, and device control as needed.

Exact supported integrations, permission boundaries, per-action confirmations, permission revocation, and audit history require design. Connecting a service does not yet define which individual actions may run without confirmation.

### Personalization and memory

The assistant remembers the user's name or nickname and location. Location source, precision, updates, timezone behavior, conversation history, additional memory, cloud processing, retention, export, and deletion are not decided.

### Commercial model and localization

- Subscription-based product.
- English and Russian application languages.
- Intended audience is not restricted to one region; actual distribution, payment, and service availability require validation later.
- Whether AI usage is included, uses the customer's own API key, or supports both options is unresolved. Plan limits, cost controls, trial behavior, and expired-subscription behavior are also open.

## Existing application reference

Read-only reference: `W:\DVORETSKI`.

Evidence inspected in `Jarvis/README.md`, lines 84–122, and `Jarvis/jarvis/facts.py`, lines 36–52:

- Top-three priorities, an hourly plan, remaining/completed/overdue tasks, habit progress, and period-of-day briefings.
- The documented assistant reads today's planner information; requests to create, edit, or delete tasks are rejected and redirected to the planner.
- Frontend source was not found in the inspected installation. Backend contracts and documentation were reviewed; the actual UI was not visually assessed and no claim about all installed UI capabilities is made.

Use this as a product reference rather than an approved technology choice. Voice-driven changes are an intended capability of the new product beyond the documented reference behavior. No reference files were modified or copied into this repository.

## Voice preparation

The supplied local sample exists at `Vois/join-5tracks.mp3`. Only its presence was checked; audio quality, suitability, and usage permissions have not been evaluated. It is not included in this documentation commit or uploaded to the public repository.

Proposed voice directions for discussion, not selected production voices:

- High-tech butler: calm, precise, restrained warmth and dry humor.
- Eccentric scientist: energetic delivery, variable intonation, configurable sarcasm.
- Dark butler: composed, formal, smooth pacing and reserved irony.

Whether to use exact referenced characters and voices or original personas remains a product decision. Do not imply commercial rights or a final voice provider have been verified.

## Decisions needed before architecture

1. Included AI usage, customer API keys, or both; subscription rules for each.
2. Local and cloud data boundaries, offline behavior, and accounts on Windows.
3. Supported Windows versions, baseline hardware, and background-operation expectations.
4. Wake listening behavior, microphone indicators, voice interruption, and proactive situation triggers.
5. Character presentation: static, animated 2D, 3D, or another format; exact persona and voice requirements.
6. Confirmation and undo rules for changes to plans, mail, files, and device actions.
7. Initial supported external services, calendar ownership, and import/export needs.
8. Detailed task scheduling and habit semantics.

Next: resolve these product questions, review full user journeys, and then propose an architecture for explicit owner approval.
