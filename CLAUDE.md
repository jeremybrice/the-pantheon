# the-pantheon

A Claude Code plugin marketplace. Users install plugins from other repos via:

```
/plugin marketplace add jeremybrice/the-pantheon
```

Plugins live as top-level directories (e.g., `guardian/`, not `plugins/guardian/`).

## Rules

- Every plugin directory must contain `.claude-plugin/plugin.json` with `name`, `version`, `description`, and `author`
- Every plugin must be fully self-contained — no references to files outside its own directory (Claude Code copies plugins to a cache on install)
- Every plugin must have a `README.md` documenting purpose, installation, and usage
- When adding a new plugin, its entry must be added to `.claude-plugin/marketplace.json`
- Version bumps: update both the plugin's `plugin.json` and the marketplace entry (`plugin.json` takes priority)
- Plugins at `1.0.0-alpha` or higher — use semver (MAJOR.MINOR.PATCH)
- Hook scripts must be executable (`chmod +x`) and use `${CLAUDE_PLUGIN_ROOT}` for paths
- No shared dependencies between plugins — each plugin stands alone

## Plugin Directory Structure

```
<plugin-name>/
├── .claude-plugin/
│   └── plugin.json
├── README.md
├── commands/          (slash commands)
├── agents/            (subagent definitions)
├── skills/            (SKILL.md-based skills)
├── hooks/             (hooks.json or shell scripts)
├── templates/         (optional, plugin-specific templates)
├── playbooks/         (optional, for agent team plugins)
└── scripts/           (optional, utility scripts)
```

## Git Conventions

### Branches

- `main` is the stable marketplace — users point at this
- Feature branches for new plugins or significant changes: `plugin/<name>` or `feature/<description>`

### Tags

- Marketplace-level releases: `v1.0.0`, `v1.1.0`, etc.
- Individual plugin releases: `<plugin>-v<version>` (e.g., `guardian-v1.0.0-alpha`)
- Users can pin to a ref/tag in their marketplace config for stability

### Commit Messages

- Plugin-scoped commits: `<plugin-name>: <description>` (e.g., `guardian: fix test guardian exit code`)
- Marketplace-level commits: `marketplace: <description>` (e.g., `marketplace: add sentinel plugin`)
