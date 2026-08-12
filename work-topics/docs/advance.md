# Advance

The `advance` keyword moves a topic forward through its lifecycle. It detects the topic's current state, reports it, proposes the next action, and executes on approval.

## Behavior Modes

- **Default**: Advance reports current state, proposes next step, waits for approval.
- **Force** ("advance force", "no time to chat"): Skips confirmations except merge. Runs autonomously.

## States

The topic's `step` is tracked in frontmatter and represents where it is in the lifecycle. Advance reads the step, checks real-world signals (worktree exists? tests passing? CI status?), and determines the next action.

```yaml
step: needs-tests
```

### State Machine

```
                    ┌──────────────┐
                    │ needs-context│ <-- interview loop
                    └──────┬───────┘
                           v
                    ┌──────────────┐
                    │ needs-setup  │ <-- topic/board/worktree/deps
                    └──────┬───────┘
                           v
                    ┌──────────────┐
                    │    ready     │
                    └──────┬───────┘
                           v
                    ┌──────────────┐
                    │ implementing │ <-- collaborative
                    └──────┬───────┘
                           v
                    ┌──────────────┐
                    │ needs-tests  │ <-- lint + unit + e2e + screenshots
                    └──────┬───────┘    (loops until passing)
                           v
                    ┌──────────────┐
                    │ needs-attention │ <-- user reviews changes
                    └──────┬───────┘
                           v
                    ┌──────────────┐
                    │ready-to-ship │ <-- commit + draft PR + push
                    └──────┬───────┘
                           v
              ┌────────────┴────────────┐
              v                         v
      ┌──────────────┐         ┌──────────────┐
      │  ci-failing  │────┐    │  ci-passing  │
      └──────────────┘    │    └──────┬───────┘
              ^           │           v
              │     (self-correct:    │
              │      fix, lint,  ┌────┴──────────────┐
              │      test, push) │changes-requested  │
              │           │     └────┬───────────────┘
              │           v          │
              │    ┌────────────┐    │  (address feedback,
              └────│needs-tests │<───┘   loop back)
                   └────────────┘
                                    │
              ┌─────────────────────┘
              v (when approved + CI green)
      ┌──────────────┐
      │ready-to-merge│
      └──────┬───────┘
             v
      ┌──────────────┐
      │     done     │
      └──────┬───────┘
             v
      ┌──────────────┐
      │   archived   │
      └──────────────┘
```

### State Definitions

| State | What it means | Advance action |
|-------|--------------|----------------|
| `needs-context` | Interview not complete | Read topic note + issue, ask clarifying questions, append context. Loop until user says go. |
| `needs-setup` | Topic/board/worktree/deps not ready | Infer which substep is needed: create topic note, link issue, move board to In Progress, create worktree, run `yarn install` or repo-specific setup. |
| `ready` | Setup complete, ready to implement | Report ready. Implementation is collaborative. |
| `implementing` | Actively coding | -- |
| `needs-tests` | Code changes need validation | Run lint (auto-fix), unit tests, E2E tests (`yarn e2e`). Capture screenshots if UI changes. Loop until all passing. |
| `needs-attention` | Blocked on human action | Could be: review a diff, make a decision, take an external action. Advance can't proceed until resolved. |
| `ready-to-ship` | User approved, needs commit + PR | Commit (confirm unless force), rebase, push, create draft PR using repo config template. Move issue to PR Review on board. |
| `ci-failing` | PR CI checks failing | Investigate failing checks, fix, loop back to `needs-tests`. |
| `ci-passing` | CI green, awaiting human review | Report status. Nothing to do but wait (or nudge reviewers). |
| `changes-requested` | Reviewer feedback to address | Read review comments, address feedback, loop back to `needs-tests`. |
| `ready-to-merge` | Approved + CI passing | Confirm with user (always, even force mode), merge, delete branch, mark done. |
| `done` | Merged and complete | Clean up worktree, offer to archive. |
| `archived` | Topic archived | No action. |

### State Detection

Advance doesn't rely solely on the stored `step` -- it cross-references real signals:

| Signal | Inference |
|--------|-----------|
| No topic note | `needs-setup` |
| Topic note has no/sparse context | `needs-context` |
| No worktree exists | `needs-setup` |
| Worktree has uncommitted changes, no PR | `needs-tests` or `implementing` |
| Tests passing + screenshots captured | `needs-attention` |
| PR exists, CI failing | `ci-failing` |
| PR exists, CI passing, no reviews | `ci-passing` |
| PR has changes-requested review | `changes-requested` |
| PR approved + CI passing | `ready-to-merge` |
| PR merged | `done` |

When stored `step` conflicts with real signals, real signals win. Update the stored step to match.

## Setup Phase Detail

`needs-setup` is one state but covers multiple substeps. Advance infers which substep is needed:

1. **Topic note** -- create if missing, link issue/PR if provided, check for duplicates
2. **Board sync** -- if issue is on a project board, move to "In Progress"
3. **Worktree** -- create from latest default branch if missing
4. **Dependencies** -- `yarn install` or per-repo setup from repo config

All substeps run automatically in sequence. Once all complete, transition to `ready`.

## Test Phase Detail

`needs-tests` covers lint + unit + E2E in a loop:

1. Run linter with auto-fix (e.g. `yarn lint --fix`)
2. Run unit tests for changed files
3. Run E2E tests (`yarn e2e`) for the changed app
4. If UI changes: capture screenshots for PR evidence
5. **Loop**: if anything fails, fix and re-run from step 1

**E2E first-page rule**: If E2E tests get stuck on the very first page (can't load, can't get past initial render), **STOP immediately and call for help**. Do not attempt to debug -- it indicates a fundamental setup problem and the agent will waste time in circles. Later failures (page 2+, specific interactions) are fine to investigate and fix.

## Ship Phase Detail

`ready-to-ship` runs these steps in sequence:

1. Stage and commit (show message + files, confirm unless force)
2. Rebase on default branch
3. Push branch
4. Create **draft PR** using repo config template (show title + body, confirm unless force)
5. If UI changes: include screenshots in PR body
6. Move linked issue to "PR Review" on board
7. Update topic note: set `pr`, set step to `ci-passing` (or `ci-failing` once checks run)

PRs are **always draft**. Always use the repo config's PR template.

## CI Self-Correction Loop

When CI fails (`ci-failing`):

1. Investigate failing checks (same as `/w pr check`)
2. Fix the issue in the worktree
3. Run lint + tests locally (transition to `needs-tests` loop)
4. Commit and push
5. Wait for CI to re-run
6. If still failing, repeat. If passing, transition to `ci-passing`.

## Confirmation Summary

| Action | Default | Force |
|--------|---------|-------|
| Context gathering | interactive | skip if context exists |
| Commit | confirm | auto |
| Draft PR | confirm | auto |
| Merge | **confirm** | **confirm** |

## Open Questions

- Should force mode have an iteration limit on self-correction loops?
- How does advance handle multi-repo topics (e.g. topic spans two repos at once)?
