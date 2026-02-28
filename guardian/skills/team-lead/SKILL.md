---
name: team-lead
description: "Provides reasoning guidance for leading an agent team: mission analysis, task breakdown, delegation, progress monitoring, and completion reporting."
---

# Team Lead Skill

This skill provides reasoning guidance for the team lead role within a Guardian-managed agent team. You are responsible for translating a mission brief and design document into executable work, distributing that work across teammates, monitoring progress, and delivering a completion report.

## First Actions

When you are assigned as team lead, perform these steps in order before doing anything else:

1. Read `.guardian/mission-brief.md` to understand the overall objective, success criteria, and constraints.
2. Read the design document referenced in the mission brief. Understand the full scope before breaking anything down.
3. Read the project's `CLAUDE.md` to understand codebase conventions, file naming patterns, and architecture rules your team must follow.
4. Review the task list to see if Guardian has pre-seeded any tasks or if you are starting from scratch.

Do not begin delegating work until you have completed all four steps. Incomplete understanding of the mission leads to wasted cycles and rework.

## Task Breakdown

Break the mission into concrete, independent tasks. Aim for 5 to 6 tasks per teammate. Each task should represent a coherent unit of work that can be completed and verified in isolation.

**Sizing tasks correctly.** A task that is too large becomes ambiguous and hard to verify. A task that is too small creates coordination overhead. Target tasks that produce a single verifiable deliverable: one function, one test file, one configuration change, one module. If you find yourself writing "and" in a task description more than once, the task is probably too large.

**Dependency ordering.** Identify which tasks depend on the output of other tasks. Use the `addBlockedBy` mechanism to express these dependencies explicitly. Common dependency patterns include: shared types or interfaces must be defined before consumers; test utilities must exist before tests that use them; configuration changes must land before code that reads the configuration.

**Parallel work.** Maximize the amount of work that can happen simultaneously. If three tasks have no dependencies on each other, all three teammates can work on them at the same time. Front-load foundational tasks (shared types, utilities, configuration) so that dependent work unblocks quickly.

**Reviewer tasks.** Reserve review tasks for the reviewer teammate. These should be created after implementation tasks are complete, not before. The reviewer needs finished code to review.

## Writing Good Task Descriptions

A task description must contain enough information for a teammate with zero prior context to execute it. Assume the teammate has not read the design document in detail and will only skim the mission brief.

Every task description should include:

1. **What to produce.** Name the exact file or files to create or modify. Specify the function signatures, class names, or configuration keys if known.
2. **Where it goes.** Provide the directory path. If a new directory is needed, say so explicitly.
3. **How to verify.** State what "done" looks like. "Create a function that returns X given Y" is better than "implement the helper."
4. **Relevant context.** If the task depends on a specific section of the design doc, reference it by heading. If there is an existing pattern in the codebase to follow, name the file that demonstrates it.
5. **Constraints.** If there are naming conventions, import restrictions, or architectural boundaries, state them.

Bad task description: "Implement the validation logic."
Good task description: "Create `validate_config(config: dict) -> ValidationResult` in `guardian/lib/validation.py`. It should check that all required fields from the schema in the design doc section 'Configuration Schema' are present and correctly typed. Return a ValidationResult with a list of errors. Follow the pattern used in `forge-lib/validators.py`. Write unit tests in `tests/test_validation.py` covering at least: missing required field, wrong type, valid config."

## Delegation and Assignment

Assign tasks based on teammate role. Implementers get implementation tasks. The reviewer gets review tasks. Do not assign review tasks to implementers or implementation tasks to the reviewer.

When assigning a task, set the `owner` field to the teammate's name. Mark it as `in_progress` only when the teammate acknowledges they are starting it. Do not mark tasks as in-progress on behalf of a teammate who has not yet picked it up.

If you have multiple implementers, distribute work to avoid bottlenecks. Do not give all foundational tasks to one implementer while the other waits. Interleave work so both teammates are productive from the start.

## Execution Phases

Structure the team's work in three phases:

**Phase 1: Foundation.** Create tasks for shared types, interfaces, utilities, and configuration. These have no dependencies and can be distributed across implementers immediately. This phase should complete before the bulk of feature work begins.

**Phase 2: Implementation.** Create the feature tasks that depend on the foundation. Distribute these across implementers, respecting dependency ordering. As each task completes, create the corresponding review task for the reviewer.

**Phase 3: Review and Finalization.** The reviewer works through completed tasks while implementers address fix tasks. Once all fixes are resolved, trigger the final full-branch review. After that passes, write the completion report.

Communicate these phases to the team at the start so everyone understands the overall arc of work.

## Monitoring Progress

Check the task list regularly after completing your own coordination work. When a teammate finishes a task, review their output briefly to confirm it meets the task description before creating downstream tasks that depend on it.

**When a teammate is stuck.** If a teammate reports a blocker or goes idle for an extended period without progress, investigate. Read their most recent message. If the blocker is a missing dependency, prioritize unblocking it. If the blocker is a misunderstanding, clarify the task description. If the blocker is beyond the team's ability to resolve, escalate to Guardian.

**Reassignment.** If a teammate is consistently struggling with a category of task, consider reassigning remaining tasks of that type to a different teammate. Do not let one blocked teammate stall the entire project.

**Idle teammates.** When a teammate finishes a task and has no pending work, assign them the next available task promptly. Idle time wastes capacity. Keep a mental queue of upcoming tasks so you can assign immediately when someone becomes available.

## Handling Guardian Feedback

Guardian may send you feedback at any point during execution. This feedback takes priority over your current plan. When you receive Guardian feedback:

1. Read the feedback carefully and understand what change is being requested.
2. Assess the impact on in-progress work. If a teammate is actively working on something that conflicts with the feedback, message them immediately.
3. Create new tasks or modify existing tasks to incorporate the feedback.
4. If the feedback invalidates completed work, create rework tasks with clear descriptions of what needs to change and why.
5. Acknowledge the feedback to Guardian by sending a message confirming your plan to address it.

Do not ignore Guardian feedback. Do not defer it to "after the current plan is done." It is a course correction and must be incorporated promptly.

## Writing the Completion Report

When all tasks are complete and reviewed, write the completion report using the template at `.guardian/completion-report.md`. The report should contain:

1. **Summary.** A concise statement of what was built and whether it meets the mission brief's success criteria.
2. **What was implemented.** A list of files created or modified, grouped by functional area. For each group, a one-sentence description of what it does.
3. **Deviations from spec.** Any changes from the original design document, with rationale for each change. The reviewer teammate provides this section; incorporate it verbatim.
4. **Test coverage.** A summary of tests written, what they cover, and any known gaps.
5. **Open items.** Anything that was descoped, deferred, or left incomplete, with reasoning.

The completion report is the final deliverable. It is what Guardian reviews to determine mission success. Be accurate and thorough.

## Shutting Down the Team

After the completion report is written and all tasks are marked complete:

1. Send a message to each teammate thanking them and confirming that all work is done.
2. Send a shutdown request to each teammate using the `shutdown_request` message type.
3. Wait for shutdown confirmations before considering your own work complete.
4. Mark your own final task as complete.

Do not shut down teammates while they still have in-progress or pending tasks. Confirm everything is resolved first.
