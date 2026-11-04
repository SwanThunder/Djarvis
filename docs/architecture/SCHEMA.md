# Database schema, version 1

[Русская версия](SCHEMA.ru.md) · [Technical design](TECHNICAL_DESIGN.md) · [API](API.md) · [Modules](MODULES.md) · [Planner core](PLANNER_CORE.md) · [Decisions](DECISIONS.md)

Status: proposal by agent-02 (PLAN-024), 2026-11-04. Under owner review. This is the complete structure of the first migration `0001_initial`: all tables, columns, keys and constraints. No code or SQL migration files are written until approval. The owner's answers to questions Q1–Q5 (PLAN-024) are incorporated into the schema and collected in §12.

## 1. General rules

| Rule | How |
| --- | --- |
| Schema | All tables are in the `app` schema; service tables are in `meta` |
| Keys | `uuid DEFAULT uuidv7()` — time-ordered, suitable for future synchronization |
| Revisions | Every mutable record has `revision bigint NOT NULL DEFAULT 1`, `created_at`, `updated_at` (`timestamptz`). The shared trigger `meta.touch()` before `UPDATE` increments `revision` and sets `updated_at = now()`. The core updates with the condition `WHERE id = $1 AND revision = $expected`; zero rows is a `Conflict` |
| Profile | `profile_id` is present on root entities (task, habit, project, note, event, etc.). Child records get the profile through their parent |
| Time | An instant is `timestamptz`. The user's intent is stored as separate fields `*_date date`, `*_time time` and `*_tz text` (IANA zone name) |
| Enumerations | `text` + `CHECK (... IN (...))`; a new value is added by a migration |
| Deletion | Physical, with cascade, unless an ADR requires history. Completion history, habit entries and the audit log are not deleted on edit |
| Money, license, OAuth tokens | Absent from the database. License and trial are in protected storage; tokens are in the Windows secret store (CP15) |

The tables below are grouped by meaning; in the migration file they are created in foreign-key dependency order. Abbreviation used in the tables below: **[common]** = `revision`, `created_at`, `updated_at`.

## 2. Profile and settings

```sql
CREATE TABLE app.profile (
  id            uuid PRIMARY KEY DEFAULT uuidv7(),
  display_name  text,                                   -- how to address the user
  locale        text NOT NULL CHECK (locale IN ('ru','en')),
  timezone      text NOT NULL,                          -- current IANA zone
  city          text,
  city_source   text CHECK (city_source IN ('manual','auto')),
  persona       text NOT NULL DEFAULT 'edward' CHECK (persona IN ('edward','volt','nova'))
  -- [common]
);

CREATE TABLE app.setting (
  profile_id  uuid NOT NULL REFERENCES app.profile(id) ON DELETE CASCADE,
  key         text NOT NULL,
  value       jsonb NOT NULL,
  revision    bigint NOT NULL DEFAULT 1,
  updated_at  timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (profile_id, key)
);

CREATE TABLE app.availability_window (       -- available hours for auto-planning
  id          uuid PRIMARY KEY DEFAULT uuidv7(),
  profile_id  uuid NOT NULL REFERENCES app.profile(id) ON DELETE CASCADE,
  weekday     smallint NOT NULL CHECK (weekday BETWEEN 1 AND 7),   -- 1 = Monday
  start_time  time NOT NULL,
  end_time    time NOT NULL CHECK (end_time > start_time)
  -- [common]
);
```

The `setting` keys are defined by a closed registry in code; each value is validated by its own Pydantic model. Registry v1: `appearance` (palette, Glass/Solid, microphone button), `advanced_fields` (subtasks, checklists, tags, attachments), `breaks` (duration and frequency; empty means no automatic breaks), `quiet_hours` (schedule or an explicit "no quiet hours"), `proactive` (morning plan, daytime reminders, evening review, triggers, absence threshold), `voice` (wake phrase, response wait, automatic model unloading), `history` (retention period, on/off), `backup` (schedule, retention, folder), `notifications`, `autostart`.

## 3. Projects, notes, tags, attachments

```sql
CREATE TABLE app.project (
  id          uuid PRIMARY KEY DEFAULT uuidv7(),
  profile_id  uuid NOT NULL REFERENCES app.profile(id) ON DELETE CASCADE,
  title       text NOT NULL CHECK (length(btrim(title)) > 0),
  description text,
  color       text,
  state       text NOT NULL DEFAULT 'active' CHECK (state IN ('active','archived')),
  sort_order  integer NOT NULL DEFAULT 0
  -- [common]
);

CREATE TABLE app.note (
  id          uuid PRIMARY KEY DEFAULT uuidv7(),
  profile_id  uuid NOT NULL REFERENCES app.profile(id) ON DELETE CASCADE,
  project_id  uuid REFERENCES app.project(id) ON DELETE SET NULL,
  title       text NOT NULL DEFAULT '',
  body        text NOT NULL DEFAULT '',             -- Markdown
  pinned      boolean NOT NULL DEFAULT false,
  search      tsvector GENERATED ALWAYS AS (
                setweight(to_tsvector('russian', title), 'A') || setweight(to_tsvector('english', title), 'A') ||
                to_tsvector('russian', body) || to_tsvector('english', body)) STORED
  -- [common]
);
CREATE INDEX note_search ON app.note USING gin (search);

CREATE TABLE app.note_task (                         -- link between a note and tasks
  note_id  uuid NOT NULL REFERENCES app.note(id) ON DELETE CASCADE,
  task_id  uuid NOT NULL REFERENCES app.task(id) ON DELETE CASCADE,
  PRIMARY KEY (note_id, task_id)
);

CREATE TABLE app.tag (
  id          uuid PRIMARY KEY DEFAULT uuidv7(),
  profile_id  uuid NOT NULL REFERENCES app.profile(id) ON DELETE CASCADE,
  name        text NOT NULL CHECK (length(btrim(name)) > 0),
  color       text
  -- [common]
);
CREATE UNIQUE INDEX tag_name ON app.tag (profile_id, lower(name));

CREATE TABLE app.task_tag (task_id uuid REFERENCES app.task(id) ON DELETE CASCADE,
                           tag_id  uuid REFERENCES app.tag(id)  ON DELETE CASCADE,
                           PRIMARY KEY (task_id, tag_id));
CREATE TABLE app.note_tag (note_id uuid REFERENCES app.note(id) ON DELETE CASCADE,
                           tag_id  uuid REFERENCES app.tag(id)  ON DELETE CASCADE,
                           PRIMARY KEY (note_id, tag_id));

CREATE TABLE app.attachment (
  id          uuid PRIMARY KEY DEFAULT uuidv7(),
  profile_id  uuid NOT NULL REFERENCES app.profile(id) ON DELETE CASCADE,
  task_id     uuid REFERENCES app.task(id) ON DELETE CASCADE,
  note_id     uuid REFERENCES app.note(id) ON DELETE CASCADE,
  file_name   text NOT NULL,
  media_type  text NOT NULL,
  size_bytes  bigint NOT NULL CHECK (size_bytes >= 0),
  sha256      bytea NOT NULL,                      -- file name in storage: files/<sha256>
  created_at  timestamptz NOT NULL DEFAULT now(),
  CHECK (num_nonnulls(task_id, note_id) = 1)
);
```

An attachment file is immutable and stored once per content. The garbage collector deletes a file only when no record references its `sha256` and it is not pinned by a running backup (CP15).

## 4. Tasks

Three concepts from the [planner core](PLANNER_CORE.md) §2: **task** (what to do), **occurrence** (an executable instance with its own deadline and completion), **placement** (when it is scheduled).

```sql
CREATE TABLE app.task (
  id              uuid PRIMARY KEY DEFAULT uuidv7(),
  profile_id      uuid NOT NULL REFERENCES app.profile(id) ON DELETE CASCADE,
  parent_id       uuid REFERENCES app.task(id) ON DELETE CASCADE,       -- Q1: the core asks whether to delete the branch or lift the children
  project_id      uuid REFERENCES app.project(id) ON DELETE SET NULL,
  title           text NOT NULL CHECK (length(btrim(title)) > 0),
  description     text,
  priority        text NOT NULL CHECK (priority IN ('low','normal','high','urgent')),  -- no default value
  estimate_min    integer CHECK (estimate_min > 0),                     -- may be absent
  split_allowed   boolean NOT NULL DEFAULT false,                       -- splitting only with consent
  split_min_min   integer CHECK (split_min_min > 0),
  advanced_open   boolean NOT NULL DEFAULT false,                       -- whether the advanced fields are expanded
  announce_missed boolean NOT NULL DEFAULT true,                        -- Q5: announce a missed slot aloud
  sort_order      integer NOT NULL DEFAULT 0,
  archived_at     timestamptz,
  CHECK (parent_id IS DISTINCT FROM id)
  -- [common]
);
CREATE INDEX task_parent ON app.task (parent_id);
CREATE INDEX task_project ON app.task (project_id);
CREATE INDEX task_title_trgm ON app.task USING gin (title gin_trgm_ops);   -- fast search

CREATE TABLE app.recurrence_rule (
  id                 uuid PRIMARY KEY DEFAULT uuidv7(),
  task_id            uuid NOT NULL UNIQUE REFERENCES app.task(id) ON DELETE CASCADE,
  freq               text NOT NULL CHECK (freq IN ('daily','weekly','monthly','yearly','every_n_days')),
  interval_n         integer NOT NULL DEFAULT 1 CHECK (interval_n > 0),
  weekdays           smallint[],                      -- for weekly, 1..7
  month_day          smallint CHECK (month_day BETWEEN 1 AND 31),
  anchor_date        date NOT NULL,                   -- original anchor, never shifted
  anchor_time        time,
  tz                 text NOT NULL,
  tz_policy          text CHECK (tz_policy IN ('follow_local','fixed_origin')),   -- NULL = ask when the zone changes
  missing_day        text NOT NULL DEFAULT 'last_day' CHECK (missing_day IN ('last_day','skip')),
  deadline_offset_min integer,                        -- occurrence deadline relative to its date, if set
  until_date         date,
  generated_until    date NOT NULL,                   -- cursor: the date up to which occurrences have been created
  rule_version       integer NOT NULL DEFAULT 1
  -- [common]
);

CREATE TABLE app.recurrence_exception (                 -- skip of an occurrence not yet created
  rule_id         uuid NOT NULL REFERENCES app.recurrence_rule(id) ON DELETE CASCADE,
  recurrence_key  date NOT NULL,                        -- original date of the occurrence
  kind            text NOT NULL CHECK (kind IN ('skip')),
  created_at      timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (rule_id, recurrence_key)
);

CREATE TABLE app.task_occurrence (
  id              uuid PRIMARY KEY DEFAULT uuidv7(),
  task_id         uuid NOT NULL REFERENCES app.task(id) ON DELETE CASCADE,
  parent_occurrence_id uuid REFERENCES app.task_occurrence(id) ON DELETE CASCADE,  -- Q2: subtask occurrence inside an occurrence of a recurring parent
  recurrence_key  date,                                 -- NULL for a one-off task
  planning_date   date,                                 -- "do on this day", window 06:00–22:00
  deadline_date   date,
  deadline_time   time,
  deadline_tz     text,
  start_marker_at timestamptz,                          -- start only, duration unknown
  start_marker_tz text,
  state           text NOT NULL DEFAULT 'open' CHECK (state IN ('open','completed','cancelled')),
  completed_at    timestamptz,
  cancelled_at    timestamptz,
  CHECK ((deadline_date IS NULL) = (deadline_time IS NULL)),     -- a deadline without a time is forbidden: always ask
  CHECK ((deadline_date IS NULL) = (deadline_tz IS NULL)),
  CHECK ((start_marker_at IS NULL) = (start_marker_tz IS NULL)),
  CHECK ((state = 'completed') = (completed_at IS NOT NULL)),
  CHECK ((state = 'cancelled') = (cancelled_at IS NOT NULL))
  -- [common]
);
CREATE UNIQUE INDEX occurrence_key ON app.task_occurrence (task_id, recurrence_key) NULLS NOT DISTINCT;
CREATE INDEX occurrence_open_deadline ON app.task_occurrence (deadline_date) WHERE state = 'open';
CREATE INDEX occurrence_open_planning ON app.task_occurrence (planning_date) WHERE state = 'open';
CREATE INDEX occurrence_parent ON app.task_occurrence (parent_occurrence_id);

CREATE TABLE app.checklist_template_item (              -- Q2: checklist template of a recurring task
  id        uuid PRIMARY KEY DEFAULT uuidv7(),
  task_id   uuid NOT NULL REFERENCES app.task(id) ON DELETE CASCADE,
  text      text NOT NULL CHECK (length(btrim(text)) > 0),
  position  integer NOT NULL
  -- [common]
);

CREATE TABLE app.checklist_item (                       -- items of a specific occurrence
  id            uuid PRIMARY KEY DEFAULT uuidv7(),
  occurrence_id uuid NOT NULL REFERENCES app.task_occurrence(id) ON DELETE CASCADE,
  text          text NOT NULL CHECK (length(btrim(text)) > 0),
  done_at       timestamptz,
  position      integer NOT NULL
  -- [common]
);
```

Rules checked by the core (not expressible as `CHECK`):

- No cycles in `parent_id`: before insertion and move, the core verifies with a recursive query that the new parent is not a descendant.
- **Q1 (deletion):** if a task has subtasks, the core responds with `NeedsClarification` giving their count and two options: "Delete all" (cascade) or "Keep subtasks" (the children get the `parent_id` of the task being deleted, that is, they are lifted one level up; for a root task they become root tasks).
- **Q2 (recurring parent):** subtasks of a recurring task are templates without their own recurrence rule. When creating each occurrence of the parent, the core creates one occurrence of each subtask with the `parent_occurrence_id` of that occurrence; the checklist is copied from `checklist_template_item` into the occurrence's `checklist_item`. Marks from a past repetition do not carry over to the next one. Editing the template affects occurrences not yet created and, depending on the chosen scope, the open ones.
- **Q4 (moving a branch):** a task with subtasks can be moved into any project and under any task except its own descendants. The children's project does not change by itself.
- A new subtask gets the parent's suggested project and priority only after confirmation; the deadline is set separately; later edits of the parent do not propagate to the children (ADR-009).
- "Finish subtasks" returns to the child list and leaves the parent incomplete; "Close task" completes only the selected parent occurrence (ADR-008).
- Creating occurrences of a recurring task is a background job: from `generated_until` to a horizon of 60 days ahead, `INSERT … ON CONFLICT DO NOTHING`. Missed occurrences stay open — that is debt. Cancelled ones are not created again because their row already exists.
- Editing a recurrence asks for the scope: "only this occurrence", "this and future", "the whole series". "This and future" closes the rule with `until_date` and creates a new rule with a new anchor; completed occurrences do not change.

## 5. Placements and the day plan

```sql
CREATE TABLE app.schedule_placement (
  id             uuid PRIMARY KEY DEFAULT uuidv7(),
  profile_id     uuid NOT NULL REFERENCES app.profile(id) ON DELETE CASCADE,
  occurrence_id  uuid REFERENCES app.task_occurrence(id) ON DELETE CASCADE,
  habit_id       uuid REFERENCES app.habit(id) ON DELETE CASCADE,
  habit_date     date,                                  -- the habit day the block belongs to
  start_at       timestamptz NOT NULL,
  end_at         timestamptz NOT NULL,                  -- end is exclusive
  tz             text NOT NULL,
  source         text NOT NULL CHECK (source IN ('manual','auto','sync')),
  locked         boolean NOT NULL,                      -- manual ones are true until the user allows changes
  segment_no     smallint NOT NULL DEFAULT 1 CHECK (segment_no > 0),
  checked_off_at timestamptz,                           -- part marked: progress only
  state          text NOT NULL DEFAULT 'active' CHECK (state IN ('active','released')),
  released_at    timestamptz,
  proposal_id    uuid REFERENCES app.day_plan_proposal(id) ON DELETE SET NULL,
  CHECK (end_at > start_at),
  CHECK (num_nonnulls(occurrence_id, habit_id) = 1),
  CHECK ((habit_id IS NULL) = (habit_date IS NULL)),
  CHECK ((state = 'released') = (released_at IS NOT NULL))
  -- [common]
);
CREATE INDEX placement_active_time ON app.schedule_placement (profile_id, start_at) WHERE state = 'active';
CREATE INDEX placement_occurrence ON app.schedule_placement (occurrence_id);

CREATE TABLE app.planning_guard (                       -- revision of everything that affects the plan
  profile_id  uuid PRIMARY KEY REFERENCES app.profile(id) ON DELETE CASCADE,
  revision    bigint NOT NULL DEFAULT 1
);

CREATE TABLE app.day_plan_proposal (
  id                uuid PRIMARY KEY DEFAULT uuidv7(),
  profile_id        uuid NOT NULL REFERENCES app.profile(id) ON DELETE CASCADE,
  local_date        date NOT NULL,
  tz                text NOT NULL,
  planning_revision bigint NOT NULL,                    -- snapshot of planning_guard
  origin            text NOT NULL CHECK (origin IN ('ui','voice','proactive')),
  state             text NOT NULL DEFAULT 'proposed' CHECK (state IN ('proposed','applied','rejected','stale')),
  created_at        timestamptz NOT NULL DEFAULT now(),
  decided_at        timestamptz
);

CREATE TABLE app.day_plan_item (
  id             uuid PRIMARY KEY DEFAULT uuidv7(),
  proposal_id    uuid NOT NULL REFERENCES app.day_plan_proposal(id) ON DELETE CASCADE,
  kind           text NOT NULL CHECK (kind IN ('place','move','keep','break','unplaced')),
  occurrence_id  uuid REFERENCES app.task_occurrence(id) ON DELETE CASCADE,
  habit_id       uuid REFERENCES app.habit(id) ON DELETE CASCADE,
  placement_id   uuid REFERENCES app.schedule_placement(id) ON DELETE CASCADE,   -- for move/keep
  start_at       timestamptz,
  end_at         timestamptz,
  reason         text CHECK (reason IN ('no_interval','deadline_unreachable','needs_duration','excluded')),
  CHECK ((kind = 'unplaced') = (reason IS NOT NULL)),
  CHECK (kind IN ('unplaced','break') OR (start_at IS NOT NULL AND end_at > start_at))
);
```

- Every command that changes tasks, occurrences, placements, events, available hours, breaks or habits with placement increments `planning_guard.revision` in the same transaction. Applying a plan checks the revision; on mismatch the proposal becomes `stale` and the plan is rebuilt (CP02 §3.3).
- Completing an occurrence moves its **future** active placements to `released`; past ones remain as history (ADR-007). **Q3:** if an occurrence is completed in the middle of an active block, the block's `end_at` becomes the moment of completion (the past part remains as history) and the remaining time is released.
- Missed time (the placement has passed, the occurrence is not completed) and an overdue deadline are computed by a query and not stored.

## 6. Habits and timers

```sql
CREATE TABLE app.habit (
  id             uuid PRIMARY KEY DEFAULT uuidv7(),
  profile_id     uuid NOT NULL REFERENCES app.profile(id) ON DELETE CASCADE,
  title          text NOT NULL CHECK (length(btrim(title)) > 0),
  kind           text NOT NULL CHECK (kind IN ('yes_no','quantity','duration','abstinence')),
  unit           text,                                  -- for quantity
  quantity_mode  text CHECK (quantity_mode IN ('sum','daily_total')),
  started_on     date NOT NULL,                         -- no entries before this date
  ended_on       date,
  tz             text NOT NULL,
  tz_policy      text CHECK (tz_policy IN ('follow_local','fixed_origin')),
  state          text NOT NULL DEFAULT 'active' CHECK (state IN ('active','archived')),
  color          text,
  sort_order     integer NOT NULL DEFAULT 0,
  CHECK ((kind = 'quantity') = (quantity_mode IS NOT NULL))
  -- [common]
);

CREATE TABLE app.habit_schedule (                       -- versions of the goal and schedule
  id              uuid PRIMARY KEY DEFAULT uuidv7(),
  habit_id        uuid NOT NULL REFERENCES app.habit(id) ON DELETE CASCADE,
  effective_from  date NOT NULL,
  schedule_kind   text NOT NULL CHECK (schedule_kind IN ('fixed_days','times_per_week')),
  weekdays        smallint[],                           -- fixed_days
  times_per_week  smallint CHECK (times_per_week BETWEEN 1 AND 7),
  target_value    numeric(12,3) CHECK (target_value > 0),     -- quantity
  target_seconds  integer CHECK (target_seconds > 0),         -- duration
  created_at      timestamptz NOT NULL DEFAULT now(),
  UNIQUE (habit_id, effective_from),
  CHECK ((schedule_kind = 'fixed_days') = (weekdays IS NOT NULL)),
  CHECK ((schedule_kind = 'times_per_week') = (times_per_week IS NOT NULL))
);

CREATE TABLE app.habit_pause (
  id         uuid PRIMARY KEY DEFAULT uuidv7(),
  habit_id   uuid NOT NULL REFERENCES app.habit(id) ON DELETE CASCADE,
  from_date  date NOT NULL,
  to_date    date NOT NULL CHECK (to_date >= from_date)
  -- [common]
);

CREATE TABLE app.habit_entry (                          -- append-only; corrections reference the original
  id              uuid PRIMARY KEY DEFAULT uuidv7(),
  habit_id        uuid NOT NULL REFERENCES app.habit(id) ON DELETE CASCADE,
  local_date      date NOT NULL,
  kind            text NOT NULL CHECK (kind IN ('done','portion','daily_total','duration','complied','violated')),
  value           numeric(12,3),
  seconds         integer CHECK (seconds > 0),
  source          text NOT NULL CHECK (source IN ('manual','voice','timer')),
  timer_session_id uuid REFERENCES app.timer_session(id) ON DELETE SET NULL,
  corrects_id     uuid REFERENCES app.habit_entry(id),  -- this entry corrects another one
  superseded_at   timestamptz,                          -- entry replaced by a correction or cancelled
  action_id       text NOT NULL,                        -- replay protection
  recorded_at     timestamptz NOT NULL DEFAULT now(),
  UNIQUE (habit_id, action_id)
);
CREATE INDEX habit_entry_day ON app.habit_entry (habit_id, local_date) WHERE superseded_at IS NULL;

CREATE TABLE app.timer_session (
  id              uuid PRIMARY KEY DEFAULT uuidv7(),
  habit_id        uuid NOT NULL REFERENCES app.habit(id) ON DELETE CASCADE,
  state           text NOT NULL CHECK (state IN ('running','paused','stopped')),
  started_at      timestamptz NOT NULL,
  last_resumed_at timestamptz,                          -- start of the current segment
  accumulated_s   integer NOT NULL DEFAULT 0,           -- sum of closed segments
  tz              text NOT NULL,
  stopped_at      timestamptz
  -- [common]
);
CREATE UNIQUE INDEX one_live_timer ON app.timer_session (habit_id) WHERE state <> 'stopped';
-- At most one live timer per habit; independent timers for different habits are allowed.

CREATE TABLE app.habit_goal_proposal (                  -- assistant proposals; applied only after consent
  id            uuid PRIMARY KEY DEFAULT uuidv7(),
  habit_id      uuid NOT NULL REFERENCES app.habit(id) ON DELETE CASCADE,
  proposed      jsonb NOT NULL,                         -- new version of habit_schedule
  reason        text NOT NULL,
  effective_from date NOT NULL,
  state         text NOT NULL DEFAULT 'proposed' CHECK (state IN ('proposed','accepted','rejected','expired')),
  created_at    timestamptz NOT NULL DEFAULT now(),
  decided_at    timestamptz
);
```

- The current value of a day is the sum of the active entries (`superseded_at IS NULL`). Backdated correction: the old entry gets `superseded_at`, the new one gets `corrects_id`. History is preserved; statistics take the goal from the `habit_schedule` version in effect on that day (ADR-009).
- `daily_total` replaces the sum of the day's portions rather than adding to it. Changing the quantity mode recalculates only the current day.
- Abstinence: success only with a `complied` entry; the absence of an entry is not success.
- Timer: each segment is a "start, pause" pair; the value is stored in `accumulated_s` and `last_resumed_at`, so the timer survives sleep, exit and shutdown without background ticking. On stop, the core splits the total at local midnights and writes one `duration` entry per day in one transaction. If at startup `now()` is earlier than `last_resumed_at` (the clock was set back), the timer gets the status "needs review", and the user is shown a question instead of a negative time.
- Statistics (streaks, percentages, misses) are computed by queries over `habit_entry`, `habit_schedule` and `habit_pause`; there is no separate cache table in v1. If measurements show slow performance, a materialized view is added.

## 7. Calendar and external providers

```sql
CREATE TABLE app.calendar_event (
  id                 uuid PRIMARY KEY DEFAULT uuidv7(),
  profile_id         uuid NOT NULL REFERENCES app.profile(id) ON DELETE CASCADE,
  title              text NOT NULL,
  description        text,
  location           text,
  all_day            boolean NOT NULL DEFAULT false,
  start_at           timestamptz,                       -- for timed events
  end_at             timestamptz,
  start_date         date,                              -- for all-day events
  end_date           date,
  tz                 text NOT NULL,
  busy               boolean NOT NULL DEFAULT true,
  rrule              text,                              -- subset of RFC 5545
  series_id          uuid REFERENCES app.calendar_event(id) ON DELETE CASCADE,   -- modified instance of a series
  original_start     timestamptz,                       -- original time of the modified instance
  cancelled          boolean NOT NULL DEFAULT false,
  origin             text NOT NULL CHECK (origin IN ('local','google','microsoft')),
  CHECK (all_day OR (start_at IS NOT NULL AND end_at > start_at)),
  CHECK (NOT all_day OR (start_date IS NOT NULL AND end_date > start_date)),
  CHECK ((series_id IS NULL) = (original_start IS NULL))
  -- [common]
);
CREATE INDEX event_range ON app.calendar_event (profile_id, start_at, end_at);

CREATE TABLE app.provider_account (
  id            uuid PRIMARY KEY DEFAULT uuidv7(),
  profile_id    uuid NOT NULL REFERENCES app.profile(id) ON DELETE CASCADE,
  provider      text NOT NULL CHECK (provider IN ('google','microsoft')),
  account_label text NOT NULL,                          -- address shown to the user
  scopes        text[] NOT NULL,
  secret_ref    text NOT NULL,                          -- key in the Windows secret store, not the token itself
  state         text NOT NULL CHECK (state IN ('connected','needs_reauth','revoked'))
  -- [common]
);

CREATE TABLE app.provider_calendar (
  id                   uuid PRIMARY KEY DEFAULT uuidv7(),
  account_id           uuid NOT NULL REFERENCES app.provider_account(id) ON DELETE CASCADE,
  remote_id            text NOT NULL,
  name                 text NOT NULL,
  sync_events          boolean NOT NULL DEFAULT false,  -- selected events, both directions
  export_task_blocks   boolean NOT NULL DEFAULT false,
  export_habit_blocks  boolean NOT NULL DEFAULT false,  -- separate consent, off by default
  sync_cursor          text,
  UNIQUE (account_id, remote_id)
  -- [common]
);

CREATE TABLE app.provider_mapping (
  id               uuid PRIMARY KEY DEFAULT uuidv7(),
  calendar_id      uuid NOT NULL REFERENCES app.provider_calendar(id) ON DELETE CASCADE,
  remote_object_id text NOT NULL,
  remote_etag      text,
  event_id         uuid REFERENCES app.calendar_event(id) ON DELETE SET NULL,
  placement_id     uuid REFERENCES app.schedule_placement(id) ON DELETE SET NULL,
  base_snapshot    jsonb NOT NULL,                      -- last reconciled version, used for comparison
  last_synced_at   timestamptz NOT NULL,
  UNIQUE (calendar_id, remote_object_id)
  -- [common]
);

CREATE TABLE app.sync_conflict (
  id               uuid PRIMARY KEY DEFAULT uuidv7(),
  mapping_id       uuid NOT NULL REFERENCES app.provider_mapping(id) ON DELETE CASCADE,
  kind             text NOT NULL CHECK (kind IN ('both_changed','remote_deleted')),
  local_snapshot   jsonb,
  remote_snapshot  jsonb,
  state            text NOT NULL DEFAULT 'open' CHECK (state IN ('open','kept_local','kept_remote','deleted_local')),
  created_at       timestamptz NOT NULL DEFAULT now(),
  resolved_at      timestamptz
);
```

`provider_mapping` references a placement, not a task: deleting a block at the provider does not delete the task or habit (PRODUCT). Gmail does not store mail in the database: messages are read on demand, and drafts and sending go through the `outbox` (§8).

## 8. Actions, permissions, queue

```sql
CREATE TABLE app.processed_action (                     -- command idempotency
  profile_id   uuid NOT NULL REFERENCES app.profile(id) ON DELETE CASCADE,
  action_id    text NOT NULL,
  request_hash bytea NOT NULL,                          -- replay with a different body = Conflict
  result       jsonb NOT NULL,
  created_at   timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (profile_id, action_id)
);

CREATE TABLE app.approval_request (                     -- pending confirmation
  id               uuid PRIMARY KEY DEFAULT uuidv7(),
  profile_id       uuid NOT NULL REFERENCES app.profile(id) ON DELETE CASCADE,
  command          text NOT NULL,
  payload          jsonb NOT NULL,                      -- exact recipients, texts, targets
  payload_hash     bytea NOT NULL,
  target_revisions jsonb NOT NULL,
  origin           text NOT NULL CHECK (origin IN ('ui','voice','assistant','proactive','sync')),
  state            text NOT NULL DEFAULT 'pending' CHECK (state IN ('pending','approved','rejected','expired','stale')),
  expires_at       timestamptz NOT NULL,
  created_at       timestamptz NOT NULL DEFAULT now(),
  decided_at       timestamptz
);

CREATE TABLE app.capability_grant (                     -- revocable "no confirmation" permissions
  id          uuid PRIMARY KEY DEFAULT uuidv7(),
  profile_id  uuid NOT NULL REFERENCES app.profile(id) ON DELETE CASCADE,
  capability  text NOT NULL CHECK (capability IN (
                'task.create','task.edit','task.move','task.complete','task.delete',
                'plan.apply','app.launch','gmail.access','calendar.google','calendar.microsoft','city.auto')),
  granted_at  timestamptz NOT NULL DEFAULT now(),
  revoked_at  timestamptz
);
CREATE UNIQUE INDEX grant_active ON app.capability_grant (profile_id, capability) WHERE revoked_at IS NULL;

CREATE TABLE app.launch_target (                        -- programs that are allowed to be launched
  id           uuid PRIMARY KEY DEFAULT uuidv7(),
  profile_id   uuid NOT NULL REFERENCES app.profile(id) ON DELETE CASCADE,
  display_name text NOT NULL,
  exe_path     text NOT NULL,
  publisher    text,                                    -- publisher from the file signature, if any
  sha256       bytea NOT NULL                           -- launch only the same file
  -- [common]
);

CREATE TABLE app.outbox (                               -- external actions: calendars, mail
  id            uuid PRIMARY KEY DEFAULT uuidv7(),
  profile_id    uuid NOT NULL REFERENCES app.profile(id) ON DELETE CASCADE,
  adapter       text NOT NULL CHECK (adapter IN ('google_calendar','microsoft_calendar','gmail')),
  operation     text NOT NULL,
  operation_key text NOT NULL,
  payload       jsonb NOT NULL,
  state         text NOT NULL DEFAULT 'pending' CHECK (state IN ('pending','sending','confirmed','failed','unknown','conflict')),
  attempts      integer NOT NULL DEFAULT 0,
  next_attempt_at timestamptz NOT NULL DEFAULT now(),
  last_error    text,
  created_at    timestamptz NOT NULL DEFAULT now(),
  UNIQUE (adapter, operation_key)
);
CREATE INDEX outbox_due ON app.outbox (next_attempt_at) WHERE state = 'pending';

CREATE TABLE app.audit_event (                          -- metadata without content
  id          uuid PRIMARY KEY DEFAULT uuidv7(),
  profile_id  uuid NOT NULL REFERENCES app.profile(id) ON DELETE CASCADE,
  action_id   text,
  command     text NOT NULL,
  entity_type text,
  entity_id   uuid,
  origin      text NOT NULL,
  outcome     text NOT NULL,
  at          timestamptz NOT NULL DEFAULT now()
);
```

- A message in the `unknown` state (sending was interrupted, the outcome is not known) is never resent automatically: the user is shown a question (PRODUCT).
- Permissions for deleting and overwriting files, sending mail, shutdown, restart and signing out of Windows are intentionally absent from `capability_grant`: they always require confirmation.

## 9. Reminders, background jobs, assistant

```sql
CREATE TABLE app.reminder_rule (
  id            uuid PRIMARY KEY DEFAULT uuidv7(),
  profile_id    uuid NOT NULL REFERENCES app.profile(id) ON DELETE CASCADE,
  occurrence_id uuid REFERENCES app.task_occurrence(id) ON DELETE CASCADE,
  task_id       uuid REFERENCES app.task(id) ON DELETE CASCADE,          -- for every occurrence of the series
  habit_id      uuid REFERENCES app.habit(id) ON DELETE CASCADE,
  event_id      uuid REFERENCES app.calendar_event(id) ON DELETE CASCADE,
  anchor        text NOT NULL CHECK (anchor IN ('start','deadline','fixed_time')),
  offset_min    integer NOT NULL DEFAULT 0,             -- minutes before the anchor
  fixed_time    time,                                   -- for fixed_time (habits)
  channel       text NOT NULL CHECK (channel IN ('voice','notification','both')),
  enabled       boolean NOT NULL DEFAULT true,
  CHECK (num_nonnulls(occurrence_id, task_id, habit_id, event_id) = 1)
  -- [common]
);

CREATE TABLE app.scheduled_job (                        -- single reliable queue of background jobs
  id            uuid PRIMARY KEY DEFAULT uuidv7(),
  profile_id    uuid NOT NULL REFERENCES app.profile(id) ON DELETE CASCADE,
  kind          text NOT NULL CHECK (kind IN (
                  'reminder','morning_plan','evening_review','catch_up_summary',
                  'recurrence_generation','backup','history_expiry','outbox_dispatch',
                  'calendar_sync','proactive_check','placement_missed')),
  logical_key   text NOT NULL,                          -- for example reminder:<rule>:<occurrence>:<due>
  due_at        timestamptz NOT NULL,
  payload       jsonb NOT NULL DEFAULT '{}',
  state         text NOT NULL DEFAULT 'pending' CHECK (state IN ('pending','running','done','suppressed','missed','cancelled','failed')),
  attempts      integer NOT NULL DEFAULT 0,
  finished_at   timestamptz,
  last_error    text,
  UNIQUE (kind, logical_key)
);
CREATE INDEX job_due ON app.scheduled_job (due_at) WHERE state = 'pending';

CREATE TABLE app.conversation (
  id          uuid PRIMARY KEY DEFAULT uuidv7(),
  profile_id  uuid NOT NULL REFERENCES app.profile(id) ON DELETE CASCADE,
  persona     text NOT NULL,
  started_at  timestamptz NOT NULL DEFAULT now(),
  ended_at    timestamptz
);

CREATE TABLE app.conversation_message (
  id               uuid PRIMARY KEY DEFAULT uuidv7(),
  conversation_id  uuid NOT NULL REFERENCES app.conversation(id) ON DELETE CASCADE,
  role             text NOT NULL CHECK (role IN ('user','assistant','tool')),
  text             text NOT NULL,
  tool_name        text,
  created_at       timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX message_age ON app.conversation_message (created_at);

CREATE TABLE app.history_watermark (                    -- explicitly deleted history does not come back on restore
  profile_id      uuid PRIMARY KEY REFERENCES app.profile(id) ON DELETE CASCADE,
  deleted_before  timestamptz NOT NULL,
  updated_at      timestamptz NOT NULL DEFAULT now()
);
```

- On startup after sleep or shutdown, overdue `reminder` jobs are not played one by one: the core marks them `missed` and creates one `catch_up_summary` job (PRODUCT). Jobs for completed, cancelled and deleted targets are discarded.
- Reminders for a series (`task_id`) are expanded into jobs when occurrences are created.
- Raw audio is never stored in the database; `conversation_message` holds only recognized text, if history is enabled.

## 10. Service tables

```sql
CREATE TABLE meta.schema_migration (
  id          integer PRIMARY KEY,                      -- 1 = 0001_initial
  name        text NOT NULL,
  checksum    bytea NOT NULL,
  applied_at  timestamptz NOT NULL DEFAULT now(),
  app_version text NOT NULL
);

CREATE TABLE meta.backup_record (
  id             uuid PRIMARY KEY DEFAULT uuidv7(),
  file_name      text NOT NULL,
  kind           text NOT NULL CHECK (kind IN ('daily','pre_migration','manual','pre_restore')),
  schema_version integer NOT NULL,
  size_bytes     bigint,
  state          text NOT NULL CHECK (state IN ('writing','verified','failed','expired','deleted')),
  created_at     timestamptz NOT NULL DEFAULT now(),
  verified_at    timestamptz
);

CREATE TABLE meta.operation_marker (                    -- unfinished migration or restore
  kind        text PRIMARY KEY CHECK (kind IN ('migration','restore')),
  detail      jsonb NOT NULL,
  started_at  timestamptz NOT NULL DEFAULT now()
);
```

Extensions: `pg_trgm` (substring search in titles). There are no other extensions.

## 11. Role privileges

- `djarvis_owner` — owner of the `app` and `meta` schemas; runs migrations.
- `djarvis_app` — `SELECT, INSERT, UPDATE, DELETE` on the `app` tables; `SELECT, INSERT, UPDATE` on `meta.backup_record` and `meta.operation_marker`; `SELECT` only on `meta.schema_migration`. Changing the structure is forbidden.
- The connection for `pg_dump` during backup runs as `djarvis_owner`.

## 12. Owner decisions (PLAN-024)

| № | Question | Decision |
| --- | --- | --- |
| Q1 | Deleting a task with subtasks | Ask every time: "Delete all" or "Keep subtasks" (lift them one level up) |
| Q2 | Subtasks and checklist of a recurring task | A copy in each occurrence from the template; marks do not carry over between repetitions |
| Q3 | Completion in the middle of a scheduled block | The block is trimmed at the moment of completion, the remainder is released |
| Q4 | Moving a branch of subtasks | Under any task and into any project except its own descendants; the children's project does not change by itself |
| Q5 | Announcing missed time | A per-task switch "Don't announce the miss aloud"; the highlight in the list always remains |
