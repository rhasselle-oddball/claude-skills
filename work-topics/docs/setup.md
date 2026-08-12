# Setup

First-time configuration. Be direct -- ask upfront, then do everything in one shot.

1. **Ask the user** where to store work-topics data (any directory -- should be an Obsidian vault root so topic notes and the Topics base are accessible). Do NOT search the filesystem -- just ask.
2. **Run `gh auth status`** to check GitHub CLI. Note pass/fail -- don't block on it.
3. **Run the setup script**:
   ```bash
   scripts/setup-profile.sh "<data_dir>"
   ```
   This creates the work-topics directory and writes config to `~/.config/work-topics/config.json`.
4. **Verify the Topics base exists**:
   ```bash
   obsidian.com bases vault=Notes
   ```
   Look for `templates/Bases/Topics.base`. If it doesn't exist, the user needs to create it in Obsidian (a Base with a filter on `categories contains [[Topics]]`).
5. **Print a checklist summary**:
   ```
   Setup complete:
   [x] Data: /path/to/dir/work-topics/
   [x] Topics base: templates/Bases/Topics.base
   [x] gh: authenticated as <user>  (or [ ] gh: run `gh auth login`)
   ```
