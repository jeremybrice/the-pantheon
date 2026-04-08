#!/bin/bash
# Guardian SessionStart Hook
# Injects active guardian context and Superpowers skill requirements on session start.
# Only activates if .guardian/guardians.json exists in the project.

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
GUARDIAN_DIR="$PROJECT_DIR/.guardian"
CONFIG="$GUARDIAN_DIR/guardians.json"

# Only activate if guardian is configured for this project
if [ ! -f "$CONFIG" ]; then
  exit 0
fi

# Read active guardians
ACTIVE_GUARDIANS=$(jq -r 'to_entries[] | select(.value.enabled == true) | .key' "$CONFIG" 2>/dev/null | tr '\n' ', ' | sed 's/,$//')

# Read mission brief summary (first 20 lines)
MISSION_SUMMARY=""
if [ -f "$GUARDIAN_DIR/mission-brief.md" ]; then
  MISSION_SUMMARY=$(head -20 "$GUARDIAN_DIR/mission-brief.md" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
fi

# Build context message
CONTEXT="GUARDIAN ACTIVE SESSION"
CONTEXT="${CONTEXT}\\n\\nActive guardians: ${ACTIVE_GUARDIANS}"
CONTEXT="${CONTEXT}\\n\\nRequired Superpowers skills for this project:"
CONTEXT="${CONTEXT}\\n- superpowers:test-driven-development (all implementation tasks)"
CONTEXT="${CONTEXT}\\n- superpowers:systematic-debugging (debugging tasks)"
CONTEXT="${CONTEXT}\\n- superpowers:verification-before-completion (before marking any task done)"

if [ -n "$MISSION_SUMMARY" ]; then
  CONTEXT="${CONTEXT}\\n\\nMission brief summary:\\n${MISSION_SUMMARY}"
fi

# Output JSON for Claude Code hookSpecificOutput
printf '{"hookSpecificOutput":{"additionalContext":"%s"}}' "$CONTEXT"

exit 0
