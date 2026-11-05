---
name: pr-ready
description: Get a topic's PR ready for my eyes, mine or someone else's: triage CI, review, and leave pending comments with screenshots so I can follow it. On my PRs also run review-loop, confidence, visual-demo, and lean-writing. Skips steps already done and records a checklist on the topic note. Use when I say /pr-ready, "get this PR ready", "is this ready for me", or when spread hands off.
argument-hint: "[PR url | topic name]"
---

# pr-ready

Take the topic's open PR to "ready for human". Use the PR in the argument, else the active topic's `PR` field. No PR: say so and stop.

Check the author against my login. My PR: get it ready to ship. Someone else's: get me ready to review it.

Never mark a PR ready for review, never submit a review, and never push to someone else's branch.

## Checklist

Each step is a property on the topic note, valued `<short sha> <date>` for the PR head it was done at, or `n/a <short sha>` when it doesn't apply:

`pr-ci` `pr-review-loop` `pr-confidence` `pr-visual-demo` `pr-lean-writing` `pr-comments`

```bash
obsidian.com property:read vault=Notes name=pr-review-loop path="Notes/<Name>.md"
obsidian.com property:set vault=Notes name=pr-review-loop value="<sha> <YYYY-MM-DD>" path="Notes/<Name>.md"
```

Read them all first. A step is done if its sha is the current head, or if the commits since then don't touch what the step cares about. Merges of main never count. Code changes reopen `pr-review-loop`, `pr-confidence`, `pr-lean-writing`, and `pr-comments`. UI changes reopen `pr-visual-demo`. A body or title edit reopens `pr-lean-writing`. Set each property as soon as its step finishes, so an interrupted run keeps its progress.

## My PR

Work in the topic's worktree. In this order, skipping what's done:

1. **CI.** If checks are red, follow `/w pr fix`: rebase on main first, then sort out whether the failure is ours (fix it) or someone else's (flaky, broken on main, another team's test). For someone else's, say whose and what you recommend; don't sink time into their code. Record `pr-ci` once checks pass or every failure is shown not to be ours.
2. **Review loop.** Run `/review-loop` on the PR.
3. **Confidence.** Run `/confidence`. Apply the cheap levers yourself (a missing test, a buried decision called out in the body). Don't split the PR: list proposed splits for me.
4. **Visual demo.** Only if the diff changes UI and the body has no screenshots or GIFs for it. Run `/visual-demo` (see the lock below) and add the results to the PR body.
5. **Lean writing.** Apply `/lean-writing` to the title, body, commit messages added since the last pass, and code comments in the diff.
6. **Pending comments.** Run `/draft-comments` in its explain mode on the key parts of the change. Attach a screenshot from step 4 where it helps me follow a comment.

Do the local work first and push once at the end, so I confirm one push per PR. After a push that changes code, check CI again.

## Someone else's PR

Read only: no pushes, no edits to their PR body.

1. **CI.** Note red checks and whether they look like the author's or someone else's. Don't fix them.
2. **Review.** Spawn one fresh reviewer as in `/review-loop` (one round, plain prompt), and review it yourself. Keep only the points you agree with, per the `verdict` skill.
3. **Visual demo.** If the PR changes UI, capture the feature with `/visual-demo` (see the lock below), but don't add it to their PR.
4. **Pending comments.** Run `/draft-comments`: explain the key parts so I understand the change, plus the agreed critique points in my voice. Attach screenshots where they help.

Record `pr-ci`, `pr-review-loop` (for the review), `pr-visual-demo`, and `pr-comments`.

## Pending comments here

These are for my understanding; I may never post them. So in this hand-off, skip `/draft-comments`' wait for me to agree on the points: draft straight to pending, then list them in the reply. If a pending review already exists, add to it and don't repeat points it already makes.

## Visual demo lock

Only one agent at a time runs a dev server or browser. Take the lock first and wait if it's held:

```bash
mkdir ~/.cache/pr-ready-visual.lock 2>/dev/null && echo "<topic> $(date +%s)" > ~/.cache/pr-ready-visual.lock/owner
```

Retry every minute or so. Treat a lock older than an hour as stale. `rm -r` it when done, and stop the dev server.

## Reply

A two-line verdict. My PR: **ready for human**, or what's blocking and who owns it. Someone else's: **ready for your review**, plus the one or two points that matter most. Then the pending comments (`file:line` and one line each), and any proposed splits or points left out. The PR URL is always the last line, alone.
