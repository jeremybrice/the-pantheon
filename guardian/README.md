# Guardian

Hook-based guardian agents and team playbooks for autonomous, validated development workflows. Guardian enables a workflow where you spend 15-20 minutes loading context and aligning on a design, then walk away while a team of agents executes, cross-checks, and validates, returning to finished, trustworthy work on a feature branch.

## Quick Start

### 1. Install hooks in your project

```
/guardian:init
```

This registers the `TaskCompleted` hook in `.claude/settings.json`.

### 2. Run a playbook

```
/guardian:run-playbook feature-build
```

You'll be asked for a design doc path, key files, test command, and any gotchas. Then the team spins up and works autonomously.

### 3. Check available playbooks

```
/guardian:list-playbooks
```

## Playbooks

| Playbook | Team | Purpose |
|----------|------|---------|
| **feature-build** | Lead + 2 Implementers + Reviewer | New feature from a design doc |
| **hardening** | Lead + Security + Edge Cases + Perf | Quality sweep before merge |
| **bug-hunt** | Lead + 3 Investigators + Fixer | Competing hypothesis debugging |
| **refactor** | Lead + 2 Module Owners + Integration Tester | Cross-module restructuring |
| **doc-sprint** | Lead + Writer + Code Reader + Accuracy Checker | Documentation push |
| **test-suite** | Lead + 2 Test Writers + Coverage Analyst | Backfill tests for existing code |

## Guardians

Guardians are hook-based validation agents that fire when teammates complete tasks:

| Guardian | What It Validates |
|----------|------------------|
| **Spec Guardian** | Implementation matches the design document |
| **Test Guardian** | Tests exist, pass, and cover requirements |
| **Convention Guardian** | Code follows CLAUDE.md conventions |
| **Integration Guardian** | Cross-module compatibility (3+ files changed) |
| **Context Guardian** | Captures decisions to a log (non-blocking) |

## Plugin Structure

```
guardian/
├── .claude-plugin/plugin.json
├── commands/
│   ├── init.md
│   ├── list-playbooks.md
│   └── run-playbook.md
├── skills/
│   ├── team-lead/SKILL.md
│   ├── team-implementer/SKILL.md
│   └── team-reviewer/SKILL.md
├── agents/
│   ├── spec-guardian.md
│   ├── test-guardian.md
│   ├── convention-guardian.md
│   ├── integration-guardian.md
│   └── context-guardian.md
├── playbooks/
│   ├── feature-build.md
│   ├── hardening.md
│   ├── bug-hunt.md
│   ├── refactor.md
│   ├── doc-sprint.md
│   └── test-suite.md
├── hooks/
│   └── task-completed.sh
├── templates/
│   ├── mission-brief.md
│   ├── decisions-log.md
│   └── completion-report.md
└── README.md
```

## How It Works

1. `/guardian:run-playbook` gathers context from the developer
2. The team lead writes a **mission brief** to `.guardian/mission-brief.md`
3. Guardians are configured in `.guardian/guardians.json`
4. Teammates are spawned with role-specific skills and the mission brief
5. On each task completion, the `TaskCompleted` hook fires enabled guardians
6. Failed guardians block the task and send feedback; the teammate iterates
7. When all tasks pass, the lead writes a **completion report** to `.guardian/completion-report.md`

## Guardian Configuration

When a playbook runs, it creates a `.guardian/` directory in your project:

```
your-project/
├── .guardian/
│   ├── guardians.json          # Which guardians are active
│   ├── mission-brief.md        # Requirements, key files, test command
│   ├── decisions-log.md        # Design choices made during execution
│   └── completion-report.md    # Final summary when team finishes
```

Example `guardians.json`:

```json
{
  "spec_guardian": { "enabled": true, "design_doc": "docs/plans/my-feature.md" },
  "test_guardian": { "enabled": true, "require_passing": true, "test_command": "pytest" },
  "convention_guardian": { "enabled": true },
  "integration_guardian": { "enabled": true, "file_threshold": 3 },
  "context_guardian": { "enabled": true, "frequency": 3 }
}
```

The `test_command` makes it portable: `pytest` for Python, `npm test` for JS, `cargo test` for Rust.

## Guardian Feedback Loop

When a guardian blocks a task, the teammate receives specific feedback on stderr:

```
TEST GUARDIAN FAILED for task 'Implement notification service':
The test suite did not pass. Fix the failing tests before completing this task.
Test command: pytest tests/
Output (last 50 lines):
...
```

The teammate reads this feedback, fixes the issue, and tries to complete the task again. This loop continues until all guardians pass.

## Portability

Guardian is standalone and portable. It works in any repo because:

1. It reads conventions from the project's own `CLAUDE.md`
2. The test command is configured per-project (not hardcoded)
3. No dependencies on forge-lib or any external tooling
4. The hook script only requires `bash` and `jq`

## Design Doc

See `docs/plans/2026-02-28-guardian-plugin-design.md` for the full design document.
