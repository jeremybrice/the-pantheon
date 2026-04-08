# Superpowers vs Guardian: Deep Comparative Analysis

> **Date:** 2026-04-06
> **Author:** Analysis generated for the-pantheon project
> **Guardian Version:** 1.0.0-alpha
> **Superpowers Version:** 5.0.7
> **Superpowers Repo:** [obra/superpowers](https://github.com/obra/superpowers)

---

## Executive Summary

Guardian and Superpowers solve **different layers** of the same problem. Guardian is a **team orchestration + enforcement** system that spawns multi-agent teams and blocks invalid work via hook-based validation gates. Superpowers is an **individual agent methodology + guidance** library that teaches agents *how to think and code* through 14 composable skills (TDD, debugging, verification, planning).

**They are ~70% complementary and only ~30% overlapping.** The primary recommendation is to **use both together**, keeping Guardian focused on orchestration/enforcement and delegating coding methodology to Superpowers.

---

## 1. Architecture Comparison

| Dimension | Guardian (v1.0.0-alpha) | Superpowers (v5.0.7) |
|---|---|---|
| **Core Paradigm** | Team orchestration + validation gates | Individual agent skill library |
| **Primary Mechanism** | Hook-based enforcement (TaskCompleted) | Skill injection (SessionStart) |
| **Agent Model** | Multi-agent teams (4-5 agents per workflow) | Single agent with composable skills |
| **Validation** | 5 blocking guardian agents | Verification-before-completion skill (advisory) |
| **Workflow** | Playbook-driven (6 playbooks) | Skill-chained (14 skills) |
| **Configuration** | Per-project `.guardian/` dir | Plugin-level, no per-project config |
| **Dependencies** | bash + jq | Zero (pure markdown + JS entry point) |
| **Platform Support** | Claude Code only | Claude Code, Cursor, Codex, OpenCode, Copilot CLI, Gemini CLI |
| **Maturity** | Alpha | Mature, active community, 94% PR rejection rate |
| **Test Infrastructure** | None for itself | 6 test directories |
| **License** | Not specified | MIT |

---

## 2. Feature-by-Feature Comparison

### 2.1 Team Orchestration

| Aspect | Guardian | Superpowers | Confidence |
|---|---|---|---|
| Multi-agent team spawning | Full support (lead, implementers, reviewer) | Subagent dispatch only (no team structure) | **95/100** |
| Role specialization | 3 defined roles with detailed skills | 1 code-reviewer agent | **95/100** |
| Playbook workflows | 6 playbooks for different work types | No playbook concept | **95/100** |
| Task delegation & tracking | Lead breaks down and delegates tasks | TodoWrite-based tracking within plans | **85/100** |

**Winner: Guardian** — This is Guardian's core strength and Superpowers' gap.

### 2.2 Validation & Quality Gates

| Aspect | Guardian | Superpowers | Confidence |
|---|---|---|---|
| Blocking validation | Hook-based, blocks task completion | Advisory only (skill guidance) | **95/100** |
| Spec compliance checking | Dedicated spec-guardian agent | Plan alignment in code-reviewer | **90/100** |
| Test validation | test-guardian + integration-guardian | verification-before-completion skill | **85/100** |
| Convention enforcement | convention-guardian reads CLAUDE.md | No equivalent | **90/100** |
| Context preservation | context-guardian + decisions log | No equivalent | **90/100** |

**Winner: Guardian** — Guardian *enforces*; Superpowers *guides*.

### 2.3 Development Methodology

| Aspect | Guardian | Superpowers | Confidence |
|---|---|---|---|
| TDD enforcement | Mentioned but not deeply specified | Detailed red-green-refactor cycle, "iron law" | **90/100** |
| Debugging methodology | No specific debugging workflow | Systematic 4-phase debugging process | **90/100** |
| Plan writing | Mission brief template | Full writing-plans skill with detailed structure | **85/100** |
| Plan execution | Playbook-driven | executing-plans + subagent-driven-development | **85/100** |
| Brainstorming/Design | No design phase workflow | Full 9-step brainstorming process with design gate | **90/100** |
| Git workflow | No git guidance | using-git-worktrees + finishing-a-development-branch | **90/100** |

**Winner: Superpowers** — Much deeper methodology for how agents should *think and work*.

### 2.4 Code Review

| Aspect | Guardian | Superpowers | Confidence |
|---|---|---|---|
| Review process | Reviewer role skill (team member) | Dedicated requesting + receiving code review skills | **80/100** |
| Review agent | No dedicated agent | code-reviewer.md agent with 5-area review | **85/100** |
| Feedback handling | Guardian feedback loop (block + iterate) | receiving-code-review skill (verify before implementing) | **80/100** |

**Winner: Superpowers** — More structured review methodology, though Guardian's blocking mechanism is more enforceable.

### 2.5 Platform & Ecosystem

| Aspect | Guardian | Superpowers | Confidence |
|---|---|---|---|
| Platform support | Claude Code only | 6 platforms | **95/100** |
| Community | Single author | Active (Discord, mailing list, contributors) | **95/100** |
| Maturity | Alpha | v5.0.7, battle-tested | **95/100** |
| Documentation | Good README + detailed agent/skill markdown | Comprehensive README + CLAUDE.md + skill docs | **85/100** |
| Extensibility | Configurable guardians, customizable playbooks | Composable skills, writing-skills meta-skill | **80/100** |

**Winner: Superpowers** — Significantly more mature, broader ecosystem.

---

## 3. Pros and Cons

### Guardian

| Pros | Cons |
|---|---|
| **Enforcement, not just guidance** — hook-based blocking means bad work cannot complete | **Early alpha** — v1.0.0-alpha, not battle-tested |
| **Team orchestration** — multi-agent teams with specialized roles (unique capability) | **No self-tests** — no test infrastructure for Guardian itself |
| **Playbook variety** — 6 workflow types for different task categories | **Single platform** — Claude Code only |
| **Context preservation** — decisions log maintains reasoning across context windows | **Thin methodology** — doesn't deeply guide *how* agents should code |
| **Spec traceability** — maps requirements to implementations | **Single hook point** — only fires on TaskCompleted |
| **Convention enforcement** — automatically checks CLAUDE.md conventions | **Single maintainer** — bus factor of 1 |
| **Self-contained** — only needs bash + jq | **No design phase** — jumps straight to implementation |
| **Customizable** — per-project guardian configuration | **No git workflow** — no worktree or branch management |

### Superpowers

| Pros | Cons |
|---|---|
| **Deep methodology** — 14 skills covering full dev lifecycle | **No team orchestration** — single-agent focus |
| **Battle-tested** — v5.0.7, active community, high quality bar | **Advisory only** — skills guide but don't enforce |
| **TDD enforcement** — detailed red-green-refactor with "iron law" | **No blocking gates** — no hook-based validation |
| **Multi-platform** — 6 AI coding platforms | **No convention enforcement** — doesn't check project conventions |
| **Composable skills** — chain together naturally | **No context preservation** — no decisions log |
| **Design-first** — brainstorming skill enforces design before code | **No playbook concept** — no predefined team workflows |
| **Zero dependencies** — pure markdown + minimal JS | **Tightly maintained** — 94% PR rejection rate |
| **Active community** — Discord, contributors, mailing list | **No spec traceability** — doesn't map requirements to implementations |
| **Verification culture** — "evidence before claims, always" | |
| **Self-improving** — writing-skills meta-skill for extending the system | |
| **MIT licensed** — can freely learn from and incorporate ideas | |

---

## 4. Overlap Analysis

### Shared Territory (~30% overlap)
- Code review (both have review mechanisms)
- Plan writing and execution
- Test verification before completion
- Subagent dispatch for task execution

### Unique to Guardian (~35%)
- Multi-agent team orchestration (lead, implementers, reviewer)
- Blocking validation gates (hook-based enforcement)
- 5 specialized guardian agents
- 6 playbook workflows
- Convention enforcement
- Context/decisions preservation
- Spec-to-implementation traceability
- Per-project configuration

### Unique to Superpowers (~35%)
- TDD methodology (red-green-refactor)
- Systematic debugging
- Brainstorming/design-first workflow
- Git worktree management
- Branch finishing workflow
- Receiving/responding to code review
- Parallel agent dispatch
- Multi-platform support
- Skill composability and meta-skill creation
- SessionStart bootstrap
- Verification-before-completion culture

---

## 5. Complementarity Analysis

These systems are **highly complementary** because they operate at different levels:

| Layer | Guardian | Superpowers |
|---|---|---|
| **Strategic** (what to do) | Playbooks define the workflow type | Brainstorming defines the approach |
| **Tactical** (how to organize) | Team orchestration with roles | Plan writing and execution |
| **Operational** (how to code) | *Gap — no coding methodology* | TDD, debugging, verification skills |
| **Enforcement** (quality gates) | Blocking guardian agents | *Gap — advisory only* |

**The ideal stack:**
- Superpowers skills teach agents *how to think and code*
- Guardian orchestrates *teams of superpowers-enhanced agents*
- Guardian's blocking gates *enforce* what Superpowers only *advises*

---

## 6. Maintenance Burden Assessment

| Strategy | Effort | Risk | Benefit |
|---|---|---|---|
| **Keep Guardian Only** | Medium-high. Must mature from alpha, add tests, expand methodology | Reinventing what Superpowers already solved | Full control, tailored to needs |
| **Switch to Superpowers Only** | Low initial | Losing team orchestration + enforcement entirely | Zero maintenance, community-driven |
| **Use Both Together** | Medium. Maintain Guardian for orchestration, delegate methodology | Potential skill conflicts, configuration complexity | Best of both worlds |
| **Enhance Guardian with Superpowers Ideas** | Medium-high. Port ideas into Guardian framework | Ongoing maintenance, falling behind Superpowers updates | Single system, fully customized |

---

## 7. Strategic Recommendation

### Primary Recommendation: Use Both Together
**Confidence: 85/100**

The systems are complementary, not competitive. The recommended approach:

1. **Keep Superpowers as a dependency** — already enabled in your settings.json. Use it for individual agent methodology (TDD, debugging, verification, git workflows).

2. **Keep Guardian focused on its unique strengths** — team orchestration, playbooks, blocking validation gates, convention enforcement, context preservation.

3. **Remove methodology overlap from Guardian** — don't try to compete with Superpowers on TDD, debugging, or planning methodology. Let Superpowers handle that.

4. **Enhance Guardian with Superpowers integration points:**
   - Playbooks should reference Superpowers skills (e.g., "implementer agents should use superpowers:test-driven-development")
   - Team-implementer skill should delegate to Superpowers skills for coding methodology
   - Add a brainstorming/design phase before playbook execution using superpowers:brainstorming

5. **Add missing Guardian capabilities inspired by Superpowers:**
   - SessionStart hook (Superpowers has this, Guardian doesn't)
   - Git worktree integration for agent isolation
   - Verification-before-completion enforcement (make it a blocking gate, not just advisory)

### Alternative: Switch to Superpowers Only
**Confidence: 40/100** — Only if team orchestration isn't needed, single-agent workflows suffice, or Guardian maintenance becomes unsustainable. You'd lose Guardian's unique enforcement and team capabilities.

### Alternative: Keep Guardian, Drop Superpowers
**Confidence: 30/100** — Only if multi-platform support isn't needed and you want complete control over all methodology. You'd be reinventing problems Superpowers has already solved through 5 major versions.

---

## 8. Risk Analysis

| Risk | Impact | Likelihood | Mitigation |
|---|---|---|---|
| Superpowers skills conflict with Guardian skills | Medium | Medium | Clear delineation: Guardian = orchestration, Superpowers = methodology |
| Superpowers breaking changes (v5 to v6) | Low | Medium | Pin to version tag, test before upgrading |
| Guardian maintenance becomes unsustainable | High | Medium | Slim Guardian to orchestration-only, offload methodology to Superpowers |
| Skills confusion for agents (too many instructions) | Medium | Low | Clear hierarchy: user instructions > Guardian playbook > Superpowers skills |
| Superpowers project abandoned | Medium | Low | MIT licensed, can fork; community is active |
| Guardian never matures past alpha | High | Medium | "Use both" strategy reduces risk by shrinking Guardian's scope |

---

## 9. Actionable Next Steps

If the "use both together" recommendation is approved:

1. **Phase 1 — Integration Planning**
   - Audit Guardian skills for overlap with Superpowers
   - Define clear boundaries: Guardian owns orchestration, Superpowers owns methodology
   - Document the integration architecture

2. **Phase 2 — Guardian Slimming**
   - Remove thin methodology guidance from Guardian that Superpowers handles better
   - Add references to Superpowers skills in Guardian's implementer and reviewer role skills
   - Add design/brainstorming phase to playbooks via Superpowers integration

3. **Phase 3 — Guardian Enhancement**
   - Add SessionStart hook to Guardian
   - Add git worktree integration
   - Make verification-before-completion a blocking guardian gate
   - Add test infrastructure for Guardian itself

4. **Phase 4 — Validation**
   - Run real workflows with both plugins active
   - Measure quality improvements
   - Iterate on integration points
