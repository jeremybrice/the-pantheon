---
name: bug-hunt
description: Competing hypothesis debugging with parallel investigators
team_size: 5
roles: [lead, investigator, investigator, investigator, fixer]
guardians: [test, integration]
autonomy: full
---

# Bug Hunt Playbook

## Overview

Use this playbook when debugging a complex issue whose root cause is unknown. Three investigators
pursue DIFFERENT hypotheses simultaneously, sharing evidence and challenging each other's
theories. This competing-hypothesis approach avoids the tunnel vision that occurs when one
person pursues a single theory. Once the root cause is identified with evidence, a dedicated
fixer implements the solution.

This playbook is appropriate when:
- A bug has been reported but the root cause is unknown or debated
- Initial debugging attempts have failed or produced conflicting theories
- The bug is complex enough to warrant multiple investigation paths
- The bug has significant impact and speed of resolution matters

This playbook is NOT appropriate when:
- The root cause is already known and just needs a fix (assign directly)
- You are building a new feature (use feature-build)
- You are doing a broad quality sweep (use hardening)

## Roles

### Lead

The lead coordinates the investigation and makes the final call on root cause.

1. **Define the bug clearly.** Write a precise description of the observed behavior, the expected behavior, and the steps to reproduce. Include any relevant logs, error messages, or screenshots.
2. **Assign distinct hypotheses.** Each investigator MUST pursue a different theory. If two investigators converge on the same hypothesis, the lead redirects one of them. Diversity of investigation paths is the core value of this playbook.
3. **Facilitate evidence sharing.** As investigators discover facts, the lead ensures all investigators see the evidence. One investigator's finding may disprove another's hypothesis or open a new line of inquiry.
4. **Challenge weak hypotheses.** If an investigator's theory does not explain all observed symptoms, push back. The root cause must explain everything, not just part of the bug.
5. **Validate the root cause.** Before assigning the fix, the lead confirms that the proposed root cause explains all symptoms, is supported by evidence (not just theory), and can be reproduced or demonstrated.
6. **Assign the fix.** Once validated, the lead briefs the fixer with the root cause, evidence, and expected fix approach. The lead also defines what tests should verify the fix.
7. **Write the investigation summary.** Document each hypothesis explored, the evidence for and against, and the final root cause determination. This is valuable for future debugging.

### Investigator (x3)

Each investigator pursues a DIFFERENT hypothesis about the root cause. This is the critical constraint. Investigators do NOT fix the bug.

1. **Receive your hypothesis assignment.** The lead assigns you a specific theory to investigate. Your job is to prove or disprove this theory with evidence.
2. **Gather evidence systematically.** Read code, add logging, write reproduction scripts, examine data. Every claim must be backed by evidence, not speculation.
3. **Share findings as you go.** Do not wait until you have a complete theory. Share intermediate findings so other investigators can incorporate them. A fact you discover may disprove someone else's hypothesis early, saving time.
4. **Challenge other investigators.** When another investigator presents a theory, actively look for evidence that contradicts it. Healthy competition between hypotheses leads to the correct root cause faster.
5. **Abandon disproven hypotheses.** If evidence clearly disproves your hypothesis, report this to the lead immediately. The lead will either assign you a new hypothesis or have you assist another investigator.
6. **Document your investigation path.** Record what you checked, what you found, and what you concluded. Even disproven hypotheses are valuable documentation.

Investigators should NOT:
- Fix the bug (that is the fixer's job)
- Pursue the same hypothesis as another investigator
- Make code changes beyond temporary debugging instrumentation (which must be reverted)

### Fixer

The fixer does NOT investigate. The fixer waits until the lead validates a root cause, then implements the fix.

1. **Wait for the validated root cause.** Do not start fixing until the lead explicitly assigns the fix with a confirmed root cause and evidence.
2. **Understand the root cause thoroughly.** Read the investigators' evidence. Understand not just what is broken but why it is broken. A fix that addresses symptoms instead of the root cause will fail.
3. **Implement the minimal correct fix.** Fix the root cause, not symptoms. Avoid refactoring or improving unrelated code in the same change. Keep the fix focused and reviewable.
4. **Write regression tests.** Every bug fix must include a test that reproduces the original bug and verifies the fix. This test must fail without the fix and pass with it.
5. **Verify the fix addresses all symptoms.** If the bug had multiple symptoms, confirm that the fix resolves all of them, not just the most obvious one.
6. **Clean up investigation artifacts.** Remove any temporary logging, debug flags, or instrumentation that investigators added during their work.

## Task Creation Guidance

The lead creates tasks in phases:

**Phase 1 -- Investigation tasks (created at start):**
- One task per investigator, each with a distinct hypothesis to pursue
- Each task includes: the hypothesis statement, relevant code areas to examine, available evidence so far, and what would prove or disprove the hypothesis

**Phase 2 -- Fix task (created when root cause is validated):**
- One task for the fixer containing: validated root cause with evidence, recommended fix approach, required regression tests, and list of all symptoms that must be resolved

**Phase 3 -- Cleanup tasks (created if needed):**
- Tasks to remove investigation artifacts, update documentation, or address related issues discovered during investigation

## Guardian Configuration

Two guardians are active for bug hunts:

- **test** -- The fix must include regression tests. The test guardian ensures that the fixer writes tests that reproduce the bug and verify the fix.
- **integration** -- The full test suite must pass after the fix. Bug fixes must not introduce new regressions.

The spec, convention, and context guardians are not active. Bug fixes should be minimal and focused. Convention enforcement and spec validation add friction without proportional value for targeted fixes.

## Completion Criteria

The bug hunt is complete when:

1. **Root cause is validated.** The lead has confirmed the root cause with evidence from at least one investigator, and no contradicting evidence remains unexplained.
2. **Fix is implemented and passes guardians.** The fixer's change passes both the test and integration guardians.
3. **All symptoms are resolved.** Every reported symptom of the bug is verified as fixed.
4. **Regression test exists.** A test that would catch this bug if it recurred is included in the test suite.
5. **Investigation summary is written.** The lead documents:
   - Original bug report and symptoms
   - Each hypothesis explored and its outcome
   - The validated root cause with evidence
   - The fix applied and its verification
   - Lessons learned for future debugging
6. **Investigation artifacts are cleaned up.** No temporary logging, debug flags, or reproduction scripts remain in the codebase.
