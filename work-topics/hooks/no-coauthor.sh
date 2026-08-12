#!/bin/bash
set -e

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only inspect git commit commands
if ! echo "$COMMAND" | grep -q 'git commit'; then
  exit 0
fi

# Block if Co-Authored-By is present
if echo "$COMMAND" | grep -qi "Co-Authored-By"; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "Commits must not include Co-Authored-By trailers. Remove it and retry."
    }
  }'
  exit 0
fi

exit 0
