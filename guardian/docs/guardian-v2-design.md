# Guardian v2 Design: Superpowers-Powered Teams

> **Date:** 2026-04-07
> **Status:** Draft — Pending Approval
> **Approach:** A — "Superpowers-Powered Teams"
> **Guardian Version:** 1.0.0-alpha → 2.0.0-alpha
> **Superpowers Dependency:** Hard (requires `superpowers@claude-plugins-official`)
> **Platform:** Claude Code only

---

## 1. Design Vision

Guardian v2 becomes the **orchestration and enforcement layer** that wraps Superpowers-enhanced agents. The division of responsibility:

| Concern | Owner | How |
|---|---|---|
| **Who does what** | Guardian | Team roles, task delegation, playbooks |
| **When work is validated** | Guardian | Hook-based blocking gates (guardians) |
| **How agents think and code** | Superpowers | TDD, debugging, verification, planning skills |
| **How agents manage branches** | Superpowers | Git worktrees, branch finishing |
| **What conventions to follow** | Guardian | Convention guardian reads CLAUDE.md |
| **What decisions were made** | Guardian | Context guardian + decisions log |

Guardian stops trying to teach agents *how to code* and instead tells them *which Superpowers skills to use*. This eliminates methodology overlap and lets each system do what it does best.

---

## 2. What Changes

### 2.1 Role Skills (Moderate Rewrite)

The three role skills are the primary integration point. They currently contain inline methodology guidance (how to write tests, how to check patterns, how to review code). In v2, that guidance is replaced with explicit Superpowers skill references.

#### team-implementer/SKILL.md

**Remove:**
- "Writing Tests" section (lines 43-50) — replaced by Superpowers TDD skill reference
- "Checking Existing Patterns" section (lines 30-40) — partially replaced; keep the "read neighboring files" instruction but drop the generic methodology

**Add:**
- **Required Superpowers skills** section at the top:
  ```
  ## Required Superpowers Skills

  Before starting any implementation task, load these skills. They define
  how you write code, tests, and verify your work:

  - superpowers:test-driven-development — Follow the red-green-refactor
    cycle for ALL code changes. Write the test first, watch it fail,
    then implement. This is non-negotiable.
  - superpowers:systematic-debugging — When you encounter a bug or
    unexpected behavior, follow the 4-phase debugging process. Do NOT
    guess at fixes.
  - superpowers:verification-before-completion — Before marking ANY task
    as complete, you must have fresh evidence (test output, build output)
    that your work is correct. Claims without evidence will be blocked
    by the verification guardian.
  ```
- **Git worktree awareness** — Note that the team may be working in a git worktree; respect the worktree boundary.

**Keep unchanged:**
- First Actions (reading mission brief, design doc, CLAUDE.md)
- Claiming Tasks
- Handling Guardian Feedback
- Non-Obvious Decisions
- Communicating Blockers
- Completing Tasks

The implementer skill becomes a ~60% smaller file focused purely on *team coordination behavior* (how to interact with lead, how to handle feedback, when to escalate) while delegating *coding methodology* to Superpowers.

#### team-lead/SKILL.md

**Remove:**
- Nothing major — the lead skill is already orchestration-focused and has minimal methodology overlap.

**Add:**
- **Design phase integration** section:
  ```
  ## Design Phase (Before Task Breakdown)

  If no design document exists yet, or if the mission brief references
  a high-level goal rather than a detailed spec, invoke the Superpowers
  design workflow before breaking down tasks:

  1. Use superpowers:brainstorming to explore the problem space with the
     user and produce a design document.
  2. Use superpowers:writing-plans to convert the approved design into
     a detailed implementation plan.

  Only proceed to task breakdown after a design document exists and has
  been approved.
  ```
- **Superpowers skill delegation** guidance in the Task Breakdown section:
  ```
  When writing task descriptions, include which Superpowers skills the
  assignee should use. For implementation tasks, always include:
  "Use superpowers:test-driven-development for this task."
  For debugging tasks: "Use superpowers:systematic-debugging."
  ```
- **Git worktree setup** — Lead should set up a worktree via `superpowers:using-git-worktrees` before spawning the team.

**Keep unchanged:**
- First Actions, Task Breakdown (structure), Delegation, Execution Phases, Monitoring, Guardian Feedback handling, Completion Report, Shutting Down

#### team-reviewer/SKILL.md

**Remove:**
- Nothing major — the reviewer skill is already review-focused.

**Add:**
- **Code review skill integration**:
  ```
  ## Review Methodology

  Use superpowers:requesting-code-review to structure your review process.
  When receiving feedback on your review findings from implementers, follow
  superpowers:receiving-code-review — verify claims before accepting them,
  push back with technical reasoning when warranted.
  ```

**Keep unchanged:**
- First Actions, What You Review (all 6 review dimensions), Creating Fix Tasks, Severity Assessment, Final Full-Branch Review, Writing the Deviations Section, What You Do Not Do

### 2.2 New Guardian Agent: verification-guardian

Inspired by Superpowers' `verification-before-completion` skill, but **blocking** instead of advisory. This is Guardian's unique value add — taking Superpowers' philosophy and enforcing it.

**File:** `agents/verification-guardian.md`

```markdown
---
name: verification-guardian
description: Blocks task completion when claims lack fresh verification evidence
tools: [Read, Grep, Glob, Bash]
blocking: true
---

# Verification Guardian

You validate that completed tasks have fresh evidence supporting their
completion claims. You enforce the principle: "Evidence before claims, always."

## What You Check

When a task is marked complete, examine:

1. **Test evidence.** Were tests actually run? Look for test output in
   the recent session. If the task claims "tests pass," there must be
   actual test output showing passage — not just "should pass" or
   "looks correct."

2. **Build evidence.** If the task involved code changes, was the code
   built or linted? Check for build/lint output.

3. **Requirement coverage.** Does the completed work address every item
   in the task description? Compare the task description against the
   actual file changes.

## Blocking Rules

Block (exit 2) if:
- Task claims tests pass but no test output exists in the working
  directory or recent git history
- Task description lists deliverables that don't exist in the
  file system
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

### 2.3 Hook Expansion

#### New: SessionStart Hook

**File:** `hooks/session-start.sh`

Fires on session start. Responsibilities:
- Check if `.guardian/guardians.json` exists (active Guardian project)
- If active, inject a context reminder about active guardians, mission brief summary, and Superpowers skill requirements
- Detect if Superpowers plugin is installed; warn if not

```bash
#!/bin/bash
set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
GUARDIAN_DIR="$PROJECT_DIR/.guardian"
CONFIG="$GUARDIAN_DIR/guardians.json"

# Only activate if guardian is configured for this project
if [ ! -f "$CONFIG" ]; then
  exit 0
fi

# Check if superpowers plugin is available
SUPERPOWERS_CHECK=""
if [ ! -d "${CLAUDE_PLUGIN_ROOT}/../superpowers" ] 2>/dev/null; then
  SUPERPOWERS_CHECK="WARNING: Superpowers plugin not detected. Guardian v2 requires superpowers@claude-plugins-official. Install it via: /plugin marketplace add superpowers"
fi

# Read active guardians
ACTIVE_GUARDIANS=$(jq -r 'to_entries[] | select(.value.enabled == true) | .key' "$CONFIG" 2>/dev/null | tr '\n' ', ' | sed 's/,$//')

# Read mission brief summary (first 5 lines after header)
MISSION_SUMMARY=""
if [ -f "$GUARDIAN_DIR/mission-brief.md" ]; then
  MISSION_SUMMARY=$(head -20 "$GUARDIAN_DIR/mission-brief.md")
fi

cat <<CONTEXT
{
  "hookSpecificOutput": {
    "additionalContext": "GUARDIAN ACTIVE SESSION\\n\\nActive guardians: ${ACTIVE_GUARDIANS}\\n\\n${SUPERPOWERS_CHECK}\\n\\nRequired Superpowers skills for this project:\\n- superpowers:test-driven-development (all implementation tasks)\\n- superpowers:systematic-debugging (debugging tasks)\\n- superpowers:verification-before-completion (before marking any task done)\\n\\nMission brief summary:\\n${MISSION_SUMMARY}"
  }
}
CONTEXT

exit 0
```

#### Updated: hooks.json

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

#### Updated: task-completed.sh

Add verification guardian to the hook script alongside the existing test and integration guardians. The verification guardian checks for evidence of test runs and deliverable completion.

### 2.4 Playbook Updates

All 6 playbooks get two additions. No structural changes to roles, team sizes, or guardian configurations.

#### Addition 1: Design Phase (feature-build, refactor, doc-sprint)

Add a new section before "Roles" in playbooks where a design document is expected:

```markdown
## Pre-Flight: Design Phase

Before spawning the team, ensure a design document exists:

1. If the user provides a design doc path, validate it exists and is detailed
   enough for task breakdown.
2. If no design doc exists, run the Superpowers design workflow:
   - Invoke superpowers:brainstorming to explore the problem and produce a spec
   - Invoke superpowers:writing-plans to convert the spec into an implementation plan
   - Save the plan as the design document referenced in the mission brief
3. Only proceed to team creation after the design is approved.
```

#### Addition 2: Git Worktree Setup (all playbooks)

Add to Phase 4 (Create the Agent Team) in `run-playbook.md`:

```markdown
### Step 0: Set Up Worktree

Before creating the team, set up an isolated workspace:

1. Invoke superpowers:using-git-worktrees to create a worktree for this playbook run.
2. Record the worktree path in the mission brief.
3. All team agents work in the worktree, not the main working tree.
4. At completion, use superpowers:finishing-a-development-branch to merge,
   create a PR, or discard.
```

#### Addition 3: Verification Guardian (all playbooks)

Add `verification` to the guardian list for every playbook:

| Playbook | Current Guardians | v2 Guardians |
|---|---|---|
| feature-build | spec, test, convention, integration, context | spec, test, convention, integration, context, **verification** |
| bug-hunt | test, integration | test, integration, **verification** |
| hardening | test, convention, integration | test, convention, integration, **verification** |
| refactor | test, convention, integration, context | test, convention, integration, context, **verification** |
| doc-sprint | spec, convention | spec, convention, **verification** |
| test-suite | test, convention, integration | test, convention, integration, **verification** |

### 2.5 Guardian Configuration Update

Update the `.guardian/guardians.json` schema to include the verification guardian:

```json
{
  "spec_guardian": { "enabled": true, "design_doc": "...", "agent": "..." },
  "test_guardian": { "enabled": true, "test_command": "...", "require_passing": true },
  "convention_guardian": { "enabled": true, "agent": "..." },
  "integration_guardian": { "enabled": true, "file_threshold": 3 },
  "context_guardian": { "enabled": true, "decisions_log": ".guardian/decisions-log.md" },
  "verification_guardian": { "enabled": true, "require_test_evidence": true, "require_deliverables_check": true }
}
```

### 2.6 Plugin Metadata Update

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

### 2.7 README Update

Rewrite the README to position Guardian as the orchestration + enforcement complement to Superpowers:

- **Tagline:** "Guardian orchestrates agent teams and enforces quality gates. Superpowers teaches them how to code."
- **Prerequisites section:** Lists `superpowers@claude-plugins-official` as required
- **How It Works:** Updated diagram showing Superpowers skills flowing into Guardian-managed agents
- **Guardians table:** Add verification guardian (6 guardians total)
- **Superpowers Integration section:** Explains which Superpowers skills are used where

---

## 3. What Does NOT Change

These Guardian components remain unchanged — they are unique to Guardian and have no Superpowers equivalent:

1. **All 5 existing guardian agents** (spec, test, convention, integration, context) — their markdown definitions stay as-is
2. **All 6 playbooks** (structure, roles, team sizes) — only additions noted above
3. **Commands** (init, run-playbook, list-playbooks) — minor updates for verification guardian
4. **Templates** (mission-brief, decisions-log, completion-report)
5. **The core hook mechanism** (TaskCompleted blocking pattern)
6. **Per-project `.guardian/` configuration** model

---

## 4. File Change Summary

| File | Action | Scope |
|---|---|---|
| `skills/team-implementer/SKILL.md` | **Edit** | Remove inline methodology (~30 lines), add Superpowers skills section (~15 lines) |
| `skills/team-lead/SKILL.md` | **Edit** | Add design phase section (~15 lines), add skill delegation guidance (~10 lines), add worktree setup (~5 lines) |
| `skills/team-reviewer/SKILL.md` | **Edit** | Add code review skill reference (~10 lines) |
| `agents/verification-guardian.md` | **Create** | New guardian agent (~50 lines) |
| `hooks/session-start.sh` | **Create** | New SessionStart hook (~40 lines) |
| `hooks/hooks.json` | **Create** | Hook registration for SessionStart + TaskCompleted |
| `hooks/task-completed.sh` | **Edit** | Add verification guardian check (~20 lines) |
| `playbooks/feature-build.md` | **Edit** | Add design phase + worktree + verification guardian (~15 lines) |
| `playbooks/bug-hunt.md` | **Edit** | Add worktree + verification guardian (~10 lines) |
| `playbooks/hardening.md` | **Edit** | Add worktree + verification guardian (~10 lines) |
| `playbooks/refactor.md` | **Edit** | Add design phase + worktree + verification guardian (~15 lines) |
| `playbooks/doc-sprint.md` | **Edit** | Add design phase + worktree + verification guardian (~15 lines) |
| `playbooks/test-suite.md` | **Edit** | Add worktree + verification guardian (~10 lines) |
| `commands/run-playbook.md` | **Edit** | Add worktree setup step, verification guardian config (~15 lines) |
| `commands/init.md` | **Edit** | Register both hooks (SessionStart + TaskCompleted) (~5 lines) |
| `.claude-plugin/plugin.json` | **Edit** | Version bump, add dependencies field |
| `README.md` | **Rewrite** | Reposition as Superpowers complement (~full rewrite) |

**Total: 4 new files, 13 edited files, 0 deleted files**

---

## 5. Superpowers Skills Mapping

Which Superpowers skills are consumed by which Guardian components:

| Superpowers Skill | Used By | When |
|---|---|---|
| `superpowers:test-driven-development` | team-implementer | All implementation tasks |
| `superpowers:systematic-debugging` | team-implementer | Debugging tasks, bug-hunt playbook |
| `superpowers:verification-before-completion` | team-implementer, verification-guardian | Before marking any task complete |
| `superpowers:brainstorming` | team-lead, run-playbook | When no design doc exists |
| `superpowers:writing-plans` | team-lead, run-playbook | Converting design to implementation plan |
| `superpowers:using-git-worktrees` | run-playbook | Playbook setup phase |
| `superpowers:finishing-a-development-branch` | run-playbook | Playbook completion phase |
| `superpowers:requesting-code-review` | team-reviewer | Structuring reviews |
| `superpowers:receiving-code-review` | team-reviewer, team-implementer | Handling review feedback |

**Not used by Guardian** (available to agents but not explicitly referenced):
- `superpowers:dispatching-parallel-agents` — Guardian handles its own parallelism via team structure
- `superpowers:subagent-driven-development` — Guardian has its own team orchestration
- `superpowers:writing-skills` — Meta-skill, not needed at runtime
- `superpowers:executing-plans` — Guardian's playbook system replaces this

---

## 6. Migration Path

For users upgrading from Guardian v1:

1. **Install Superpowers** — `superpowers@claude-plugins-official` must be enabled
2. **Re-run `/guardian:init`** — Registers the new SessionStart hook alongside TaskCompleted
3. **Existing `.guardian/` configs** — Remain compatible. The verification guardian defaults to disabled if not present in an existing `guardians.json`
4. **Existing playbooks** — Work unchanged. New features (design phase, worktree) are additive

No breaking changes to the user workflow. The primary behavioral change is that agents inside teams will now follow Superpowers methodology for coding, testing, and debugging instead of Guardian's lighter inline guidance.

---

## 7. Risk Mitigation

| Risk | Mitigation |
|---|---|
| Superpowers skill names change in a future version | Pin to a Superpowers version range in docs. Skill names have been stable across v4→v5. |
| Skill conflicts (Guardian instructions vs Superpowers instructions) | Clear hierarchy: Guardian role skills define *what to do* (orchestration), Superpowers skills define *how to do it* (methodology). No overlapping instructions. |
| Agents overloaded with too many instructions | Role skills become *shorter* (removing inline methodology), so net instruction volume decreases even with Superpowers skills loaded. |
| Superpowers plugin not installed | SessionStart hook warns explicitly. Run-playbook command checks and blocks if missing. |
| Verification guardian too strict (blocks legitimate completions) | Configurable: `require_test_evidence` and `require_deliverables_check` can be individually disabled per project. |

---

## 8. Success Criteria

Guardian v2 is successful when:

1. **Role skills are leaner** — team-implementer is ~40% shorter, with methodology delegated to Superpowers
2. **Verification is enforced** — The new verification guardian blocks unverified completion claims
3. **Design-first is the default** — Playbooks invoke Superpowers brainstorming/planning when no design doc exists
4. **Git isolation works** — Teams operate in worktrees, with clean branch finishing at completion
5. **No methodology duplication** — Guardian contains zero lines of TDD methodology, debugging methodology, or verification methodology. All delegated to Superpowers.
6. **Backward compatible** — Existing v1 `.guardian/` configs work without modification
