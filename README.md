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
- Maintain English and Russian documentation as separate synchronized files.
- Present and discuss the implementation plan before programming; begin only after owner approval.

Repository: [SwanThunder/Djarvis](https://github.com/SwanThunder/Djarvis).

The next step is to agree on MVP scope and application architecture. A GitHub copy of source files does not back up the excluded database or personal data; those require separate backups before risky changes.
