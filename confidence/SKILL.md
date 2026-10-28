---
name: confidence
description: >-
  Suggest how to make the current work easier for me to review and be confident in: split
  PRs, surface buried decisions, add before/after evidence, cut scope. Use when I say /confidence, or
  say a PR is too big, mixes topics, or I'm not sure about its scope or validity.
---

I'm the reviewer. Suggest what would make me confident in each PR in the current scope. Suggestions only; don't change anything.

## What lowers my confidence

- Too big to hold in my head.
- Mixed topics: a refactor, a fix, and a new prop in one diff.
- A key decision buried somewhere in the middle.
- "Adds props" that quietly changes behavior.
- Claims I can't see proof of.

## Levers

1. **No-behavior-change PR first.** Plumbing, refactors, new options that default to today's behavior. Safe to approve on its own.
2. **Decision in its own small PR.** Put the behavior change behind one helper or default so the flip is a few lines and easy to revert.
3. **One topic per PR.** Move unrelated changes out.
4. **Cut what isn't needed.** Scope I don't have to review is scope I don't have to trust.
5. **Show it.** Before/after screenshots or a GIF of the behavior (`visual-demo`). Tests that prove the claim, failing before and passing after when that's cheap.
6. **Name the decisions.** Each real choice stated plainly in the PR body: what, why, what the alternative was.
7. **Say what didn't change**, so I don't have to check.

## How

1. Read the PRs or diff in scope. For each one, say if it changes behavior, and how. Be honest about behavior hiding behind new props.
2. Suggest what would help: which PRs to split, merge, cut, or reorder, and what evidence each needs. Use the levers that apply and skip the rest. Most useful first.
3. Stop there. I'll pick what to do.
