---
name: review-loop
description: Loop on changes until a fresh reviewer agent has nothing left worth fixing. Use when asked to run the review loop, or when another skill hands off to it. Not for a one-off review, and never nested. If a loop spawned you or handed you its findings, do that work and stop.
---

Each round:

1. Spawn one fresh general-purpose subagent and ask it something as plain as
   "thoughts on these changes?" or "review this PR", plus "don't edit anything"
   and a path or PR number if it can't figure out the scope on its own. One turn,
   then let it die.
2. Go point by point and decide whether you actually agree. That comes first;
   fixing is only what follows for the points you agreed with. You have far more
   context than the reviewer does, so the call is yours. Leave the rest and say
   why at the end.

Say nothing else to the reviewer, before or after. Not what the change is meant
to do, not what earlier reviewers said, not what you changed since. Framing
pollutes the read: a reviewer told the intent grades against your narrative
instead of the code, and one told the history confirms it.

You are not in a conversation with it. Read the reply and let it die. No
follow-up questions, no clarifying, no arguing a point you disagree with, no
forks, no reviving a previous reviewer. If a reply is too vague to act on, that
round just produced nothing; the next fresh reviewer is cheaper than a thread.

Their feedback is input, not a work order. A reviewer with no context is often
right about correctness and wrong about intent, and will usually find something
to say whether or not anything is wrong. The exit condition is a satisfied
reviewer, which tempts you into changes you think are wrong just to end the loop;
don't.

Agreeing with a point is not the same as doing it in this PR. Reviewers are
usually right that the code around your diff has problems, which is what gets
this past the "do I agree" filter. Separate question: does this PR's intent need
it? Code your change broke is in scope; code it sat next to is not.

If you delegated the work, the call is still yours and never the reviewer's, but
you are not the one holding the context. Ask whoever wrote it before rejecting a
point on intent. Applying a fix can be delegated; deciding cannot.

One loop runs per change, and you are running it. Anyone you hand work to is
doing a turn, not starting a loop of their own. Send accepted points as your own
change requests, never as a forwarded review, or you get fresh reviewers on the
same diff from inside every round of this one.

Past round three, only change code to fix a demonstrated failure. By then the
loop starts generating the defects it catches: a refactor one reviewer asks for
gets undone by the next, and a function renamed on three reviewers' conflicting
advice is three rounds of churn and three chances to break something. Style
preferences at that depth are the loop talking to itself.

Keep looping until two rounds in a row produce no correctness fix. A round whose
only changes were naming, comments, or style counts as one of the two, and so
does a round that changed nothing at all. Any correctness fix resets the count.
One quiet round isn't proof: reviewers vary, and the next one often finds what
the last one missed. There is always a cosmetic nit available, so "did anything
change" never terminates on its own. Stop after 10 rounds regardless.

Keep a list of what you have settled: the point, and why you rejected it. Fresh
reviewers have no memory, so the same findings resurface every round. Weigh a
repeat once, then match it against the list and move on without re-deliberating.
Never show the list to a reviewer, that is the framing you are avoiding. Put a
persistent repeat to the user rather than re-arguing it with yourself.

Prefer committing over pushing between rounds. If there's a push in the picture
at all, do it once at the end rather than each round.

Apply the `lean-writing` skill to anything you write along the way (comments,
commit messages, PR body, docs), and do a pass over all of it once the loop
ends. Rounds accrete prose: each one adds a caveat or an explanation, and what
survives is much longer than anything you'd have written in one go.

When the loop ends, report to the user: how many rounds ran, then one short bullet
per round saying what changed in it. A round you changed nothing over still gets a
bullet saying so and why. Meant to be read at a glance:

```
4 rounds.
- 1: fixed the off-by-one in the date range, dropped an unused helper
- 2: added the null guard on the API response
- 3: no changes, disagreed with the suggested refactor
- 4: no changes, only style nits left
```

Anything still open for the user to decide goes after that, one line each. Skip
it if there's nothing.
