---
name: w
description: "Persistent memory and lifecycle management for work topics. Tracks topics from creation through PR to completion -- linking GitHub issues/PRs, branches, and Obsidian notes. Use when the user says /w, or mentions 'topics', 'topic', 'work topics', or 'my topics'."
argument-hint: "<command> [args]"
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Task
hooks:
  PreToolUse:
    - matcher: Bash
      hooks:
        - type: command
          command: $HOME/.claude/skills/work-topics/hooks/no-coauthor.sh
          timeout: 5
        - type: command
          command: $HOME/.claude/skills/work-topics/hooks/confirm-push.sh
          timeout: 5
    - matcher: Edit
      hooks:
        - type: command
          command: $HOME/.claude/skills/work-topics/hooks/allow-data-dir.sh
          timeout: 5
    - matcher: Write
      hooks:
        - type: command
          command: $HOME/.claude/skills/work-topics/hooks/allow-data-dir.sh
          timeout: 5
---

# /w -- Work Topics

Persistent memory for work topics. The user writes `/w` followed by natural language -- not rigid commands. The verb headers below (e.g. `scan`, `sync`, `topics`) are **keywords** to match against, not exact syntax. "sync my stuff", "sync everything", and just "sync" all match the `sync` keyword. Interpret intent, not tokens.

## Current State

!`$HOME/.claude/skills/work-topics/scripts/load-state.sh`

## Paths

- **Config**: `~/.config/work-topics/config.json`
- **Topic notes**: `Notes/<Human Name>.md` in the Obsidian vault (one note per topic)
- **Session notes**: `Notes/<topic-slug> <YYYY-MM-DD>.md` in the Obsidian vault (one note per session)
- **Topics base**: `templates/Bases/Topics.base` -- Obsidian Base that queries all topic notes
- **Sessions base**: `templates/Bases/Sessions.base` -- Obsidian Base that queries all session notes
- **Session template**: `templates/Session Template.md` -- template for new session notes
- **Repo config**: `<data_dir>/work-topics/repos/<org>/<repo>.md` (optional, per-repo customization)
- **Scripts**: `scripts/` (sibling to this SKILL.md) -- setup and state loading

## Architecture

**Topic notes are the single source of truth.** Each topic is an Obsidian note with rich frontmatter. The Obsidian Topics base provides visual table/board views by querying notes with `categories: [[Topics]]`. The CLI skill discovers topics via `base:query` or `search`.

There is no kanban.md or index file. The base IS the index.

### Topic discovery

To list all topics:
```bash
obsidian.com open vault=Notes path="templates/Bases/Topics.base"
obsidian.com base:query vault=Notes path="templates/Bases/Topics.base" view="All" format=json
```

The base must be opened first (one-time per Obsidian session), then `base:query` returns structured JSON with path, status, issue, PR, created, and other frontmatter fields.

Available base views: `All`, `Active`, `In Progress`, `Done`. **Note**: The "Active" view may have its own filter criteria that don't match our status vocabulary. Use `All` view and filter client-side (exclude `done`/`archived`) for reliable results.

### Slug-to-note resolution

Query the base to find a topic by slug:
```bash
obsidian.com base:query vault=Notes path="templates/Bases/Topics.base" view="All" format=json
```
Then match the slug from the JSON results. The `path` field gives the note location.

Alternatively, if the base isn't available, fall back to text search:
```bash
obsidian.com search vault=Notes query="slug: <slug>" path="Notes/" format=json
```

**Resolving by worktree path.** A slug cannot be inferred from a worktree directory or a branch name: both drift from it over a topic's life. When given a worktree path (the `wt` launcher hands one over), match on the `worktree:` frontmatter field instead, which records the path verbatim. Fall back to fuzzy-matching the directory name only if nothing matches.

## Conventions

### Branches

- Branch name = topic slug (e.g. `auth-refactor`). No user prefix.

### Pane topic

Whenever a topic becomes active in this pane -- `topic start`, `issue start`, `switch`, `status`, `auto`, `advance` -- record it for tmux:

```bash
tmux set-option -p @wt_topic "<slug>"
```

Skip when `$TMUX` is unset. The window-title hook reads `@wt_topic` and names the tab after it. Nothing else can: sessions usually start in `~/dev` rather than the worktree, so there is no branch to infer the topic from.

### Worktrees

- Default pattern: `<repo-root>.worktrees/<topic-slug>/`
  - Example: if repo is at `/home/user/projects/my-app`, worktree goes to `/home/user/projects/my-app.worktrees/auth-refactor/`
- Configurable via `worktree_pattern` in config. Supports `{repo_root}`, `{repo_name}`, and `{slug}` placeholders.
  - Default: `{repo_root}.worktrees/{slug}`
- Create with: `git -C <repo-root> fetch origin <default_branch> && git worktree add <worktree-path> -b <topic-slug> origin/<default_branch>`
- Shell cwd resets between Bash calls. Prefix worktree commands: `cd <worktree-path> && <command>`

### Commits

- Do NOT add `Co-Authored-By` trailers. Commits are the user's work.

### Confirmations

- Before creating a **commit**: show the full commit message and list of staged files. Wait for user confirmation.
- Before creating a **PR**: show the full title and body. Wait for user confirmation.
- Before creating an **issue**: show the full title, body, labels, and project fields. Wait for user confirmation.

### Draft PRs

- Every draft PR title starts with `(WIP) `, e.g. `(WIP) Fix nav bug`.
- Only the user removes `(WIP)` and moves the PR out of draft. Never do either.

### Default branch

- Use `default_branch` from the injected Git context (defaults to `main`, falls back to `master`).

### Last-active tracking

Automatically set `last-active` to today's date on the topic note whenever the user interacts with a topic through any of these verbs: `switch`, `status`, `pr` (create/merge/update/rerun), `note`, `wrap`, `run`, `done`, `issue start`, `topic start`. Use `property:set` with `type=date`:

```bash
obsidian.com property:set vault=Notes name=last-active value=2026-04-01 type=date path="Notes/<Name>.md"
```

Do NOT update `last-active` for read-only listing commands (`topics`, `recent`, `kanban`, `prs`, `issues`, `scan`) -- those are browsing, not working. Exception: `sync` backfills `last-active` from git commit dates when missing or stale.

### Multi-repo topics

- A topic can span multiple repos. List each repo's branch/worktree/PR as separate lines in the topic note.
- When running `start`, create a worktree in the current repo and add the info to the topic note.
- When running commands like `status` or `pr`, operate on the current repo (matched via git remote).

## Verbs

### `help`

Print this quick reference. These are **keywords**, not rigid commands -- the user writes natural language and these are the concepts the skill recognizes:

```
setup                           -- first-time config
topic <link|name> [start]       -- create topic (start = branch + begin work)
topics                          -- list all topics
recent                          -- topics sorted by last activity
kanban                          -- visual kanban board
status                          -- active topic summary
scan [sprint]                   -- check board for new work assigned to me
sync                            -- reconcile worktrees, topics, PRs, statuses
issue <title> [start]           -- create GitHub issue (start = topic + begin work)
auto <title|issue-url>          -- full pipeline: issue + worktree + implement + screenshots + draft PR
issues                          -- list issues linked to topics
prs                             -- list all PRs across topics
pr                              -- create PR for current branch
  pr status                     -- CI checks, reviews, merge readiness
  pr check <name>               -- investigate a failing CI check
  pr fix [name|PR-url]          -- triage, fix branch-caused; else watch re-run + escalate (rebase/ownership/hand-off)
  pr update                     -- rebase branch on latest base
  pr rerun                      -- re-run failed CI jobs
  pr merge                      -- merge current topic's PR
repo                            -- view repo config
  repo setup                    -- interactive repo config setup
  repo edit <section>           -- update one section
done [slug]                     -- mark done, cleanup worktree
archive [slug]                  -- set done topics to archived
remove <slug>                   -- delete a topic entirely
reset                           -- fresh board (wipe all topics)
code                            -- open active topic in VS Code
run [slug]                      -- dev server + localhost URL
inspect [slug]                  -- prep a hand-test: server + URL + checklist, then stop
note <text>                     -- add note to active topic
wrap                            -- end-of-session synthesis (creates session note)
switch <slug>                   -- change active topic
help                            -- this message
```

### `setup`

First-time configuration. Read [docs/setup.md](docs/setup.md) for full instructions.

### `repo`

View or configure per-repo instructions. Config is stored at `<data_dir>/work-topics/repos/<org>/<repo>.md`, derived from the git remote. The `repo_slug` (e.g. `<user>/<repo>`) is available from the injected Repo Config section.

**`repo`** (no args) -- Show the current repo config. If none exists, print the expected path so the user knows where it would go.

**`repo setup`** -- Interactive setup. Prompt the user for each section one at a time:

1. **Commits**: format/style (e.g. conventional commits, max subject length, scope conventions). Skip if user says none.
2. **Issues**: body template, default labels, assignee, project board (name/number), default column, sprint/iteration field, milestone. The project and assignee fields are also used by `scan` to query the board. Skip if user says none.
3. **PR**: title format, body template, required sections (e.g. Summary, Test Plan). Skip if user says none.
4. **Checks**: commands for lint, test, e2e, type check, build, etc. Ask which ones apply and what the commands are. Skip if user says none.
5. **Run**: dev server command, port, and URL template. Skip if user says none.

Write the result to the repo config path. Create parent directories as needed (`mkdir -p`).

**`repo edit <section>`** -- Update a single section of an existing repo config. Read the current config, show the current value of that section, ask what to change, and update in place using Edit.

### `topic <input> [start]`

Create a new topic. `<input>` can be:

- **A GitHub link** (issue or PR) -- extract metadata automatically.
- **A name/description** -- create a freeform topic.
- **Nothing** -- ask what it's about.

**Check the injected `=== Workflow ===` section** to determine the workflow type (`full` or `lightweight`).

Steps:

1. **If GitHub link**: parse org/repo/number, fetch with `gh issue view --json title,body,state,labels` or `gh pr view --json ...` (always use `--json`). Derive a slug from the title. Use the issue/PR title as the description.
2. **If freeform**: use the input as the slug (or derive one). Ask for a one-line description if not obvious from the input.
3. **Check for duplicates**: query the base to ensure no existing topic has the same slug or issue URL. If a match exists, say so instead of creating a duplicate.
4. Create a new topic note at `Notes/<Human Name>.md` in the vault (see Data Formats for frontmatter). Only include fields that are relevant -- don't add blank fields. The base automatically picks it up.
5. If `start` is present, **branch on workflow type**:

   **`full` workflow** (default):
   - Check the repo has at least one commit. If not, ask if they'd like to create an initial commit first.
   - Resolve worktree path from `worktree_pattern` in config.
   - Fetch latest and create worktree: `git -C <repo-root> fetch origin <default_branch> && git worktree add <worktree-path> -b <topic-slug> origin/<default_branch>`
   - **Bootstrap the worktree**: new worktrees do not inherit `node_modules` / `vendor` / `.venv` from the parent. If the repo config has an `## Install` section, run its command in the new worktree now. Without this, the first lint/test/build invocation fails with missing-binary errors. Run in the foreground so later steps can rely on it.
   - Update the topic note: add branch/worktree info to frontmatter.
   - Set the topic note's `status` to `in-progress`.
   - **Begin implementation**: Fetch the full issue body, understand the requirements, and start working on the issue in the worktree. Do the work -- don't just set up tracking.

   **`lightweight` workflow** (hobby/personal -- no git mechanics):
   - Infer a working folder from context: use cwd, or a folder related to the issue/link, or ask.
   - Create a tmux window: `tmux new-window -n <slug> -c <folder>`
   - Update the topic note: add `folder` and `tmux` fields to frontmatter.
   - Set the topic note's `status` to `in-progress`.
   - No worktree, no branch, no git operations.

**Important**: The injected Current State has the latest config and active topic data. Use it to plan your edits, but you must still read files before modifying them.

### `status`

Answer "where are we on this topic?" -- a recap grounded in the topic's notes, not a CI dashboard. This is the DEFAULT reading of any "status / how's X going / where are we / where'd we leave off / what's the latest / recap / catch me up" ask. Match **intent, not the word** "status": the user usually means the topic's recent status. For pure merge-readiness ("is CI green", "can I merge", "what's failing"), use `pr status` instead -- that verb owns the check/review/mergeable dashboard.

**Read the notes first -- this is a read of the vault, not of GitHub.** Resolve the topic (the active topic, or the one the user named), then:

1. Read the topic note (`obsidian.com read`) -- description, `## Notes`, any `### Next` block.
2. Find its session notes: `obsidian.com search vault=Notes query="<slug>" path="Notes/" format=json` (or the topic's backlinks). Sort by date descending.
3. **Read the most recent session note IN FULL** (`obsidian.com read`) -- frontmatter AND body. Do not stop at the `summary`/`next` fields: the body is where the real detail lives (the arc, findings, the blow-by-blow next-session plan). This is the single most important read for a recap. Read older sessions too when the user wants the whole arc; otherwise the newest one read fully plus older frontmatter for context is enough.

**Lead with that newest session note.** Its content IS the latest status and takes #1 precedence -- convey it faithfully at the detail level the note carries, don't compress it back down to one line. Surface its `next` prominently, and if it names a concrete human action (test this, decide that), put that action item up top -- that's usually the thing the user is actually asking for. Then add supporting context only where it helps: the one-line description, still-open `## Notes` items, and the arc across older sessions when it adds signal (how the approach evolved, what was decided).

Keep PR/CI to **a single line at the end**, and only when a worktree/PR exists and it's cheap. It is not the point of this verb. If a check is genuinely blocking, note it in one line and point to `pr status` / `pr fix`. Do NOT spawn a subagent to gather `gh` data here unless the user explicitly asked about CI or merge-readiness.

If the user refers to several related topics as one thing (a cluster, e.g. "the feature toggle stuff"), recap each one newest-session-first and name the through-line connecting them.

Output shape (narrative, newest-first -- not a status-bar):
```
**<topic>** -- <latest session summary, faithful to the note>
Next: <the latest session's next items; call out any human action item>
<supporting context: description, open ## Notes, approach arc if useful>
<one PR/CI line only if relevant>
```

If no session notes exist yet, lead with the topic note's description + `## Notes` and say there's no session history recorded yet. If no topic matches, say so. Always end with the standard status line (see Output Formatting).

### `topics`

List all topics. Query the base and format as a grouped list:

```bash
obsidian.com open vault=Notes path="templates/Bases/Topics.base"
obsidian.com base:query vault=Notes path="templates/Bases/Topics.base" view="Active" format=json
```

Group by status, render as direct markdown. Exclude `done` and `archived` unless explicitly asked. Show slug (bold), description (first line of note body), issue/PR if present. Within each status group, sort by `last-active` descending (most recent first), falling back to `created` if no `last-active`.

### `recent`

List topics sorted by most recent activity with dates. Query the base, sort by `last-active` descending, and render as a flat list grouped by time period.

```bash
obsidian.com open vault=Notes path="templates/Bases/Topics.base"
obsidian.com base:query vault=Notes path="templates/Bases/Topics.base" view="Active" format=json
```

Output format -- grouped by recency with dates and step:

```
This week
  **auth-refactor** -- Apr 1 -- implementing
  **file-upload-validation** -- Apr 1 -- needs-tests
  **cli-error-messages** -- Mar 27 -- ci-passing

Last week
  **screenshot-capture** -- Mar 26 -- in-review
  **worktree-path-fix** -- Mar 23 -- ready-to-merge

Older
  **date-picker** -- Mar 12 -- implementing
  ...
```

Show `step` if set, otherwise fall back to `status`. Include `last-active` date (or `created` if no `last-active`). Exclude `done` and `archived` unless explicitly asked. Also useful context for `/w advance` -- "advance recent topics" uses this list.

### `kanban`

Render the kanban board visually using a markdown code block with box-drawing characters. Query the base for all active topics, group by status, skip empty columns.

- Open/active cards shown normally, done cards marked differently
- Slug in the card line, links on the next line

```
+-- In Progress -------------------------------------+
| o fix-nav-bug -- Fix navigation bug                |
|   Issue: https://github.com/org/repo/issues/8      |
|                                                     |
| o auth-refactor -- Auth middleware rewrite          |
|   Issue: https://github.com/org/repo/issues/5      |
+-- In Review ---------------------------------------+
| o feature-x-y -- Add jq and rg guides              |
|   PR: https://github.com/org/repo/pull/2           |
+----------------------------------------------------+
```

- Omit empty columns entirely.

### `pr [url]`

Create a PR or link an existing one to the active topic.

**`pr`** (no args) -- Create a new PR:

1. Determine the active topic from the current branch.
2. Check for uncommitted changes in the worktree. If any, stage and commit them first (derive a commit message from the changes, no Co-Authored-By).
3. Rebase on the default branch: `git -C <worktree> pull --rebase origin <default_branch>`. Abort and warn if there are conflicts.
4. Gather context: topic's issue link, branch name, recent commits.
5. Push the branch: `git push -u origin <branch>`.
6. Create the PR: `gh pr create --title "<title>" --body "<body>"` with:
   - Title derived from topic slug or issue title, prefixed with `(WIP) ` when the PR is a draft (see Draft PRs convention).
   - Body with a `## Related issue(s)` section containing just the link on its own line (e.g. `- https://github.com/org/repo/issues/N`). GitHub auto-formats standalone issue/PR links. Never use `Closes` or `Fixes` prefixes.
7. **Apply PR labels** per the repo config's `## PR Labels` section (if present). Add the configured labels when the change matches the rule (e.g. a feature or bug fix touching a shared library) and skip them otherwise (pure refactors, tooling, test-only). The repo config carries the exact labels, path triggers, and apply command.
8. Update the topic note: set `pr` property and set `status` to `in-review`.

**`pr <url>`** -- Link an existing PR to the active topic:

1. Parse the PR URL to extract org/repo/number.
2. Fetch PR metadata with `gh pr view <number> --repo <org/repo> --json title,state,headRefName`.
3. Update the topic note: set `pr` property.
4. If the topic's status is still `backlog` or `in-progress`, set status to `in-review`.

### `pr status`

Show detailed PR status for the active topic. **Use a subagent** to gather all data.

Subagent prompt should include the active topic's PR number and repo, and instruct it to run these exact commands (no `gh api`):

1. `gh pr view <number> --repo <org/repo> --json state,mergeable,reviewDecision,reviews`
2. `gh pr checks <number> --repo <org/repo> --required`

Return only: state, mergeable, reviewDecision, reviewer names + decisions, and any non-passing required checks with their status.

Output should be **problem-focused**. If everything is green, say so in one line. If there are blockers, list only the blockers:

- Non-passing required checks (name + fail/cancelled/pending)
- Review state (who approved, who requested changes, or "no reviews yet")
- Merge conflicts if not mergeable

If all required checks pass, reviews approved, and mergeable -- just say "ready to merge."

### `pr update`

Update the PR branch with the latest base branch via rebase (same as GitHub's "Update branch" button). No local git operations needed.

1. Determine the active topic and its PR number for the current repo.
2. Run: `gh api -X PUT repos/<org>/<repo>/pulls/<number>/update-branch -f update_method=rebase`
3. Report success or failure. If there are merge conflicts, say so.

### `pr rerun`

Re-run failed CI jobs (same as GitHub's "Re-run failed jobs" button).

1. Determine the active topic and its PR for the current repo.
2. Get the latest run ID: `gh pr checks <number> --repo <org/repo> --json link --jq '.[0].link'` and extract the run ID from the URL, or use `gh run list --branch <branch> --repo <org/repo> --limit 1 --json databaseId --jq '.[0].databaseId'`.
3. Re-run only failed jobs: `gh run rerun <run-id> --repo <org/repo> --failed`
4. Report that the re-run was triggered, then **watch it to completion** (see `pr fix` step 9) rather than treating the trigger as a pass. If the same tests fail again, escalate per `pr fix` step 10.

### `pr merge`

Merge the active topic's PR and update tracking.

1. Determine the active topic and its PR number for the current repo.
2. Ask the user to confirm the merge.
3. Merge in one call: `gh pr merge <number> --repo <org/repo> --merge --delete-branch`
4. Update the topic note: set `status` to `done`, set `completed` to today's date.
5. Offer to clean up the worktree (same flow as `done`).

### `pr check <name>`

Investigate a specific failing CI check. **Use a subagent** to fetch and parse the log -- CI logs can be very large, so the subagent must absorb the output and return only the relevant failure info.

1. Run `gh pr checks <number> --repo <org/repo> --json name,link,state,bucket` to find the check matching `<name>` (fuzzy match -- user might say "unit tests" for "Unit Tests").
2. Extract the **job ID** from the check's link URL -- it's the last segment: `.../actions/runs/<run-id>/job/<job-id>`.
3. Subagent prompt should include the job ID and repo, and instruct it to fetch the failure from the smallest source that reveals it:
   - First try annotations: `gh api repos/<org>/<repo>/check-runs/<job-id>/annotations` -- often returns the assertion message directly without downloading the log.
   - If empty, pull the raw log: `gh api repos/<org>/<repo>/actions/jobs/<job-id>/logs`, then grep for `failing`, `AssertionError`, `Error`, `✖`, `Failing:\s+[1-9]`, and test file paths.
   - **Do NOT use `gh run view --log` / `--log-failed`** -- on GitHub Enterprise they return empty (silent, exit 0). The `gh api .../actions/jobs/<job-id>/logs` endpoint is the only thing that works there.
   - For Enterprise PRs, prefix calls with `GH_HOST=<ghe-host>` (or run inside the repo so gh infers the host).
   - Return only: failing test name(s), error message, file path and line number if available, and a brief summary of what went wrong. Do NOT return the full log -- summarize.
4. Output the subagent's result as direct markdown. Example:

```
**Unit Tests** -- 1 failing

  X FileInput.unit.spec.js:42
    "should render selected file on review page"
    Expected: "document.pdf"
    Received: "[object Object]"
```

If `<name>` is omitted, investigate all non-passing required checks (run the subagent for each).

### `pr fix [name|PR-url]` -- fix CI

Triage failing CI, then **reproduce locally and fix it** when the failure is caused by this branch. Matches "fix ci", "fix the ci", "ci fix", "fix failing checks", and "fix this `<PR/CI link>`", plus `pr fix`. Takes an optional PR/issue/run link (otherwise uses the active topic). This verb changes code, commits, and pushes, so use **visible** tool calls (not a subagent) for the repro/fix/commit/push steps; the triage step may still use a subagent like `pr check`.

**1. Resolve the PR, repo, and topic.** Infer the target without asking when you can:

- **A link is given** (PR, issue, or `.../actions/runs/...` job URL -- "fix this `<link>`"): parse org/repo from it. A PR URL gives the number directly; for an issue or run link, resolve the PR (the run's head branch, or the matching topic's `pr` field). Then `gh pr view <number> --repo <org/repo> --json number,headRefName,state,title`. For Enterprise links, prefix with `GH_HOST=<ghe-host>`. Map the link to its **topic** by querying the base for one whose `pr`, `issue`, or `branch` matches, and reuse that topic's worktree if it has one.
- **No link given** ("just fix ci"): use the **active topic** -- the injected `=== Active Topic ===`, resolved from the current git branch / cwd. Its `pr` field is the target.
- **No topic matches** the link or branch: still fix the PR directly off `<headRefName>`, and note that no topic was found (you may suggest `/w topic <url>` to start tracking it). Don't block on it.

**2. Triage the failures** (same mechanics as `pr check`): list failing checks, fetch each failing job's log via `gh api repos/<org>/<repo>/actions/jobs/<job-id>/logs` (never `--log-failed`), and pull out each failing test's file:line + error message.

**3. Get a worktree on the PR's branch.** The branch already exists -- check it out, do NOT branch off `<default_branch>`.

- If a topic/worktree already exists for `<headRefName>`, reuse it.
- Else create one: `git -C <repo-root> fetch origin <headRefName>` then `git worktree add <repo-root>.worktrees/<headRefName> <headRefName>` (if there's no local branch yet, use `git worktree add <path> --track -b <headRefName> origin/<headRefName>`).
- Bootstrap a freshly created worktree: run the repo config's `## Install` command (e.g. `yarn install`). Skip when reusing an already-installed worktree.

**4. Reproduce each failing test locally** in the worktree:

- Unit: `yarn test:unit <file>`.
- Cypress/E2E: start the dev server for the app, then `yarn cy:run --spec "<file>"` (see the repo's Cypress workflow). If standing the E2E up is impractical, say so rather than guessing at a fix.

**5. Decide related vs not** for each failure:

- **Related** -- the failing test covers code this branch touches (cross-check `git -C <worktree> diff origin/<default_branch>...HEAD`) AND it fails locally on the branch. When unsure, confirm the same test passes on `origin/<default_branch>`.
- **Not related / flaky** -- it also fails on `<default_branch>`, or it's an unrelated app's timeout / known flake (e.g. a Cypress 4s retry timeout in an app the diff doesn't touch). Do NOT change code for these.

**6. Fix the related failures** in the worktree. Re-run the same test command to confirm it passes. Lint the changed files (`yarn lint --fix` or the repo config's lint command).

**7. Commit and push the fix.**

- Stage only the files you changed. Show the commit message + file list (don't paste full diffs).
- Commit with a short message describing the fix (no `Co-Authored-By` -- the hook enforces this).
- `git push`. The push hook asks for confirmation -- that is the gate.

**8. Update tracking + report.** Set the topic's `last-active`; once green, if its `step` was `ci-failing`, set it to `ci-passing`. Then report per-failure:

- `fixed` -- what was wrong, what changed, and the pushed commit.
- `flaky` / `unrelated` -- why it isn't this branch's fault. For these, **don't stop at "re-run triggered"** -- kick off `pr rerun` and continue to step 9.

**9. Watch the run to completion yourself -- detecting "CI is done" is YOUR job, never the user's.** After any push-fix, rebase, or `pr rerun`, *you* own the wait. Do **not** ask the user "is it done?", do **not** wait to be told, and do **not** evaluate results, query required checks, draw a verdict, or move to step 10 until the run has actually **settled**. A triggered or pending run is not a result. A *different* background task finishing (e.g. a triage subagent) is **not** the CI finishing -- only the CI watcher firing tells you the run is done.

- **Wait with a background poll** (one wake-up when the run finishes), launched with `run_in_background`. Not a subagent (subagents just burn tokens polling), not a fixed `sleep`, not the user. For babysitting that spans many re-runs over hours, `/loop` is the heavier alternative.
- **Key the watcher on the new head SHA and use two phases**: first wait for the fresh run to *start* (pending checks appear on the new commit), then wait for it to *finish*. A naive `while gh pr checks | grep -q pending` exits immediately after a rebase/push, because the new run's checks have not registered yet and it misreads the *old* commit's settled state as "done".
  ```bash
  # YOU launch this with run_in_background. Capture the new head SHA first.
  SHA=$(GH_HOST=<ghe-host> gh pr view <n> --repo <org/repo> --json headRefOid --jq .headRefOid)
  P='[.statusCheckRollup[]|select(.status|IN("QUEUED","IN_PROGRESS","PENDING","WAITING"))]|length'
  # phase 1: wait until the FRESH run (new SHA) has started -- pending checks exist
  until r=$(GH_HOST=<ghe-host> gh pr view <n> --repo <org/repo> --json statusCheckRollup,headRefOid) \
    && [ "$(jq -r .headRefOid <<<"$r")" = "$SHA" ] && [ "$(jq "$P" <<<"$r")" -gt 0 ]; do sleep 30; done
  # phase 2: wait until it finishes -- nothing pending
  until [ "$(GH_HOST=<ghe-host> gh pr view <n> --repo <org/repo> --json statusCheckRollup --jq "$P")" = 0 ]; do sleep 120; done
  echo CI_SETTLED
  ```
- **Size the cap to the repo's CI duration -- don't under-cap.** A large monorepo's CI can run **30 to 60 minutes**, usually gated on one long regression suite. Give phase 2 ~90 to 100 min of headroom (e.g. 50 iterations x 120s) so an hour-long run finishes inside it, and poll every 90 to 120s, not faster -- the runs are long and the gh calls add up.
- **On the completion notification** (`CI_SETTLED`), re-read `gh pr checks <n> --repo <org/repo>` and only **then** evaluate. If the watcher times out without settling, re-check once and re-arm it -- do not conclude from a timeout.
- **Green** -> done. Finish step 8's tracking update and report.
- **Same test(s) failed again** -> it's persistent, not a one-off flake. Go to step 10.

**10. Escalate a persistent failure** (recurs after a re-run). Surface your recommendation at each branch -- say what you'd do and why, and let the user redirect.

  a. **Rebase on latest main first** (cheap, often enough). A newer base commit may already contain the fix. Run `pr update` (or rebase the worktree on `origin/<default_branch>`), then return to step 9 and watch. Cap this at ~2 rerun/rebase cycles before spending effort on a repro.

  b. **Confirm ownership -- ours or someone else's?** Cheapest signal first:
  - **Is the same check red off our branch?** Check recent base CI and a couple of sibling PRs: `gh run list --branch <default_branch> --repo <org/repo> --limit 5` plus other open PRs' `gh pr checks`. If the same test is failing elsewhere, it's environmental/base -- not ours.
  - **Reproduce on a clean base** when that's inconclusive. Make a throwaway worktree on the **latest** `origin/<default_branch>` -- **never check out `<default_branch>` itself** (the user is usually working there):
    ```bash
    git -C <repo-root> fetch origin <default_branch>
    git worktree add <repo-root>.worktrees/_ci-base-check origin/<default_branch> --detach
    ```
    Reproduce the exact failing test there, then `git worktree remove` it. Caveat: a **test-pollution flake passes alone but fails in-shard**, so running the single file proves little -- reproduce within the same multi-file run/shard, or lean on the "red elsewhere" signal instead.
  - **Verdict:** fails on the clean base too -> **not our branch**. Passes on the clean base but fails on ours -> it **is** ours; go back to step 6 and fix it (triage misjudged it).

  c. **If it's not our branch** (broken base / another team's flake):
  - **Easy fix** (obvious, low-risk, clear owner): be proactive. Find the owning team via `.github/CODEOWNERS` (or `git blame` on the failing file), then spin up a **separate work topic + branch + draft PR** to fix it for them (normal `topic`/`issue` -> implement -> draft-PR flow). Link that PR back to our blocked PR so reviewers see why ours is red.
  - **Hard fix** (non-trivial, unclear root cause, risky, or unsafe for us to touch): **pause and recommend a support ticket** and/or pinging the owning team in Slack. Don't sink unbounded effort into another team's code.

  d. **Keep our PR moving.** Once the failure is confirmed external (and either handed off or a known flake), our PR shouldn't stay hostage: keep re-running until the flake passes (flakes usually pass on retry), and note in the PR that the red check is a known external failure, linking the tracking issue/ticket.

**Stop conditions** -- the loop ends when **CI is green**, OR the failure is **identified as external and handed off** (separate PR or support ticket), OR you hit the rerun/effort cap and **pause with a recommendation**. Don't loop silently forever.

**Do not**:

- Change code for tests that also fail on `<default_branch>` -- that's not this branch's regression.
- Declare success on a *triggered* re-run -- watch it settle first (step 9).
- `pr rerun` to mask a failure you haven't yet confirmed is external/flaky.
- Sink unbounded effort into another team's broken test -- hand it off (step 10c) instead.
- Create a PR or flip **our** branch to ready -- this operates on an existing PR. (The *separate* fix-it-for-them PR in step 10c is the one exception, and it stays draft.)
- Touch unrelated files in our branch.

### `prs`

List all PRs across topics. Query the base for topics with PR fields, then **use a subagent** to fetch live status.

Subagent prompt should include the list of PR URLs extracted from the base query, and instruct it to:

1. For each PR, run `gh pr view <number> --repo <org/repo> --json state,reviews,statusCheckRollup`.
2. Return: slug, PR number, state, CI summary (passing/failing/pending), review count, repo.

Then output the subagent's result as a direct markdown table:

```
feature-x-y    PR #2 open   CI: --      0 reviews   <user>/<repo>
fix-nav-bug    PR #5 open   CI: passing 1/2 approved <user>/other-repo
```

If no PRs exist, say so.

### `issue <title> [start]`

Create a new GitHub issue on the current repo and optionally start working on it.

1. **Build the issue** from the title and any additional context the user provides.
   - Check the repo config for an **Issues** section -- follow its format for body structure, default labels, assignee, etc.
   - If no repo config, ask the user for a brief description to use as the body.
2. Show the full issue details: title, body, labels, assignee, project, milestone (see Confirmations convention).
3. Create the issue:
   ```bash
   gh issue create --repo <org/repo> --title "<title>" --body "<body>" \
     --label "<label>" --assignee "<assignee>" --milestone "<milestone>"
   ```
   Include flags only for fields that are configured or provided.
4. **If a project is configured**: add the issue to the project and set fields:
   ```bash
   gh project item-add <project-number> --owner <org> --url <issue-url>
   ```
   Then set status and sprint via GraphQL mutations. To find the new item's ID, query `items(last: 5)` on the project and match by issue URL. **Do not use `gh project item-list`** as it paginates through all items and is extremely slow on large projects. If the repo config has cached field/option IDs, use them directly instead of querying `fields(first: N)` each time.

   **Always auto-detect the current sprint at runtime -- do not trust the cached `Sprint:` value in the repo config.** Iterations roll over every 1-2 weeks, and a stale cache silently assigns new issues to the previous sprint. Query the project's iteration field and pick the iteration where `startDate <= today < startDate + duration`:
   ```bash
   gh api graphql -f query='{ organization(login:"<org>") { projectV2(number: <n>) { field(name:"Sprint") { ... on ProjectV2IterationField { configuration { iterations { id title startDate duration } } } } } } }'
   ```
   Use the detected iteration's `id` in the `updateProjectV2ItemFieldValue` mutation. When the detected sprint differs from the one cached in the repo config, update the config's `Sprint` line and iteration ID so it stays fresh.

   **Fallback if `gh project item-add` fails with `unknown owner type`** (observed for some repo URLs even when it works for others in the same org): use the GraphQL mutation directly. Get the issue's node ID, then add via `addProjectV2ItemById` — this also returns the new item ID immediately, so you can skip the `items(last: 5)` lookup:
   ```bash
   gh issue view <number> --repo <org/repo> --json id --jq .id
   gh api graphql -f query='mutation { addProjectV2ItemById(input: {projectId: "<PROJECT_NODE_ID>", contentId: "<ISSUE_NODE_ID>"}) { item { id } } }'
   ```
5. If `start` is present:
   - Automatically create a topic from the new issue (same flow as `topic <issue-url> start`).
   - This creates the topic note, worktree, and begins implementation.
6. If no `start`: offer to create a topic from it.

**Creating bug tickets from informal input (Slack threads, chat, a loose report)**

When the input is an unstructured bug report rather than a clean title, distill it into a proper ticket instead of pasting it verbatim.

1. **Write a precise title**: `[bug] <symptom>`. Turn the vague phrasing ("potential bug with the upload component") into a symptom-first title that says what is wrong and where (e.g. `[bug] File input (upload) shows error state instead of loading state while revalidating password`). Do not restate "X is broken."
2. **Structure the body** to match the reference:
   - Lead with reporter attribution and the Slack permalink: `Reported by <name> on this [thread](<slack-url>):`
   - Then the reproduction steps / description, cleaned of Slack chrome (timestamps, "3 replies", "Hi team" intros, reply-author headers). Keep the reporter's own wording for the actual steps.
   - Put any screenshot or video attachment URL on its own line at the bottom.
3. **Apply the bug defaults** from the repo config's Bug tickets guidance: label `bug` plus the relevant area label (infer from the component or feature mentioned), assign the PM, and place it on the board as **New with no sprint**. A filed bug ticket goes to the PM to triage and schedule, not into your current sprint or In Progress. This **overrides** the sprint auto-detection in step 4 below.
4. **Fill the gaps before creating (the "if we don't have the info" case).** Check for the essentials and ask in one short plain-text batch (not multiple-choice) for anything you cannot infer:
   - The **Slack thread permalink**, if it was not pasted. It is needed for the attribution line and is the one thing you cannot derive from the pasted text. Ask the user to paste it ("Copy link" on the Slack message).
   - Any **screenshot or video** to embed.
   - The **area label**, if the text does not make it obvious.

   Extract the reporter's name and steps from the pasted text when present; only ask for what is actually missing. Do not block on details you can reasonably infer.

Then continue with the normal flow above (show the full ticket for confirmation, create it, add it to the board), except set Status **New** and leave the sprint **unset** instead of auto-detecting the current sprint.

### `auto <title|issue-url>`

Run the full issue-to-draft-PR pipeline end-to-end without stopping for per-step confirmation. The user invokes `auto` when they want "just do the whole thing" -- matches any `/w` request that contains the literal token **`auto`** (e.g. `/w auto fix the nav bug`, `/w <issue-url> auto`).

**Intent**: the user is trusting the skill to make reasonable defaults for issue body, commit message, and PR body. You still *show* what is being created (print title + body before running `gh` so they can interrupt), but do not *wait* for confirmation. Treat this as authorization equivalent to Auto Mode.

**Pipeline**:

1. **Create the issue** (same as `issue <title>`): auto-detect current sprint at runtime, apply repo-config defaults (labels, assignee, project, type). Keep body terse -- facts only, no launch framing.
2. **Start the topic** (same as `topic <issue-url> start`): create topic note, create worktree off `origin/<default_branch>`, bootstrap the worktree (run the repo config's `## Install` command).
3. **Implement the change** in the worktree. Fetch the full issue body; do the actual work; follow repo code style.
4. **Capture screenshots for any UI change.** If the repo config has a `## Screenshots` section, follow its command template. Prefer a single self-serving e2e command that self-serves the dev server on a free port -- do not start `yarn watch` separately. Write a one-off `*.cypress.spec.js` that visits the changed route(s).

   **Frame the screenshot around only what changed, not the whole page.** Three options, in preference order:

   a. **Tight clip via bounding-rect math** -- best when the change is one section of a long page and you want to exclude the site header, page title, unrelated sections, etc. Scroll the element into view, read `getBoundingClientRect()` for the top-most and bottom-most relevant nodes, and pass a `clip` to `cy.screenshot({ capture: 'viewport', clip: { x, y, width, height } })` with a small padding. Crop width is usually ~500-700px so the image reads well inline in a PR body.
   b. **Element screenshot** (`cy.get(selector).screenshot(name)`) -- simpler, but Cypress occasionally cuts off when the element is taller than the viewport or has absolutely-positioned children.
   c. **`capture: 'fullPage'`** -- last resort. Stitches multiple viewport captures and produces duplicate content bands on pages with sticky headers. Avoid unless the change genuinely spans the whole page.

   Delete the demo spec before committing unless the user asked to keep it.
5. **Commit** (no Co-Authored-By trailer) and **push** the branch.
6. **Upload screenshots** to the repo config's `## Screenshot Host` repo under `<branch-slug>/<name>.png`. Reference `raw.githubusercontent.com` URLs in the PR body. Do not try `gh gist create` for PNGs -- it rejects binaries. If no host is configured, skip screenshots and flag it in the summary.
7. **Create a draft PR** (`gh pr create --draft`) with the title prefixed `(WIP) ` (see Draft PRs convention) and the PR body from the repo config's `## PR` template, with screenshots embedded under the `## Screenshots` section. Apply PR labels per the repo config's `## PR Labels` section when the change matches (feature or bug fix touching a shared library).
8. **Update tracking**: set the topic note's `pr` property and `status: in-review`, and move the project board item to `PR Review` (repo config has the option ID).
9. **Summarize**: return the issue URL, PR URL, and a one-line status line.

**Do not**:

- Ask for confirmation between steps.
- Commit unrelated files (e.g. demo specs, ad-hoc screenshots) into the branch.
- Submit as a ready PR -- always draft. The user flips to ready after review.

If any step fails hard (e.g. install, push), stop and report. Do not paper over with fallbacks.

### `issues`

List issues linked to topics. Query the base for topics with issue fields, then **use a subagent** to fetch live status.

Subagent prompt should include the list of issue URLs extracted from the base query, and instruct it to:

1. For each issue, run `gh issue view <number> --repo <org/repo> --json state,title,labels`.
2. Return: slug, issue number, state, title, repo.

Then output the subagent's result as a direct markdown table:

```
feature-x-y    #1 open    Add guide for X and Y    <user>/<repo>
fix-nav-bug    #8 closed  Navigation bug           <user>/other-repo
```

If no issues exist, say so.

### `scan [sprint]`

Check the GitHub project board for new work assigned to the user. Creates topics for new sprint issues and updates existing topics with board changes. This is specifically about the **project board** -- for reconciling local state (worktrees, PRs, statuses), use `sync` instead.

Requires a repo config with an `## Issues` section that includes `Project` and `Assignee` fields.

**Sprint detection**: If no sprint argument given, auto-detect the current sprint by querying the project's iteration field and matching against today's date. Each iteration has `startDate` and `duration` -- the current sprint is the one where `startDate <= today < startDate + duration`.

**Data fetching**: Use a single GraphQL query with the `items(query:...)` filter on `ProjectV2`. The `query` parameter supports the same syntax as the GitHub Projects UI filter bar:

```graphql
{
  organization(login: "<org>") {
    projectV2(number: <project-number>) {
      items(first: 100, query: "sprint:\"<Sprint Name>\" assignee:<username>") {
        totalCount
        nodes {
          fieldValues(first: 10) {
            nodes {
              ... on ProjectV2ItemFieldSingleSelectValue {
                name
                field { ... on ProjectV2SingleSelectField { name } }
              }
              ... on ProjectV2ItemFieldNumberValue {
                number
                field { ... on ProjectV2Field { name } }
              }
              ... on ProjectV2ItemFieldIterationValue {
                title
                field { ... on ProjectV2IterationField { name } }
              }
            }
          }
          content {
            ... on Issue {
              number
              title
              url
              state
              repository { name nameWithOwner }
            }
          }
        }
      }
    }
  }
}
```

This filters server-side -- no pagination needed for typical sprint sizes.

**Reconciliation**: Query the base for all topics, then match against sprint issues by issue URL.

**Board -> Topics (inbound sync):**

1. **New issues** (on board but no matching topic): auto-create a topic note with `status: backlog`. No worktree, no branch -- just tracking. Include `sprint`, `points`, `repo`, and `board-status` in frontmatter. The base picks it up automatically.
2. **Status changes**: Map board statuses to topic statuses and update if they differ:
   - Board `New` / `Ready for work` -> `backlog`
   - Board `In Progress` -> `in-progress`
   - Board `PR Review` -> `in-review`
   - Board `Closed` -> `done` (set `completed` date)
   - If the repo config defines custom status mappings in the Issues section, use those instead.
3. **Closed issues**: If an issue's `state` is `CLOSED` and the topic isn't `done`, set status to `done` and add `completed` date.
4. **Field updates**: Update `points`, `board-status`, and `sprint` on existing topics if they've changed on the board.

**Topics -> report (outbound awareness):**

5. **Topics not on the board**: Topics that have an issue URL but that issue isn't in the current sprint -- flag as "not in sprint" so the user knows they're working on something unscheduled. Don't modify them, just note it.

**Property updates**: Use `obsidian.com property:set` for individual field changes instead of read-modify-overwrite:
```bash
obsidian.com property:set vault=Notes name=status value=done path="Notes/<Name>.md"
obsidian.com property:set vault=Notes name=sprint value="Sprint 26" path="Notes/<Name>.md"
obsidian.com property:set vault=Notes name=points value=5 type=number path="Notes/<Name>.md"
```

**Output**:

```
Sprint 26 (2026-03-30 -- 2026-04-12) -- 6 issues, 18pts

Synced:
  . #101 date-picker            in-progress  5pts
  . #102 auth-refactor          in-progress  3pts

New (created topics):
  + #103 deprecate-legacy-link  backlog      --pts
  + #104 onboarding-docs        backlog      5pts

Closed (moved to done):
  v #105 worktree-path-fix      done         2pts

Not in sprint:
  ? #106 review-heading-levels  in-progress
  ? #107 incomplete-dates       in-progress
```

The output is a reconciliation report showing what changed. When run via `/loop`, it operates silently (no confirmations) -- just syncs and reports.

**Sprint config update**: If the detected current sprint differs from the one cached in the repo config, update the repo config's `Sprint` field and cache the new iteration ID.

### `sync`

Reconcile the local ecosystem: worktrees, topic notes, GitHub PRs, and statuses. Auto-fix obvious drift, only prompt for ambiguous cases. **Use a subagent** to gather all external data, then apply fixes and report.

**Data gathering** (subagent collects all of this in parallel):

1. **Worktrees**: List all directories in `<repo-root>.worktrees/` and `<repo-root>-agent.worktrees/` for each active repo. For each worktree, get the branch name and latest commit date (`git -C <wt> log -1 --format=%aI`).
2. **Topics**: Query the base for all non-done/non-archived topics.
3. **Open PRs**: `gh pr list --author=@me --repo <org/repo> --json number,title,url,headRefName,state,reviewDecision,statusCheckRollup --limit 30` for each active repo.
4. **Recently merged PRs**: `gh pr list --author=@me --repo <org/repo> --state merged --json number,title,url,headRefName,mergedAt --limit 10` for each active repo. Filter to last 14 days.

**Reconciliation rules** (applied automatically):

| Situation | Action |
|-----------|--------|
| **Worktree exists, no topic** | Create topic note (slug from dir name, branch from git, worktree path, status `in-progress`) |
| **Topic has PR, PR is merged, topic not `done`** | Set status to `done`, set `completed` to merge date |
| **Topic has PR, PR is closed (not merged)** | Flag as ambiguous -- ask user |
| **Open PR exists, no matching topic** | Create topic note (slug from branch, link PR, status `in-review`) |
| **Topic has worktree path, worktree doesn't exist** | Remove `worktree` property from topic. If status is `in-progress`, flag for user |
| **Topic status is `in-review` but PR checks are all passing + approved** | Note as ready to merge in report |
| **Topic status is `in-progress` but has a PR** | Update status to `in-review` |
| **Topic has no `last-active`** | Backfill from worktree's latest commit date, or from PR activity, or `created` as fallback |
| **Topic `last-active` is older than worktree's latest commit** | Update `last-active` to latest commit date |
| **Topic has issue URL, issue is closed on GitHub** | Set status to `done`, set `completed` date |

**Ambiguous cases** (prompt the user):

- PR closed without merge -- abandon topic or keep?
- Worktree exists but branch has no commits ahead of default branch -- stale setup?
- Topic has status `in-progress` but no worktree and no recent activity (>30 days) -- stale?

**Output**: A reconciliation report grouped by action type.

```
Sync complete -- 3 fixed, 1 created, 2 flagged

Auto-fixed:
  . date-picker -- last-active updated to 2026-04-01
  . screenshot-capture -- status -> done (PR #112 merged 2026-03-28)
  . auth-refactor -- status -> in-review (has open PR)

Created:
  + cli-error-messages -- new topic from orphan worktree

Flagged:
  ? email-overflow -- worktree exists, 0 commits ahead, stale?
  ? old-auth-fix -- PR #98 closed without merge, abandon?

Ready to merge:
  > worktree-path-fix -- PR #113 approved, CI passing
```

**Repos to scan**: Derive from the active repos in the workspace (the repos you actually work in) plus any additional repos referenced in existing topics' `repo` fields.

### `code`

Open the active topic's worktree in VS Code.

1. Determine the active topic and find its worktree path from the topic note.
2. If the topic has a worktree: `code <worktree-path>`
3. If no worktree (e.g. non-dev topic), say so.

### `run [slug]`

Start the dev server for the active topic's application and provide the localhost URL.

**Check for per-repo run config first** (see Repo Config). If the injected `=== Repo Config ===` contains a `## Run` section, use its `Command`, `Port`, and `URL` fields. Otherwise, fall back to monorepo auto-detection.

**With repo config `## Run` section:**

1. Determine the active topic and find its worktree or folder.
2. Parse the `## Run` section: `Command`, `Port`, `URL` (URL may contain `{port}` placeholder).
3. If the configured port is already in use, warn and show the URL without starting a new process.
4. Start the dev server: `nohup <command> > /tmp/run-<slug>.log 2>&1 &`
5. Wait for the port, then output the URL.

**Without repo config (monorepo fallback):**

1. Determine the active topic (by slug arg, current branch, or cwd) and find its worktree.
2. Detect which app(s) are modified: `git diff --name-only origin/<default_branch>...HEAD` filtered to `src/applications/`.
3. Find `manifest.json` in the changed app directory. Extract `entryName` and `rootUrl`.
4. If port 3001 is already in use, warn and show the URL without starting a new process.
5. Start the dev server: `nohup yarn watch --env entry=<entryName> > /tmp/yarn-watch-<slug>.log 2>&1 &`
6. Wait for port 3001, then output the URL: `http://localhost:3001<rootUrl>`

If multiple apps are changed, join entry names with commas and show all URLs.

### `inspect [slug]`

Prep a manual hand-test so the user can QA the change with zero setup, like driving through a car wash. Matches `inspect`, `inspection`, `inspection time`, `qa`, `try`, `ready to test`, `hand test`.

**The contract**: this verb preps and then **stops**. It is for the *human* to inspect. Do NOT drive the change, click through it, run Cypress, or take screenshots. The agent sets up the bay (server + URL + checklist); the user walks the change. (Contrast with `verify` / `show me`, where the agent exercises the change itself.)

Steps:

1. **Start the server** exactly like `run` (reuse the `## Run` repo config if present, else the monorepo fallback). Difference: if the configured port is already in use by **another** topic, pick the next free port instead of refusing, so this topic can be inspected alongside others. Pass the chosen port to the dev server (e.g. `yarn watch --env entry=<entry> --port <port>`).
2. **Resolve the URL(s)** to the changed app. Deep-link to the affected route where one is derivable (read the changed app's `manifest.json` `rootUrl`; for forms this is typically the intro/start route). Output the full `http://localhost:<port><rootUrl>`.
3. **Generate the inspection checklist** from the topic note (`## Notes`, description, origin/bug context) plus the diff (`git -C <worktree> diff origin/<default_branch>...HEAD`). Render as bullets:
   - **Steps**: the click-path to reach and trigger the change.
   - **Expect**: the observable result, framed before/after when the change has a visible effect.
   - If the change touches multiple consumers/pages, list each one's route and steps.
4. **Stop.** Print the URL and checklist as direct markdown and end. Do not proceed to test it yourself.

Update `last-active` on the topic (this is a working interaction, same as `run`).

**Output shape:**

```
Inspect **file-upload-validation** -- server up on :3001

http://localhost:3001/example-form (upload step)

Steps:
- Upload a file, then pick a document type
- Replace the file with a different one
Expect:
- Before: doc-type stays selected, Continue blocked by a stale required error
- After: doc-type select resets to blank, Continue is not blocked

Also check the same flow on:
- /other-form (upload documents page)
- /third-form (supporting evidence pages)
```

### `done [slug]`

Mark a topic as done. Uses active topic if no slug given.

1. Update the topic note: set `status` to `done`, set `completed` to today's date.
2. If the topic has a worktree:
   - Ask the user if they want to clean it up.
   - If yes: `git worktree remove <path>` and remove the worktree property from the topic note.
   - If the branch is fully merged, offer to delete it: `git branch -d <branch>`.

### `archive [slug]`

Set completed topics to archived status. The topic note persists in the vault as history.

- If `slug` given: archive that specific topic.
- If no slug: archive all topics with `status: done`.

Steps:

1. Set the topic note's `status` to `archived`.

Topic notes are the long-term log. The base's "Active" view filters out archived/done topics automatically.

### `remove <slug>`

Delete a topic entirely -- the vault note itself.

1. Ask the user to confirm (destructive action).
2. If the topic has a worktree, offer to remove it: `git worktree remove <path>`.
3. If the topic has a local branch, offer to delete it: `git branch -d <branch>`.
4. Delete the topic note: `obsidian.com delete vault=Notes path="Notes/<Name>.md"`

### `reset`

Fresh board -- wipe all topics and start clean.

1. Ask the user to confirm (destructive action). List all topics that will be removed.
2. For any topics with worktrees, offer to clean them up first.
3. Delete all topic notes from the vault (or ask which to keep).

### `switch <slug>`

Switch the active topic. Fuzzy-match slug against topics from the base.

1. Query the base to find the matching topic. Read the topic note for full detail.
2. If the topic has a worktree: `cd <worktree-path>` so subsequent Bash commands operate there.
3. Print the status line for the switched topic.
4. If the topic has a PR, briefly show its state (one line -- same as `status` summary).

If the topic has no worktree (freeform/non-dev topic), just acknowledge the switch and show the status line.

### `wrap`

End-of-session synthesis. Creates a session note from the conversation context and git state -- no user input needed. See [docs/wrap.md](docs/wrap.md) for full spec.

### Catch-all

If the arguments don't match a known verb, interpret the user's intent in the context of work topics. Common patterns:

- `note <text>` -- append to the active topic's `## Notes` section (the scratchpad area in the note body).

Use your best judgment. If truly ambiguous, ask.

### `advance`

Move a topic forward through its lifecycle -- from context gathering through setup, implementation, shipping, and cleanup. Detects where the topic is and performs the next logical step. See [docs/advance.md](docs/advance.md) for the full pipeline spec.

## Subagents

Use the Task tool (`subagent_type: "general-purpose"`) for **read-only commands that gather external data**: `status`, `pr status`, `prs`, `issues`. This hides intermediate Bash calls (git, gh) from the user and avoids output truncation.

**How**: Build a prompt with all the context the subagent needs (topic details, PR numbers, repo slugs from the injected state). The subagent runs the Bash commands, and returns structured data. You then output the result as direct markdown text.

**Do NOT use subagents for**: commands that modify state (`topic`, `pr` create/merge, `done`, `remove`, `reset`, etc.) -- those need visible tool calls so the user can confirm actions.

## Output Formatting

Render all structured output as **direct markdown text** -- never use `echo -e` or Bash for display. This avoids noisy `Bash(...)` wrappers and output truncation in the Claude Code UI.

### Formatting conventions

- **Bold** (`**text**`) for topic slugs and emphasis
- `code spans` for PR numbers, branch names, commands
- Standard markdown tables for tabular data (topics, issues, prs)
- Code blocks with box-drawing characters for kanban

### Status line

**Every** `/w` response must end with a status line rendered as direct text (not via Bash):

```
--- **topic-slug** | repo-name | PR #N | CI: status | status
```

Fields:

- `topic-slug`: active topic (or `no active topic`)
- `repo-name`: current repo (short name, not full URL)
- `PR #N`: PR number if exists, `no PR` otherwise
- `CI: status`: `passing`, `failing`, `pending`, or `--` if no PR
- `status`: the topic's current status from frontmatter

If no config exists yet (pre-setup), omit the status line.

## Data Formats

### Topic Note (`Notes/<Human Name>.md`)

Each topic is an individual Obsidian vault note. The file name is a human-readable name (e.g. `Auth Refactor.md`, `Fix Nav Bug.md`). Metadata lives in YAML frontmatter; the body is freeform context.

```markdown
---
categories:
  - "[[Topics]]"
status: in-progress
slug: auth-refactor
created: 2026-02-16
issue: https://github.com/org/repo/issues/5
pr: https://github.com/org/repo/pull/123
branch: auth-refactor
worktree: /home/user/projects/my-app.worktrees/auth-refactor
sprint: Sprint 26
points: 5
repo: org/repo
board-status: In Progress
---

Auth middleware rewrite to support new token format.

## Notes
- Confirm the new token format with the API team
- API returns dates as epoch, not ISO

![[Backlinks.base]]
```

**Frontmatter fields:**

- `categories`: always `["[[Topics]]"]`
- `status`: lowercase -- `general`, `backlog`, `in-progress`, `in-review`, `done`, `archived`
- `step`: lifecycle step tracked by advance -- `needs-context`, `needs-setup`, `ready`, `implementing`, `needs-tests`, `needs-attention`, `ready-to-ship`, `ci-failing`, `ci-passing`, `changes-requested`, `ready-to-merge`, `done`, `archived`. See [docs/advance.md](docs/advance.md) for the full state machine.
- `slug`: the kebab-case identifier (matches branch name)
- `created`: date created (YYYY-MM-DD)
- `completed`: date completed (YYYY-MM-DD, added when done)
- `issue`: GitHub issue URL (optional)
- `pr`: GitHub PR URL (optional)
- `branch`: git branch name (optional, `full` workflow)
- `worktree`: worktree path (optional, `full` workflow)
- `folder`: working directory (optional, `lightweight` workflow)
- `tmux`: tmux window name (optional, `lightweight` workflow)
- `sprint`: sprint name, e.g. "Sprint 26" (optional, set by `scan`)
- `points`: story points (optional, set by `scan`)
- `repo`: repo slug e.g. "org/repo" (optional, set by `scan`)
- `board-status`: raw status from the GitHub project board (optional, set by `scan`)
- `last-active`: date of last interaction (YYYY-MM-DD, auto-updated)

Only include fields that are relevant. Don't add blank fields.

The description line (first line after frontmatter) is a one-line summary. The `## Notes` section is a scratchpad for persistent context and open items -- `wrap` folds addressed items into session notes. The `![[Backlinks.base]]` embed at the end is an Obsidian convention -- preserve it when creating notes. Session notes linked to this topic appear automatically via backlinks.

### Session Note (`Session/<topic-slug> <YYYY-MM-DD>.md`)

Each session is an individual Obsidian note created by `wrap`. See [docs/wrap.md](docs/wrap.md) for the full format and creation spec.

### Topics Base (`templates/Bases/Topics.base`)

The Obsidian Base that provides table views over all topic notes. It queries notes with `categories: [[Topics]]` and surfaces frontmatter as columns. Views: `All`, `Active`, `In Progress`, `Done`.

The base is read-only from the skill's perspective -- it's a view, not a data store. All mutations go through topic notes.

To query:
```bash
obsidian.com open vault=Notes path="templates/Bases/Topics.base"
obsidian.com base:query vault=Notes path="templates/Bases/Topics.base" view="Active" format=json
```

## Repo Config

Optional per-repo customization stored in the data directory (not in the repo itself). Path: `<data_dir>/work-topics/repos/<org>/<repo>.md`, derived from the git remote URL. Injected as `=== Repo Config ===` in the current state. Follow any instructions it contains -- they override defaults.

Format: `## Section` headings (`Commits`, `Issues`, `PR`, `Checks`, `Install`, `Run`, `Screenshots`, `Screenshot Host`) with bullet-point rules under each. Can define commit style, issue templates/labels/project fields, PR format, lint/test/build commands, worktree bootstrap, dev server configuration, and screenshot hosting. If no repo config exists, use sensible defaults.

### `## Run` section (optional)

Configures the dev server for the `run` verb:

```markdown
## Run
- Command: `npm run dev`
- Port: 5173
- URL: `http://localhost:{port}`
```

- **Command**: the shell command to start the dev server
- **Port**: the port number to watch for readiness
- **URL**: the URL to display (use `{port}` placeholder)

### `## Install` section (optional)

Command to bootstrap a fresh worktree (install dependencies). Used by `topic start` and `auto` after `git worktree add`.

```markdown
## Install
- Command: `yarn install`
```

Leave unset if the repo has no install step (e.g. a Go module with no vendored deps).

### `## Screenshots` section (optional)

Command template for capturing UI screenshots during `auto`. The command should self-serve the dev server (on a free port) so the skill does not have to manage one separately.

```markdown
## Screenshots
- Command: `yarn e2e --spec {spec}`
- Placeholder `{spec}` is replaced with the path to the one-off spec the skill writes
```

If no Screenshots section is configured, `auto` skips the screenshot step and notes it in the summary.

### `## Screenshot Host` section (optional)

A public GitHub repo used to host screenshots that get embedded in PR descriptions. The skill pushes PNGs to `<repo>/<branch-slug>/<name>.png` and references them via raw URLs.

```markdown
## Screenshot Host
- Repo: `<user>/<asset-repo>`
- Branch: `main`
```

`gh gist create` does not support binary files -- do not fall back to gists for PNGs. If no Screenshot Host is configured, `auto` omits images from the PR body.

## Vault access

The Obsidian vault lives on a synced drive and is NOT directly accessible from the WSL filesystem. You MUST use `obsidian.com` CLI commands to read and write files in the vault.

### Core commands

```bash
# Read a file
obsidian.com read vault=Notes path="Notes/<Name>.md"

# Create a new note
obsidian.com create vault=Notes name="<Name>" path="Notes/" content="<content>"

# Update a note (overwrite existing)
obsidian.com create vault=Notes name="<Name>" path="Notes/" overwrite content="<content>"

# Append to a note
obsidian.com append vault=Notes path="Notes/<Name>.md" content="<content>"

# Delete a note
obsidian.com delete vault=Notes path="Notes/<Name>.md"
```

### Property commands

Read and set individual frontmatter properties without touching the full note:

```bash
# Read a property
obsidian.com property:read vault=Notes name=status path="Notes/<Name>.md"

# Set a property (text)
obsidian.com property:set vault=Notes name=status value=done path="Notes/<Name>.md"

# Set a property (number)
obsidian.com property:set vault=Notes name=points value=5 type=number path="Notes/<Name>.md"

# Set a property (date)
obsidian.com property:set vault=Notes name=completed value=2026-04-01 type=date path="Notes/<Name>.md"

# Remove a property
obsidian.com property:remove vault=Notes name=worktree path="Notes/<Name>.md"
```

**Prefer `property:set` over read-modify-overwrite** when updating individual fields. Only use the full overwrite pattern when changing multiple fields at once or modifying the note body.

### Base commands

```bash
# List all bases
obsidian.com bases vault=Notes

# List views in a base
obsidian.com base:views vault=Notes path="templates/Bases/Topics.base"

# Query a base view (returns structured data)
obsidian.com base:query vault=Notes path="templates/Bases/Topics.base" view="All" format=json

# Available formats: json, csv, tsv, md, paths
```

**Important**: The base file must be opened in Obsidian before querying. Run `obsidian.com open` first:
```bash
obsidian.com open vault=Notes path="templates/Bases/Topics.base"
obsidian.com base:query vault=Notes path="templates/Bases/Topics.base" view="Active" format=json
```

### Search commands

```bash
# Text search (useful as fallback when base isn't available)
obsidian.com search vault=Notes query="slug: auth-refactor" path="Notes/" format=json

# List files in a folder
obsidian.com files vault=Notes folder="Notes/" ext=md
```

**Writing `.base` files**: Use `obsidian.com create path="templates/Bases/Topics.base" overwrite content="..."` -- the `path=` parameter with the full `.base` extension is required. Using `name=` will create a `.md` file instead.

**CLI reference**: Run `obsidian.com --help` for the always-up-to-date command list. Don't guess at commands -- check help first.

**Do NOT use** the Read/Write/Edit tools with WSL paths like `/mnt/<drive>/<vault>/...` -- they won't work. Always use `obsidian.com` via Bash.

## Editing guidelines

- **Prefer `property:set`** for updating individual frontmatter fields.
- **Use `obsidian.com create ... overwrite`** when changing multiple fields at once or editing the note body.
- **Read the topic note before full overwrites**: Use `obsidian.com read` to get current content before modifying.
- **Creating topic notes**: Use `obsidian.com create` with the full note content (frontmatter + body).
- **Appending to topic notes**: Use `obsidian.com append` to add content to the note body (e.g. for `note <text>`).

## State injection

`load-state.sh` outputs the current state for the skill to consume:

- `=== Config ===` -- work-topics config JSON
- `=== Git ===` -- repo, branch, default_branch, root
- `=== Repo Config ===` -- per-repo customization if available
- `=== Topics ===` -- JSON output from `base:query` on the "Active" view (all non-done, non-archived topics with their properties)
- `=== Active Topic ===` -- the full note content for the topic matching the current git branch (resolved via slug match from the topics list)

If no active topic matches the current branch, the Active Topic section will be empty or absent.

## Principles

- **Terse in, terse out.** Keep responses short. The status line is the primary feedback.
- **Don't ask when you can act.** If intent is clear, just do it.
- **Single source of truth.** Topic notes are the data. The base is a view. Never duplicate state.
- **Idempotent.** Running the same command twice should not create duplicates.
- **Fail gracefully.** If `gh` fails or a file is missing, explain what's wrong and how to fix it.
