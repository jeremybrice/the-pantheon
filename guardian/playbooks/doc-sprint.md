---
name: doc-sprint
description: Documentation push with accuracy validation
team_size: 4
roles: [lead, writer, code-reader, accuracy-checker]
guardians: [spec, convention]
autonomy: full
---

# Doc Sprint Playbook

## Overview

Use this playbook when producing or overhauling documentation. The team separates the
concerns of writing, code analysis, and accuracy validation into distinct roles so that
documentation is both well-written and technically correct. The code reader provides
ground truth from the actual implementation, and the accuracy checker verifies that the
final documentation matches reality.

This playbook is appropriate when:
- A feature or module needs documentation written or rewritten
- Existing documentation is known to be outdated or inaccurate
- A documentation audit has identified significant gaps
- You are preparing documentation for a release or handoff

This playbook is NOT appropriate when:
- You are fixing a bug (use bug-hunt)
- You are writing code (use feature-build)
- The documentation change is a single sentence or paragraph (just edit it directly)

## Roles

### Lead

1. **Create the documentation plan.** Identify every document that needs to be written or updated. Prioritize by audience impact -- which documents will the most people read?
2. **Define the scope and audience.** For each document, specify who will read it (end users, developers, operators) and what they need to learn from it.
3. **Assign work.** Give the writer specific documents to produce, the code reader specific modules to analyze, and the accuracy checker specific claims to verify.
4. **Ensure coverage.** Track which modules, features, and workflows have documentation and which do not. The goal is no undocumented public interfaces.
5. **Review the final output.** Read every document for clarity, completeness, and consistency of voice. The lead is the quality gate for the overall documentation set.

### Writer

The writer produces documentation content. The writer does NOT need to read source code directly -- the code reader provides technical details.

1. **Write from the reader's perspective.** Start with what the reader wants to accomplish, not with what the code does internally. Lead with use cases and examples.
2. **Use the code reader's analysis.** The code reader provides accurate technical details about function signatures, parameters, return values, error conditions, and behavior. Incorporate these into the documentation.
3. **Write clear examples.** Every public API, command, or workflow should have at least one complete example. Examples should be copy-pasteable and produce the described output.
4. **Maintain consistent structure.** Use the same heading hierarchy, section ordering, and terminology across all documents. If one document uses "configuration" instead of "settings," all documents should use the same term.
5. **Flag ambiguities.** If the code reader's analysis is unclear or seems contradictory, ask for clarification rather than guessing. Inaccurate documentation is worse than missing documentation.

### Code Reader

The code reader examines the actual source code and provides accurate technical details to the writer. The code reader does NOT write documentation prose.

1. **Analyze assigned modules thoroughly.** Read the code, not just the existing comments or docstrings. Comments can be outdated; the code is the source of truth.
2. **Document function signatures and behavior.** For every public function, provide: parameters with types, return value with type, side effects, error conditions, and any important behavioral details.
3. **Identify undocumented behavior.** Look for behavior that a user would encounter but that is not obvious from the function name or signature. Edge cases, default values, implicit ordering, and silent failures are all important.
4. **Provide accurate examples.** When providing example inputs and outputs to the writer, verify them by tracing through the code. Do not guess at output values.
5. **Note code-level constraints.** Maximum lengths, required formats, valid ranges, and other constraints that affect users should be communicated to the writer even if the code does not enforce them explicitly.

### Accuracy Checker

The accuracy checker validates that finished documentation matches the actual code behavior. The accuracy checker does NOT write documentation.

1. **Verify every technical claim.** When documentation says "function X returns Y," check that function X actually returns Y in the code. When documentation says "parameter Z is optional," check that the code handles a missing parameter Z.
2. **Test every example.** Run or trace through every code example in the documentation. Verify that the inputs produce the documented outputs. Flag any example that produces different results.
3. **Check for omissions.** Compare the documentation against the code to find features, parameters, or behaviors that exist in the code but are missing from the documentation.
4. **Verify error documentation.** Check that documented error messages match actual error messages. Verify that documented error handling advice actually resolves the error.
5. **Create fix tasks for inaccuracies.** When the documentation does not match the code, create a task for the writer to correct it. Include the specific inaccuracy, the correct information from the code, and the file and line reference.

## Task Creation Guidance

The lead creates tasks following these principles:

- **One document per task for the writer.** Each task produces one complete document or one major section of a large document.
- **One module per task for the code reader.** Each task analyzes one module or component and produces a technical summary for the writer.
- **Batch verification for the accuracy checker.** Group 3-5 related documents into one verification task to allow the checker to work efficiently.
- **Order: code reader first, then writer, then accuracy checker.** The code reader's output feeds the writer, and the writer's output feeds the accuracy checker.
- **Include a style guide task.** If one does not exist, the first task should be establishing a documentation style guide (terminology, structure, voice) that all documents follow.

## Guardian Configuration

Two guardians are active for documentation sprints:

- **spec** -- Validates that documentation covers what was planned. The documentation plan serves as the spec. Every document in the plan must be produced.
- **convention** -- Validates formatting, structure, and terminology consistency across all documents. Documentation should follow a uniform style.

The test, integration, and context guardians are not active. Documentation sprints do not produce code, so test and integration are irrelevant. Context tracking is less important when the work product is documentation itself.

## Completion Criteria

The doc sprint is complete when:

1. **Every document in the plan is written** by the writer and reviewed by the lead.
2. **The accuracy checker has verified all documents.** Every technical claim, example, and error description has been checked against the code.
3. **All accuracy fix tasks are resolved.** Inaccuracies found by the checker have been corrected by the writer.
4. **Convention guardian passes.** All documents follow the established style guide and formatting conventions.
5. **Coverage is confirmed.** The lead verifies that no public interfaces, commands, or workflows remain undocumented.
6. **The documentation summary is written** by the lead, containing:
   - List of documents produced or updated
   - Coverage assessment (what is documented vs. what exists)
   - Known gaps deferred to future work
   - Accuracy verification results
