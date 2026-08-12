#!/bin/bash
# Creates work-topics directory structure.
# Usage: setup-profile.sh <data_dir>

set -e

DATA_DIR="$1"

if [ -z "$DATA_DIR" ]; then
    echo "Usage: setup-profile.sh <data_dir>"
    exit 1
fi

if [ ! -d "$DATA_DIR" ]; then
    echo "Error: $DATA_DIR does not exist"
    exit 1
fi

WORK_DIR="$DATA_DIR/work-topics"

if [ -d "$WORK_DIR" ]; then
    echo "work-topics already exists at $WORK_DIR"
else
    mkdir -p "$WORK_DIR"
    echo "Created work-topics at $WORK_DIR"
fi

# Create repos directory for per-repo configs
mkdir -p "$WORK_DIR/repos"

# Always write config (may be re-running setup)
mkdir -p "$HOME/.config/work-topics"
cat > "$HOME/.config/work-topics/config.json" << CONFIG
{
  "data_dir": "$DATA_DIR",
  "worktree_pattern": "{repo_root}.worktrees/{slug}"
}
CONFIG

echo "Setup complete:"
echo "  Work dir: $WORK_DIR"
echo "  Repos: $WORK_DIR/repos/"
echo "  Config: $HOME/.config/work-topics/config.json"
echo ""
echo "Topic notes live in Notes/<Name>.md in the Obsidian vault."
echo "The Topics base at templates/Bases/Topics.base provides table views."
