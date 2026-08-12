---
name: visual-demo
description: Visually demonstrate code changes by running Cypress tests and capturing screenshots/video, and host those screenshots in a va.ghe.com PR. Use when the user says "show me", "what does it look like", "show me the fix", "visual demo", "screenshot", "add screenshots to the PR", "upload to my screenshot repo", or asks to see what changed visually. Also trigger after completing a form-related fix when the user wants visual confirmation.
allowed-tools: Bash, Read, Edit, Write, Grep, Glob, Agent
---

# Visual Demo

Visually demonstrate code changes by running Cypress E2E tests with screenshot/video capture. Works with any vets-website form application.

## How it works

1. Determine what changed and which form/page is affected
2. Either use an existing Cypress test or generate a temporary one with targeted screenshots
3. Run via `yarn cy:run:auto --spec "<spec>"` from the worktree directory
4. Display screenshots using the Read tool (which renders images inline) and open in VS Code
5. Clean up any temporary specs

## Running tests

### Basic command

```bash
cd <worktree> && yarn cy:run:auto --spec "<path-to-spec>"
```

`cy:run:auto` handles everything: starts a dev server on a free port, runs the spec, stops the server. Use `--verbose` to see full Cypress output (helpful for debugging).

**Important**: Do NOT pass `--screenshots` or `--no-video` — these are not valid Cypress CLI flags and will cause errors. The `cy:run:auto` script already disables video by default.

### Worktree considerations

When running in a git worktree, webpack resolves `../content-build` relative to the worktree root, which fails because content-build is a sibling of the main repo, not the worktree. If you get 404s on `cy.visit()`:

1. Check if `config/webpack.config.js` has the `getMainRepoRoot()` worktree fix
2. If not, the dev server will serve but all app routes will 404
3. Run `yarn install-safe` in the worktree before running tests

## Targeted screenshots (specific pages)

Generate a temporary Cypress spec that navigates to specific pages and captures viewport screenshots. This is the primary mode for demonstrating fixes.

### Key principles

1. **Frame the shot around only what changed.** A reviewer should see the diff, not hunt for it inside a capture of the VA header, page title, and three unrelated sections. Three options, in preference order:

   a. **Tight clip via bounding-rect math** — the default. Scroll the element into view, read `getBoundingClientRect()` on the top-most and bottom-most relevant nodes, and pass a `clip` to `cy.screenshot({ capture: 'viewport', clip: { x, y, width, height } })` with a small padding. Crop width around 500-700px reads well inline in a PR body. Let the height follow the content instead of fixing it.

   b. **Element screenshot** (`cy.get(selector).screenshot(name)`) — simpler, but Cypress cuts off when the element is taller than the viewport or has absolutely-positioned children.

   c. **`capture: 'fullPage'`** — last resort. It starts at the top of the document and stitches multiple captures, producing duplicate bands on pages with sticky headers.

   Never leave `cy.screenshot()` bare. The default is full-page.

2. **Scroll to the element of interest before screenshotting** — use `.scrollIntoView()` then `.wait(500)` to ensure the element is in view and rendered.

3. **Do NOT use `stopTestAfterPath` if you need screenshots on that page** — it stops the test before the page hook runs. Instead, just don't submit/continue from the last page.

4. **Understand where data comes from** — for prefill forms, email/phone/address come from the `user.json` mock's `vet360ContactInformation` object, NOT from SIP (save-in-progress) data. To test with specific data, deep-clone and modify the user mock in the spec.

5. **Set viewport before screenshotting, then scroll again** — changing viewport can reflow the page, so scroll to the target element again after `cy.viewport()`, and recompute the clip. Viewport size only sets the window; the clip is what crops the image.

### Template

```js
import path from 'path';
import testForm from 'platform/testing/e2e/cypress/support/form-tester';
import { createTestConfig } from 'platform/testing/e2e/cypress/support/form-tester/utilities';
import featureToggles from '../fixtures/mocks/feature-toggles.json';
import baseUser from '../fixtures/mocks/user.json';
import mockSubmit from '../fixtures/mocks/application-submit.json';
import mockSipGet from '../fixtures/mocks/sip-get.json';
import mockSipPut from '../fixtures/mocks/sip-put.json';
import mockVamcEhr from '../fixtures/mocks/vamc-ehr.json';
import formConfig from '../../config/form';
import manifest from '../../manifest.json';

// Deep clone and modify mock data if needed
const user = JSON.parse(JSON.stringify(baseUser));
user.data.attributes.vet360ContactInformation.email.emailAddress =
  'very-long-test-value@example.com';

// Crop to what changed. Height follows the content, not a fixed number.
const shotOf = (selector, name, pad = 12) =>
  cy
    .get(selector)
    .scrollIntoView()
    .wait(500)
    .then($el => {
      const r = $el[0].getBoundingClientRect();
      cy.screenshot(name, {
        capture: 'viewport',
        clip: {
          x: Math.max(0, Math.round(r.left - pad)),
          y: Math.max(0, Math.round(r.top - pad)),
          width: Math.round(r.width + pad * 2),
          height: Math.round(r.height + pad * 2),
        },
      });
    });

const testConfig = createTestConfig(
  {
    dataPrefix: 'data',
    dataSets: ['minimal-test'],
    dataDir: path.join(__dirname, '..', 'fixtures', 'data'),
    pageHooks: {
      introduction: ({ afterHook }) => {
        afterHook(() => {
          cy.findAllByText(/^start/i, { selector: 'a[href="#start"]' })
            .last()
            .click({ force: true });
        });
      },
      '<target-page>': ({ afterHook }) => {
        afterHook(() => {
          cy.viewport(1280, 800);
          cy.wait(300);
          shotOf('<selector>', 'target-desktop');

          // Resizing reflows, so shotOf re-scrolls and recomputes the clip
          cy.viewport(375, 800);
          cy.wait(500);
          shotOf('<selector>', 'target-mobile-375px');

          // Continue to next page (or omit to stop here)
          cy.findByText(/continue/i, { selector: 'button' }).click();
        });
      },
      'review-and-submit': ({ afterHook }) => {
        afterHook(() => {
          // Expand all sections on review page
          cy.contains('button', /expand all/i).click({ force: true });
          cy.wait(1000);

          cy.viewport(1280, 800);
          cy.wait(300);
          // Clip the whole row, not just the label
          shotOf('.review-row:has(dt:contains("target label"))', 'review-desktop');

          // Don't submit — test ends here
        });
      },
    },
    // Do NOT use stopTestAfterPath if you need the page hook to run
    setupPerTest: () => {
      cy.intercept('GET', '/v0/user', user);
      cy.intercept('GET', '/v0/feature_toggles?*', featureToggles);
      cy.intercept('GET', '/data/cms/vamc-ehr.json', mockVamcEhr);
      cy.intercept('GET', '/v0/in_progress_forms/<FORM-ID>', mockSipGet);
      cy.intercept('PUT', '/v0/in_progress_forms/<FORM-ID>', mockSipPut);
      cy.intercept('POST', formConfig.submitUrl, mockSubmit);
      cy.login(user);
    },
  },
  manifest,
  formConfig,
);

testForm(testConfig);
```

When the change spans several nodes, clip from the top of the first to the bottom of the last rather than screenshotting each one:

```js
cy.get('<first>, <last>').then($els => {
  const rects = [...$els].map(el => el.getBoundingClientRect());
  const top = Math.min(...rects.map(r => r.top));
  const bottom = Math.max(...rects.map(r => r.bottom));
  // pass { x, y: top - pad, width, height: bottom - top + pad * 2 } as clip
});
```

**Temp spec location:** `<app>/tests/e2e/_visual-demo.cypress.spec.js` (prefixed with `_` to indicate temporary). Always clean up after the run.

### Review page tips

- The form tester expands the first accordion but may not expand nested review sections
- Use `cy.contains('button', /expand all/i).click({ force: true })` to expand all sections
- Review page data rows use `dl.review .review-row` with `dt` (label) and `dd` (value)
- Wait at least 1000ms after expanding for content to render

## Displaying results

### Primary method: Read tool

Use the Read tool to view screenshot files — it renders images inline in Claude Code:

```
Read the screenshot file at <path>
```

### Open in VS Code

Also open in VS Code so the user can see them in their editor:

```bash
code <screenshot1.png> <screenshot2.png>
```

### Inline terminal display (if available)

Check for terminal image support:

```bash
command -v imgcat 2>/dev/null    # iTerm2
command -v kitten 2>/dev/null    # Kitty
command -v chafa 2>/dev/null     # broad support
```

## Screenshotting a non-Cypress artifact (HTML report, static page)

For anything that is already rendered HTML (a c8 coverage report, a built page, an artifact) there is no need for Cypress. Use the Playwright chromium already cached on this machine to screenshot the file directly:

```bash
CHROME=$(ls ~/.cache/ms-playwright/chromium-*/chrome-linux/chrome | tail -1)
"$CHROME" --headless --disable-gpu --hide-scrollbars --force-color-profile=srgb \
  --window-size=1000,560 --screenshot="out.png" "file:///abs/path/to/index.html"
```

The DBus/UPower errors it prints are harmless. Size the window to clip tightly around the content. For a before/after of a config-gated report, run once, snapshot the output dir, toggle the one line, run again, then revert.

## Hosting screenshots in a va.ghe.com PR

va.ghe.com has no CLI to attach an image to a PR body (browser drag-drop is web-UI only). Host the PNGs on the public github.com repo `rhasselle-oddball/pr-screenshots` and embed `raw.githubusercontent.com` URLs; va.ghe.com renders them through its camo proxy.

github.com auth is separate from the va.ghe.com token. Confirm the right account first: `gh auth status -h github.com` should show `rhasselle-oddball` active. Set the identity on the clone so commits don't inherit a global one.

```bash
gh repo clone rhasselle-oddball/pr-screenshots
cd pr-screenshots
git config user.name "rhasselle-oddball"
git config user.email "123402053+rhasselle-oddball@users.noreply.github.com"
DIR="vets-website/<pr-or-issue-slug>"          # namespace so files never collide
mkdir -p "$DIR" && cp /path/coverage-before.png /path/coverage-after.png "$DIR/"
git add "$DIR" && git commit -q -m "Add <slug> screenshots for <repo> #<pr>"
git push origin main
```

Raw URL form (default branch is `main`):

```
https://raw.githubusercontent.com/rhasselle-oddball/pr-screenshots/main/<DIR>/<file>.png
```

Verify each resolves before editing the PR: `curl -so /dev/null -w '%{http_code} %{content_type}\n' <url>` (expect `200 image/png`).

Embed into the PR body. `gh pr edit` FAILS on va.ghe.com (Projects-classic GraphQL error), so fetch-append-PATCH via REST:

```bash
gh api --hostname va.ghe.com repos/<org>/<repo>/pulls/<n> --jq '.body' > body.md
cat >> body.md <<'EOF'

## Before / After

**Before**

![before](https://raw.githubusercontent.com/rhasselle-oddball/pr-screenshots/main/<DIR>/coverage-before.png)

**After**

![after](https://raw.githubusercontent.com/rhasselle-oddball/pr-screenshots/main/<DIR>/coverage-after.png)
EOF
gh api --hostname va.ghe.com -X PATCH repos/<org>/<repo>/pulls/<n> -F body=@body.md
```

## Workflow

1. **Identify the target**: Check `git diff` or conversation context to determine what files changed and which form page is affected.

2. **Find the app**: From changed file paths, resolve the app directory (e.g., `src/applications/simple-forms/21-0845/`).

3. **Find existing tests**: Look for `*.cypress.spec.js` files in the app's `tests/e2e/` directory. Read them to understand the test setup (mocks, intercepts, page hooks).

4. **Understand the data flow**: Read the fixture mocks to understand where the data you want to demonstrate comes from. For prefill contact info, it's `user.json` → `vet360ContactInformation`, not SIP data.

5. **Generate a temp spec**: Based on an existing spec, create `_visual-demo.cypress.spec.js` with targeted screenshots. Override mock data as needed.

6. **Run the test**: `cd <worktree> && yarn cy:run:auto --verbose --spec "<spec>"`. The test will fail at the end (no submit) — that's expected. Check that the named screenshots were captured.

7. **Display**: Use Read tool to view screenshots inline, then open in VS Code for the user.

8. **Clean up**: Remove the temporary spec file. Optionally clean up `cypress/screenshots/`.

## Video mode

```bash
cd <worktree> && yarn cy:run:auto --spec "<spec>" -- --config video=true
```

Video is saved to `cypress/videos/`.

## Common pitfalls

- **404 on cy.visit()**: Dev server is up but app isn't built. Usually a worktree content-build path issue or missing `yarn install-safe`.
- **Screenshots show top of page**: bare `cy.screenshot()` defaults to full page. Pass a `clip`, or at minimum `{ capture: 'viewport' }` after `scrollIntoView()`.
- **Screenshot is the right area but way too wide**: you captured the viewport instead of clipping. Viewport size sets the window; the `clip` is what crops.
- **Wrong data displayed**: Modified the wrong mock. Trace the data flow from the component back to the mock fixture.
- **`stopTestAfterPath` prevents screenshots**: It stops BEFORE the page hook runs. Don't use it on pages where you need screenshots.
- **Review page sections collapsed**: Use "expand all" button and wait for render.
- **`--screenshots` flag error**: This is NOT a valid Cypress CLI flag. Don't pass it.
