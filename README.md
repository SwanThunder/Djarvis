# Djarvis

[Русская версия](README.ru.md)

Djarvis is a personal intelligent assistant intended to manage tasks and habits, hold conversations, and find information on the internet.

Phase P0 — the application skeleton — is under way (authorized by the owner on 2026-11-05, ADR-033). Flutter UI, a Python core/background host and app-managed private PostgreSQL are selected; technical directions T1–T6, phases P0–P7 with their acceptance criteria, process architecture and the core/ + ui/ layout (ADR-022), schema, API and modules (ADR-024–026) are approved. Step 1 of the [P0 plan](docs/architecture/P0_PLAN.md) is done: core and UI skeleton, pinned check tooling and CI. There is no runnable application yet — only the skeleton.

## Structure

```text
core/             Python core: djarvis_core package, tests, pinned development dependencies
ui/               Flutter UI for Windows (djarvis_ui package)
scripts/          Check and build scripts (check.ps1)
.github/          CI checks for pull requests before main
docs/             Development rules, design and approved decisions
Plan/             Shared development work log in English and Russian
config/           Configuration without secrets
assets/           Static assets
data/
  db/             Local scaffold folder; the future PostgreSQL cluster lives under %LOCALAPPDATA%
  files/          Local scaffold folder; installed application files live outside the repository
cache/            Rebuildable cache
logs/             Runtime logs
tmp/              Temporary files
```

The full approved layout is in the [implementation plan](docs/architecture/IMPLEMENTATION_PLAN.md) §2; the remaining parts appear in later P0 steps and later phases.

The data/, cache/, logs/ and tmp/ folders may contain local preparation artifacts; their runtime contents are excluded from publication under project rules. Do not clear them as part of the layout change. The installed application keeps its private database and user files outside the repository in the Windows profile. data/db does not currently contain a live Djarvis database.

## Development

- Read the [project rules](docs/PROJECT_RULES.md) before each task.
- Check and update the [shared work log](Plan/WORK_LOG.md) before editing files.
- Record approved architecture decisions in the [decision register](docs/architecture/DECISIONS.md).
- Review the [product](docs/PRODUCT.md), [accepted decisions](docs/architecture/DECISIONS.md), [architecture and phases](docs/architecture/IMPLEMENTATION_PLAN.md) and [architecture summary](docs/architecture/ARCHITECTURE_REVIEW.md). Phases, architecture/layout, schema, API and modules are approved; P0 is in progress under the [P0 plan](docs/architecture/P0_PLAN.md).
- Follow the owner's [required Djarvis visual design](docs/DESIGN.md); technology choices must preserve this design.
- Review the [detailed planner core, data, and interaction proposal](docs/architecture/PLANNER_CORE.md) before implementation planning.
- Use the [remaining design and decision plan](docs/architecture/REMAINING_PLAN.md) for all eight workstreams, selectable questions, acceptance criteria and context recovery.
- Review the [detailed remaining component plan](docs/architecture/COMPONENT_PLAN.md) for CP01–CP20, dependencies, design deliverables and approval gates.
- Review the concrete proposals for [foundation CP01–CP07](docs/architecture/FOUNDATION_DESIGN.md), [assistant CP08–CP14](docs/architecture/ASSISTANT_DESIGN.md) and [delivery CP15–CP20](docs/architecture/DELIVERY_DESIGN.md). Accepted owner choices and unapproved engineering recommendations are marked separately; these documents are not an implementation.
- See the [project status summary](docs/STATUS.md) for accepted decisions, open questions and remaining work, and the [main-screen layout review](docs/architecture/DASHBOARD_LAYOUT_REVIEW.md) for the layout brief and floating microphone button.
- Maintain English and Russian documentation as separate synchronized files.
- Present and discuss the implementation plan before programming; begin only after owner approval.

## Local checks

Requires Windows, Python 3.12 and Flutter 3.47.7. From the repository root in PowerShell:

```powershell
py -3.12 -m venv core\.venv
core\.venv\Scripts\python -m pip install --require-hashes -r core\requirements\dev.txt
core\.venv\Scripts\python -m pip install --no-deps --no-build-isolation -e core
powershell -ExecutionPolicy Bypass -File scripts\check.ps1
```

The script runs core and UI analysis and tests and stops at the first failure; `-Build` also builds the Windows UI (requires Visual Studio with the C++ desktop workload). The same checks run in CI for pull requests before main.

Repository: [SwanThunder/Djarvis](https://github.com/SwanThunder/Djarvis).

The next step is step 2 of the [P0 plan](docs/architecture/P0_PLAN.md): embedded Python and PostgreSQL runtimes. GitHub stores only pushed files and does not replace a backup of future local user data.
