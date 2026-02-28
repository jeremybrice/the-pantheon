---
description: "Show available Guardian playbooks and their descriptions"
---

# List Playbooks

Display all available Guardian playbooks, their team compositions, and the guardians each one enables.

## Instructions

### 1. Scan Playbook Directory

Use Glob to find all `.md` files in the plugin's playbooks directory:

```
$CLAUDE_PLUGIN_ROOT/playbooks/*.md
```

If no playbook files are found, inform the user:

```
No playbooks found in the Guardian plugin.
Check that playbook files exist at guardian/playbooks/*.md
```

### 2. Extract Playbook Metadata

For each playbook file, read the YAML frontmatter and extract:

- **name** — the playbook identifier (also derivable from the filename without `.md`)
- **description** — one-line summary of what the playbook does
- **team_size** — total number of agents in the team
- **roles** — the role names that will be spawned
- **guardians** — which guardian agents are enabled for this playbook

### 3. Present Playbook Table

Display a formatted summary:

```
## Available Playbooks

| Playbook | Description | Team | Guardians |
|----------|-------------|------|-----------|
| feature-build | New feature from a design doc | 4 (Lead + 2 Impl + Reviewer) | spec, test, convention, integration, context |
| hardening | Quality sweep before merge | 4 (Lead + Security + Edge + Perf) | test, convention, integration |
| bug-hunt | Competing hypothesis debugging | 5 (Lead + 3 Invest + Fixer) | test, integration |
| ... | ... | ... | ... |
```

### 4. Show Usage

After the table, explain how to run a playbook:

```
To run a playbook:

  /guardian:run-playbook <name>

Example:
  /guardian:run-playbook feature-build

The run command will ask you for a design doc, key files, test command,
and any constraints. Then it spins up the team and they work autonomously.
```
