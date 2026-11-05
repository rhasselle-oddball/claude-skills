---
name: wrap
description: Shorthand for /w wrap. "/wrap all" tells every other Claude agent in herdr to run /w wrap. Use when I say /wrap, "wrap up", "wrap all", or "wrap everyone".
argument-hint: "[all]"
---

# wrap

## This session

No argument: run `/w wrap` here, exactly as the work-topics skill defines it.

## all

Usually said to the orchestrator. Don't wrap this session; tell every other Claude agent to wrap its own.

1. `herdr agent list`, keep entries with `"agent":"claude"` and drop this pane (`$HERDR_PANE_ID`).
2. Before prompting each pane, `herdr pane read <pane> | tail` and look at its input box. If I've typed something there and not sent it, skip that pane, since a prompt would land on top of my text.
3. Send `herdr agent prompt <name> "/w wrap"`. Agents without a name: `herdr pane send-text <pane> "/w wrap"` then `herdr pane send-keys <pane> Enter`. A busy agent queues it after its current turn; that's fine.
4. Check each pane afterward as in the `herdr` skill and resend any prompt that didn't land.

Leave panes open. Reply with one line per agent: its tab label and whether it got the wrap, plus any skipped and why.
