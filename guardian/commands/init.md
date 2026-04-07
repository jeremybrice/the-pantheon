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

If the `TaskCompleted` hook already exists and contains a command referencing `task-completed.sh`, and the `SessionStart` hook already exists and references `session-start.sh`, inform the user and stop:

```
Guardian hooks are already registered in this project.

  Hooks:
    SessionStart  -> session-start.sh (context injection)
    TaskCompleted -> task-completed.sh (guardian validation)
  Config: .guardian/guardians.json (created when you run a playbook)

You're ready to go. Run /guardian:list-playbooks to see available playbooks.
```

Do not modify the file. Do not proceed to subsequent steps.

### 3. Merge Hook into Settings

Add the `TaskCompleted` hook entry to the settings. MERGE with any existing hooks — do not overwrite other hook types that may already be configured.

The hook entries to add:

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

Write the merged settings back to `.claude/settings.json`.

### 4. Create Guardian Working Directory

Create the `.guardian/` directory in the project root if it does not already exist. This directory will hold the per-run configuration files (`guardians.json`, `mission-brief.md`, `decisions-log.md`) when a playbook is executed.

### 5. Confirm to User

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
