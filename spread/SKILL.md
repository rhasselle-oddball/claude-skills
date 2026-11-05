---
name: spread
description: Fan out recent work topics into herdr panes, one Claude agent per topic, each asked for that topic's status and told to rename its tab. Use when I say /spread or "spread", usually to the orchestrator.
argument-hint: "[week | <N> days | topic names]"
---

# spread

Open one agent per recent work topic, ask each for its status, and name each tab. You are the dispatcher: don't read the topics yourself.

## Pick topics

```bash
obsidian.com open vault=Notes path="templates/Bases/Topics.base" >/dev/null
obsidian.com base:query vault=Notes path="templates/Bases/Topics.base" view="All" format=json
```

Keep topics whose `Status` is not `done` or `archived` and whose `Last Active` falls in the window:

- An argument wins: `week` means the last 7 days, `<N> days` means N, topic names mean exactly those topics.
- Monday: back to the previous Wednesday, so last week's tail isn't lost behind the weekend.
- Other days: the last 3 days.

If more than 8 topics match, list them and ask which to open. If none match, say so and offer the week.

## Skip what's already open

`herdr agent list` shows every Claude agent's `name` and `terminal_title_stripped`. A topic already has a session when one of them is about it: same topic or slug, its PR or issue number, or plainly the same work in other words. Use judgment; titles drift from topic names. Don't open a new pane for it.

If that session's tab isn't named yet (no color token on the pane in `herdr pane list`, and the tab label in `herdr tab list` has no leading square), name it from here using the `rename-tab` commands with that agent's `pane_id` and `tab_id`. Don't prompt the agent; it may be mid-task. Leave already-named tabs alone. These count toward color assignment below.

## Colors

Assign colors here, all at once, so parallel agents don't pick the same one. Follow the color rules in the `rename-tab` skill: related topics get neighboring shades, unrelated ones sit far apart, and skip colors other panes already use (`tokens` in `herdr pane list`). The label is 2 to 4 lowercase words from the topic name.

## Open panes

Use the **dev** space, two panes per window (see the `herdr` skill). For each pair of topics:

```bash
ws=$(herdr workspace list | jq -r '.result.workspaces[] | select(.label=="dev") | .workspace_id')
pane=$(herdr tab create --workspace "$ws" --cwd ~/dev --label "<label>" | jq -r .result.root_pane.pane_id)
pane2=$(herdr pane split "$pane" --direction right --cwd ~/dev | jq -r .result.pane.pane_id)
```

Stop on any empty ID. Then start an agent in each pane, named after the topic slug, and send two prompts:

```bash
herdr agent start <slug> --kind claude --pane "$pane"
herdr agent prompt <slug> "/rename-tab <label> <color>"
herdr agent prompt <slug> "/w status <Topic name>"
```

If the topic has a PR, send a third prompt: `/pr-ready <PR url>`. Agents in already-open sessions don't get it; mention in the reply which of those have a PR.

Both agents in a window run `/rename-tab`, so the window ends up named after the second one. That's fine; each pane's sidebar color still marks its own topic.

## Check

After all prompts are sent, `herdr pane read <pane> | tail` each pane. If a prompt sits unsent, `herdr pane send-keys <pane> Enter`. If the box is empty, prompt again.

## Reply

One line per opened topic: label, color, window. Then the topics that already had a session, noting which tabs you renamed. Don't relay the statuses; I'll read them in the panes.
