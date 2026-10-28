---
name: simple-list
description: >-
  Only when I explicitly ask for it: "distill this", "simple list", "simple
  words". Do not invoke for lists I did not ask to be simplified.
---

Write the list the way I'd type it in Slack. Read alongside `lean-writing`.

**One line per bullet.** `-` bullets, one line each, and it has to fit on one line without wrapping. If a bullet needs a second sentence to make sense, cut it to the part that matters or drop it. I read these in one glance; anything I have to parse has failed.

**One flat list.** No severity tiers, no categories, no "before X / after Y" headers. If something needs framing, one sentence above the list does it. Headers manufacture structure the content didn't ask for.

**Only what actually came up.** Don't pad to look thorough. Don't list what you cut ("also considered", "not included", "dropped"). Not worth saying means not worth saying.

**Say when you're unsure.** "I believe it's X." "Not sure if intentional." "maybe". Don't go verify everything just to avoid hedging, and don't launder a guess into a fact.

**Don't show work.** No `file.jsx:82,118`, no "I checked every sibling and they all do this." Name the thing. I know my codebase and I was in the conversation.

**Detail only when it isn't obvious.** One clause, not a sentence explaining the bullet you just wrote.

**Fragments are fine.** No bold lead-ins, no parallel bullet structure, no full sentences if a fragment lands it.

When the list is suggestions about something I own: ask rather than direct ("should we also move focus when the error happens?"), and give an out ("can be follow-up or omitted if not necessary").

### Example

This was a PR review, but the shape applies to any list.

Too much:

> ## Before the flag goes on
> - **Focus the radio group when the "Select an address" error fires.** `handleContinue` sets the error but never moves focus.
> - **Use the nav props FormPage passes:** `props.NavButtons || FormNavButtons`, plus `useWebComponents={props.formOptions?.useWebComponentForNavigation}`. See `ArrayBuilderItemPage.jsx:82,118`.
>
> ## Whenever
> - **Add `maturityCategory`/`maturityLevel` to the README frontmatter.** Default is `use`/`deployed`, too generous for one pilot.
>
> ## Dropped
> Empty-object guard, `subHeader` naming, missing `street3`, inline margin style.

How I'd write it:

> some minor feedback (can be done as follow-up or omitted if not necessary):
>
> Should we also move focus when error happens?
> FormNavButtons expects to also receive useWebComponents to opt out of imposter components (I believe it's an imposter component by default)
> Add maturityCategory/maturityLevel to the README frontmatter (automatically read by https://staging.va.gov/mock-form-patterns. Default is use/deployed - maybe to start should use caution/available
