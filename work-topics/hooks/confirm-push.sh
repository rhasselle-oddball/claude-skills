#!/bin/bash
set -e

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only inspect git push commands
if ! echo "$COMMAND" | grep -q 'git push'; then
  exit 0
fi

# Require user confirmation before pushing
jq -n '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "ask",
    permissionDecisionReason: "About to push to remote. Confirm?"
  }
}'
