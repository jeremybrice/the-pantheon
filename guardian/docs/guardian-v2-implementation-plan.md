# Guardian v2 Implementation Plan

> **Feature:** Guardian v2 — Superpowers-Powered Teams
> **Goal:** Refactor Guardian from a standalone orchestration plugin into the orchestration + enforcement layer that wraps Superpowers-enhanced agents.
> **Architecture:** Guardian owns team roles, playbooks, and blocking validation gates. Superpowers owns coding methodology (TDD, debugging, verification, planning, git workflows). Hard dependency on `superpowers@claude-plugins-official`.
> **Tech Stack:** Markdown (skills, agents, playbooks, commands), Bash (hooks), JSON (config)
> **Design Doc:** `guardian/docs/guardian-v2-design.md`

---

## Task 1: Create verification-guardian agent

**Files:**
- Create: `guardian/agents/verification-guardian.md`

**Steps:**

- [ ] **1.1** Create `guardian/agents/verification-guardian.md` with the following content:

```markdown
---
name: verification-guardian
description: Blocks task completion when claims lack fresh verification evidence
tools: [Read, Grep, Glob, Bash]
blocking: true
---

# Verification Guardian

You validate that completed tasks have fresh evidence supporting their completion claims. You enforce the principle: "Evidence before claims, always."

## What You Check

When a task is marked complete, examine:

1. **Test evidence.** Were tests actually run? Look for test output in the recent session. If the task claims "tests pass," there must be actual test output showing passage — not just "should pass" or "looks correct."

2. **Build evidence.** If the task involved code changes, was the code built or linted? Check for build/lint output.

3. **Requirement coverage.** Does the completed work address every item in the task description? Compare the task description against the actual file changes.

## Blocking Rules

Block (exit 2) if:
- Task claims tests pass but no test output exists in the working directory or recent git history
- Task description lists deliverables that don't exist in the file system
- Task modifies code but no tests were added or updated

Pass (exit 0) if:
- Fresh test output confirms all tests pass
- All deliverables from the task description exist
- Test coverage for the change is present

## Output Format

When blocking, provide specific feedback:
- Which evidence is missing
- What command to run to produce the evidence
- Which deliverables are not found
```

- [ ] **1.2** Verify the file exists and follows the same frontmatter pattern as the other guardian agents:
  ```
  ls -la guardian/agents/verification-guardian.md
  head -5 guardian/agents/spec-guardian.md   # compare frontmatter style
  head -5 guardian/agents/verification-guardian.md
  ```

- [ ] **1.3** Commit:
  ```
  git add guardian/agents/verification-guardian.md
  git commit -m "guardian: add verification-guardian agent"
  ```

---

## Task 2: Create SessionStart hook

**Files:**
- Create: `guardian/hooks/session-start.sh`

**Steps:**

- [ ] **2.1** Create `guardian/hooks/session-start.sh` with the following content:

```bash
#!/bin/bash
# Guardian SessionStart Hook
# Injects active guardian context and Superpowers skill requirements on session start.
# Only activates if .guardian/guardians.json exists in the project.

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
GUARDIAN_DIR="$PROJECT_DIR/.guardian"
CONFIG="$GUARDIAN_DIR/guardians.json"

# Only activate if guardian is configured for this project
if [ ! -f "$CONFIG" ]; then
  exit 0
fi

# Read active guardians
ACTIVE_GUARDIANS=$(jq -r 'to_entries[] | select(.value.enabled == true) | .key' "$CONFIG" 2>/dev/null | tr '\n' ', ' | sed 's/,$//')

# Read mission brief summary (first 20 lines)
MISSION_SUMMARY=""
if [ -f "$GUARDIAN_DIR/mission-brief.md" ]; then
  MISSION_SUMMARY=$(head -20 "$GUARDIAN_DIR/mission-brief.md" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
fi

# Build context message
CONTEXT="GUARDIAN ACTIVE SESSION"
CONTEXT="${CONTEXT}\\n\\nActive guardians: ${ACTIVE_GUARDIANS}"
CONTEXT="${CONTEXT}\\n\\nRequired Superpowers skills for this project:"
CONTEXT="${CONTEXT}\\n- superpowers:test-driven-development (all implementation tasks)"
CONTEXT="${CONTEXT}\\n- superpowers:systematic-debugging (debugging tasks)"
CONTEXT="${CONTEXT}\\n- superpowers:verification-before-completion (before marking any task done)"

if [ -n "$MISSION_SUMMARY" ]; then
  CONTEXT="${CONTEXT}\\n\\nMission brief summary:\\n${MISSION_SUMMARY}"
fi

# Output JSON for Claude Code hookSpecificOutput
printf '{"hookSpecificOutput":{"additionalContext":"%s"}}' "$CONTEXT"

exit 0
```

- [ ] **2.2** Make the script executable:
  ```
  chmod +x guardian/hooks/session-start.sh
  ```

- [ ] **2.3** Verify it parses without errors:
  ```
  bash -n guardian/hooks/session-start.sh
  ```

- [ ] **2.4** Commit:
  ```
  git add guardian/hooks/session-start.sh
  git commit -m "guardian: add SessionStart hook for context injection"
  ```

---

## Task 3: Create hooks.json registration file

**Files:**
- Create: `guardian/hooks/hooks.json`

**Steps:**

- [ ] **3.1** Create `guardian/hooks/hooks.json` with the following content:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/session-start.sh",
            "async": false
          }
        ]
      }
    ],
    "TaskCompleted": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "cat /dev/stdin | bash ${CLAUDE_PLUGIN_ROOT}/hooks/task-completed.sh"
          }
        ]
      }
    ]
  }
}
```

- [ ] **3.2** Validate the JSON:
  ```
  jq . guardian/hooks/hooks.json
  ```

- [ ] **3.3** Commit:
  ```
  git add guardian/hooks/hooks.json
  git commit -m "guardian: add hooks.json with SessionStart and TaskCompleted registration"
  ```

---

## Task 4: Update task-completed.sh with verification guardian

**Files:**
- Modify: `guardian/hooks/task-completed.sh`

**Steps:**

- [ ] **4.1** Add the verification guardian check block after the integration guardian block (before the final error check). Insert after line 62 (after the integration guardian `fi`):

```bash
# --- Verification Guardian ---
VERIFICATION_ENABLED=$(jq -r '.verification_guardian.enabled // false' "$CONFIG")
if [ "$VERIFICATION_ENABLED" = "true" ]; then
  REQUIRE_TEST_EVIDENCE=$(jq -r '.verification_guardian.require_test_evidence // true' "$CONFIG")
  REQUIRE_DELIVERABLES=$(jq -r '.verification_guardian.require_deliverables_check // true' "$CONFIG")

  if [ "$REQUIRE_TEST_EVIDENCE" = "true" ]; then
    # Check if tests were run by looking for recent test output files or git changes to test files
    TEST_FILES_CHANGED=$(cd "$PROJECT_DIR" && git diff --name-only HEAD 2>/dev/null | grep -c -E '(test_|_test\.|\.test\.|spec\.)' || true)
    CODE_FILES_CHANGED=$(cd "$PROJECT_DIR" && git diff --name-only HEAD 2>/dev/null | grep -c -v -E '(test_|_test\.|\.test\.|spec\.)' || true)

    if [ "$CODE_FILES_CHANGED" -gt 0 ] && [ "$TEST_FILES_CHANGED" -eq 0 ]; then
      ERRORS="${ERRORS}VERIFICATION GUARDIAN FAILED for task '$TASK_SUBJECT':\n"
      ERRORS="${ERRORS}Code files were changed but no test files were added or updated.\n"
      ERRORS="${ERRORS}Evidence of testing is required before task completion.\n"
      ERRORS="${ERRORS}Add or update tests for your changes, run the test suite, and try again.\n\n"
    fi
  fi
fi
```

- [ ] **4.2** Verify the script still parses:
  ```
  bash -n guardian/hooks/task-completed.sh
  ```

- [ ] **4.3** Commit:
  ```
  git add guardian/hooks/task-completed.sh
  git commit -m "guardian: add verification guardian to task-completed hook"
  ```

---

## Task 5: Rewrite team-implementer skill with Superpowers integration

**Files:**
- Modify: `guardian/skills/team-implementer/SKILL.md`

**Steps:**

- [ ] **5.1** Replace the frontmatter description to reflect Superpowers integration:

  Old:
  ```
  description: "Provides reasoning guidance for implementing tasks within an agent team: reading context, following patterns, writing tests, handling feedback, and communicating blockers."
  ```
  New:
  ```
  description: "Provides orchestration guidance for the implementer role: team coordination, task claiming, feedback handling, and blocker communication. Delegates coding methodology to Superpowers skills."
  ```

- [ ] **5.2** Add the Required Superpowers Skills section immediately after the frontmatter block (after line 6, before "## First Actions"):

```markdown
## Required Superpowers Skills

Before starting any implementation task, load these skills. They define how you write code, tests, and verify your work:

- **superpowers:test-driven-development** — Follow the red-green-refactor cycle for ALL code changes. Write the test first, watch it fail, then implement. This is non-negotiable.
- **superpowers:systematic-debugging** — When you encounter a bug or unexpected behavior, follow the 4-phase debugging process. Do NOT guess at fixes.
- **superpowers:verification-before-completion** — Before marking ANY task as complete, you must have fresh evidence (test output, build output) that your work is correct. Claims without evidence will be blocked by the verification guardian.

These skills define the *how* of your work. The sections below define the *what* — how you coordinate with the team, handle feedback, and communicate.
```

- [ ] **5.3** Replace the "Checking Existing Patterns" section (lines 30-40). Keep only the first paragraph about reading neighboring files. Remove the rest (shared utilities, architecture paragraphs — these are covered by Superpowers TDD and the convention guardian). Replace with:

```markdown
## Checking Existing Patterns

Before writing any new code, look at how similar things are already done in the codebase. This is not optional.

**Read neighboring files.** If you are adding a new module to a package, read at least two existing modules in that package to understand the conventions: import style, error handling patterns, naming conventions, docstring format, and export patterns.

For detailed guidance on writing tests and structuring your implementation, follow the loaded Superpowers skills — particularly `superpowers:test-driven-development` for the red-green-refactor cycle.
```

- [ ] **5.4** Replace the "Writing Tests" section (lines 43-50) with a brief delegation:

```markdown
## Writing Tests

Follow `superpowers:test-driven-development` for all test writing. The key rule: write the test first, watch it fail, then implement the minimal code to pass. Run the full test suite before marking any task complete.

Follow existing test patterns in the codebase (framework, fixtures, directory structure). The convention guardian will flag deviations.
```

- [ ] **5.5** Add a "Git Worktree Awareness" section before "Completing Tasks":

```markdown
## Git Worktree Awareness

The team may be working in a git worktree rather than the main working tree. If the team lead set up a worktree during playbook initialization:

- All your file changes happen within the worktree directory.
- Do not modify files outside the worktree boundary.
- Commits go to the worktree's branch, not the main branch.
```

- [ ] **5.6** Verify the file is well-formed (check for broken markdown):
  ```
  wc -l guardian/skills/team-implementer/SKILL.md  # should be shorter than before
  head -30 guardian/skills/team-implementer/SKILL.md
  ```

- [ ] **5.7** Commit:
  ```
  git add guardian/skills/team-implementer/SKILL.md
  git commit -m "guardian: rewrite team-implementer skill with Superpowers delegation"
  ```

---

## Task 6: Update team-lead skill with design phase and skill delegation

**Files:**
- Modify: `guardian/skills/team-lead/SKILL.md`

**Steps:**

- [ ] **6.1** Add the "Design Phase" section after "## First Actions" (after the 4 numbered first-action steps, before "## Task Breakdown"):

```markdown
## Design Phase (Before Task Breakdown)

If no design document exists yet, or if the mission brief references a high-level goal rather than a detailed spec, invoke the Superpowers design workflow before breaking down tasks:

1. Use `superpowers:brainstorming` to explore the problem space with the user and produce a design document.
2. Use `superpowers:writing-plans` to convert the approved design into a detailed implementation plan with exact file paths, code blocks, and verification steps.

Only proceed to task breakdown after a design document exists and has been approved. A vague goal is not a sufficient basis for creating tasks.
```

- [ ] **6.2** Add Superpowers skill delegation guidance to the "Writing Good Task Descriptions" section. Append after the existing item 5 ("Constraints"):

```markdown
6. **Superpowers skills.** Specify which Superpowers skills the assignee should use. For implementation tasks, always include: "Use superpowers:test-driven-development for this task." For debugging tasks: "Use superpowers:systematic-debugging." For review tasks: "Use superpowers:requesting-code-review."
```

- [ ] **6.3** Add "Git Worktree Setup" guidance to the "First Actions" section. Add as step 5:

```markdown
5. If a git worktree was set up for this playbook run (check the mission brief for a worktree path), confirm all team members are working in the worktree directory, not the main working tree.
```

- [ ] **6.4** Verify the file:
  ```
  head -40 guardian/skills/team-lead/SKILL.md
  ```

- [ ] **6.5** Commit:
  ```
  git add guardian/skills/team-lead/SKILL.md
  git commit -m "guardian: add design phase and Superpowers delegation to team-lead skill"
  ```

---

## Task 7: Update team-reviewer skill with code review skill integration

**Files:**
- Modify: `guardian/skills/team-reviewer/SKILL.md`

**Steps:**

- [ ] **7.1** Add "Review Methodology" section after "## First Actions" (after the 4 numbered steps, before "## What You Review"):

```markdown
## Review Methodology

Use `superpowers:requesting-code-review` to structure your review process — it provides a systematic framework for dispatching focused reviews.

When receiving feedback on your review findings from implementers, follow `superpowers:receiving-code-review`:
- Verify claims before accepting them ("Tests pass" requires actual test output)
- Push back with technical reasoning when warranted
- Restate technical requirements rather than using performative agreement
```

- [ ] **7.2** Verify:
  ```
  head -30 guardian/skills/team-reviewer/SKILL.md
  ```

- [ ] **7.3** Commit:
  ```
  git add guardian/skills/team-reviewer/SKILL.md
  git commit -m "guardian: add Superpowers code review integration to team-reviewer skill"
  ```

---

## Task 8: Update all 6 playbooks

**Files:**
- Modify: `guardian/playbooks/feature-build.md`
- Modify: `guardian/playbooks/bug-hunt.md`
- Modify: `guardian/playbooks/hardening.md`
- Modify: `guardian/playbooks/refactor.md`
- Modify: `guardian/playbooks/doc-sprint.md`
- Modify: `guardian/playbooks/test-suite.md`

**Steps:**

- [ ] **8.1** For each playbook, add `verification` to the frontmatter `guardians` list:

  **feature-build.md:** `guardians: [spec, test, convention, integration, context, verification]`
  **bug-hunt.md:** `guardians: [test, integration, verification]`
  **hardening.md:** `guardians: [test, convention, integration, verification]`
  **refactor.md:** `guardians: [test, convention, integration, context, verification]`
  **doc-sprint.md:** `guardians: [spec, convention, verification]`
  **test-suite.md:** `guardians: [test, convention, integration, verification]`

- [ ] **8.2** For **feature-build.md**, **refactor.md**, and **doc-sprint.md** — add the "Pre-Flight: Design Phase" section before "## Roles":

```markdown
## Pre-Flight: Design Phase

Before spawning the team, ensure a design document exists:

1. If the user provides a design doc path, validate it exists and is detailed enough for task breakdown.
2. If no design doc exists, run the Superpowers design workflow:
   - Invoke `superpowers:brainstorming` to explore the problem and produce a spec
   - Invoke `superpowers:writing-plans` to convert the spec into an implementation plan
   - Save the plan as the design document referenced in the mission brief
3. Only proceed to team creation after the design is approved.
```

- [ ] **8.3** For ALL 6 playbooks, add "Git Worktree" note to the Guardian Configuration section. Append after the guardian list:

```markdown
### Git Worktree

All team members work in an isolated git worktree created via `superpowers:using-git-worktrees` during playbook setup. At completion, use `superpowers:finishing-a-development-branch` to merge, create a PR, or discard the branch.
```

- [ ] **8.4** For ALL 6 playbooks, add verification guardian description to the guardian list in the body:

```markdown
- **verification** -- Enforces evidence-based completion. When a task is marked complete, the verification guardian checks that tests were actually run and that all deliverables exist. Claims without evidence are blocked.
```

- [ ] **8.5** Verify all frontmatter is valid:
  ```
  for f in guardian/playbooks/*.md; do echo "--- $f ---"; head -8 "$f"; done
  ```

- [ ] **8.6** Commit:
  ```
  git add guardian/playbooks/*.md
  git commit -m "guardian: add verification guardian, design phase, and worktree to all playbooks"
  ```

---

## Task 9: Update run-playbook command

**Files:**
- Modify: `guardian/commands/run-playbook.md`

**Steps:**

- [ ] **9.1** Add "Step 0: Set Up Worktree" to Phase 4 (before "Step 1: Create Team"). Insert before the existing Step 1:

```markdown
### Step 0: Set Up Worktree

Before creating the team, set up an isolated workspace:

1. Invoke `superpowers:using-git-worktrees` to create a worktree for this playbook run.
2. Record the worktree path in the mission brief under a `worktree_path` field.
3. All subsequent team agent prompts should include the worktree path so agents work in the correct directory.
4. At playbook completion, use `superpowers:finishing-a-development-branch` to merge, create a PR, or discard.
```

- [ ] **9.2** Add `verification_guardian` to the example `guardians.json` in Phase 3:

```json
"verification_guardian": { "enabled": true, "require_test_evidence": true, "require_deliverables_check": true }
```

- [ ] **9.3** Update the Superpowers skill references in the teammate prompt template (Phase 4, Step 3). Update the prompt to include:

```
  Read your role skill for detailed guidance:
  Read file: $CLAUDE_PLUGIN_ROOT/skills/{skill_name}/SKILL.md

  Your role skill references Superpowers skills. Load them as instructed
  in the skill file — they define how you write code, tests, and reviews.
```

- [ ] **9.4** Commit:
  ```
  git add guardian/commands/run-playbook.md
  git commit -m "guardian: add worktree setup and verification guardian to run-playbook"
  ```

---

## Task 10: Update init command

**Files:**
- Modify: `guardian/commands/init.md`

**Steps:**

- [ ] **10.1** Update the hook entry in section 3 ("Merge Hook into Settings") to include both SessionStart and TaskCompleted hooks:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash $CLAUDE_PLUGIN_ROOT/hooks/session-start.sh",
            "async": false
          }
        ]
      }
    ],
    "TaskCompleted": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "cat /dev/stdin | bash $CLAUDE_PLUGIN_ROOT/hooks/task-completed.sh"
          }
        ]
      }
    ]
  }
}
```

- [ ] **10.2** Update the "Check for Existing Hook" section to also check for the SessionStart hook.

- [ ] **10.3** Update the confirmation message to show both hooks:

```
Guardian initialized.

  Hooks registered:
    SessionStart  -> session-start.sh (context injection)
    TaskCompleted -> task-completed.sh (guardian validation)
  Working directory: .guardian/

When a session starts in a project with .guardian/guardians.json, the
SessionStart hook injects active guardian context and Superpowers skill
requirements. When a teammate marks a task complete, the TaskCompleted
hook runs all enabled guardians.

Prerequisite: superpowers@claude-plugins-official must be installed.

Next steps:
  /guardian:list-playbooks  — see available playbooks
  /guardian:run-playbook    — spin up a team for a development task
```

- [ ] **10.4** Commit:
  ```
  git add guardian/commands/init.md
  git commit -m "guardian: register SessionStart hook in init command"
  ```

---

## Task 11: Update plugin metadata and marketplace entry

**Files:**
- Modify: `guardian/.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`

**Steps:**

- [ ] **11.1** Update `guardian/.claude-plugin/plugin.json`:

```json
{
  "name": "guardian",
  "version": "2.0.0-alpha",
  "description": "Team orchestration and enforcement layer for Superpowers-enhanced agent teams",
  "author": { "name": "Jeremy Brice" },
  "dependencies": {
    "plugins": ["superpowers@claude-plugins-official"]
  }
}
```

- [ ] **11.2** Update `.claude-plugin/marketplace.json` to match the new version and description.

- [ ] **11.3** Validate both JSON files:
  ```
  jq . guardian/.claude-plugin/plugin.json
  jq . .claude-plugin/marketplace.json
  ```

- [ ] **11.4** Commit:
  ```
  git add guardian/.claude-plugin/plugin.json .claude-plugin/marketplace.json
  git commit -m "guardian: bump to v2.0.0-alpha, add Superpowers dependency"
  ```

---

## Task 12: Rewrite README

**Files:**
- Modify: `guardian/README.md`

**Steps:**

- [ ] **12.1** Rewrite the README with the following structure:

  1. **Title and tagline:** "Guardian — Team orchestration and enforcement for Superpowers-enhanced agents"
  2. **What Guardian Does vs What Superpowers Does:** Clear 2-column table
  3. **Prerequisites:** `superpowers@claude-plugins-official` required
  4. **Quick Start:** `/guardian:init` then `/guardian:run-playbook feature-build`
  5. **Playbooks:** Table of 6 playbooks with team sizes and guardian configs (updated with verification)
  6. **Guardians:** Table of 6 guardians (add verification)
  7. **Superpowers Integration:** Table mapping which skills are used where
  8. **How It Works:** Updated 7-step workflow including design phase and worktree
  9. **Plugin Structure:** Updated directory tree
  10. **Migration from v1:** Brief upgrade notes

- [ ] **12.2** Verify no broken links or references:
  ```
  grep -n 'CLAUDE_PLUGIN_ROOT\|\.guardian\|superpowers:' guardian/README.md
  ```

- [ ] **12.3** Commit:
  ```
  git add guardian/README.md
  git commit -m "guardian: rewrite README for v2 Superpowers integration"
  ```

---

## Task 13: Final verification and push

**Steps:**

- [ ] **13.1** Verify all files exist and are well-formed:
  ```
  # New files
  ls -la guardian/agents/verification-guardian.md
  ls -la guardian/hooks/session-start.sh
  ls -la guardian/hooks/hooks.json

  # Verify bash scripts parse
  bash -n guardian/hooks/session-start.sh
  bash -n guardian/hooks/task-completed.sh

  # Verify JSON files parse
  jq . guardian/hooks/hooks.json
  jq . guardian/.claude-plugin/plugin.json
  jq . .claude-plugin/marketplace.json

  # Verify session-start.sh is executable
  test -x guardian/hooks/session-start.sh && echo "executable" || echo "NOT executable"
  ```

- [ ] **13.2** Verify no methodology duplication remains — Guardian should NOT contain detailed TDD, debugging, or verification methodology:
  ```
  grep -r "red-green-refactor\|iron law\|root cause investigation\|evidence before claims" guardian/skills/ guardian/agents/ guardian/playbooks/
  # Should return zero matches (methodology is in Superpowers, not Guardian)
  ```

- [ ] **13.3** Verify all Superpowers references are consistent:
  ```
  grep -r "superpowers:" guardian/ | sort
  # Should show consistent skill names across all files
  ```

- [ ] **13.4** Run a full git status and diff review:
  ```
  git status
  git log --oneline main..HEAD
  ```

- [ ] **13.5** Push to remote:
  ```
  git push -u origin claude/analyze-superpowers-guardian-jgdoo
  ```

---

## Execution Options

1. **Subagent-Driven** (recommended) — Fresh agent per task, spec compliance review after each, code quality review after each. Best for quality.
2. **Inline Execution** — Execute tasks sequentially in the current session. Faster, less overhead.
