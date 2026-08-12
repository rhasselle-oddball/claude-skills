# Wrap

End-of-session synthesis. Creates a session note that captures what happened, what was decided, and what's next -- without the user having to explain. The conversation context and git state tell the story.

## Session Notes

Session notes are individual Obsidian notes in the `Notes/` folder (alongside everything else), linked to a topic via the `topic` frontmatter field. They use the `[[Sessions]]` category and are queryable via the `Sessions.base`.

### Naming

`Notes/<topic-slug> <YYYY-MM-DD>.md` (e.g. `Notes/auth-refactor 2026-04-07.md`). If a session note already exists for today, append a sequence number (e.g. `auth-refactor 2026-04-07 2.md`).

### Format

Frontmatter is the primary content -- it's what shows up in the backlinks table on the topic note. The body is optional overflow for anything that doesn't fit cleanly in frontmatter (long context, code snippets, links to specific files). Most sessions the body stays empty.

```yaml
---
categories:
  - "[[Sessions]]"
topic: "[[<Topic Note Name>]]"
date: <YYYY-MM-DD>
summary: <What happened -- 1-3 dense sentences. Progress, blockers, approach changes. Not a play-by-play.>
decisions:
  - <Decision and why. This is the highest-value field -- decisions are invisible in diffs but critical for context.>
next:
  - <Concrete next step, not vague goals>
commits: <number of commits this session>
files-changed: <number of files touched>
---
```

**Field guidance:**
- `summary`: Dense but complete. Someone reading just this field should understand what happened. Include approach changes, blockers hit, key progress milestones.
- `decisions`: Each entry is a decision + reasoning. Skip if nothing was decided. These are what future-you forgets first.
- `next`: Actionable items for the next session. Specific enough to pick up cold. **Carry forward** any still-open items from the prior session's `next` that weren't finished this session, so this field is the complete open list -- `status` reads only the newest note, so it must stand alone without walking back through prior sessions.
- `commits` / `files-changed`: Quick sense of session size. Get from git log/diff.
- Omit empty fields -- don't include `decisions: []` if nothing was decided.

The `topic` field is a wiki link to the topic note (e.g. `"[[Auth Refactor]]"`). This creates a backlink so sessions appear in the topic's `![[Backlinks.base]]` and enables click-navigation between the two.

### Creating

```bash
obsidian.com create vault=Notes name="<topic-slug> <date>" path="Notes/" content="<full note content>"
```

**Important**: The `topic` field must be a wiki link to the topic's note name (e.g. `"[[Auth Refactor]]"`), not the slug. Resolve the note name from the topic's file path (e.g. `Notes/Auth Refactor.md` -> `Auth Refactor`).

**Quoting**: When using `property:set`, use single-quoted shell args to avoid double-quoting issues:
```bash
obsidian.com property:set vault=Notes name=topic value='[[Auth Refactor]]' path="Notes/auth-refactor 2026-04-07.md"
```

## Steps

1. **Read the conversation context** -- what was discussed, decided, changed, discovered during this session. This is the primary source.
2. **Read the git state** -- if the topic has a worktree, check `git log` for commits since the last session, `git diff --stat` for uncommitted changes. If the topic has a PR, check its current state.
3. **Read any open notes** -- check the topic note's `## Notes` section for scratchpad items added during the session.
4. **Synthesize the session note** -- distill the meaningful deltas into frontmatter fields:
   - `summary`: What happened in 1-3 dense sentences. Focus on progress, blockers, and approach changes.
   - `decisions`: Things that were decided and *why*. Omit if nothing was decided.
   - `next`: What's queued up for the next session. Concrete next steps. Carry forward unfinished items from the prior session's `next` so this list is complete on its own.
   - `commits` / `files-changed`: From git state.
   - If something needs more space than frontmatter allows (long explanations, code context, file lists), put it in the note body.
5. **Create the session note** in `Notes/`.
6. **Fold scratchpad notes** -- any items in the topic note's `## Notes` section that were addressed this session get removed. Items still open stay.
7. **Fold any ad-hoc status/next block from the topic body** -- if a prior session hand-wrote a `### Next` / status block into the topic note body, merge its still-open items into this session note's `next` and remove the block from the topic body. The newest session note is the single canonical "latest status"; don't let a second copy drift in the topic body.
8. **Update `last-active`** on the topic note.
9. **Advance step** if the work naturally moved it forward (e.g. `implementing` to `needs-tests`, or `ci-failing` to `ci-passing`). Use the same detection logic as `advance` but don't prompt -- just update if obvious.

## Principles

- **Don't ask, synthesize.** The AI was present for the whole session. It knows what happened.
- **Frontmatter is the record.** The backlinks table on the topic note is how sessions get consumed. Frontmatter fields must tell the whole story at a glance.
- **Newest session note is the canonical latest status.** Its `summary` + `next` must stand alone -- `status`/recap reads it first and leads with it. Carry forward open items so the reader never has to reconstruct the open list from older notes.
- **Decisions over diffs.** Git tracks what changed. Sessions track *why* and *what's next*.
- **Terse but complete.** Scannable in 10 seconds, but missing nothing important.
- **No empty fields.** If nothing was decided, omit `decisions`. Don't include placeholder values.
