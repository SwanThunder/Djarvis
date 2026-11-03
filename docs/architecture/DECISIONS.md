# Architecture decision register

[Русская версия](DECISIONS.ru.md)

Two narrowly scoped technology decisions are approved: ADR-001 selects Flutter for UI and necessary Dart UI code; ADR-002 selects PostgreSQL as the local backend database. The planner-core language, runtime packaging, detailed schema, and remaining architecture are not approved. Existing folders remain an organizational scaffold.

## ADR-001 — Flutter UI and necessary Dart UI implementation

- Date: 2026-11-03
- Status: APPROVED (limited scope)
- Context: The owner requires the supplied Djarvis visual design, Windows 10/11 first, and Android later. The owner confirmed: “Flutter Подходит; теперь подробно ядро планера, данные и взаимодействие.”
- Considered options: Flutter/Dart and .NET MAUI/C# were compared as UI directions in the initial proposal.
- Decision: Use Flutter as the UI framework and Dart only as needed to implement the UI.
- Consequences: Flutter is the selected UI direction; .NET MAUI is a historical considered alternative, not an active UI competitor. This does not select Dart for the planner core/background host or approve any broader architecture. Exact SDK versions and dependencies, core/host boundaries, database engine, model runtimes, process protocol, performance targets, and full architecture remain unresolved. This decision does not authorize code; implementation requires a separate reviewed plan and owner approval.
- Approval basis: Owner's explicit statement above, 2026-11-03. [Flutter supported platforms](https://docs.flutter.dev/reference/supported-platforms).

## ADR-002 — PostgreSQL backend database

- Date: 2026-11-03
- Status: APPROVED (database choice only)
- Context: The owner explicitly approved PostgreSQL “для бэкенда PostgreSQL” and clarified that it runs locally on the user's computer; no remote application backend or cloud user data.
- Considered options: PostgreSQL was selected; prior SQLite implementation proposals are superseded as the active database choice.
- Decision: Select PostgreSQL as the local backend database on the user's device.
- Consequences: This does not approve a remote/server deployment, cloud user data, a Dart backend, or any broader architecture. Driver, connection/pooling model, version, schema/DDL, migrations, local lifecycle/packaging, and full architecture remain unresolved. No PostgreSQL installation or implementation is authorized by this decision.
- Approval basis: Owner's explicit statement, 2026-11-03.

Record each approved decision with a stable ID, date, status, context, considered options, chosen solution, consequences, and owner approval reference. Keep IDs and statuses aligned with the Russian version. Mark proposals as proposed until approved; preserve superseded decisions and link their replacements.
