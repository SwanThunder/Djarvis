# Схема базы данных, версия 1

[English version](SCHEMA.md) · [Технические детали](TECHNICAL_DESIGN.ru.md) · [API](API.ru.md) · [Модули](MODULES.ru.md) · [Ядро планировщика](PLANNER_CORE.ru.md) · [Решения](DECISIONS.ru.md)

Статус: предложение agent-02 (PLAN-024), 2026-11-04. На проверке у владельца. Это полная структура первой миграции `0001_initial`: все таблицы, поля, ключи и ограничения. Код и SQL-файлы миграций не пишутся до утверждения. Ответы владельца на вопросы В1–В5 (PLAN-024) внесены в схему и собраны в §12.

## 1. Общие правила

| Правило | Как |
| --- | --- |
| Схема | Все таблицы в схеме `app`; служебные — в `meta` |
| Ключи | `uuid DEFAULT uuidv7()` — упорядочены по времени, пригодны для будущей синхронизации |
| Ревизии | У каждой изменяемой записи `revision bigint NOT NULL DEFAULT 1`, `created_at`, `updated_at` (`timestamptz`). Общий триггер `meta.touch()` перед `UPDATE` увеличивает `revision` и ставит `updated_at = now()`. Ядро обновляет с условием `WHERE id = $1 AND revision = $ожидаемая`; ноль строк — это `Conflict` |
| Профиль | `profile_id` есть у корневых сущностей (задача, привычка, проект, заметка, событие и т. д.). Дочерние записи получают профиль через родителя |
| Время | Мгновение — `timestamptz`. Намерение пользователя — `*_date date`, `*_time time` и `*_tz text` (имя зоны IANA) отдельными полями |
| Перечисления | `text` + `CHECK (... IN (...))`; новое значение добавляется миграцией |
| Удаление | Физическое с каскадом, если ADR не требует истории. История выполнений, записи привычек и журнал аудита не удаляются при правке |
| Деньги, лицензия, токены OAuth | В базе отсутствуют. Лицензия и триал — в защищённом хранилище; токены — в хранилище секретов Windows (CP15) |

Таблицы ниже сгруппированы по смыслу; в файле миграции они создаются в порядке зависимостей внешних ключей. Сокращение в таблицах ниже: **[общие]** = `revision`, `created_at`, `updated_at`.

## 2. Профиль и настройки

```sql
CREATE TABLE app.profile (
  id            uuid PRIMARY KEY DEFAULT uuidv7(),
  display_name  text,                                   -- как обращаться к пользователю
  locale        text NOT NULL CHECK (locale IN ('ru','en')),
  timezone      text NOT NULL,                          -- текущая зона IANA
  city          text,
  city_source   text CHECK (city_source IN ('manual','auto')),
  persona       text NOT NULL DEFAULT 'edward' CHECK (persona IN ('edward','volt','nova'))
  -- [общие]
);

CREATE TABLE app.setting (
  profile_id  uuid NOT NULL REFERENCES app.profile(id) ON DELETE CASCADE,
  key         text NOT NULL,
  value       jsonb NOT NULL,
  revision    bigint NOT NULL DEFAULT 1,
  updated_at  timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (profile_id, key)
);

CREATE TABLE app.availability_window (       -- доступные часы для автопланирования
  id          uuid PRIMARY KEY DEFAULT uuidv7(),
  profile_id  uuid NOT NULL REFERENCES app.profile(id) ON DELETE CASCADE,
  weekday     smallint NOT NULL CHECK (weekday BETWEEN 1 AND 7),   -- 1 = понедельник
  start_time  time NOT NULL,
  end_time    time NOT NULL CHECK (end_time > start_time)
  -- [общие]
);
```

Ключи `setting` задаёт закрытый реестр в коде; каждое значение проверяется своей моделью Pydantic. Реестр v1: `appearance` (палитра, Glass/Solid, кнопка микрофона), `advanced_fields` (подзадачи, чек-листы, теги, вложения), `breaks` (длительность и частота; пусто — без автоперерывов), `quiet_hours` (расписание или явное «без тихих часов»), `proactive` (утренний план, дневные напоминания, вечерний обзор, триггеры, порог отсутствия), `voice` (ключевая фраза, ожидание ответа, автовыгрузка модели), `history` (срок хранения, вкл/выкл), `backup` (расписание, срок, папка), `notifications`, `autostart`.

## 3. Проекты, заметки, теги, вложения

```sql
CREATE TABLE app.project (
  id          uuid PRIMARY KEY DEFAULT uuidv7(),
  profile_id  uuid NOT NULL REFERENCES app.profile(id) ON DELETE CASCADE,
  title       text NOT NULL CHECK (length(btrim(title)) > 0),
  description text,
  color       text,
  state       text NOT NULL DEFAULT 'active' CHECK (state IN ('active','archived')),
  sort_order  integer NOT NULL DEFAULT 0
  -- [общие]
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
  -- [общие]
);
CREATE INDEX note_search ON app.note USING gin (search);

CREATE TABLE app.note_task (                         -- связь заметки с задачами
  note_id  uuid NOT NULL REFERENCES app.note(id) ON DELETE CASCADE,
  task_id  uuid NOT NULL REFERENCES app.task(id) ON DELETE CASCADE,
  PRIMARY KEY (note_id, task_id)
);

CREATE TABLE app.tag (
  id          uuid PRIMARY KEY DEFAULT uuidv7(),
  profile_id  uuid NOT NULL REFERENCES app.profile(id) ON DELETE CASCADE,
  name        text NOT NULL CHECK (length(btrim(name)) > 0),
  color       text
  -- [общие]
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
  sha256      bytea NOT NULL,                      -- имя файла в хранилище: files/<sha256>
  created_at  timestamptz NOT NULL DEFAULT now(),
  CHECK (num_nonnulls(task_id, note_id) = 1)
);
```

Файл вложения неизменяем и хранится один раз на содержимое. Сборщик мусора удаляет файл, только когда на его `sha256` не ссылается ни одна запись и он не закреплён идущим бэкапом (CP15).

## 4. Задачи

Три понятия из [ядра планировщика](PLANNER_CORE.ru.md) §2: **задача** (что сделать), **вхождение** (исполняемый экземпляр со своим сроком и выполнением), **размещение** (когда запланировано).

```sql
CREATE TABLE app.task (
  id              uuid PRIMARY KEY DEFAULT uuidv7(),
  profile_id      uuid NOT NULL REFERENCES app.profile(id) ON DELETE CASCADE,
  parent_id       uuid REFERENCES app.task(id) ON DELETE CASCADE,       -- В1: ядро спрашивает, удалить ветку или поднять детей
  project_id      uuid REFERENCES app.project(id) ON DELETE SET NULL,
  title           text NOT NULL CHECK (length(btrim(title)) > 0),
  description     text,
  priority        text NOT NULL CHECK (priority IN ('low','normal','high','urgent')),  -- без значения по умолчанию
  estimate_min    integer CHECK (estimate_min > 0),                     -- может отсутствовать
  split_allowed   boolean NOT NULL DEFAULT false,                       -- дробление только по согласию
  split_min_min   integer CHECK (split_min_min > 0),
  advanced_open   boolean NOT NULL DEFAULT false,                       -- раскрыты ли расширенные поля
  announce_missed boolean NOT NULL DEFAULT true,                        -- В5: объявлять пропуск вслух
  sort_order      integer NOT NULL DEFAULT 0,
  archived_at     timestamptz,
  CHECK (parent_id IS DISTINCT FROM id)
  -- [общие]
);
CREATE INDEX task_parent ON app.task (parent_id);
CREATE INDEX task_project ON app.task (project_id);
CREATE INDEX task_title_trgm ON app.task USING gin (title gin_trgm_ops);   -- быстрый поиск

CREATE TABLE app.recurrence_rule (
  id                 uuid PRIMARY KEY DEFAULT uuidv7(),
  task_id            uuid NOT NULL UNIQUE REFERENCES app.task(id) ON DELETE CASCADE,
  freq               text NOT NULL CHECK (freq IN ('daily','weekly','monthly','yearly','every_n_days')),
  interval_n         integer NOT NULL DEFAULT 1 CHECK (interval_n > 0),
  weekdays           smallint[],                      -- для weekly, 1..7
  month_day          smallint CHECK (month_day BETWEEN 1 AND 31),
  anchor_date        date NOT NULL,                   -- исходный якорь, не сдвигается
  anchor_time        time,
  tz                 text NOT NULL,
  tz_policy          text CHECK (tz_policy IN ('follow_local','fixed_origin')),   -- NULL = спросить при смене зоны
  missing_day        text NOT NULL DEFAULT 'last_day' CHECK (missing_day IN ('last_day','skip')),
  deadline_offset_min integer,                        -- срок вхождения относительно его даты, если задан
  until_date         date,
  generated_until    date NOT NULL,                   -- курсор: до какой даты вхождения созданы
  rule_version       integer NOT NULL DEFAULT 1
  -- [общие]
);

CREATE TABLE app.recurrence_exception (                 -- пропуск ещё не созданного вхождения
  rule_id         uuid NOT NULL REFERENCES app.recurrence_rule(id) ON DELETE CASCADE,
  recurrence_key  date NOT NULL,                        -- исходная дата вхождения
  kind            text NOT NULL CHECK (kind IN ('skip')),
  created_at      timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (rule_id, recurrence_key)
);

CREATE TABLE app.task_occurrence (
  id              uuid PRIMARY KEY DEFAULT uuidv7(),
  task_id         uuid NOT NULL REFERENCES app.task(id) ON DELETE CASCADE,
  parent_occurrence_id uuid REFERENCES app.task_occurrence(id) ON DELETE CASCADE,  -- В2: вхождение подзадачи внутри вхождения повторяющегося родителя
  recurrence_key  date,                                 -- NULL у разовой задачи
  planning_date   date,                                 -- «сделать в этот день», окно 06:00–22:00
  deadline_date   date,
  deadline_time   time,
  deadline_tz     text,
  start_marker_at timestamptz,                          -- только начало, длительность неизвестна
  start_marker_tz text,
  state           text NOT NULL DEFAULT 'open' CHECK (state IN ('open','completed','cancelled')),
  completed_at    timestamptz,
  cancelled_at    timestamptz,
  CHECK ((deadline_date IS NULL) = (deadline_time IS NULL)),     -- срок без времени запрещён: всегда спросить
  CHECK ((deadline_date IS NULL) = (deadline_tz IS NULL)),
  CHECK ((start_marker_at IS NULL) = (start_marker_tz IS NULL)),
  CHECK ((state = 'completed') = (completed_at IS NOT NULL)),
  CHECK ((state = 'cancelled') = (cancelled_at IS NOT NULL))
  -- [общие]
);
CREATE UNIQUE INDEX occurrence_key ON app.task_occurrence (task_id, recurrence_key) NULLS NOT DISTINCT;
CREATE INDEX occurrence_open_deadline ON app.task_occurrence (deadline_date) WHERE state = 'open';
CREATE INDEX occurrence_open_planning ON app.task_occurrence (planning_date) WHERE state = 'open';
CREATE INDEX occurrence_parent ON app.task_occurrence (parent_occurrence_id);

CREATE TABLE app.checklist_template_item (              -- В2: шаблон чек-листа повторяющейся задачи
  id        uuid PRIMARY KEY DEFAULT uuidv7(),
  task_id   uuid NOT NULL REFERENCES app.task(id) ON DELETE CASCADE,
  text      text NOT NULL CHECK (length(btrim(text)) > 0),
  position  integer NOT NULL
  -- [общие]
);

CREATE TABLE app.checklist_item (                       -- пункты конкретного вхождения
  id            uuid PRIMARY KEY DEFAULT uuidv7(),
  occurrence_id uuid NOT NULL REFERENCES app.task_occurrence(id) ON DELETE CASCADE,
  text          text NOT NULL CHECK (length(btrim(text)) > 0),
  done_at       timestamptz,
  position      integer NOT NULL
  -- [общие]
);
```

Правила, которые проверяет ядро (не выражаются `CHECK`):

- Нет циклов в `parent_id`: перед вставкой и переносом ядро проверяет рекурсивным запросом, что новый родитель не является потомком.
- **В1 (удаление):** если у задачи есть подзадачи, ядро отвечает `NeedsClarification` с их числом и двумя вариантами: «Удалить всё» (каскад) или «Оставить подзадачи» (дети получают `parent_id` удаляемой задачи, то есть поднимаются на уровень выше; у корня — становятся корневыми).
- **В2 (повторяющийся родитель):** подзадачи повторяющейся задачи — шаблоны без собственного правила повторения. При создании каждого вхождения родителя ядро создаёт по одному вхождению каждой подзадачи с `parent_occurrence_id` этого вхождения; чек-лист копируется из `checklist_template_item` в `checklist_item` вхождения. Отметки прошлого повторения не переходят в следующее. Правка шаблона действует на ещё не созданные вхождения и, по выбору области, на открытые.
- **В4 (перенос ветки):** задачу с подзадачами можно перенести в любой проект и под любую задачу, кроме собственных потомков. Проект детей сам не меняется.
- Новая подзадача получает предложенные проект и приоритет родителя только после подтверждения; срок задаётся отдельно; последующие правки родителя не распространяются на детей (ADR-009).
- «Закрыть задачу» завершает только вхождение родителя; «Доделать подзадачи» ничего не меняет (ADR-008).
- Создание вхождений повторяющейся задачи — фоновая задача: от `generated_until` до горизонта 60 дней вперёд, `INSERT … ON CONFLICT DO NOTHING`. Пропущенные вхождения остаются открытыми — это долг. Отменённые не создаются заново, потому что их строка уже есть.
- Правка повторения спрашивает область: «только это вхождение», «это и будущие», «вся серия». «Это и будущие» закрывает правило датой `until_date` и создаёт новое правило с новым якорем; выполненные вхождения не меняются.

## 5. Размещения и план дня

```sql
CREATE TABLE app.schedule_placement (
  id             uuid PRIMARY KEY DEFAULT uuidv7(),
  profile_id     uuid NOT NULL REFERENCES app.profile(id) ON DELETE CASCADE,
  occurrence_id  uuid REFERENCES app.task_occurrence(id) ON DELETE CASCADE,
  habit_id       uuid REFERENCES app.habit(id) ON DELETE CASCADE,
  habit_date     date,                                  -- день привычки, к которому относится блок
  start_at       timestamptz NOT NULL,
  end_at         timestamptz NOT NULL,                  -- конец не включается
  tz             text NOT NULL,
  source         text NOT NULL CHECK (source IN ('manual','auto','sync')),
  locked         boolean NOT NULL,                      -- ручные — true, пока пользователь не разрешит менять
  segment_no     smallint NOT NULL DEFAULT 1 CHECK (segment_no > 0),
  checked_off_at timestamptz,                           -- отметка части: только прогресс
  state          text NOT NULL DEFAULT 'active' CHECK (state IN ('active','released')),
  released_at    timestamptz,
  proposal_id    uuid REFERENCES app.day_plan_proposal(id) ON DELETE SET NULL,
  CHECK (end_at > start_at),
  CHECK (num_nonnulls(occurrence_id, habit_id) = 1),
  CHECK ((habit_id IS NULL) = (habit_date IS NULL)),
  CHECK ((state = 'released') = (released_at IS NOT NULL))
  -- [общие]
);
CREATE INDEX placement_active_time ON app.schedule_placement (profile_id, start_at) WHERE state = 'active';
CREATE INDEX placement_occurrence ON app.schedule_placement (occurrence_id);

CREATE TABLE app.planning_guard (                       -- ревизия всего, что влияет на план
  profile_id  uuid PRIMARY KEY REFERENCES app.profile(id) ON DELETE CASCADE,
  revision    bigint NOT NULL DEFAULT 1
);

CREATE TABLE app.day_plan_proposal (
  id                uuid PRIMARY KEY DEFAULT uuidv7(),
  profile_id        uuid NOT NULL REFERENCES app.profile(id) ON DELETE CASCADE,
  local_date        date NOT NULL,
  tz                text NOT NULL,
  planning_revision bigint NOT NULL,                    -- снимок planning_guard
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
  placement_id   uuid REFERENCES app.schedule_placement(id) ON DELETE CASCADE,   -- для move/keep
  start_at       timestamptz,
  end_at         timestamptz,
  reason         text CHECK (reason IN ('no_interval','deadline_unreachable','needs_duration','excluded')),
  CHECK ((kind = 'unplaced') = (reason IS NOT NULL)),
  CHECK (kind IN ('unplaced','break') OR (start_at IS NOT NULL AND end_at > start_at))
);
```

- Каждая команда, меняющая задачи, вхождения, размещения, события, доступные часы, перерывы или привычки с размещением, в той же транзакции увеличивает `planning_guard.revision`. Применение плана сверяет ревизию; при несовпадении предложение становится `stale`, и план строится заново (CP02 §3.3).
- Завершение вхождения переводит его **будущие** активные размещения в `released`; прошедшие остаются историей (ADR-007). **В3:** если вхождение выполнено посреди активного блока, у блока `end_at` становится моментом выполнения (прошедшая часть остаётся историей), остаток времени освобождается.
- Пропущенное время (размещение прошло, вхождение не выполнено) и просроченный срок вычисляются запросом и не хранятся.

## 6. Привычки и таймеры

```sql
CREATE TABLE app.habit (
  id             uuid PRIMARY KEY DEFAULT uuidv7(),
  profile_id     uuid NOT NULL REFERENCES app.profile(id) ON DELETE CASCADE,
  title          text NOT NULL CHECK (length(btrim(title)) > 0),
  kind           text NOT NULL CHECK (kind IN ('yes_no','quantity','duration','abstinence')),
  unit           text,                                  -- для quantity
  quantity_mode  text CHECK (quantity_mode IN ('sum','daily_total')),
  started_on     date NOT NULL,                         -- раньше этой даты записей нет
  ended_on       date,
  tz             text NOT NULL,
  tz_policy      text CHECK (tz_policy IN ('follow_local','fixed_origin')),
  state          text NOT NULL DEFAULT 'active' CHECK (state IN ('active','archived')),
  color          text,
  sort_order     integer NOT NULL DEFAULT 0,
  CHECK ((kind = 'quantity') = (quantity_mode IS NOT NULL))
  -- [общие]
);

CREATE TABLE app.habit_schedule (                       -- версии цели и расписания
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
  -- [общие]
);

CREATE TABLE app.habit_entry (                          -- только добавление; исправления ссылаются на исходник
  id              uuid PRIMARY KEY DEFAULT uuidv7(),
  habit_id        uuid NOT NULL REFERENCES app.habit(id) ON DELETE CASCADE,
  local_date      date NOT NULL,
  kind            text NOT NULL CHECK (kind IN ('done','portion','daily_total','duration','complied','violated')),
  value           numeric(12,3),
  seconds         integer CHECK (seconds > 0),
  source          text NOT NULL CHECK (source IN ('manual','voice','timer')),
  timer_session_id uuid REFERENCES app.timer_session(id) ON DELETE SET NULL,
  corrects_id     uuid REFERENCES app.habit_entry(id),  -- эта запись исправляет другую
  superseded_at   timestamptz,                          -- запись заменена исправлением или отменена
  action_id       text NOT NULL,                        -- защита от повтора
  recorded_at     timestamptz NOT NULL DEFAULT now(),
  UNIQUE (habit_id, action_id)
);
CREATE INDEX habit_entry_day ON app.habit_entry (habit_id, local_date) WHERE superseded_at IS NULL;

CREATE TABLE app.timer_session (
  id              uuid PRIMARY KEY DEFAULT uuidv7(),
  habit_id        uuid NOT NULL REFERENCES app.habit(id) ON DELETE CASCADE,
  state           text NOT NULL CHECK (state IN ('running','paused','stopped')),
  started_at      timestamptz NOT NULL,
  last_resumed_at timestamptz,                          -- начало текущего отрезка
  accumulated_s   integer NOT NULL DEFAULT 0,           -- сумма закрытых отрезков
  tz              text NOT NULL,
  stopped_at      timestamptz
  -- [общие]
);
CREATE UNIQUE INDEX one_live_timer ON app.timer_session (habit_id) WHERE state <> 'stopped';

CREATE TABLE app.habit_goal_proposal (                  -- предложения ассистента; применяются только после согласия
  id            uuid PRIMARY KEY DEFAULT uuidv7(),
  habit_id      uuid NOT NULL REFERENCES app.habit(id) ON DELETE CASCADE,
  proposed      jsonb NOT NULL,                         -- новая версия habit_schedule
  reason        text NOT NULL,
  effective_from date NOT NULL,
  state         text NOT NULL DEFAULT 'proposed' CHECK (state IN ('proposed','accepted','rejected','expired')),
  created_at    timestamptz NOT NULL DEFAULT now(),
  decided_at    timestamptz
);
```

- Текущее значение дня — сумма действующих записей (`superseded_at IS NULL`). Исправление задним числом: старая запись получает `superseded_at`, новая — `corrects_id`. История сохраняется; статистика берёт цель из версии `habit_schedule`, действовавшей в тот день (ADR-009).
- `daily_total` заменяет сумму порций дня, а не добавляется к ней. Смена режима количества пересчитывает только текущий день.
- Воздержание: успех только при записи `complied`; отсутствие записи — не успех.
- Таймер: каждый отрезок — пара «начало, пауза», значение хранится в `accumulated_s` и `last_resumed_at`, поэтому таймер переживает сон, выход и выключение без фонового тиканья. При остановке ядро делит итог по локальным полуночам и пишет по одной записи `duration` на день в одной транзакции. Если при запуске `now()` раньше `last_resumed_at` (часы переведены назад), таймер получает статус «нужна проверка», и пользователю показывается вопрос, а не отрицательное время.
- Статистика (серии, проценты, пропуски) считается запросами по `habit_entry`, `habit_schedule` и `habit_pause`; отдельной таблицы кэша в v1 нет. Если замеры покажут медленную работу, добавляется материализованное представление.

## 7. Календарь и внешние провайдеры

```sql
CREATE TABLE app.calendar_event (
  id                 uuid PRIMARY KEY DEFAULT uuidv7(),
  profile_id         uuid NOT NULL REFERENCES app.profile(id) ON DELETE CASCADE,
  title              text NOT NULL,
  description        text,
  location           text,
  all_day            boolean NOT NULL DEFAULT false,
  start_at           timestamptz,                       -- для событий со временем
  end_at             timestamptz,
  start_date         date,                              -- для событий на весь день
  end_date           date,
  tz                 text NOT NULL,
  busy               boolean NOT NULL DEFAULT true,
  rrule              text,                              -- подмножество RFC 5545
  series_id          uuid REFERENCES app.calendar_event(id) ON DELETE CASCADE,   -- изменённый экземпляр серии
  original_start     timestamptz,                       -- исходное время изменённого экземпляра
  cancelled          boolean NOT NULL DEFAULT false,
  origin             text NOT NULL CHECK (origin IN ('local','google','microsoft')),
  CHECK (all_day OR (start_at IS NOT NULL AND end_at > start_at)),
  CHECK (NOT all_day OR (start_date IS NOT NULL AND end_date > start_date)),
  CHECK ((series_id IS NULL) = (original_start IS NULL))
  -- [общие]
);
CREATE INDEX event_range ON app.calendar_event (profile_id, start_at, end_at);

CREATE TABLE app.provider_account (
  id            uuid PRIMARY KEY DEFAULT uuidv7(),
  profile_id    uuid NOT NULL REFERENCES app.profile(id) ON DELETE CASCADE,
  provider      text NOT NULL CHECK (provider IN ('google','microsoft')),
  account_label text NOT NULL,                          -- адрес, показанный пользователю
  scopes        text[] NOT NULL,
  secret_ref    text NOT NULL,                          -- ключ в хранилище секретов Windows, не сам токен
  state         text NOT NULL CHECK (state IN ('connected','needs_reauth','revoked'))
  -- [общие]
);

CREATE TABLE app.provider_calendar (
  id                   uuid PRIMARY KEY DEFAULT uuidv7(),
  account_id           uuid NOT NULL REFERENCES app.provider_account(id) ON DELETE CASCADE,
  remote_id            text NOT NULL,
  name                 text NOT NULL,
  sync_events          boolean NOT NULL DEFAULT false,  -- выбранные события в обе стороны
  export_task_blocks   boolean NOT NULL DEFAULT false,
  export_habit_blocks  boolean NOT NULL DEFAULT false,  -- отдельное согласие, по умолчанию выкл
  sync_cursor          text,
  UNIQUE (account_id, remote_id)
  -- [общие]
);

CREATE TABLE app.provider_mapping (
  id               uuid PRIMARY KEY DEFAULT uuidv7(),
  calendar_id      uuid NOT NULL REFERENCES app.provider_calendar(id) ON DELETE CASCADE,
  remote_object_id text NOT NULL,
  remote_etag      text,
  event_id         uuid REFERENCES app.calendar_event(id) ON DELETE SET NULL,
  placement_id     uuid REFERENCES app.schedule_placement(id) ON DELETE SET NULL,
  base_snapshot    jsonb NOT NULL,                      -- последняя согласованная версия для сравнения
  last_synced_at   timestamptz NOT NULL,
  UNIQUE (calendar_id, remote_object_id)
  -- [общие]
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

Ссылка `provider_mapping` на размещение, а не на задачу: удаление блока у провайдера не удаляет задачу или привычку (PRODUCT). Gmail не хранит почту в базе: письма читаются по запросу, черновики и отправка идут через `outbox` (§8).

## 8. Действия, разрешения, очередь

```sql
CREATE TABLE app.processed_action (                     -- идемпотентность команд
  profile_id   uuid NOT NULL REFERENCES app.profile(id) ON DELETE CASCADE,
  action_id    text NOT NULL,
  request_hash bytea NOT NULL,                          -- повтор с другим телом = Conflict
  result       jsonb NOT NULL,
  created_at   timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (profile_id, action_id)
);

CREATE TABLE app.approval_request (                     -- ожидающее подтверждение
  id               uuid PRIMARY KEY DEFAULT uuidv7(),
  profile_id       uuid NOT NULL REFERENCES app.profile(id) ON DELETE CASCADE,
  command          text NOT NULL,
  payload          jsonb NOT NULL,                      -- точные получатели, тексты, цели
  payload_hash     bytea NOT NULL,
  target_revisions jsonb NOT NULL,
  origin           text NOT NULL CHECK (origin IN ('ui','voice','assistant','proactive','sync')),
  state            text NOT NULL DEFAULT 'pending' CHECK (state IN ('pending','approved','rejected','expired','stale')),
  expires_at       timestamptz NOT NULL,
  created_at       timestamptz NOT NULL DEFAULT now(),
  decided_at       timestamptz
);

CREATE TABLE app.capability_grant (                     -- отзываемые разрешения «без подтверждения»
  id          uuid PRIMARY KEY DEFAULT uuidv7(),
  profile_id  uuid NOT NULL REFERENCES app.profile(id) ON DELETE CASCADE,
  capability  text NOT NULL CHECK (capability IN (
                'task.create','task.edit','task.move','task.complete','task.delete',
                'plan.apply','app.launch','gmail.access','calendar.google','calendar.microsoft','city.auto')),
  granted_at  timestamptz NOT NULL DEFAULT now(),
  revoked_at  timestamptz
);
CREATE UNIQUE INDEX grant_active ON app.capability_grant (profile_id, capability) WHERE revoked_at IS NULL;

CREATE TABLE app.launch_target (                        -- программы, которые разрешено запускать
  id           uuid PRIMARY KEY DEFAULT uuidv7(),
  profile_id   uuid NOT NULL REFERENCES app.profile(id) ON DELETE CASCADE,
  display_name text NOT NULL,
  exe_path     text NOT NULL,
  publisher    text,                                    -- издатель из подписи файла, если есть
  sha256       bytea NOT NULL                           -- запуск только того же файла
  -- [общие]
);

CREATE TABLE app.outbox (                               -- внешние действия: календари, почта
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

CREATE TABLE app.audit_event (                          -- метаданные без содержимого
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

- Письмо в состоянии `unknown` (отправка прервалась, результат не известен) никогда не отправляется повторно автоматически: пользователь видит вопрос (PRODUCT).
- Разрешения на удаление и перезапись файлов, отправку письма, выключение, перезагрузку и выход из Windows в `capability_grant` отсутствуют намеренно: они всегда требуют подтверждения.

## 9. Напоминания, фоновые задания, ассистент

```sql
CREATE TABLE app.reminder_rule (
  id            uuid PRIMARY KEY DEFAULT uuidv7(),
  profile_id    uuid NOT NULL REFERENCES app.profile(id) ON DELETE CASCADE,
  occurrence_id uuid REFERENCES app.task_occurrence(id) ON DELETE CASCADE,
  task_id       uuid REFERENCES app.task(id) ON DELETE CASCADE,          -- для каждого вхождения серии
  habit_id      uuid REFERENCES app.habit(id) ON DELETE CASCADE,
  event_id      uuid REFERENCES app.calendar_event(id) ON DELETE CASCADE,
  anchor        text NOT NULL CHECK (anchor IN ('start','deadline','fixed_time')),
  offset_min    integer NOT NULL DEFAULT 0,             -- минут до якоря
  fixed_time    time,                                   -- для fixed_time (привычки)
  channel       text NOT NULL CHECK (channel IN ('voice','notification','both')),
  enabled       boolean NOT NULL DEFAULT true,
  CHECK (num_nonnulls(occurrence_id, task_id, habit_id, event_id) = 1)
  -- [общие]
);

CREATE TABLE app.scheduled_job (                        -- единая надёжная очередь фоновых заданий
  id            uuid PRIMARY KEY DEFAULT uuidv7(),
  profile_id    uuid NOT NULL REFERENCES app.profile(id) ON DELETE CASCADE,
  kind          text NOT NULL CHECK (kind IN (
                  'reminder','morning_plan','evening_review','catch_up_summary',
                  'recurrence_generation','backup','history_expiry','outbox_dispatch',
                  'calendar_sync','proactive_check','placement_missed')),
  logical_key   text NOT NULL,                          -- например reminder:<rule>:<occurrence>:<due>
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

CREATE TABLE app.history_watermark (                    -- явное удаление истории не воскресает при восстановлении
  profile_id      uuid PRIMARY KEY REFERENCES app.profile(id) ON DELETE CASCADE,
  deleted_before  timestamptz NOT NULL,
  updated_at      timestamptz NOT NULL DEFAULT now()
);
```

- При запуске после сна или выключения просроченные `reminder` не воспроизводятся по одному: ядро помечает их `missed` и создаёт одно задание `catch_up_summary` (PRODUCT). Задания для выполненных, отменённых и удалённых целей отбрасываются.
- Напоминания для серии (`task_id`) разворачиваются в задания при создании вхождений.
- Сырой звук в базе не хранится никогда; в `conversation_message` — только распознанный текст, если история включена.

## 10. Служебные таблицы

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

CREATE TABLE meta.operation_marker (                    -- незавершённая миграция или восстановление
  kind        text PRIMARY KEY CHECK (kind IN ('migration','restore')),
  detail      jsonb NOT NULL,
  started_at  timestamptz NOT NULL DEFAULT now()
);
```

Расширения: `pg_trgm` (поиск по подстроке в названиях). Других расширений нет.

## 11. Права ролей

- `djarvis_owner` — владелец схем `app` и `meta`; выполняет миграции.
- `djarvis_app` — `SELECT, INSERT, UPDATE, DELETE` на таблицы `app`; `SELECT, INSERT, UPDATE` на `meta.backup_record` и `meta.operation_marker`; только `SELECT` на `meta.schema_migration`. Изменение структуры запрещено.
- Подключение для `pg_dump` при бэкапе — под `djarvis_owner`.

## 12. Решения владельца (PLAN-024)

| № | Вопрос | Решение |
| --- | --- | --- |
| В1 | Удаление задачи с подзадачами | Спрашивать каждый раз: «Удалить всё» или «Оставить подзадачи» (поднять на уровень выше) |
| В2 | Подзадачи и чек-лист у повторяющейся задачи | Копия в каждое вхождение по шаблону; отметки не переходят между повторениями |
| В3 | Выполнение посреди запланированного блока | Блок обрезается моментом выполнения, остаток освобождается |
| В4 | Перенос ветки подзадач | Под любую задачу и в любой проект, кроме собственных потомков; проект детей сам не меняется |
| В5 | Объявление пропущенного времени | Переключатель в задаче «Не объявлять пропуск вслух»; подсветка в списке остаётся всегда |
