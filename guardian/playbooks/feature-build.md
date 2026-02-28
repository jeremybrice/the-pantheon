---
name: feature-build
description: End-to-end feature implementation from a design doc
team_size: 4
roles: [lead, implementer, implementer, reviewer]
guardians: [spec, test, convention, integration, context]
autonomy: full
---

# Feature Build Playbook

## Overview

Use this playbook when implementing a new feature from a design document or specification.
The team works in parallel with two implementers building code while a dedicated reviewer
ensures quality without writing feature code themselves. All five guardians are active to
catch issues early and continuously.

This playbook is appropriate when:
- A design doc, RFC, or specification exists and has been approved
- The feature touches multiple files or modules
- The work can be parallelized across two implementers
- You want continuous review pressure throughout implementation, not just at the end

This playbook is NOT appropriate when:
- You are debugging an existing issue (use bug-hunt)
- You are restructuring code without changing behavior (use refactor)
- The work is a single-file change that one person can complete in minutes

## Roles

### Lead

The lead does NOT write feature code. The lead's responsibilities are:

1. **Read the design doc thoroughly.** Identify every deliverable, constraint, and acceptance criterion.
2. **Break the work into tasks.** Create 5-6 tasks per implementer (10-12 total). Each task must produce a testable deliverable. See Task Creation Guidance below.
3. **Assign tasks respecting dependencies.** If task B depends on task A's output, assign them to the same implementer or ensure ordering. Maximize parallel work across the two implementers.
4. **Monitor guardian feedback.** When a guardian flags an issue, decide whether the implementer should fix it immediately or whether it becomes a new task.
5. **Coordinate between implementers.** When one implementer's work affects the other's, communicate the change and its impact.
6. **Produce the completion report.** After all tasks pass, write a summary covering what was built, any deviations from the design doc, and remaining follow-up items.

### Implementer (x2)

Each implementer receives a mission brief from the lead containing their assigned tasks, relevant context, and dependencies. Implementer responsibilities:

1. **Read the mission brief completely before starting.** Understand not just your tasks but how they fit into the overall feature.
2. **Implement one task at a time.** Do not start the next task until the current one passes all active guardians.
3. **Write tests alongside code.** Every task that produces code must also produce tests. Do not defer testing to a later task.
4. **Address guardian feedback promptly.** When a guardian flags an issue on your task, fix it before moving to the next task. If you disagree with guardian feedback, raise it to the lead rather than ignoring it.
5. **Communicate blockers immediately.** If a dependency is not ready or you discover the design doc is ambiguous, notify the lead rather than making assumptions.

### Reviewer

The reviewer does NOT write feature code. This constraint is critical -- the reviewer's value comes from fresh eyes and independence. Reviewer responsibilities:

1. **Review each task after it passes guardians.** Guardians catch mechanical issues (test failures, convention violations). The reviewer catches conceptual issues that automated checks miss.
2. **Check for spec drift.** Compare the implementation against the design doc. Flag any behavior that differs from what was specified, even if the code works correctly.
3. **Identify edge cases.** Look for inputs, states, or sequences that the implementer may not have considered. Create fix tasks for edge cases that need handling.
4. **Evaluate naming and abstraction.** Are functions, variables, and modules named clearly? Are abstractions at the right level? Will another developer understand this code in six months?
5. **Create fix tasks when issues are found.** Do not fix issues yourself. Write a clear task describing the problem and the expected fix, then assign it back to the appropriate implementer.
6. **Write the deviations section of the completion report.** Document every place where the implementation differs from the design doc, whether intentional or not, and why.

## Task Creation Guidance

The lead should follow these principles when breaking the design doc into tasks:

- **Group by module or component.** Each task should focus on one module, one component, or one logical unit. Avoid tasks that touch many unrelated files.
- **Each task produces a testable deliverable.** A task is not "research how X works." A task is "implement X with tests that verify Y." If a task cannot be tested, it is too vague.
- **Order by dependency within each implementer's queue.** If task 3 depends on task 1, they should be assigned to the same implementer in order. Minimize cross-implementer dependencies.
- **Aim for 5-6 tasks per implementer.** Fewer than 4 tasks means they are too large and hard to review. More than 8 means they are too granular and create coordination overhead.
- **Include interface tasks early.** If the two implementers' code must interact, create an interface definition task first so both sides agree on the contract.
- **Reserve a final integration task.** The last task for at least one implementer should be wiring the pieces together and verifying the end-to-end flow.

Example task breakdown for a notification feature:
1. Implementer A: Define notification data model and persistence layer
2. Implementer A: Implement notification creation and storage
3. Implementer A: Implement notification query and filtering
4. Implementer A: Implement notification deletion and cleanup
5. Implementer A: Wire notification API endpoints
6. Implementer B: Implement notification rendering templates
7. Implementer B: Implement real-time notification delivery
8. Implementer B: Implement notification preferences and settings
9. Implementer B: Implement notification batching and digest
10. Implementer B: End-to-end integration with notification API

## Guardian Configuration

All five guardians are active for feature builds:

- **spec** -- Validates that implementation matches the design doc. Critical for feature builds where spec drift is the primary risk.
- **test** -- Validates that every code change has corresponding tests. Implementers must write tests alongside code, not after.
- **convention** -- Validates naming, formatting, and structural patterns. Keeps the new feature consistent with the existing codebase.
- **integration** -- Runs the full test suite after each task to catch regressions. Especially important when two implementers work in parallel.
- **context** -- Records decisions and rationale. When the lead or implementer deviates from the design doc, the context guardian captures why.

## Completion Criteria

The feature build is complete when ALL of the following are true:

1. **All tasks are marked complete.** Every task created by the lead, including any fix tasks created by the reviewer, has been implemented and passed guardians.
2. **All guardians pass on the final state.** Run all five guardians against the complete feature, not just individual tasks.
3. **Full test suite passes.** The integration guardian must confirm that no existing tests were broken by the new feature.
4. **Completion report is written.** The lead writes the report with input from the reviewer's deviations section. The report includes:
   - Summary of what was built
   - Deviations from the design doc (written by the reviewer)
   - Follow-up items or known limitations
   - Guardian pass/fail summary
5. **Reviewer has signed off.** The reviewer confirms that all fix tasks have been addressed and no outstanding spec drift remains.
