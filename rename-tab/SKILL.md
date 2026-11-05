---
name: rename-tab
description: Rename and color the herdr tab (window) this session runs in, or every Claude tab with "all". Use when I say /rename-tab, "rename the tab", "name this window", "color the tabs", or ask to rename the tab along with the session.
---

# rename-tab

Rename the herdr tab this Claude session runs in, and color its name in the herdr sidebar. `/rename` only renames the session; this renames the tab.

## Label

- Use the argument if one is given.
- Else use the session name if `/rename` set one this conversation.
- Else make one up: 2 to 4 lowercase words naming the current work (e.g. `progress nav review`).

## Color

The sidebar shows each agent's name in a color, set as a pane metadata token. The herdr config (`~/.config/herdr/config.toml`, `[ui.sidebar.agents]`) styles one token per color, in wheel order:

`red` `pink` `orange` `yellow` `lime` `green` `teal` `cyan` `sky` `blue` `indigo` `purple`

Related topics (same feature, same component, a review and its fix) get neighboring shades, like `sky` `blue` `indigo` for forms work. Unrelated topics sit far apart.

The tab bar can't color text, so the tab label starts with the square for the color's family:

| Square | Colors |
|--------|--------|
| 🟥 | red, pink |
| 🟧 | orange |
| 🟨 | yellow |
| 🟩 | lime, green, teal |
| 🟦 | cyan, sky, blue |
| 🟪 | indigo, purple |
| 🔲 | black |

- If I name a color in the argument, use it.
- Else a tab in the `orchestrator` space gets `black`. Other tabs never do.
- Else keep the pane's current color (`herdr pane get "$HERDR_PANE_ID"`, the key in `tokens`).
- Else check the other panes' `tokens` in `herdr pane list`: take an unused neighbor of a related topic's color, or else the first unused color in my preference order:

  `blue` `pink` `orange` `green` `purple` `yellow` `teal` `red` `sky` `indigo` `lime` `cyan`

## Run

The tab is in `$HERDR_TAB_ID` and the pane in `$HERDR_PANE_ID`. If they're unset, this session isn't in herdr: say so and stop. Never fall back to a tab from `herdr tab list` for the rename, since that renames someone else's tab.

The sidebar token and the tab label are both `<square> <label>`, so the two match. Clear the old color token first if the color changes, since only one should be set.

```bash
herdr pane report-metadata "$HERDR_PANE_ID" --source rename-tab --clear-token <old-color>
herdr pane report-metadata "$HERDR_PANE_ID" --source rename-tab --token "<color>=<square> <label>"
herdr tab rename "$HERDR_TAB_ID" "<square> <label>"
```

Reply with one line: the new label and its color.

## All tabs

`/rename-tab all` renames and colors every Claude agent instead of just this one.

1. `herdr agent list`, keep entries with `"agent":"claude"`. Each has a `pane_id` and `tab_id`.
2. Label each from the agent's `name` if set, else its `terminal_title_stripped` (drop leading status glyphs like `◑`), shortened to 2 to 4 words. Use the label rules above for this session's own tab.
3. Group related topics and assign colors as a whole: each group's lead topic takes the next color in my preference order, related topics take neighboring shades. Keep existing colors where they still fit the grouping.
4. Run the commands above for each pane and tab. Leave panes without a Claude agent alone.

Reply with one line per tab: the label and its color.
