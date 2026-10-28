---
name: herdr
description: Open, move, or find Claude agents in herdr. Use when I mention a space, window, or pane, say "<name> space" (dev space, prs space), or ask to open a session or spin up agents somewhere.
---

# herdr

## Terms

- **space** = herdr workspace. "dev space" means the workspace labeled `dev`.
- **window** = tab.
- **pane** = pane.

Commands take IDs (`w1H`), not labels. `--workspace dev` fails. Resolve the label first:

```bash
herdr workspace list | jq -r '.result.workspaces[] | select(.label=="dev") | .workspace_id'
```

## Where things go

- My own work: **dev** space.
- Reviewing someone else's PR: **prs** space.
- At most 2 panes per window. Need more? Make another window.
- Start agents from `~/dev` (trusted folder).
- Leave existing windows and panes alone unless I ask.

## Recipes

New window with an agent:

```bash
pane=$(herdr tab create --workspace <ws_id> --cwd ~/dev --label "<label>" | jq -r .result.root_pane.pane_id)
herdr agent start <name> --kind claude --pane "$pane"
herdr agent prompt <name> "<prompt>"
```

Second agent in that window:

```bash
pane2=$(herdr pane split "$pane" --direction right --cwd ~/dev | jq -r .result.pane.pane_id)
```

Resume an old session: `herdr agent start <name> --kind claude --pane <pane> -- --resume <session-id>`. Find the session ID by grepping `~/.claude/projects/*/*.jsonl`. File names start with `-`, so pass `--` to `ls`/`stat`.

Find an agent: `herdr agent list` shows name, pane, status, and title for every space.

## Gotchas

- Pane IDs change when a pane moves to another space, and can disappear when I rearrange things. List panes right before you split or move, address agents by name, and stop on any error. A failed lookup gives an empty ID, and the next command then runs against the current pane, which is the orchestrator.
- `pane move` takes either `--tab <id> --split right|down [--target-pane <id>]` or `--new-tab --workspace <id>`. Moving the last pane out of a window closes that window.
- After a fan-out, check each pane with `herdr pane read <pane> | tail`. A prompt sometimes doesn't land: if the text sits unsent, `herdr pane send-keys <pane> Enter`; if the box is empty, prompt again.
- Review prompts stay minimal: "thoughts on these changes? <url>".
