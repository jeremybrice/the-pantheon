---
name: refactor
description: Cross-module restructuring with module ownership
team_size: 4
roles: [lead, module-owner, module-owner, integration-tester]
guardians: [test, convention, integration, context]
autonomy: full
---

# Refactor Playbook

## Overview

Use this playbook when restructuring code across multiple modules without changing external
behavior. Each module owner is responsible for specific modules or directories, and a dedicated
integration tester continuously verifies that the refactored code maintains the same behavior.
The context guardian is especially important here to capture the reasoning behind structural
decisions.

This playbook is appropriate when:
- Code needs restructuring to improve maintainability, readability, or extensibility
- Multiple modules or directories are affected by the change
- The external behavior must remain identical (no feature changes)
- The refactoring requires coordination to avoid broken intermediate states

This playbook is NOT appropriate when:
- You are adding new behavior or features (use feature-build)
- You are fixing a specific bug (use bug-hunt)
- The change is limited to a single file or function (just do it directly)

## Roles

### Lead

The lead plans the refactoring strategy and coordinates execution order.

1. **Define the target architecture.** Describe what the code should look like after refactoring. Include module boundaries, dependency direction, and naming conventions.
2. **Inventory what must change.** List every file, module, and interface that will be affected. Miss nothing -- surprises during refactoring cause broken intermediate states.
3. **Plan the refactoring order.** This is the lead's most critical job. Changes must be ordered so that the codebase compiles and tests pass after each individual task. Avoid steps that break multiple things at once.
4. **Assign module ownership.** Each module owner gets specific directories or modules. Ownership boundaries must be clear -- two people editing the same file causes conflicts.
5. **Manage interface changes.** When a refactoring changes an interface between modules, coordinate the producer and consumer sides. The producer changes the interface, and the consumer adapts. Never leave the interface in an inconsistent state.
6. **Record rationale via context guardian.** Every structural decision should have a recorded reason. "Why did we split this module?" and "Why did we move this function here?" are questions future developers will ask.
7. **Produce the refactoring summary.** Document what changed, why, and any follow-up work remaining.

### Module Owner (x2)

Each module owner is responsible for refactoring specific modules or directories.

1. **Understand your module boundaries.** Know exactly which files and directories you own. Do NOT modify files outside your ownership without coordinating with the other module owner or the lead.
2. **Refactor one task at a time.** Each task should be a self-contained change that leaves the codebase in a working state. Do not batch multiple structural changes into one task.
3. **Maintain all existing tests.** Refactoring must not change behavior. If a test breaks, you have changed behavior, not just structure. Fix the refactoring, not the test. The only exception is when a test was testing internal structure rather than behavior -- in that case, update the test and note why.
4. **Update imports, references, and documentation.** When you move or rename something, update every reference. Partial updates create broken intermediate states.
5. **Communicate interface changes.** If your refactoring changes a public interface (function signature, module export, API contract), notify the lead and the other module owner immediately, before making the change.
6. **Write migration notes.** For each task, briefly document what moved where and why. These notes help the integration tester understand what to verify and help future developers understand the history.

### Integration Tester

The integration tester does NOT refactor code. Their job is to verify that behavior is preserved.

1. **Run the full test suite after every task.** This is the primary responsibility. After each module owner completes a task, the integration tester runs all tests and reports the results.
2. **Check cross-module compatibility.** When module A's interface changes, verify that module B still uses it correctly. Look for subtle breakages that tests might miss: changed return types, different error handling, altered side effects.
3. **Verify no behavior changes.** Compare the before and after behavior for key scenarios. Refactoring should produce identical outputs for identical inputs. If behavior changed, report it as a bug in the refactoring.
4. **Track test suite health over time.** If the test count decreases during refactoring, investigate. Tests should not be deleted during refactoring; they should be moved or updated.
5. **Report flaky or slow tests.** Refactoring sometimes exposes test flakiness or creates performance regressions in tests. Report these to the lead for triage.

## Task Creation Guidance

The lead creates tasks following these principles:

- **One structural change per task.** A task should do ONE thing: rename a module, move a function, split a file, update an interface. Combining multiple changes makes failures hard to diagnose.
- **Order tasks to preserve a working codebase.** After every task, the full test suite should pass. Plan the order carefully:
  - Create new structure before removing old structure
  - Add new interface before removing old interface (use deprecation wrappers if needed)
  - Move consumers before removing the producer's old location
- **Mark dependency chains explicitly.** If task 4 depends on task 2, annotate this clearly so module owners do not execute out of order.
- **Include "verify" checkpoints.** After major milestones (e.g., completing all moves in a module), create a task specifically for the integration tester to do a thorough verification.
- **Estimate scope per task.** Each task should touch no more than 5-10 files. Larger changes should be split further.

## Guardian Configuration

Four guardians are active for refactoring:

- **test** -- Every refactoring step must pass existing tests. If a test breaks, the refactoring introduced a behavior change. New tests are welcome but not required unless new internal structure needs coverage.
- **convention** -- Refactored code must follow established conventions. Refactoring is an opportunity to improve consistency, not introduce new inconsistencies.
- **integration** -- The full test suite runs after every task. This is the primary safety net for refactoring. A red integration run means stop and fix before continuing.
- **context** -- Records why refactoring decisions were made. This is especially important for refactoring because the "what" is visible in the code diff but the "why" is not. Capture the reasoning.

The spec guardian is not active because refactoring does not reference a design doc.

## Completion Criteria

The refactoring is complete when:

1. **All tasks are complete** and the target architecture matches the plan.
2. **The full test suite passes** with no test removals that are not explicitly justified.
3. **No behavior changes were introduced.** The integration tester confirms that all external behavior is preserved.
4. **Convention guardian passes.** The refactored code follows all established conventions.
5. **Context is recorded.** Every major structural decision has a recorded rationale.
6. **The refactoring summary is written** by the lead, containing:
   - Before and after architecture description
   - List of modules affected and what changed
   - Rationale for key decisions
   - Follow-up items or further refactoring opportunities
   - Confirmation that behavior is preserved
