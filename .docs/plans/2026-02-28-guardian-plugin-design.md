# Guardian Plugin — Design Document

**Date:** 2026-02-28
**Status:** Approved
**Scope:** Internal development workflow tooling

## Overview

Guardian is a standalone, portable Claude Code plugin that provides two capabilities:

1. **Guardians** — Hook-based validation agents that enforce quality gates during agent team execution
2. **Playbooks** — Pre-built agent team configurations that define team composition, roles, task structures, and guardian assignments for common development patterns

The goal is to enable a workflow where the developer spends 15-20 minutes loading context and aligning on a design, then walks away while a team of agents executes, cross-checks, and validates — returning to finished, trustworthy work on a feature branch.

## Design Principles

- **Portable** — Works in any repo. Zero dependencies on forge-lib or any project-specific tooling.
- **Block and fix** — Guardians block task completion and send teammates back to fix issues. The developer comes back to clean work, not a list of problems.
- **Full autonomy** — Teams run to completion without human intervention. No PRs created — branches only.
- **Context preservation** — Design intent survives from planning through implementation through validation, even across multiple independent agent context windows.

## Guardian System

### How Guardians Work

Guardians are implemented as `TaskCompleted` hooks. When any teammate marks a task as complete, the hook fires validation checks. If a check fails (exit code 2), the teammate receives specific feedback and must fix the issue before the task can be marked complete. The teammate iterates until all guardians are satisfied.

### Guardian Roster

| Guardian | What It Validates | Fires On |
|----------|------------------|----------|
| **Spec Guardian** | Diffs implementation against the design doc. Checks that every requirement has corresponding code and no undocumented behavior was added. | Every task completion |
| **Test Guardian** | Verifies new/changed code has tests, tests pass, and tests cover stated requirements — not just happy paths. | Implementation task completions |
| **Convention Guardian** | Checks project-specific patterns defined in CLAUDE.md. | Every task completion |
| **Integration Guardian** | When changes touch multiple files/modules, verifies they work together. Runs the full test suite. Checks for import errors, interface mismatches, broken cross-references. | Tasks that touch 3+ files or multiple directories |
| **Context Guardian** | Not a blocker. Periodically captures a decisions log summarizing what choices were made and why, so context survives across the full session. | Every 3-4 task completions |

### Guardian Data Sources

Each guardian reads from two sources:

1. **The design doc** — Provided by the developer during context loading. Source of truth for spec alignment, requirements coverage, and intended architecture.
2. **CLAUDE.md** — Already exists in most projects. Convention Guardian pulls its rules from here. This is what makes the system portable — different projects have different conventions, and the guardian adapts automatically.

### Guardian Configuration

A `.guardian/guardians.json` file in the target project controls which guardians are active:

```json
{
  "spec_guardian": { "enabled": true, "design_doc": "docs/plans/current-feature.md" },
  "test_guardian": { "enabled": true, "require_passing": true, "test_command": "pytest" },
  "convention_guardian": { "enabled": true },
  "integration_guardian": { "enabled": true, "file_threshold": 3 },
  "context_guardian": { "enabled": true, "frequency": 3 }
}
```

The `test_command` field enables portability — pytest for Python, npm test for JS, cargo test for Rust.

### Guardian Feedback Format

When a guardian blocks, it provides:
- What specifically failed (e.g., "Requirement 3.2 — 'decay should be idempotent' — has no corresponding test")
- Where in the code the issue is
- A suggested fix direction (not the fix itself — the teammate figures that out)

## Playbook System

### What a Playbook Is

A structured markdown file that defines everything needed to spin up an agent team for a specific type of development work. It specifies team composition, role descriptions, guardian assignments, and task creation guidance.

### Playbook Library

| Playbook | Roles | Purpose |
|----------|-------|---------|
| **feature-build** | Lead + 2 Implementers + Reviewer | New feature with a written plan |
| **hardening** | Lead + Security Reviewer + Edge Case Finder + Perf Tester | Quality sweep before merge |
| **bug-hunt** | Lead + 3 Investigators + Fixer | Competing hypothesis debugging |
| **refactor** | Lead + 2-3 Module Owners + Integration Tester | Cross-module restructuring |
| **doc-sprint** | Lead + Writer + Code Reader + Accuracy Checker | Documentation push |
| **test-suite** | Lead + 2 Test Writers + Coverage Analyst | Backfill tests for existing code |

### Playbook Structure

Each playbook defines:
- **Metadata** — Name, description, team size, guardian config, autonomy level
- **Roles** — Detailed instructions for each teammate (Lead, Implementer, Reviewer, etc.)
- **Task creation guidance** — How the lead should break work into tasks
- **Completion criteria** — What "done" looks like

### Usage Flow

1. Developer invokes `/guardian:run-playbook feature-build`
2. Developer provides: design doc path, key files, test command, gotchas
3. Lead writes mission brief, creates task list, configures guardians, spawns teammates
4. Developer walks away
5. Team executes with guardian validation loop until all tasks pass
6. Lead writes completion report, shuts down team

## Context Preservation System

### Layer 1: Mission Brief

The lead's first action before spawning teammates. Written to `.guardian/mission-brief.md`.

Contains:
- Design doc path and summary of key requirements
- Developer's specific callouts and gotchas
- Key files and their roles
- Test commands and expected behavior
- Success criteria

Every teammate receives this file path in their spawn prompt.

### Layer 2: Decisions Log

Written by the Context Guardian throughout execution. Stored at `.guardian/decisions-log.md`.

Accumulates:
- Design choices teammates made and why
- Guardian feedback that was addressed and how
- Task dependencies discovered during implementation
- Deviations from spec with rationale

Any teammate can read this at any time to understand choices made by other teammates.

### Layer 3: Completion Report

Written by the lead when the team finishes. Stored at `.guardian/completion-report.md`.

Contains:
- Summary of what was built
- Mapping of spec requirements to implementation
- All guardian results (pass/fail history, issues caught and fixed)
- Deviations from spec with rationale from the Reviewer
- Test results and coverage summary
- Decisions log rolled up into key takeaways

## Plugin Architecture

```
guardian/
├── .claude-plugin/
│   └── manifest.json           # Claude Code plugin registration
├── commands/
│   ├── run-playbook.md         # Main entry point
│   ├── list-playbooks.md       # Show available playbooks
│   └── init.md                 # One-time hook setup in target project
├── skills/
│   ├── team-lead.md            # How to be an effective team lead
│   ├── team-implementer.md     # How to be an effective implementer
│   └── team-reviewer.md        # How to be an effective reviewer
├── agents/
│   ├── spec-guardian.md        # Spec drift detection
│   ├── test-guardian.md        # Test coverage/quality
│   ├── convention-guardian.md  # CLAUDE.md convention enforcement
│   ├── integration-guardian.md # Cross-module compatibility
│   └── context-guardian.md     # Decisions logger
├── playbooks/
│   ├── feature-build.md
│   ├── hardening.md
│   ├── bug-hunt.md
│   ├── refactor.md
│   ├── doc-sprint.md
│   └── test-suite.md
├── hooks/
│   └── task-completed.sh       # Hook that fires guardians
├── templates/
│   ├── mission-brief.md        # Template for mission brief
│   ├── completion-report.md    # Template for completion report
│   └── decisions-log.md        # Template for decisions log
└── README.md
```

### Target Project Artifacts

When a playbook runs, it creates a `.guardian/` directory in the target project:

```
your-project/
├── .guardian/
│   ├── guardians.json          # Active guardian config for this run
│   ├── mission-brief.md        # Generated from developer's context
│   ├── decisions-log.md        # Written during execution
│   └── completion-report.md    # Written at team shutdown
└── ... project files
```

### Hook Installation

The `/guardian:init` command registers the `TaskCompleted` hook in the project's `.claude/settings.json`. One-time setup per project.

## Scope

### In Scope (v1)

- Guardian plugin repo — standalone, portable, zero external dependencies
- 5 guardian agents (spec, test, convention, integration, context)
- 6 playbooks (feature-build, hardening, bug-hunt, refactor, doc-sprint, test-suite)
- 3 role skills (team-lead, team-implementer, team-reviewer)
- TaskCompleted hook that fires guardians
- Context preservation system (mission brief, decisions log, completion report)
- `/guardian:run-playbook`, `/guardian:list-playbooks`, `/guardian:init` commands
- Tested in the forge-feature repo

### Out of Scope (v1)

- No forge-lib integration
- No forge-shell dashboard
- No PR creation — branches only
- No custom guardian authoring framework
- No cross-session memory — each playbook run is independent
- No user-facing features — internal development tooling only

## Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Standalone plugin | Not built into forge-lib | Portability across any project |
| Guardians as hooks | `TaskCompleted` hook | Works with any agent team |
| Mission brief as file | `.guardian/mission-brief.md` | Survives context window limits |
| Block and fix | Exit code 2 feedback loop | Full autonomy, clean results |
| One-time init | `/guardian:init` command | Transparency in settings |
| `.guardian/` in target project | Not in plugin repo | Artifacts belong to the project |
