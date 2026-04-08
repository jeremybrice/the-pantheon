#!/bin/bash
# Guardian TaskCompleted Hook
# Reads .guardian/guardians.json config, runs test, integration, and verification guardians.
# Exit 0 = pass (task completes). Exit 2 = block (stderr fed back as feedback).

set -euo pipefail

INPUT=$(cat)
TASK_ID=$(echo "$INPUT" | jq -r '.task_id // empty')
TASK_SUBJECT=$(echo "$INPUT" | jq -r '.task_subject // empty')
TASK_DESCRIPTION=$(echo "$INPUT" | jq -r '.task_description // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

# Use CWD from hook input, fall back to CLAUDE_PROJECT_DIR
PROJECT_DIR="${CWD:-${CLAUDE_PROJECT_DIR:-.}}"
GUARDIAN_DIR="$PROJECT_DIR/.guardian"
CONFIG="$GUARDIAN_DIR/guardians.json"

# If no guardian config exists, pass through
if [ ! -f "$CONFIG" ]; then
  exit 0
fi

ERRORS=""

# --- Test Guardian ---
TEST_ENABLED=$(jq -r '.test_guardian.enabled // false' "$CONFIG")
if [ "$TEST_ENABLED" = "true" ]; then
  TEST_CMD=$(jq -r '.test_guardian.test_command // "echo no test command configured"' "$CONFIG")
  REQUIRE_PASSING=$(jq -r '.test_guardian.require_passing // true' "$CONFIG")

  if [ "$REQUIRE_PASSING" = "true" ]; then
    TEST_OUTPUT=$(cd "$PROJECT_DIR" && eval "$TEST_CMD" 2>&1) || {
      ERRORS="${ERRORS}TEST GUARDIAN FAILED for task '$TASK_SUBJECT':\n"
      ERRORS="${ERRORS}The test suite did not pass. Fix the failing tests before completing this task.\n"
      ERRORS="${ERRORS}Test command: $TEST_CMD\n"
      ERRORS="${ERRORS}Output (last 50 lines):\n"
      ERRORS="${ERRORS}$(echo "$TEST_OUTPUT" | tail -50)\n\n"
    }
  fi
fi

# --- Integration Guardian ---
INTEGRATION_ENABLED=$(jq -r '.integration_guardian.enabled // false' "$CONFIG")
if [ "$INTEGRATION_ENABLED" = "true" ]; then
  FILE_THRESHOLD=$(jq -r '.integration_guardian.file_threshold // 3' "$CONFIG")

  # Count files changed in the latest commit and working tree
  CHANGED_FILES=$(cd "$PROJECT_DIR" && { git diff --name-only HEAD~1..HEAD 2>/dev/null; git diff --name-only HEAD 2>/dev/null; } | sort -u | wc -l | tr -d ' ')

  if [ "$CHANGED_FILES" -ge "$FILE_THRESHOLD" ]; then
    TEST_CMD=$(jq -r '.test_guardian.test_command // ""' "$CONFIG")
    if [ -n "$TEST_CMD" ]; then
      INTEGRATION_OUTPUT=$(cd "$PROJECT_DIR" && eval "$TEST_CMD" 2>&1) || {
        ERRORS="${ERRORS}INTEGRATION GUARDIAN FAILED for task '$TASK_SUBJECT':\n"
        ERRORS="${ERRORS}This task touched $CHANGED_FILES files (threshold: $FILE_THRESHOLD). The full test suite must pass.\n"
        ERRORS="${ERRORS}Output (last 50 lines):\n"
        ERRORS="${ERRORS}$(echo "$INTEGRATION_OUTPUT" | tail -50)\n\n"
      }
    fi
  fi
fi

# --- Verification Guardian ---
VERIFICATION_ENABLED=$(jq -r '.verification_guardian.enabled // false' "$CONFIG")
if [ "$VERIFICATION_ENABLED" = "true" ]; then
  REQUIRE_TEST_EVIDENCE=$(jq -r '.verification_guardian.require_test_evidence // true' "$CONFIG")

  if [ "$REQUIRE_TEST_EVIDENCE" = "true" ]; then
    # Check if tests were run by looking for changes in the latest commit and working tree
    ALL_CHANGED=$(cd "$PROJECT_DIR" && { git diff --name-only HEAD~1..HEAD 2>/dev/null; git diff --name-only HEAD 2>/dev/null; } | sort -u)
    TEST_FILES_CHANGED=$(echo "$ALL_CHANGED" | grep -c -E '(test_|_test\.|\.test\.|spec\.)' || true)
    CODE_FILES_CHANGED=$(echo "$ALL_CHANGED" | grep -c -v -E '(test_|_test\.|\.test\.|spec\.)' || true)

    if [ "$CODE_FILES_CHANGED" -gt 0 ] && [ "$TEST_FILES_CHANGED" -eq 0 ]; then
      ERRORS="${ERRORS}VERIFICATION GUARDIAN FAILED for task '$TASK_SUBJECT':\n"
      ERRORS="${ERRORS}Code files were changed but no test files were added or updated.\n"
      ERRORS="${ERRORS}Evidence of testing is required before task completion.\n"
      ERRORS="${ERRORS}Add or update tests for your changes, run the test suite, and try again.\n\n"
    fi
  fi
fi

# If any guardian failed, block the task
if [ -n "$ERRORS" ]; then
  printf "%b" "$ERRORS" >&2
  exit 2
fi

exit 0
