# Djarvis

[Русская версия](README.ru.md)

Djarvis is a personal intelligent assistant intended to manage tasks and habits, hold conversations, and find information on the internet.

The repository currently contains a project scaffold and development/design documents. Flutter UI and necessary Dart UI code are selected in ADR-001; PostgreSQL is selected as the local backend database in ADR-002; Python is selected for planner-core/background logic with its own packaged runtime in ADR-003; and the app-managed lifecycle of an isolated local PostgreSQL instance is selected in ADR-004. ADR-005 confirms a local profile, offline verification of an imported signed license file, and the trial and expired-access rules; it does not approve implementation. The current release has no Djarvis-hosted remote backend or cloud storage; authorized external integrations are separate, and future cloud synchronization still requires design. Exact versions, drivers, schema, runtime/database distribution and packaging details, and remaining architecture are not approved. No application implementation is authorized by these decisions, and there is no runnable application yet.

## Structure

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
  db/             Persistent local application data (PostgreSQL data-directory layout pending)
  files/          Persistent user files
cache/            Rebuildable cache
logs/             Runtime logs
tmp/              Temporary files
Plan/             Shared development work log in English and Russian
docs/             Development rules and approved decisions
scripts/          Maintenance scripts
tests/            Tests
assets/           Static assets
```

`data/` is persistent storage and must never be cleared as a cache. `cache/` holds only rebuildable data. Runtime data, secrets, logs, and temporary files are excluded from Git. The database directory currently has no database or schema.

## Development

- Read the [project rules](docs/PROJECT_RULES.md) before each task.
- Check and update the [shared work log](Plan/WORK_LOG.md) before editing files.
- Record approved architecture decisions in the [decision register](docs/architecture/DECISIONS.md).
- Review the [product definition](docs/PRODUCT.md), [first architecture proposal](docs/architecture/PROPOSAL.md), and [decision register](docs/architecture/DECISIONS.md); ADR-001 selects Flutter/Dart for UI, ADR-002 local PostgreSQL, ADR-003 Python core/background logic, and ADR-004 app-managed lifecycle of an isolated local PostgreSQL instance, and ADR-005 offline license import and trial/access rules. Exact packaging and remaining architecture are unresolved.
- Follow the owner's [required Djarvis visual design](docs/DESIGN.md); technology choices must preserve this design.
- Review the [detailed planner core, data, and interaction proposal](docs/architecture/PLANNER_CORE.md) before implementation planning.
- Use the [remaining design and decision plan](docs/architecture/REMAINING_PLAN.md) for all eight workstreams, selectable questions, acceptance criteria and context recovery.
- Review the [detailed remaining component plan](docs/architecture/COMPONENT_PLAN.md) for CP01–CP20, dependencies, design deliverables and approval gates.
- Review the concrete proposals for [foundation CP01–CP07](docs/architecture/FOUNDATION_DESIGN.md), [assistant CP08–CP14](docs/architecture/ASSISTANT_DESIGN.md) and [delivery CP15–CP20](docs/architecture/DELIVERY_DESIGN.md). Accepted owner choices and unapproved engineering recommendations are marked separately; these documents are not an implementation.
- Maintain English and Russian documentation as separate synchronized files.
- Present and discuss the implementation plan before programming; begin only after owner approval.

Repository: [SwanThunder/Djarvis](https://github.com/SwanThunder/Djarvis).

The next step is to review the detailed planner core, data, and interaction proposal and resolve its open rules before approving implementation. ADR-005 records that the seven-day trial starts on first use of any product function, while setup/download waiting does not start it; after expiry, planner/assistant features lock while data remains and renewal/import, user deletion, and automatic backups remain available. Microphone capture and proactive speech stop. Flutter UI, Python core/background direction, and app-managed local PostgreSQL lifecycle are selected in their limited scopes; versions, drivers, packaging and other architecture decisions still need agreement. Daily local backups, pre-structure/migration backups, and seven-day configurable retention are requirements. The full requested product scope and required design remain documented. A GitHub copy of source files does not back up local user data; those require separate backups before risky changes.
