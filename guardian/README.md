# Guardian

Team orchestration and enforcement for Superpowers-enhanced agent teams.

Guardian orchestrates multi-agent teams and enforces quality gates. [Superpowers](https://github.com/obra/superpowers) teaches those agents how to code. Together, they provide autonomous, validated development workflows where you spend 15-20 minutes loading context, then walk away while a team of agents executes, cross-checks, and validates — returning finished, trustworthy work on a feature branch.

## What Guardian Does vs What Superpowers Does

| Concern | Guardian | Superpowers |
|---------|----------|-------------|
| **Who does what** | Team roles, task delegation, playbooks | — |
| **When work is validated** | Hook-based blocking gates (guardians) | — |
| **How agents code** | — | TDD, debugging, verification skills |
| **How agents manage branches** | — | Git worktrees, branch finishing |
| **What conventions to follow** | Convention guardian reads CLAUDE.md | — |
| **What decisions were made** | Context guardian + decisions log | — |

## Prerequisites

- **Superpowers plugin** — `superpowers@claude-plugins-official` must be installed and enabled. Guardian v2 has a hard dependency on Superpowers for coding methodology.

## Quick Start

### 1. Install hooks in your project

```
/guardian:init
```

This registers the `SessionStart` and `TaskCompleted` hooks in `.claude/settings.json`.

### 2. Run a playbook

```
/guardian:run-playbook feature-build
```

You'll be asked for a design doc path, key files, test command, and any gotchas. If no design doc exists, Guardian invokes `superpowers:brainstorming` and `superpowers:writing-plans` to create one. Then the team spins up and works autonomously in a git worktree.

### 3. Check available playbooks

```
/guardian:list-playbooks
```

## Playbooks

| Playbook | Team | Guardians | Purpose |
|----------|------|-----------|---------|
| **feature-build** | Lead + 2 Implementers + Reviewer | spec, test, convention, integration, context, verification | New feature from a design doc |
| **bug-hunt** | Lead + 3 Investigators + Fixer | test, integration, verification | Competing hypothesis debugging |
| **hardening** | Lead + Security + Edge Cases + Perf | test, convention, integration, verification | Quality sweep before merge |
| **refactor** | Lead + 2 Module Owners + Integration Tester | test, convention, integration, context, verification | Cross-module restructuring |
| **doc-sprint** | Lead + Writer + Code Reader + Accuracy Checker | spec, convention, verification | Documentation push |
| **test-suite** | Lead + 2 Test Writers + Coverage Analyst | test, convention, integration, verification | Backfill tests for existing code |

## Guardians

Guardians are hook-based validation agents that fire when teammates complete tasks:

| Guardian | What It Validates | Blocking |
|----------|------------------|----------|
| **Spec Guardian** | Implementation matches the design document | Yes |
| **Test Guardian** | Tests exist, pass, and cover requirements | Yes |
| **Convention Guardian** | Code follows CLAUDE.md conventions | Yes |
| **Integration Guardian** | Cross-module compatibility (3+ files changed) | Yes |
| **Context Guardian** | Captures decisions to a log | No |
| **Verification Guardian** | Evidence-based completion — tests were run, deliverables exist | Yes |

## Superpowers Integration

Guardian agents use these Superpowers skills:

| Superpowers Skill | Used By | When |
|-------------------|---------|------|
| `superpowers:test-driven-development` | Implementers | All implementation tasks |
| `superpowers:systematic-debugging` | Implementers | Debugging tasks, bug-hunt playbook |
| `superpowers:verification-before-completion` | Implementers, Verification Guardian | Before marking any task complete |
| `superpowers:brainstorming` | Lead, run-playbook | When no design doc exists |
| `superpowers:writing-plans` | Lead, run-playbook | Converting design to implementation plan |
| `superpowers:using-git-worktrees` | run-playbook | Playbook setup phase |
| `superpowers:finishing-a-development-branch` | run-playbook | Playbook completion phase |
| `superpowers:requesting-code-review` | Reviewer | Structuring reviews |
| `superpowers:receiving-code-review` | Reviewer, Implementers | Handling review feedback |

## How It Works

1. `/guardian:run-playbook` gathers context from the developer
2. If no design doc exists, Superpowers brainstorming + writing-plans create one
3. A git worktree is created via `superpowers:using-git-worktrees`
4. The team lead writes a **mission brief** to `.guardian/mission-brief.md`
5. Guardians are configured in `.guardian/guardians.json`
6. Teammates are spawned with role-specific skills (which load Superpowers skills)
7. On each task completion, the `TaskCompleted` hook fires enabled guardians
8. Failed guardians block the task and send feedback; the teammate iterates
9. When all tasks pass, the lead writes a **completion report**
10. `superpowers:finishing-a-development-branch` merges, creates a PR, or discards

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
│   ├── context-guardian.md
│   └── verification-guardian.md
├── playbooks/
│   ├── feature-build.md
│   ├── hardening.md
│   ├── bug-hunt.md
│   ├── refactor.md
│   ├── doc-sprint.md
│   └── test-suite.md
├── hooks/
│   ├── hooks.json
│   ├── session-start.sh
│   └── task-completed.sh
├── templates/
│   ├── mission-brief.md
│   ├── decisions-log.md
│   └── completion-report.md
├── docs/
│   ├── guardian-v2-design.md
│   ├── guardian-v2-implementation-plan.md
│   └── superpowers-comparison.md
└── README.md
```

## Guardian Configuration

When a playbook runs, it creates a `.guardian/` directory in your project:

```json
{
  "spec_guardian": { "enabled": true, "design_doc": "docs/plans/my-feature.md" },
  "test_guardian": { "enabled": true, "require_passing": true, "test_command": "pytest" },
  "convention_guardian": { "enabled": true },
  "integration_guardian": { "enabled": true, "file_threshold": 3 },
  "context_guardian": { "enabled": true, "frequency": 3 },
  "verification_guardian": { "enabled": true, "require_test_evidence": true, "require_deliverables_check": true }
}
```

## Migration from v1

1. **Install Superpowers** — enable `superpowers@claude-plugins-official` in your settings
2. **Re-run `/guardian:init`** — registers the new SessionStart hook alongside TaskCompleted
3. **Existing `.guardian/` configs** — remain compatible. The verification guardian defaults to disabled if not present in an existing `guardians.json`
4. **Existing playbooks** — work unchanged. New features (design phase, worktree) are additive
