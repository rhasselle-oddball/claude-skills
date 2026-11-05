# claude-skills

Daily skills I use.

**lean-writing** - conventions for anything an agent writes on my behalf: commit messages, PR bodies, code comments, docs. Shortest form that carries the thought, not the shortest form that carries all the information.

**review-loop** - runs a fresh reviewer subagent over your changes each round, with no framing about what the change is meant to do, and stops when a round produces no correctness fix.

**verdict** - after a review, just the blocking and worth-mentioning points, one lettered line each, written the way I'd say it to the author.

**draft-comments** - drafts line-anchored PR comments as a pending review. On my own PR they explain the change to me; on someone else's they carry my critique, posted only when I say so.

**confidence** - suggests how to make a change easier to review and trust: split the PR, surface buried decisions, add before/after evidence, cut scope.

**simple-list** - rewrites a list in plain words, the way I'd type it in Slack. Only when asked.

**visual-demo** - vets-website specific. Screenshots or GIFs of only the part that changed, via Cypress or Playwright, hosted in a public repo so they embed in a va.ghe.com PR body.

**herdr** - terms, conventions, and gotchas for opening and finding agents in herdr spaces, windows, and panes.

**rename-tab** - names and colors the herdr tab a session runs in, or every Claude tab. Related topics get neighboring colors. Expects one sidebar token per color in the herdr config.

**spread** - for an orchestrator session. Opens one agent per recently active work topic in herdr panes, each asked for its topic's status and to name its tab, then handed to pr-ready if the topic has a PR. Skips topics that already have a session.

**pr-ready** - gets a topic's PR ready for human eyes: CI triage, review-loop, confidence, visual-demo, lean-writing, and pending comments that explain the change. On someone else's PR it reviews read-only. Records each step on the topic note so the next session skips what's done.

**wrap** - shorthand for `/w wrap`. `/wrap all` tells every other agent in herdr to wrap its session.

**work-topics** - persistent memory for work topics, from creation through PR to done. Links GitHub issues, PRs, branches, and worktrees to Obsidian notes. Includes a `leader` mode where one agent does the work and the session only dispatches, verifies, and reviews.
