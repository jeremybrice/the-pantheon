---
name: hardening
description: Quality sweep — security, edge cases, and performance review
team_size: 4
roles: [lead, security-reviewer, edge-case-finder, perf-tester]
guardians: [test, convention, integration]
autonomy: full
---

# Hardening Playbook

## Overview

Use this playbook when existing code needs a quality sweep. The team does NOT write new features.
Instead, three specialized reviewers examine the codebase from different angles -- security,
edge cases, and performance -- and create tasks for every issue they find. The lead coordinates
the effort and produces a hardening report.

This playbook is appropriate when:
- A feature has been recently shipped and needs production-readiness review
- A periodic quality audit is scheduled
- You suspect quality issues but do not know the specific problems yet
- Code was written quickly and needs a thorough second pass

This playbook is NOT appropriate when:
- You are implementing new functionality (use feature-build)
- You have a specific known bug to fix (use bug-hunt)
- You are restructuring code architecture (use refactor)

## Roles

### Lead

1. **Define the scope.** Identify which modules, directories, or features are in scope for the hardening sweep. Communicate the boundaries clearly to all reviewers.
2. **Assign review areas.** Divide the codebase so each reviewer focuses on specific modules. All three reviewers should cover the same areas but from their specialized perspective.
3. **Triage incoming issues.** As reviewers create tasks, the lead prioritizes them: critical (must fix now), important (fix before next release), and minor (fix when convenient).
4. **Assign fix tasks.** The lead assigns fix tasks to the reviewer who found the issue, since they have the deepest understanding of the problem. For complex fixes, the lead may reassign.
5. **Produce the hardening report.** Summarize all issues found, categorized by type (security, edge case, performance), with severity ratings and fix status.

### Security Reviewer

Examine the codebase specifically for security vulnerabilities. Do NOT write new features. For every issue found, create a task describing the vulnerability and the recommended fix.

Focus areas:
- **Input validation.** Are all user inputs validated and sanitized? Look for missing validation on API endpoints, form fields, CLI arguments, and file uploads.
- **Authentication boundaries.** Are protected resources actually protected? Look for endpoints or functions that should require authentication but do not.
- **Data exposure.** Are sensitive fields (passwords, tokens, internal IDs) ever leaked in responses, logs, or error messages?
- **Injection risks.** Look for SQL injection, command injection, template injection, and path traversal vulnerabilities. Check that parameterized queries are used consistently.
- **Dependency vulnerabilities.** Check for known vulnerabilities in dependencies. Flag any dependencies that are significantly outdated.

### Edge Case Finder

Examine the codebase for unhandled edge cases and error paths. Do NOT write new features. For every issue found, create a task describing the scenario and the expected behavior.

Focus areas:
- **Error paths.** What happens when external services fail, files are missing, or network requests time out? Are errors caught and handled gracefully?
- **Boundary conditions.** What happens with empty lists, zero values, maximum-length strings, or negative numbers? Are boundaries explicitly tested?
- **Null and undefined handling.** Where can values be null or undefined? Are there null checks where needed? Are optional fields handled correctly?
- **Race conditions.** Are there concurrent operations that could conflict? File writes, database updates, or shared state that could be corrupted by parallel access.
- **State transitions.** Are all valid state transitions handled? What happens with invalid transitions? Can entities get stuck in intermediate states?

### Performance Tester

Examine the codebase for performance issues. Do NOT write new features. For every issue found, create a task describing the bottleneck and the recommended optimization.

Focus areas:
- **N+1 queries.** Look for loops that make individual database or API calls when a batch operation would work. This is the single most common performance issue.
- **Unnecessary iterations.** Look for redundant loops, repeated computation of the same value, or O(n^2) algorithms that could be O(n).
- **Memory usage.** Look for large objects held in memory unnecessarily, missing cleanup of temporary data, and unbounded growth of collections.
- **Caching opportunities.** Identify expensive computations or I/O operations whose results could be cached. Check that existing caches are invalidated correctly.
- **I/O efficiency.** Look for synchronous I/O that blocks execution, unnecessary file reads, and missing connection pooling.

## Task Creation Guidance

Every issue found by a reviewer becomes a task. Tasks created during hardening follow this structure:

- **Title:** Brief description of the issue (e.g., "Add input validation to /api/users endpoint")
- **Category:** security, edge-case, or performance
- **Severity:** critical, important, or minor
- **Description:** What the issue is, where it occurs (file and line if possible), and why it matters
- **Recommended fix:** How to resolve the issue. Be specific enough that someone unfamiliar with the code could implement the fix.
- **Test requirement:** What test should be added to verify the fix and prevent regression

The lead triages tasks as they are created and may adjust severity ratings based on the overall picture.

## Guardian Configuration

Three guardians are active for hardening:

- **test** -- Every fix must include a test that reproduces the issue and verifies the fix. This is non-negotiable for hardening work.
- **convention** -- Fixes must follow existing code conventions. Hardening should not introduce style inconsistencies.
- **integration** -- The full test suite must pass after each fix. Hardening fixes must not break existing functionality.

The spec guardian is not active because hardening does not reference a design doc. The context guardian is not active because hardening decisions are typically straightforward (fix the bug, handle the edge case).

## Completion Criteria

The hardening sweep is complete when:

1. **All reviewers have completed their examination** of the assigned scope.
2. **All critical and important tasks are fixed** and pass guardians.
3. **Minor tasks are documented** in the hardening report for future work.
4. **The full test suite passes** with all fixes applied.
5. **The hardening report is written** by the lead, containing:
   - Scope of the review
   - Issues found by category and severity
   - Issues fixed vs. deferred
   - Recommendations for preventing similar issues
   - Overall quality assessment
