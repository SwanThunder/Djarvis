# Architecture decision register

[Русская версия](DECISIONS.ru.md)

One narrowly scoped decision has been approved: ADR-001 below selects Flutter for the UI and necessary Dart UI implementation only. No broader application architecture or programming is approved. Existing folders remain an organizational scaffold, not approval of a runtime architecture.

## ADR-001 — Flutter UI and necessary Dart UI implementation

- Date: 2026-11-03
- Status: APPROVED (limited scope)
- Context: The owner requires the supplied Djarvis visual design, Windows 10/11 first, and Android later. The owner confirmed: “Flutter Подходит; теперь подробно ядро планера, данные и взаимодействие.”
- Considered options: Flutter/Dart and .NET MAUI/C# were compared as UI directions in the initial proposal.
- Decision: Use Flutter as the UI framework and Dart only as needed to implement the UI.
- Consequences: Flutter is the selected UI direction; .NET MAUI is a historical considered alternative, not an active UI competitor. This does not select Dart for the planner core/background host or approve any broader architecture. Exact SDK versions and dependencies, core/host boundaries, database engine, model runtimes, process protocol, performance targets, and full architecture remain unresolved. This decision does not authorize code; implementation requires a separate reviewed plan and owner approval.
- Approval basis: Owner's explicit statement above, 2026-11-03. [Flutter supported platforms](https://docs.flutter.dev/reference/supported-platforms).

Record each approved decision with a stable ID, date, status, context, considered options, chosen solution, consequences, and owner approval reference. Keep IDs and statuses aligned with the Russian version. Mark proposals as proposed until approved; preserve superseded decisions and link their replacements.
