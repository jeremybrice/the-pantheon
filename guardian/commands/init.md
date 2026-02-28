---
description: "One-time setup to register Guardian hooks in the current project"
---

# Guardian Init

Register the Guardian `TaskCompleted` hook in the current project so that guardian agents validate work as teammates complete tasks.

## Instructions

### 1. Read Existing Settings

Read the project's `.claude/settings.json` file.

- If `.claude/` directory does not exist, create it.
- If `.claude/settings.json` does not exist, start with an empty JSON object `{}`.
- If the file exists, parse its current contents and preserve all existing keys.

### 2. Check for Existing Hook

Inspect the parsed settings for an existing `hooks.TaskCompleted` entry.

If the `TaskCompleted` hook already exists and contains a command referencing `task-completed.sh`, inform the user and stop:

```
Guardian hooks are already registered in this project.

  Hook: TaskCompleted -> task-completed.sh
  Config: .guardian/guardians.json (created when you run a playbook)

You're ready to go. Run /guardian:list-playbooks to see available playbooks.
```

Do not modify the file. Do not proceed to subsequent steps.

### 3. Merge Hook into Settings

Add the `TaskCompleted` hook entry to the settings. MERGE with any existing hooks — do not overwrite other hook types that may already be configured.

The hook entry to add:

```json
{
  "hooks": {
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

Write the merged settings back to `.claude/settings.json`.

### 4. Create Guardian Working Directory

Create the `.guardian/` directory in the project root if it does not already exist. This directory will hold the per-run configuration files (`guardians.json`, `mission-brief.md`, `decisions-log.md`) when a playbook is executed.

### 5. Confirm to User

```
Guardian initialized.

  Hook registered: TaskCompleted -> task-completed.sh
  Working directory: .guardian/

When a teammate marks a task complete, the hook will run all enabled
guardians defined in .guardian/guardians.json. Failed guardians block the
task and send feedback to the teammate.

Next steps:
  /guardian:list-playbooks  — see available playbooks
  /guardian:run-playbook    — spin up a team for a development task
```
