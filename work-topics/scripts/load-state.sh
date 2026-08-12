#!/bin/bash
# Loads current state for /w skill dynamic injection.
# Outputs config, git context, repo config, topics (from base), and active topic note.
# Uses obsidian.com to read from the Obsidian vault (Google Drive, not WSL-accessible).
#
# Data model: Topic notes are the single source of truth.
# The Obsidian Topics base provides structured queries over all topic notes.
# No kanban.md or index file — the base IS the index.

CONFIG="$HOME/.config/work-topics/config.json"
BASE_PATH="templates/Bases/Topics.base"

# --- Config ---
echo "=== Config ==="
if [ -f "$CONFIG" ]; then
    cat "$CONFIG"
else
    echo '{"error": "no config — run /w setup"}'
fi

# --- Git context ---
echo ""
echo "=== Git ==="
echo "repo: $(git remote get-url origin 2>/dev/null || echo 'none')"
BRANCH=$(git branch --show-current 2>/dev/null || echo 'detached')
echo "branch: $BRANCH"
echo "default_branch: $(git rev-parse --verify refs/remotes/origin/main &>/dev/null && echo 'main' || echo 'master')"
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo 'not a git repo')
echo "root: $GIT_ROOT"

# --- Data ---
if [ ! -f "$CONFIG" ]; then
    echo ""
    echo "=== Topics ==="
    echo "no config"
    echo ""
    echo "=== Active Topic ==="
    echo "none"
    exit 0
fi

# --- Repo config ---
echo ""
echo "=== Repo Config ==="
REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo '')
if [ -n "$REMOTE_URL" ]; then
    REPO_SLUG=$(echo "$REMOTE_URL" | sed -E 's#.*[:/]([^/]+/[^/]+)\.git$#\1#; s#.*[:/]([^/]+/[^/]+)$#\1#')
    REPO_CONFIG="work-topics/repos/$REPO_SLUG.md"
    CONTENT=$(obsidian.com read vault=Notes path="$REPO_CONFIG" 2>/dev/null)
    if [ -n "$CONTENT" ]; then
        echo "$CONTENT"
    else
        echo "none (expected: $REPO_CONFIG)"
    fi
else
    echo "none (no git remote)"
fi

# --- Topics from base ---
echo ""
echo "=== Topics ==="
# Ensure base is open, then query All view and filter out done/archived
obsidian.com open vault=Notes path="$BASE_PATH" 2>/dev/null
ALL_TOPICS=$(obsidian.com base:query vault=Notes path="$BASE_PATH" view="All" format=json 2>/dev/null)
if [ -n "$ALL_TOPICS" ] && [ "$ALL_TOPICS" != "[]" ]; then
    # Filter to active topics (exclude done and archived)
    TOPICS=$(echo "$ALL_TOPICS" | python3 -c "
import json, sys
topics = json.load(sys.stdin)
active = [t for t in topics if t.get('Status', '') not in ('done', 'archived')]
print(json.dumps(active))
" 2>/dev/null)
    echo "$TOPICS"
else
    echo "no topics (base query returned empty)"
fi

# --- Active topic (match current branch to topic slugs, read that note) ---
echo ""
echo "=== Active Topic ==="
if [ "$BRANCH" != "detached" ] && [ "$BRANCH" != "main" ] && [ "$BRANCH" != "master" ] && [ -n "$TOPICS" ] && [ "$TOPICS" != "[]" ]; then
    # Find the topic whose slug matches the current branch
    NOTE_PATH=$(echo "$TOPICS" | python3 -c "
import json, sys
try:
    topics = json.load(sys.stdin)
    branch = '$BRANCH'
    for t in topics:
        # Try to match by slug property if available, or derive from path
        path = t.get('path', '')
        # Read slug via property:read would be slow; match by path-derived slug
        # Slug is stored in frontmatter, but base may not expose it
        # For now, we'll need to check each topic
        print(json.dumps({'path': path, 'topic': t.get('Topic', '')}))
except:
    pass
" 2>/dev/null | head -20)

    # If we have topics, try to find matching slug via property:read
    MATCHED_PATH=""
    if [ -n "$TOPICS" ] && [ "$TOPICS" != "[]" ]; then
        MATCHED_PATH=$(echo "$TOPICS" | python3 -c "
import json, sys
topics = json.load(sys.stdin)
for t in topics:
    path = t.get('path', '')
    if path:
        print(path)
" 2>/dev/null | while read -r np; do
            SLUG=$(obsidian.com property:read vault=Notes name=slug path="$np" 2>/dev/null)
            if [ "$SLUG" = "$BRANCH" ]; then
                echo "$np"
                break
            fi
        done | head -1)
    fi

    if [ -n "$MATCHED_PATH" ]; then
        NOTE=$(obsidian.com read vault=Notes path="$MATCHED_PATH" 2>/dev/null)
        if [ -n "$NOTE" ]; then
            echo "path: $MATCHED_PATH"
            echo "$NOTE"
        else
            echo "none (note not found: $MATCHED_PATH)"
        fi
    else
        echo "none (no topic matches branch: $BRANCH)"
    fi
else
    echo "none (not on a topic branch)"
fi
