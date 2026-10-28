---
name: draft-comments
description: >-
  Draft line-anchored PR comments as pending review comments, agreeing on the points first.
  On my own PR (often agent-written), they explain the change so I understand it; I usually
  throw them away. On someone else's PR, they're my critique from a review already in this
  conversation, and I may post them. Not for reviewing a PR in the first place ("how's this PR?").
---

Three stages. Don't skip ahead; each one waits for me.

Check whose PR it is first (author vs my login); the mode decides the points and the voice.

## 1. Agree on the points

**My PR, to understand it:** pick the spots I'd likely not follow from the diff alone: what a tricky bit does, why it's done this way, scope kept small on purpose, what didn't change, the alternative passed on. Skip what's obvious from the code or already in the PR body.

**Someone else's PR, my critique:** start from the review already in the conversation. If there isn't one, say so and ask before reviewing. Follow the `verdict` skill: blocking and worth mentioning only.

Either way: fewest points possible, lettered `a)`, `b)`, `c)`.

Then stop. I'll push back, drop points, add one, or ask to understand one ("explain b"). When I ask about a letter, answer in chat and leave the list alone. Keep letters stable; a dropped letter stays retired.

Move on only when I say the list is good.

## 2. Draft as pending review comments

Post each agreed point as a pending comment on the line it's about. Pending means only I can see it until submitted.

Write them in my voice per `lean-writing`: how I'd type it to the author, casual, one or two sentences. Point at the problem, skip the walkthrough.

How I write PR comments:
- lowercase, no capitalized prose
- often a question, even when the facts are certain: "can you check if...", "can you verify if...", "is this...?". Not every comment
- "e.g. ..." for a concrete case
- `inline code` and code blocks where they help
- leave the how to the engineer; raise the problem and let them figure out the fix
- a ```suggestion block is fine when the fix is a few obvious lines

Example: "can you check if a second wrong password in a row gets stuck on verifying? e.g. `passwordSubmissionSuccess` goes `false` -> `false` so the watcher wouldn't fire"

On my own PR, same casual style but explaining, not asking: no questions, no suggestion blocks. Plain words over jargon; the point is that I get it.

Example: "kept this in the pattern on purpose, direct callers of `validateCurrentOrPastMonthYear` keep the old message"

When the diff misrepresents a clean move or extraction (looks like a rename or rewrite but isn't), call it out: "the diff doesn't show this well, `x` is unchanged and `y` is new".

Points that would land on neighboring lines become one comment. A pile of adjacent comments means they're one thought.

A point with no good line goes in the review body. Keep the body empty otherwise.

In chat, show each draft under its letter with its `file:line`, so I can say "b shorter" or "drop the second sentence of a". Edit the pending comment in place and show only what changed.

## 3. Post or throw away

Pending comments are private, so leaving them unposted is a fine outcome. When I say throw away / discard / done, delete the pending review.

Submit only when I explicitly say post or submit. Approval of the wording isn't approval to post. Submit as `COMMENT` unless I say approve or request changes. Give me the link after.

## Mechanics

On GitHub Enterprise, `export GH_HOST=<host>` first. `R=repos/<owner>/<repo>/pulls/<n>`.

GitHub allows one pending review per user per PR. Check first: `gh api $R/reviews --jq '.[] | select(.state=="PENDING") | {id,node_id}'`. If one exists, add to it and mention it to me.

- Create the pending review with comments (no `event` means pending):
  `gh api -X POST $R/reviews -f commit_id=<head sha> -f 'comments[][path]=…' -F 'comments[][line]=N' -f 'comments[][side]=RIGHT' -f 'comments[][body]=…'`
- Add to an existing pending review (GraphQL only):
  `addPullRequestReviewThread(input:{pullRequestReviewId:<review node_id>, path, line, side:RIGHT, body})`
- List: `gh api $R/reviews/<id>/comments --jq '.[] | {id,node_id,path,line,body}'`
- Edit (REST PATCH 404s on pending comments, use GraphQL):
  `updatePullRequestReviewComment(input:{pullRequestReviewCommentId:<comment node_id>, body})`
- Delete one: `gh api -X DELETE repos/<owner>/<repo>/pulls/comments/<id>`
- Submit: `gh api -X POST $R/reviews/<id>/events -f event=COMMENT [-f body=…]`
- Throw it all away: `gh api -X DELETE $R/reviews/<id>`

`line` must be inside a diff hunk; `side=LEFT` for a deleted line. Multi-line: add `start_line`.
