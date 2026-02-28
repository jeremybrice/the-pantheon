---
name: test-suite
description: Backfill tests for existing code with coverage analysis
team_size: 4
roles: [lead, test-writer, test-writer, coverage-analyst]
guardians: [test, convention, integration]
autonomy: full
---

# Test Suite Playbook

## Overview

Use this playbook when existing code needs test coverage backfilled. The coverage analyst
identifies gaps and prioritizes what needs testing, the lead assigns work based on that
analysis, and two test writers produce tests in parallel. The focus order is: happy paths
first, then edge cases, then error paths. This ensures the highest-value tests are written
first even if time runs short.

This playbook is appropriate when:
- Existing code has insufficient test coverage
- A coverage audit has identified significant gaps
- You are preparing for a refactoring and need a test safety net first
- A module or feature was shipped without adequate tests

This playbook is NOT appropriate when:
- You are writing new code and tests together (use feature-build)
- You are debugging a specific issue (use bug-hunt)
- Tests exist but are failing (that is a bug fix, not a test backfill)

## Roles

### Lead

1. **Define the scope.** Identify which modules, directories, or features need test coverage. Establish the target coverage level (e.g., all public functions have at least one happy-path test).
2. **Coordinate with the coverage analyst.** The analyst identifies gaps; the lead turns those gaps into prioritized tasks for the test writers.
3. **Assign modules to test writers.** Each test writer gets specific modules to cover. Avoid assigning the same module to both writers -- this creates merge conflicts and duplicate tests.
4. **Enforce the priority order.** Happy paths first, edge cases second, error paths third. If a test writer jumps to edge cases before covering happy paths, redirect them.
5. **Monitor progress against the coverage goal.** Track how coverage improves with each completed task. Adjust priorities if some modules are harder to test than expected.
6. **Produce the coverage report.** Summarize coverage before and after, which modules were covered, and any remaining gaps.

### Test Writer (x2)

Each test writer produces tests for assigned modules. Test writers do NOT modify the code under test -- only test files are created or changed.

1. **Read the code under test carefully.** Understand what each function does, its parameters, return values, side effects, and error conditions before writing any tests.
2. **Follow the priority order.** For each assigned module:
   - **Happy paths first.** Write tests for the primary expected use case of each function. Use realistic inputs and verify the expected outputs. These are the highest-value tests.
   - **Edge cases second.** Test boundary conditions: empty inputs, maximum values, single-element collections, zero, null where applicable. These catch the bugs that happy-path tests miss.
   - **Error paths third.** Test that functions handle errors correctly: invalid inputs, missing dependencies, timeout conditions, permission failures. Verify that error messages are helpful.
3. **Write clear test names.** Each test name should describe the scenario and expected outcome. A reader should understand what the test verifies without reading the test body. Example: `test_create_user_with_duplicate_email_returns_conflict_error`.
4. **Keep tests independent.** Each test must set up its own state and clean up after itself. Tests must not depend on execution order or shared mutable state.
5. **Avoid testing implementation details.** Test behavior, not structure. If the code is refactored without changing behavior, the tests should still pass. Do not test private methods, internal data structures, or call order unless that order is part of the contract.
6. **Flag untestable code.** If a function is difficult to test because of tight coupling, hidden dependencies, or global state, report it to the lead. These are candidates for the refactor playbook.

### Coverage Analyst

The coverage analyst does NOT write tests. The analyst identifies what needs testing and prioritizes the work.

1. **Analyze current coverage.** Use coverage tools, manual inspection, or both to determine which functions, branches, and modules have tests and which do not.
2. **Prioritize by risk and impact.** Not all untested code is equally important. Prioritize:
   - Public APIs and user-facing functions (highest priority)
   - Functions with complex logic or many branches
   - Functions that handle money, authentication, or data integrity
   - Utility functions and internal helpers (lower priority)
3. **Identify coverage gaps per module.** For each module, list the untested functions and the types of tests missing (happy path, edge case, error path). Provide this analysis to the lead for task creation.
4. **Track coverage improvement.** After each test writer completes a task, re-analyze coverage to measure progress. Report which gaps have been closed and which remain.
5. **Identify test quality issues.** Coverage percentage alone is misleading. Look for tests that exercise code without asserting meaningful outcomes (coverage without verification). Flag these as low-quality tests that need improvement.
6. **Recommend testing strategies.** For modules that are hard to test, suggest approaches: dependency injection, test doubles, integration test setup, or refactoring suggestions that would make testing easier.

## Task Creation Guidance

The lead creates tasks based on the coverage analyst's findings:

- **One module per task.** Each task assigns one module to a test writer with a clear list of functions to test.
- **Specify the coverage target.** "Write happy-path tests for all public functions in module X" is better than "improve coverage for module X."
- **Include the analyst's notes.** Attach the coverage analyst's per-module gap analysis to each task so the test writer knows which functions are untested and what types of tests are missing.
- **Batch by priority tier.** Assign all happy-path tasks first. Once those are complete, assign edge-case tasks. Then error-path tasks. This ensures the highest-value work is done first.
- **Include a final coverage verification task.** The last task is for the coverage analyst to produce the final coverage report comparing before and after metrics.

## Guardian Configuration

Three guardians are active for test suite backfill:

- **test** -- Validates that tests are well-formed, follow testing conventions, and actually assert meaningful outcomes. A test that runs code without assertions is not a real test.
- **convention** -- Test files must follow naming conventions, directory structure, and style guidelines. Test code should be as clean as production code.
- **integration** -- After each batch of new tests, the full suite runs to confirm that new tests pass and existing tests still pass. New tests must not interfere with existing ones.

The spec and context guardians are not active. Test backfill does not reference a design doc, and the decisions involved (what to test and how) are straightforward enough to not require context tracking.

## Completion Criteria

The test suite backfill is complete when:

1. **All assigned modules have happy-path coverage.** Every public function in every scoped module has at least one test covering its primary use case.
2. **Edge-case and error-path tests are written** for high-priority functions as identified by the coverage analyst.
3. **All new tests pass** and the full existing test suite still passes.
4. **Convention guardian passes.** All test files follow naming, structure, and style conventions.
5. **No untestable code remains unaddressed.** Code flagged as untestable by the test writers is documented and queued for the refactor playbook.
6. **The coverage report is written** by the lead with input from the coverage analyst:
   - Coverage metrics before and after (by module)
   - Functions covered and test types written
   - Remaining gaps and their justification
   - Untestable code identified and recommended next steps
   - Overall assessment of test suite health
