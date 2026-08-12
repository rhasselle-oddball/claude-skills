---
name: lean-writing
description: >-
  When writing code comments, commit messages, PR descriptions, issue text, docs, and READMEs.
---

Preferences for any writing on my behalf:

Write it the way I'd say it out loud to a coworker. The goal is not precise wording, it's conveying the thought. Casual beats exact.

**The artifact is the elaboration.** A PR body points at the diff. A commit subject points at the commit. Docs point at the code. Convey the thought and stop; if someone wants the detail they'll read the thing. Don't pre-answer questions nobody asked.

Shortest form that carries the thought wins, not the shortest form that carries all the information. Dropping information is the point, not a side effect. If one sentence does it, write one sentence: no bullets, no headers, no supporting detail. Structure is for when there's more than one thing, not a way to compress one thing.

When cutting, delete. Don't reformat prose into bullets and call it shorter.

Compressing carefully is still overwriting. Too precise:

> Removed the three Forms System Regression CI jobs. No longer needed, unified test selection (#46614) runs a superset of their specs, and they cost ~98 job-minutes and 25 jobs per forms-system PR.

How I'd write it:

> Removed forms system regression CI jobs. Now covered by [new test selection](#46614).

- Cut any word, sentence, or comment that adds no information
- No redundant information
- Remember big picture why, not just the how
- Don't care about proper sentences or grammer - just get point across
- No em dashes
- Code comments should be pruned unless legitimately useful 1 year from now
- When referencing a link, prefer to attach it to an existing word or phrase rather than a full URL

Formats available when the content earns them, not a checklist to apply: short statements, fragments, bullets (2+ items), regular dashes, colons, `realCodeReferences`, code blocks (ONLY relevant lines), examples, before/after, problem -> solution