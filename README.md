# Djarvis

[Русская версия](README.ru.md)

Djarvis is a personal intelligent assistant intended to manage tasks and habits, hold conversations, and find information on the internet.

The repository currently contains an organizational scaffold and design documents. Flutter UI, a Python core/background host and app-managed private PostgreSQL are selected; technical directions T1–T6 and phases P0–P7 with their acceptance criteria are also approved. Process architecture and the core/ + ui/ layout are approved (ADR-022); database schema, API and modules still await review. There is no runnable application yet; P0 requires separate explicit authorization.

## Structure

This is the existing organizational scaffold; these folders contain no application code yet. The core/ + ui/ layout approved for future code is in the [implementation plan](docs/architecture/IMPLEMENTATION_PLAN.md); it is created after separate P0 authorization.

```text
src/
  core/           Core behavior and workflows
  agents/         Agent implementations and coordination
  tools/          Assistant-callable tools
  integrations/   External services and model connections
  memory/         Memory and knowledge access logic
  interfaces/     Application interfaces; specific channels are undecided
config/           Configuration without secrets
data/
  db/             Local scaffold folder; the future PostgreSQL cluster lives under %LOCALAPPDATA%
  files/          Local scaffold folder; installed application files live outside the repository
cache/            Rebuildable cache
logs/             Runtime logs
tmp/              Temporary files
Plan/             Shared development work log in English and Russian
docs/             Development rules and approved decisions
scripts/          Maintenance scripts
tests/            Tests
assets/           Static assets
```

The data/, cache/, logs/ and tmp/ folders may contain local preparation artifacts; their runtime contents are excluded from publication under project rules. Do not clear them as part of the layout change. The installed application keeps its private database and user files outside the repository in the Windows profile. data/db does not currently contain a live Djarvis database.

## Development

- Read the [project rules](docs/PROJECT_RULES.md) before each task.
- Check and update the [shared work log](Plan/WORK_LOG.md) before editing files.
- Record approved architecture decisions in the [decision register](docs/architecture/DECISIONS.md).
- Review the [product](docs/PRODUCT.md), [accepted decisions](docs/architecture/DECISIONS.md), [architecture and phases](docs/architecture/IMPLEMENTATION_PLAN.md) and [architecture summary](docs/architecture/ARCHITECTURE_REVIEW.md). Phases are approved; architecture/layout are approved; schema, API and modules require separate approval.
- Follow the owner's [required Djarvis visual design](docs/DESIGN.md); technology choices must preserve this design.
- Review the [detailed planner core, data, and interaction proposal](docs/architecture/PLANNER_CORE.md) before implementation planning.
- Use the [remaining design and decision plan](docs/architecture/REMAINING_PLAN.md) for all eight workstreams, selectable questions, acceptance criteria and context recovery.
- Review the [detailed remaining component plan](docs/architecture/COMPONENT_PLAN.md) for CP01–CP20, dependencies, design deliverables and approval gates.
- Review the concrete proposals for [foundation CP01–CP07](docs/architecture/FOUNDATION_DESIGN.md), [assistant CP08–CP14](docs/architecture/ASSISTANT_DESIGN.md) and [delivery CP15–CP20](docs/architecture/DELIVERY_DESIGN.md). Accepted owner choices and unapproved engineering recommendations are marked separately; these documents are not an implementation.
- See the [project status summary](docs/STATUS.md) for accepted decisions, open questions and remaining work, and the [main-screen layout review](docs/architecture/DASHBOARD_LAYOUT_REVIEW.md) for the layout brief and floating microphone button.
- Maintain English and Russian documentation as separate synchronized files.
- Present and discuss the implementation plan before programming; begin only after owner approval.

Repository: [SwanThunder/Djarvis](https://github.com/SwanThunder/Djarvis).

The next step is to review the database schema, then API and modules. The owner can then explicitly authorize P0. GitHub stores only pushed files and does not replace a backup of future local user data.
