#!/usr/bin/env bash
# Queries the Topics base and formats topics as a grouped list.
# Output is markdown-formatted plain text.

set -euo pipefail

BASE_PATH="templates/Bases/Topics.base"

# Ensure base is open
obsidian.com open vault=Notes path="$BASE_PATH" 2>/dev/null

# Query all topics, filter out done/archived
all_topics=$(obsidian.com base:query vault=Notes path="$BASE_PATH" view="All" format=json 2>/dev/null)
topics=$(echo "$all_topics" | python3 -c "
import json, sys
topics = json.load(sys.stdin)
active = [t for t in topics if t.get('Status', '') not in ('done', 'archived')]
print(json.dumps(active))
" 2>/dev/null)

if [ -z "$topics" ] || [ "$topics" = "[]" ]; then
    echo "No active topics."
    exit 0
fi

# Group by status and format
python3 -c "
import json, sys

topics = json.load(sys.stdin)

# Group by status
groups = {}
for t in topics:
    status = t.get('Status', 'unknown')
    if status not in groups:
        groups[status] = []
    groups[status].append(t)

# Display order
order = ['general', 'backlog', 'in-progress', 'in-review']
counts = {}

for status in order:
    if status not in groups:
        continue
    items = groups[status]
    counts[status] = len(items)

    for t in items:
        name = t.get('Topic', 'unknown')
        # Derive slug from name (kebab-case)
        slug = name.lower().replace(' ', '-')
        issue = t.get('Issue', '')
        pr = t.get('PR', '')

        print(f'**{slug}** — {name} — {status}')
        if issue:
            print(f'  Issue: {issue}')
        if pr:
            print(f'  PR: {pr}')
        print()

# Summary line
parts = []
for status in order:
    if status in counts:
        parts.append(f'**{counts[status]}** {status}')
if parts:
    print(' | '.join(parts))
" <<< "$topics"
