# Djarvis

[Русская версия](README.ru.md)

Djarvis is a personal intelligent assistant intended to manage tasks and habits, hold conversations, and find information on the internet.

The repository currently contains a project scaffold and approved development conventions. Flutter is selected only for the UI, with Dart limited to necessary UI implementation (ADR-001). The planner core, background host, other dependencies and versions, database engine, schema, and full application architecture remain unselected. This decision does not authorize programming. There is no runnable application yet.

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
  db/             Persistent local database storage
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
- Review the [product definition](docs/PRODUCT.md), [first architecture proposal](docs/architecture/PROPOSAL.md), and [decision register](docs/architecture/DECISIONS.md); ADR-001 selects Flutter/Dart only for the UI, while the remaining architecture proposals are unapproved.
- Follow the owner's [required Djarvis visual design](docs/DESIGN.md); technology choices must preserve this design.
- Review the [detailed planner core, data, and interaction proposal](docs/architecture/PLANNER_CORE.md) before implementation planning.
- Maintain English and Russian documentation as separate synchronized files.
- Present and discuss the implementation plan before programming; begin only after owner approval.

Repository: [SwanThunder/Djarvis](https://github.com/SwanThunder/Djarvis).

The next step is to review the detailed planner core, data, and interaction proposal and resolve its open rules before approving implementation. Flutter UI is selected; other architecture decisions still need agreement. The full requested product scope and required design remain documented. A GitHub copy of source files does not back up the excluded database or personal data; those require separate backups before risky changes.
