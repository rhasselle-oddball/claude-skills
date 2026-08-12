# claude-skills

Skills I use. One directory each, with a `SKILL.md`.

The format is portable, but `work-topics` registers `PreToolUse` hooks under `~/.claude`, so it only runs in Claude Code.

**lean-writing** - conventions for anything an agent writes on my behalf: commit messages, PR bodies, code comments, docs. Shortest form that carries the thought, not the shortest form that carries all the information.

**review-loop** - runs a fresh reviewer subagent over your changes each round, with no framing about what the change is meant to do, and stops when a round produces no correctness fix.

**visual-demo** - vets-website specific. Runs a Cypress spec that screenshots only the part that changed, then hosts the PNGs in a public repo so they embed in a va.ghe.com PR body.

**work-topics** - persistent memory for work topics, from creation through PR to done. Links GitHub issues, PRs, branches, and worktrees to Obsidian notes.
