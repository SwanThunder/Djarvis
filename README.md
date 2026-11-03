# Djarvis

[Русская версия](README.ru.md)

Djarvis is a personal intelligent assistant intended to manage tasks and habits, hold conversations, and find information on the internet.

The repository currently contains a project scaffold and approved development conventions. The application architecture, language, dependencies, interfaces, database engine, and schema have not been selected. There is no runnable application yet.

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
- Review the [product definition](docs/PRODUCT.md) and [first architecture proposal](docs/architecture/PROPOSAL.md); proposed technologies are not yet approved.
- Follow the owner's [required Djarvis visual design](docs/DESIGN.md); technology choices must preserve this design.
- Maintain English and Russian documentation as separate synchronized files.
- Present and discuss the implementation plan before programming; begin only after owner approval.

Repository: [SwanThunder/Djarvis](https://github.com/SwanThunder/Djarvis).

The next step is to align Djarvis screens with the owner's specified design and review component boundaries and technology candidates, then specify detailed contracts and approve an implementation plan. The full requested product scope remains documented. A GitHub copy of source files does not back up the excluded database or personal data; those require separate backups before risky changes.
