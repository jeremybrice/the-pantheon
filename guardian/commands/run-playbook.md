---
description: "Run a Guardian playbook to spin up an agent team for a development task"
arguments:
  - name: playbook
    description: "Name of the playbook to run (e.g., feature-build, hardening, bug-hunt)"
    required: true
---

# Run Playbook

Main entry point for Guardian. Loads a playbook, gathers context, configures guardians, and spawns an autonomous agent team.

## Phase 1: Load Playbook

Read `$CLAUDE_PLUGIN_ROOT/playbooks/{playbook}.md`. If the file does not exist, scan `$CLAUDE_PLUGIN_ROOT/playbooks/*.md`, list available playbooks with their descriptions, and ask the user to choose.

Parse the playbook frontmatter for: **name**, **description**, **team_size**, **roles** (name, skill, count), and **guardians** (list of guardian names to enable). Read the body for role descriptions and task breakdown guidance.

## Phase 2: Gather Context

Ask ONE question at a time. Wait for a response before proceeding to the next.

**Q1 — Design document path.** Validate the file exists by reading it. Summarize key requirements in 3-5 bullets and confirm with the user.

**Q2 — Key files and their roles.** Example: `src/api/routes.py — existing API routes to extend`

**Q3 — Test command.** Example: `pytest`, `npm test`, `cargo test`

**Q4 — Callouts and constraints.** Gotchas, things not to touch, version restrictions. Accept "none."

## Phase 3: Configure Guardians

### Write `.guardian/guardians.json`

Build the config from the playbook's guardian list. Only include guardians the playbook enables:

```json
{
  "spec_guardian": { "enabled": true, "design_doc": "{path}", "agent": "$CLAUDE_PLUGIN_ROOT/agents/spec-guardian.md" },
  "test_guardian": { "enabled": true, "test_command": "{cmd}", "require_passing": true },
  "convention_guardian": { "enabled": true, "agent": "$CLAUDE_PLUGIN_ROOT/agents/convention-guardian.md" },
  "integration_guardian": { "enabled": true, "file_threshold": 3, "test_command": "{cmd}" },
  "context_guardian": { "enabled": true, "decisions_log": ".guardian/decisions-log.md", "blocking": false }
}
```

### Write `.guardian/mission-brief.md`

Read the template from `$CLAUDE_PLUGIN_ROOT/templates/mission-brief.md`. Populate with: playbook name, design doc path, requirements summary, key files, test command, developer callouts, and success criteria extracted from the design doc.

### Write `.guardian/decisions-log.md`

Read the template from `$CLAUDE_PLUGIN_ROOT/templates/decisions-log.md`. Populate the header (mission title, date).

### Confirm with user

```
Guardian configured for {playbook_name}.
  Mission brief:  .guardian/mission-brief.md
  Guardians:      {comma-separated list}
  Test command:   {test_command}
  Team size:      {N} agents

Ready to spin up the team. Proceed? (yes/no)
```

If `.claude/settings.json` does not contain the TaskCompleted hook, warn:
```
Warning: Guardian TaskCompleted hook is not registered. Run /guardian:init first,
or proceed without guardian validation. Continue? (yes/no)
```

## Phase 4: Create the Agent Team

### Step 1: Create Team

Use `TeamCreate` with team_name `guardian-{playbook_name}` (e.g., `guardian-feature-build`).

### Step 2: Create Tasks

Break the design doc into concrete tasks using `TaskCreate`. Guidelines:
- 5-6 tasks per implementer, each producing a single verifiable deliverable
- Front-load foundational tasks (shared types, utilities, config)
- Use `addBlockedBy` for dependencies
- Reserve 2-3 review tasks blocked by the implementation tasks they review
- Final task: "Write completion report" assigned to lead, blocked by all review tasks
- Each task needs a clear **subject** (imperative), detailed **description** (what, where, how to verify, context, constraints), and **activeForm** (present continuous)

### Step 3: Spawn Teammates

Use the `Task` tool for each role in the playbook. Spawn ALL teammates in parallel with a single message. For each:

- **subagent_type**: `general-purpose`
- **team_name**: `guardian-{playbook_name}`
- **name**: Role name from playbook (e.g., `implementer-1`, `reviewer`)
- **prompt**:
  ```
  You are {role_name} on the guardian-{playbook} team.

  Read your role skill for detailed guidance:
  Read file: $CLAUDE_PLUGIN_ROOT/skills/{skill_name}/SKILL.md

  Read the mission brief to understand the full objective:
  Read file: .guardian/mission-brief.md

  Check the task list for tasks assigned to you and begin working.
  When you complete a task, mark it as completed. The TaskCompleted
  hook will run guardian validations automatically. If a guardian
  blocks your task, read the feedback and iterate until it passes.
  ```

### Step 4: Assign Initial Tasks

Use `TaskUpdate` to assign the first batch of unblocked tasks to implementers. Leave blocked tasks unassigned. Notify each teammate of their assignments via `SendMessage`.

## Phase 5: Monitor and Complete

### Ongoing

- Check the task list periodically for completed, in-progress, and blocked tasks.
- Reassign tasks as teammates finish — pull the next unblocked task and assign it.
- Unblock review tasks when their implementation dependencies are complete.
- Respond promptly to teammate messages and blockers.
- If a teammate is idle too long, send a status check; reassign if unresponsive.

### Completion Sequence

When all implementation and review tasks are complete:

1. **Final test run.** Execute the test command from the mission brief. If tests fail, create a fix task, assign it, and wait for it to pass before continuing.

2. **Final branch review.** Create a task for the reviewer to inspect all changes. This is the last quality gate.

3. **Write completion report.** Read `$CLAUDE_PLUGIN_ROOT/templates/completion-report.md`. Populate with: playbook name, design doc path, summary, requirements mapping, guardian results (issues caught/resolved per guardian), deviations from spec, final test output, and key decisions from `.guardian/decisions-log.md`. Write to `.guardian/completion-report.md`.

4. **Shut down team.** Send `shutdown_request` to each teammate via `SendMessage`. Wait for confirmations.

5. **Report to user:**
   ```
   Guardian playbook complete: {playbook_name}
     Tasks completed:   {count}
     Guardian issues:   {caught} caught, {resolved} resolved
     Test suite:        PASS
     Completion report: .guardian/completion-report.md
   ```
