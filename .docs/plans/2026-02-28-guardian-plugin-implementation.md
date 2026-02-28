# Guardian Plugin Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build the Guardian plugin — a portable Claude Code plugin providing hook-based guardian agents and team playbooks for autonomous, validated development workflows.

**Architecture:** Standalone Claude Code plugin with markdown commands, skills, agents, playbooks, a shell hook script, and markdown templates. Zero external dependencies. Portable to any repo.

**Tech Stack:** Claude Code plugin system (markdown commands/skills/agents), Bash (hook script), jq (JSON parsing in hooks)

**Design Doc:** `docs/plans/2026-02-28-guardian-plugin-design.md`

---

### Task 1: Create the plugin scaffold

**Files:**
- Create: `guardian/.claude-plugin/plugin.json`
- Create: `guardian/README.md`

**Step 1: Create plugin manifest**

```json
{
  "name": "guardian",
  "version": "1.0.0-alpha",
  "description": "Hook-based guardian agents and team playbooks for autonomous, validated development workflows",
  "author": { "name": "Jeremy Brice" }
}
```

Write to `guardian/.claude-plugin/plugin.json`.

**Step 2: Create README**

Write a README covering:
- What Guardian is (one paragraph)
- Quick start: how to install (`/guardian:init`) and run (`/guardian:run-playbook`)
- Plugin structure overview
- Link to the design doc

Write to `guardian/README.md`.

**Step 3: Register in marketplace**

Read `.claude-plugin/marketplace.json`. Add a new entry to the `plugins` array:

```json
{
  "name": "guardian",
  "source": "./guardian",
  "description": "Hook-based guardian agents and team playbooks for autonomous development"
}
```

**Step 4: Commit**

```bash
git add guardian/.claude-plugin/plugin.json guardian/README.md .claude-plugin/marketplace.json
git commit -m "feat(guardian): create plugin scaffold with manifest and README"
```

---

### Task 2: Create the context preservation templates

These templates are used by the team lead to generate mission briefs, decisions logs, and completion reports. They define the structure; the lead fills in content.

**Files:**
- Create: `guardian/templates/mission-brief.md`
- Create: `guardian/templates/decisions-log.md`
- Create: `guardian/templates/completion-report.md`

**Step 1: Write mission brief template**

```markdown
# Mission Brief

**Playbook:** {{ playbook_name }}
**Design Doc:** {{ design_doc_path }}
**Created:** {{ date }}

## Requirements Summary

{{ Numbered list of key requirements extracted from the design doc }}

## Key Files

{{ List of files and their roles, as provided by the developer }}

## Test Command

{{ The command to run tests, e.g., "pytest tests/" }}

## Developer Callouts

{{ Specific warnings, gotchas, and constraints the developer mentioned }}

## Success Criteria

{{ What "done" looks like — extracted from design doc and developer input }}
```

Write to `guardian/templates/mission-brief.md`.

**Step 2: Write decisions log template**

```markdown
# Decisions Log

**Mission:** {{ brief title }}
**Started:** {{ date }}

---

<!-- Context Guardian appends entries below this line -->

## Entry [N] — [timestamp]

**Decision:** What was decided
**Rationale:** Why this choice was made
**Alternatives considered:** What else was evaluated
**Files affected:** Which files this impacts
**Guardian feedback addressed:** Any guardian issues that influenced this decision
```

Write to `guardian/templates/decisions-log.md`.

**Step 3: Write completion report template**

```markdown
# Completion Report

**Playbook:** {{ playbook_name }}
**Design Doc:** {{ design_doc_path }}
**Completed:** {{ date }}
**Branch:** {{ branch_name }}

## Summary

{{ 2-3 sentence summary of what was built }}

## Requirements Mapping

| Requirement | Status | Implementation | Notes |
|-------------|--------|----------------|-------|
| {{ req }} | Done/Deferred/Modified | {{ file:line }} | {{ rationale if modified }} |

## Guardian Results

### Spec Guardian
- Issues caught: {{ count }}
- All resolved: Yes/No
- Details: {{ list of issues and resolutions }}

### Test Guardian
- Issues caught: {{ count }}
- All resolved: Yes/No
- Test command: {{ command }}
- Final result: PASS/FAIL
- Details: {{ list of issues and resolutions }}

### Convention Guardian
- Issues caught: {{ count }}
- All resolved: Yes/No
- Details: {{ list of issues and resolutions }}

### Integration Guardian
- Issues caught: {{ count }}
- All resolved: Yes/No
- Full suite result: PASS/FAIL
- Details: {{ list of issues and resolutions }}

## Deviations from Spec

{{ List of any changes from the original design, with rationale from the Reviewer }}

## Test Results

```
{{ Paste of final test run output }}
```

## Key Decisions

{{ Rolled-up summary from decisions log }}
```

Write to `guardian/templates/completion-report.md`.

**Step 4: Commit**

```bash
git add guardian/templates/
git commit -m "feat(guardian): add context preservation templates (mission brief, decisions log, completion report)"
```

---

### Task 3: Create the TaskCompleted hook script

This is the core enforcement mechanism. It reads the guardian config, checks which guardians are enabled, and runs validation for the completed task.

**Files:**
- Create: `guardian/hooks/task-completed.sh`

**Step 1: Write the hook script**

```bash
#!/bin/bash
# Guardian TaskCompleted Hook
# Reads .guardian/guardians.json config, runs enabled guardians.
# Exit 0 = pass (task completes). Exit 2 = block (stderr fed back as feedback).

set -euo pipefail

INPUT=$(cat)
TASK_ID=$(echo "$INPUT" | jq -r '.task_id // empty')
TASK_SUBJECT=$(echo "$INPUT" | jq -r '.task_subject // empty')
TASK_DESCRIPTION=$(echo "$INPUT" | jq -r '.task_description // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

# Use CWD from hook input, fall back to CLAUDE_PROJECT_DIR
PROJECT_DIR="${CWD:-${CLAUDE_PROJECT_DIR:-.}}"
GUARDIAN_DIR="$PROJECT_DIR/.guardian"
CONFIG="$GUARDIAN_DIR/guardians.json"

# If no guardian config exists, pass through
if [ ! -f "$CONFIG" ]; then
  exit 0
fi

ERRORS=""

# --- Test Guardian ---
TEST_ENABLED=$(jq -r '.test_guardian.enabled // false' "$CONFIG")
if [ "$TEST_ENABLED" = "true" ]; then
  TEST_CMD=$(jq -r '.test_guardian.test_command // "echo no test command configured"' "$CONFIG")
  REQUIRE_PASSING=$(jq -r '.test_guardian.require_passing // true' "$CONFIG")

  if [ "$REQUIRE_PASSING" = "true" ]; then
    TEST_OUTPUT=$(cd "$PROJECT_DIR" && eval "$TEST_CMD" 2>&1) || {
      ERRORS="${ERRORS}TEST GUARDIAN FAILED for task '$TASK_SUBJECT':\n"
      ERRORS="${ERRORS}The test suite did not pass. Fix the failing tests before completing this task.\n"
      ERRORS="${ERRORS}Test command: $TEST_CMD\n"
      ERRORS="${ERRORS}Output (last 50 lines):\n"
      ERRORS="${ERRORS}$(echo "$TEST_OUTPUT" | tail -50)\n\n"
    }
  fi
fi

# --- Integration Guardian ---
INTEGRATION_ENABLED=$(jq -r '.integration_guardian.enabled // false' "$CONFIG")
if [ "$INTEGRATION_ENABLED" = "true" ]; then
  FILE_THRESHOLD=$(jq -r '.integration_guardian.file_threshold // 3' "$CONFIG")

  # Count files changed in working tree (staged + unstaged)
  CHANGED_FILES=$(cd "$PROJECT_DIR" && git diff --name-only HEAD 2>/dev/null | wc -l | tr -d ' ')

  if [ "$CHANGED_FILES" -ge "$FILE_THRESHOLD" ]; then
    TEST_CMD=$(jq -r '.test_guardian.test_command // ""' "$CONFIG")
    if [ -n "$TEST_CMD" ]; then
      INTEGRATION_OUTPUT=$(cd "$PROJECT_DIR" && eval "$TEST_CMD" 2>&1) || {
        ERRORS="${ERRORS}INTEGRATION GUARDIAN FAILED for task '$TASK_SUBJECT':\n"
        ERRORS="${ERRORS}This task touched $CHANGED_FILES files (threshold: $FILE_THRESHOLD). The full test suite must pass.\n"
        ERRORS="${ERRORS}Output (last 50 lines):\n"
        ERRORS="${ERRORS}$(echo "$INTEGRATION_OUTPUT" | tail -50)\n\n"
      }
    fi
  fi
fi

# If any guardian failed, block the task
if [ -n "$ERRORS" ]; then
  printf "%b" "$ERRORS" >&2
  exit 2
fi

exit 0
```

Write to `guardian/hooks/task-completed.sh`.

**Step 2: Make it executable**

Run: `chmod +x guardian/hooks/task-completed.sh`

**Step 3: Verify the script parses correctly**

Run: `bash -n guardian/hooks/task-completed.sh`
Expected: No output (clean parse)

**Step 4: Commit**

```bash
git add guardian/hooks/task-completed.sh
git commit -m "feat(guardian): add TaskCompleted hook script with test and integration guardians"
```

---

### Task 4: Create the guardian agents

These are the reasoning-layer guardians — the spec, convention, and context guardians that require LLM reasoning (not just running a test command). They are referenced by the team lead and reviewer roles in playbooks.

**Files:**
- Create: `guardian/agents/spec-guardian.md`
- Create: `guardian/agents/test-guardian.md`
- Create: `guardian/agents/convention-guardian.md`
- Create: `guardian/agents/integration-guardian.md`
- Create: `guardian/agents/context-guardian.md`

**Step 1: Write spec-guardian agent**

```yaml
---
name: spec-guardian
description: Validates that implementation matches the design document requirements. Identifies spec drift, missing requirements, and undocumented behavior.
tools:
  - Read
  - Grep
  - Glob
---
```

Body should instruct the agent to:
- Read the mission brief at `.guardian/mission-brief.md` to find the design doc path
- Read the design doc and extract numbered requirements
- For each requirement, search the codebase for corresponding implementation
- Flag: requirements with no implementation, implementation with no requirement (undocumented behavior), partial implementations
- Output a structured assessment: requirement ID, status (implemented/missing/partial/undocumented), file locations, specific feedback

Write to `guardian/agents/spec-guardian.md`. Target length: 80-100 lines.

**Step 2: Write test-guardian agent**

```yaml
---
name: test-guardian
description: Validates test coverage and test quality. Checks that tests cover stated requirements, not just happy paths.
tools:
  - Read
  - Grep
  - Glob
  - Bash
---
```

Body should instruct the agent to:
- Read the mission brief to understand requirements and test command
- Find all test files related to the changed code
- Check that each requirement has at least one test
- Check for edge case coverage (empty inputs, error paths, boundary conditions)
- Run the test suite and capture output
- Output: requirements mapped to test functions, missing test coverage, edge cases not tested, test run results

Write to `guardian/agents/test-guardian.md`. Target length: 80-100 lines.

**Step 3: Write convention-guardian agent**

```yaml
---
name: convention-guardian
description: Validates that code follows project conventions defined in CLAUDE.md. Checks architecture patterns, naming, structure.
tools:
  - Read
  - Grep
  - Glob
---
```

Body should instruct the agent to:
- Read the project's CLAUDE.md to extract conventions, patterns, and rules
- Read recently changed/created files (check git diff)
- Check each file against the conventions: naming patterns, file placement, architecture rules, import patterns
- Output: convention checked, status (pass/violation), file location, specific feedback for violations

Write to `guardian/agents/convention-guardian.md`. Target length: 60-80 lines.

**Step 4: Write integration-guardian agent**

```yaml
---
name: integration-guardian
description: Validates cross-module compatibility when changes touch multiple files. Checks imports, interfaces, and cross-references.
tools:
  - Read
  - Grep
  - Glob
  - Bash
---
```

Body should instruct the agent to:
- Identify all files changed in the current branch
- Check for: broken imports, interface mismatches (function signatures changed but callers not updated), broken cross-references
- Run the full test suite
- Output: files checked, issues found, test suite results

Write to `guardian/agents/integration-guardian.md`. Target length: 60-80 lines.

**Step 5: Write context-guardian agent**

```yaml
---
name: context-guardian
description: Captures design decisions and rationale to the decisions log. Not a blocker — a logger that preserves context across agent context windows.
tools:
  - Read
  - Grep
  - Glob
---
```

Body should instruct the agent to:
- Read the current decisions log at `.guardian/decisions-log.md`
- Read recent task completions and guardian feedback from the task list
- Summarize: what decisions were made, why, what alternatives were considered, what guardian feedback was addressed
- Append a new entry to the decisions log following the template format
- This agent does NOT block — it always reports success

Write to `guardian/agents/context-guardian.md`. Target length: 50-70 lines.

**Step 6: Commit**

```bash
git add guardian/agents/
git commit -m "feat(guardian): add 5 guardian agents (spec, test, convention, integration, context)"
```

---

### Task 5: Create the role skills

Skills provide reasoning guidance for teammates in specific roles. These are pure guidance — no tools, no file operations.

**Files:**
- Create: `guardian/skills/team-lead/SKILL.md`
- Create: `guardian/skills/team-implementer/SKILL.md`
- Create: `guardian/skills/team-reviewer/SKILL.md`

**Step 1: Write team-lead skill**

```yaml
---
name: team-lead
description: Guidance for leading an agent team — task breakdown, delegation, monitoring, and completion reporting
---
```

Body should cover:
- How to read a mission brief and design doc
- How to break work into tasks (5-6 per teammate, clear deliverables, dependency ordering)
- How to write good task descriptions (specific enough that a teammate with no context can execute)
- How to monitor progress and reassign when teammates are stuck
- How to handle guardian feedback escalation
- How to write the completion report using the template
- How to gracefully shut down the team

Write to `guardian/skills/team-lead/SKILL.md`. Target length: 100-140 lines.

**Step 2: Write team-implementer skill**

```yaml
---
name: team-implementer
description: Guidance for implementing tasks within an agent team — reading context, writing code alongside tests, addressing guardian feedback
---
```

Body should cover:
- First action: read `.guardian/mission-brief.md` and the relevant design doc section
- Check existing code patterns before writing new code (read CLAUDE.md, look at neighboring files)
- Write tests alongside implementation, not after
- When guardian feedback arrives: read it carefully, understand the root cause, fix it, don't just patch the symptom
- Keep the decisions log in mind — if you make a non-obvious choice, mention it to the lead
- How to claim tasks from the task list

Write to `guardian/skills/team-implementer/SKILL.md`. Target length: 80-110 lines.

**Step 3: Write team-reviewer skill**

```yaml
---
name: team-reviewer
description: Guidance for reviewing implementation within an agent team — spec alignment, edge cases, consistency, deviation documentation
---
```

Body should cover:
- Your job is NOT to write feature code — you review and create fix tasks
- Read the mission brief and design doc before reviewing anything
- For each completed implementation task, check: spec alignment, edge case handling, error handling, naming consistency, CLAUDE.md convention compliance
- If you find issues: create new tasks assigned to the relevant implementer with specific, actionable descriptions
- After all implementation is done: do a final full-branch review
- Write the "Deviations from Spec" section of the completion report — document any changes from the original design with rationale

Write to `guardian/skills/team-reviewer/SKILL.md`. Target length: 80-110 lines.

**Step 4: Commit**

```bash
git add guardian/skills/
git commit -m "feat(guardian): add role skills (team-lead, team-implementer, team-reviewer)"
```

---

### Task 6: Create the commands

Commands are the user-facing entry points. They follow the Forge plugin pattern: markdown with YAML frontmatter, conversational flow, delegation to agents and tools.

**Files:**
- Create: `guardian/commands/run-playbook.md`
- Create: `guardian/commands/list-playbooks.md`
- Create: `guardian/commands/init.md`

**Step 1: Write the init command**

```yaml
---
description: One-time setup to register Guardian hooks in the current project
---
```

Body should:
- Read the project's `.claude/settings.json` (create if it doesn't exist)
- Add the `TaskCompleted` hook pointing to `$CLAUDE_PLUGIN_ROOT/hooks/task-completed.sh`
- Confirm to the user what was added
- Create `.guardian/` directory if it doesn't exist
- Tell the user they're ready to run playbooks

Write to `guardian/commands/init.md`. Target length: 40-60 lines.

**Step 2: Write the list-playbooks command**

```yaml
---
description: Show available Guardian playbooks and their descriptions
---
```

Body should:
- Read all `.md` files in the plugin's `playbooks/` directory
- Extract the frontmatter (name, description, team_size, guardians)
- Present a formatted table to the user
- Briefly explain how to run a playbook

Write to `guardian/commands/list-playbooks.md`. Target length: 30-50 lines.

**Step 3: Write the run-playbook command**

```yaml
---
description: Run a Guardian playbook to spin up an agent team for a development task
arguments:
  - name: playbook
    description: Name of the playbook to run (e.g., feature-build, hardening, bug-hunt)
    required: true
---
```

This is the main entry point. Body should define these phases:

**Phase 1: Load Playbook**
- Read the specified playbook from the plugin's `playbooks/` directory
- If not found, show available playbooks and ask user to choose

**Phase 2: Gather Context**
- Ask the user for: design doc path, key files, test command, specific callouts/gotchas
- Ask one question at a time (following Forge conversational patterns)
- Validate that the design doc exists

**Phase 3: Configure Guardians**
- Write `.guardian/guardians.json` based on playbook defaults and user's test command
- Write `.guardian/mission-brief.md` using the template, populated with gathered context

**Phase 4: Initialize Decisions Log**
- Write `.guardian/decisions-log.md` using the template

**Phase 5: Create the Agent Team**
- Read the playbook's role definitions
- Use `TeamCreate` to create the team
- Use `TaskCreate` to create the initial task list (broken down from the design doc)
- Use `Task` tool to spawn teammates with appropriate roles, models, and the mission brief path in their spawn prompts
- Each teammate's prompt should reference the team-implementer or team-reviewer skill and the mission brief location

**Phase 6: Monitor and Complete**
- Wait for teammates to complete all tasks
- When all tasks pass all guardians, trigger the lead to:
  - Run the full test suite one final time
  - Have the Reviewer do a final branch review
  - Write `.guardian/completion-report.md` using the template
  - Shut down teammates
  - Clean up the team
  - Report completion to the user

Write to `guardian/commands/run-playbook.md`. Target length: 120-180 lines.

**Step 4: Commit**

```bash
git add guardian/commands/
git commit -m "feat(guardian): add commands (run-playbook, list-playbooks, init)"
```

---

### Task 7: Create the playbooks

Each playbook is a markdown file with frontmatter metadata and detailed role descriptions. Start with the two highest-value playbooks first (feature-build and hardening), then add the remaining four.

**Files:**
- Create: `guardian/playbooks/feature-build.md`
- Create: `guardian/playbooks/hardening.md`
- Create: `guardian/playbooks/bug-hunt.md`
- Create: `guardian/playbooks/refactor.md`
- Create: `guardian/playbooks/doc-sprint.md`
- Create: `guardian/playbooks/test-suite.md`

**Step 1: Write feature-build playbook**

```yaml
---
name: feature-build
description: End-to-end feature implementation from a design doc
team_size: 4
roles: [lead, implementer, implementer, reviewer]
guardians: [spec, test, convention, integration, context]
autonomy: full
---
```

Body defines each role in detail:
- **Lead:** Read design doc, break into tasks (5-6 per implementer), assign respecting dependencies, monitor guardian feedback, produce completion report
- **Implementer (x2):** Read mission brief, implement assigned tasks, write tests alongside code, address guardian feedback
- **Reviewer:** Do not write feature code. After each implementer task passes guardians, deep review for spec drift, edge cases, naming. Create fix tasks if issues found. Write deviations section of completion report.
- **Task creation guidance:** Group by module/component, each task should produce a testable deliverable, order by dependency
- **Completion criteria:** All tasks complete, all guardians pass, final full-suite test passes, completion report written

Write to `guardian/playbooks/feature-build.md`. Target length: 120-160 lines.

**Step 2: Write hardening playbook**

```yaml
---
name: hardening
description: Quality sweep — security, edge cases, and performance review
team_size: 4
roles: [lead, security-reviewer, edge-case-finder, perf-tester]
guardians: [test, convention, integration]
autonomy: full
---
```

Body defines specialized reviewer roles. Each reviewer examines existing code (not writing new features) and creates tasks for issues found. The lead coordinates and produces a hardening report.

Write to `guardian/playbooks/hardening.md`. Target length: 100-130 lines.

**Step 3: Write bug-hunt playbook**

```yaml
---
name: bug-hunt
description: Competing hypothesis debugging with parallel investigators
team_size: 5
roles: [lead, investigator, investigator, investigator, fixer]
guardians: [test, integration]
autonomy: full
---
```

Body defines: 3 investigators each pursuing a different hypothesis, communicating findings to challenge each other. Once a root cause is identified, the fixer implements the fix. Lead synthesizes and validates.

Write to `guardian/playbooks/bug-hunt.md`. Target length: 100-130 lines.

**Step 4: Write refactor playbook**

```yaml
---
name: refactor
description: Cross-module restructuring with module ownership
team_size: 4
roles: [lead, module-owner, module-owner, integration-tester]
guardians: [test, convention, integration, context]
autonomy: full
---
```

Write to `guardian/playbooks/refactor.md`. Target length: 100-130 lines.

**Step 5: Write doc-sprint playbook**

```yaml
---
name: doc-sprint
description: Documentation push with accuracy validation
team_size: 4
roles: [lead, writer, code-reader, accuracy-checker]
guardians: [spec, convention]
autonomy: full
---
```

Write to `guardian/playbooks/doc-sprint.md`. Target length: 80-110 lines.

**Step 6: Write test-suite playbook**

```yaml
---
name: test-suite
description: Backfill tests for existing code with coverage analysis
team_size: 4
roles: [lead, test-writer, test-writer, coverage-analyst]
guardians: [test, convention, integration]
autonomy: full
---
```

Write to `guardian/playbooks/test-suite.md`. Target length: 80-110 lines.

**Step 7: Commit**

```bash
git add guardian/playbooks/
git commit -m "feat(guardian): add 6 playbooks (feature-build, hardening, bug-hunt, refactor, doc-sprint, test-suite)"
```

---

### Task 8: End-to-end test in the forge-feature repo

**Step 1: Run guardian init**

Invoke `/guardian:init` in the forge-feature repo. Verify:
- `.claude/settings.json` now has the `TaskCompleted` hook
- `.guardian/` directory was created

**Step 2: Test the hook script manually**

Run the hook with simulated input to verify it parses correctly:

```bash
echo '{"task_id":"test-1","task_subject":"Test task","cwd":"/Users/jeremybrice/Documents/GitHub/the-forge-feature"}' | bash guardian/hooks/task-completed.sh
echo $?
```

Expected: Exit code 0 (no guardians.json exists yet, so passthrough)

**Step 3: Create a guardians.json and test hook blocking**

Write a `.guardian/guardians.json` with test_guardian enabled and a deliberately failing test command:

```json
{
  "test_guardian": { "enabled": true, "require_passing": true, "test_command": "false" },
  "integration_guardian": { "enabled": false }
}
```

Run the hook again:

```bash
echo '{"task_id":"test-1","task_subject":"Test task","cwd":"/Users/jeremybrice/Documents/GitHub/the-forge-feature"}' | bash guardian/hooks/task-completed.sh
echo $?
```

Expected: Exit code 2, stderr contains "TEST GUARDIAN FAILED"

**Step 4: Test with passing test command**

Update guardians.json to use `true` as test command, run again.
Expected: Exit code 0

**Step 5: Clean up test artifacts**

Remove the test `.guardian/guardians.json`.

**Step 6: Run a real playbook (feature-build)**

Pick a small, well-defined task in the forge-feature repo (e.g., "add a `forge index validate` subcommand that checks index integrity"). Run:

```
/guardian:run-playbook feature-build
```

Provide the context, let the team execute, and verify:
- Team spawned correctly
- Guardians fired on task completions
- Mission brief was written
- Decisions log accumulated entries
- Completion report was generated
- Code works and tests pass

**Step 7: Commit test results**

```bash
git add -A
git commit -m "test(guardian): validate end-to-end playbook execution in forge-feature repo"
```

---

### Task 9: Final documentation pass

**Files:**
- Modify: `guardian/README.md`
- Modify: `CLAUDE.md` (add guardian to plugin table)

**Step 1: Update guardian README with real examples**

Based on the end-to-end test, update the README with:
- Actual output from a playbook run
- Real example of guardian feedback
- Tips learned from testing

**Step 2: Add guardian to the CLAUDE.md plugin table**

Add a new row:

```markdown
| **guardian** | `/guardian:run-playbook`, `/guardian:list-playbooks`, `/guardian:init` | `.guardian/` |
```

**Step 3: Commit**

```bash
git add guardian/README.md CLAUDE.md
git commit -m "docs(guardian): update README with real examples and add to CLAUDE.md plugin table"
```
