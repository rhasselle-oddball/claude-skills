---
name: verdict
description: >-
  My verdict on something already reviewed in this conversation: only the blocking and
  strongly-worth-mentioning points, one per line, conversational. Use when I ask for the
  verdict, the blocking points, the casual version, or one sentence each.
---

The call, not the report. Drop anything that wouldn't change what the author does, true things included.

Two groups at most: blocking, and worth mentioning.

One point per line, one sentence each. The claim and why it matters, then stop.

Label every point `a)`, `b)`, `c)` so I can reply about one by letter. Letters run straight through both groups and never restart, so each letter names exactly one point. Keep the same letters if I ask for the verdict again.

Conversational, the way I'd type it to the author. `lean-writing` has the voice.

Use what the conversation established. A fresh re-read brings back every point that already got disproven.

Say "nothing blocks" when nothing blocks.

Never pad, never tier, never list what you cut.

## Example

> Two that I'd actually call blocking:
>
> a) The auth widget needs a `!profile.errors` guard too, otherwise a failed profile fetch looks identical to a signed-out user and it can auto-login in a loop.
>
> b) `profile.errors` never gets cleared, so the app stays on the error message even after a later successful load.
>
> One that's more worth-a-look than a blocker:
>
> c) Clicking a link mid-load now flashes the error message instead of the spinner.
