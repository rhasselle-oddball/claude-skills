#!/bin/bash
set -e

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

CONFIG="$HOME/.config/work-topics/config.json"
if [ ! -f "$CONFIG" ]; then
    exit 0
fi

DATA_DIR=$(jq -r '.data_dir // empty' "$CONFIG")
if [ -z "$DATA_DIR" ]; then
    exit 0
fi

WORK_TOPICS_DIR="$DATA_DIR/work-topics"
NOTES_DIR="$DATA_DIR/Notes"

# Auto-allow edits within the work-topics data directory or Notes/ (topic notes)
if [[ "$FILE_PATH" == "$WORK_TOPICS_DIR"* ]] || [[ "$FILE_PATH" == "$NOTES_DIR"* ]]; then
    jq -n '{
        hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: "allow",
            permissionDecisionReason: "File is within work-topics data directory"
        }
    }'
    exit 0
fi

exit 0
