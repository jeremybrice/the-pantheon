# The Pantheon

A plugin marketplace for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

Claude Code plugins extend what Claude can do in your terminal — adding slash commands, subagents, skills, hooks, and full agent team workflows. The Pantheon is a shared marketplace where you can browse, install, and contribute plugins.

## Install

```sh
/plugin marketplace add jeremybrice/the-pantheon
```

---

## Plugins

### Guardian — Agent Teams That Build While You're Away

> `1.0.0-alpha` | [Full docs](guardian/)

Guardian turns Claude Code into a managed team of agents. You spend 15 minutes loading context — point it at a design doc, tell it how to run your tests, flag any gotchas — then walk away. A team of specialized agents builds, reviews, and validates the work autonomously, and you come back to a finished feature on a clean branch.

**How it works:**

1. A **team lead** reads your design doc, breaks it into tasks, and delegates to implementers
2. **Implementers** build in parallel — writing code and tests, one task at a time
3. A **reviewer** watches for spec drift, edge cases, and naming issues — creating fix tasks, never writing code themselves
4. **Guardian agents** fire automatically on every task completion — running your test suite, checking convention compliance, validating against the spec, and catching cross-module regressions
5. If a guardian fails, the task is **blocked with feedback** and the implementer iterates until it passes

No task is marked done until every active guardian signs off. The result is a completion report summarizing what was built, any deviations from the design, and follow-up items.

**Six playbooks for different jobs:**

| Playbook          | Team                                          | What it does                                                              |
|-------------------|-----------------------------------------------|---------------------------------------------------------------------------|
| **feature-build** | Lead + 2 Implementers + Reviewer              | End-to-end feature from a design doc, with parallel implementation        |
| **bug-hunt**      | Lead + 3 Investigators + Fixer                | Three competing hypotheses debugged in parallel — no tunnel vision        |
| **hardening**     | Lead + Security + Edge Cases + Perf           | Quality sweep: find vulnerabilities, unhandled edge cases, and bottlenecks |
| **refactor**      | Lead + 2 Module Owners + Integration Tester   | Cross-module restructuring without breaking behavior                      |
| **doc-sprint**    | Lead + Writer + Code Reader + Accuracy Checker | Documentation push with accuracy validation against the actual code       |
| **test-suite**    | Lead + 2 Test Writers + Coverage Analyst      | Backfill tests for existing code with coverage analysis                   |

**Five guardian agents validate every task:**

| Guardian        | What it catches                                                                 |
|-----------------|---------------------------------------------------------------------------------|
| **Spec**        | Implementation drifting from the design doc                                     |
| **Test**        | Missing tests, failing tests, insufficient coverage                             |
| **Convention**  | Naming, formatting, and structural patterns that violate project conventions     |
| **Integration** | Cross-module regressions when 3+ files change                                   |
| **Context**     | Captures design decisions to a log so rationale survives the session             |

**Quick start:**

```sh
/plugin install guardian
/guardian:init                          # Register hooks in your project
/guardian:run-playbook feature-build    # Launch a team
```

Works in any repo — Python, JavaScript, Rust, whatever. You configure your test command and Guardian handles the rest.

---

## Contributing a Plugin

Plugins live as top-level directories. Each one must be self-contained (Claude Code copies plugins to a local cache on install).

```text
my-plugin/
├── .claude-plugin/
│   └── plugin.json       # name, version, description, author (required)
├── README.md             # Purpose, installation, and usage (required)
├── commands/             # Slash commands
├── agents/               # Subagent definitions
├── skills/               # SKILL.md-based skills
├── hooks/                # Shell scripts on lifecycle events
├── playbooks/            # Multi-agent workflows
└── scripts/              # Utility scripts
```

To submit: branch off `main` as `plugin/my-plugin`, add your directory and an entry in `.claude-plugin/marketplace.json`, and open a PR.

## License

[MIT](LICENSE)
