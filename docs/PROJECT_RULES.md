# Project development rules

[Русская версия](PROJECT_RULES.ru.md)

Status: approved by the owner on 2026-11-03, including amendments to the log location, repository publication, and rule changes; amended by the owner on 2026-11-04 (section 9 wording and section 14).

These rules apply to both development agents for every project task and response. Check current rules and active log entries before acting. They govern development; future application behavior requires separate design and approval. Changes to the rules require explicit owner approval.

## 1. Language

Communicate with the owner in Russian. Maintain README and documentation in separate synchronized English and Russian files, such as `README.md` and `README.ru.md`. The agent may choose its internal working language.

## 2. Design before programming

Show a plan before implementation. Discuss every item with the owner and work through architecture, structure, component interactions, data, error handling, and verification in detail before writing code. Start programming only after explicit owner approval. Discuss substantial departures from an approved design before implementation. Do not treat unresolved assumptions as approved decisions.

## 3. Approval scope

Authorization applies to the agreed task and scope. Complete authorized steps without repeatedly requesting the same approval. Approval does not authorize arbitrary project redesign. Explain and obtain approval for necessary changes outside the agreed scope before making them.

## 4. Code quality

Prioritize clean, understandable, maintainable, extensible code. Do not use ad hoc workarounds, concealed bypasses, or temporary functions presented as finished features. Design architecture and structure before implementation. Document future capabilities and implement them under an approved plan. Quality and extensibility take priority over rushing the MVP.

## 5. Unrelated problems

Report unrelated problems when discovered. Fix them independently only when existing authorization covers those changes. Otherwise describe the problem and proposed fix, then wait for owner approval.

## 6. Shared work log

Both agents use the same two files in `F:\MVP Djarvis\Plan`: `Plan/WORK_LOG.md` in English and `Plan/WORK_LOG.ru.md` in Russian. These are shared language versions, not separate per-agent logs.

Before editing, inspect active entries and the working tree. Record task ID, agent identifier, date and timezone, agreed scope, status, and affected files. Coordinate overlaps before editing. At completion record checks, results, remaining work, and a commit reference. Keep task IDs and statuses aligned in both versions. Use neutral stable agent identifiers in published records.

## 7. Preserve unfinished changes

Never overwrite, revert, or delete another agent's unfinished changes without agreement. Check the journal and actual files before edits; a journal entry alone does not prove a file is unchanged. Agree on the order of overlapping work before proceeding.

## 8. Completion

A task is complete when the agreed change is implemented, verified appropriately, and necessary documentation is updated in both languages. State checks not run and limitations honestly. Do not present unfinished features as complete.

## 9. Version control, publication, and backups

Repository: `https://github.com/SwanThunder/Djarvis.git`.

Create a meaningful commit after each completed task. Include only relevant changes and preserve unrelated unfinished work. Before uploading, check the exact staged files, paths, commit metadata, and outgoing history for secrets, personal data, and development tool branding or attribution. Published files, paths, commit messages and metadata must not mention the development tool products or the AI assistants used for development, in any form. Keep provider-specific local instruction files outside version control; local exclusion configuration containing those names must not be published either.

Before database changes and other hard-to-reverse operations, create an appropriate backup and establish how to restore it. GitHub preserves only files and commits actually pushed; it does not back up the excluded local database, runtime files, or personal data. Never publish secrets or personal data.

## 10. Model delegation and token cost

Use the strongest model primarily for architecture, task allocation, and result review. Delegate suitable implementation and routine work to less expensive models when the environment supports explicit selection. Escalate implementation when a cheaper model cannot produce adequate results or the task requires stronger capabilities. Give delegates focused context and clear completion criteria; verify their results before integration. Do not claim delegation or model changes that did not occur. Report unavailable routing when relevant.

## 11. Context efficiency

Use current documentation and the shared log. Read files and changes required for the task; avoid duplicate investigations, repeated unchanged output, and unnecessary parallel work. Token savings must not compromise design quality, correctness, or meaningful verification.

## 12. Reporting

After a task, report briefly: what changed, how it was checked, and what remains. Add detail when an owner decision is required.

## 13. Approved architecture decisions

Save agreed decisions in `docs/architecture/DECISIONS.md` and `docs/architecture/DECISIONS.ru.md` so both agents use the same source. Record context, decision, consequences, and owner approval. Distinguish proposals from approved decisions. Changes to project rules themselves require explicit owner approval.

## 14. Agent skills

Store every skill an agent creates or changes for this project in the local `Skills/` folder (`F:\MVP Djarvis\Skills`), keeping one folder per skill with its instruction file. The folder is excluded from version control and is never published.
