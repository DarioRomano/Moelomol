# 2026-10-09: Godot project, tests, CI, PR builds and releases

## What was done

- Godot project (`project.godot`) with the ADR-0008 display settings (Q1
  accepted by the lead), Nearest filtering, non-antialiased default font,
  Compatibility renderer and typed-GDScript-as-errors. The last two are
  working assumptions for the still-open Q5 and Q8.
- Main scene: title over a pixel-scale test card. No gameplay.
- In-house headless test runner with `TestCase`; 23 GDScript tests and 7 Python
  tests (change-notes parser).
- Tools: `install-godot.sh`, `check-godot-version.sh`, `run-tests.sh`,
  `render-showcase.sh` (+ `render_showcase.gd`), `export.sh`, `smoke-run.sh`,
  `tools/ci/` helpers.
- Workflows: pull requests get five checks, runnable builds for Windows, macOS,
  Linux and Web, renders, and a build-links comment. Every merge to `main`
  publishes a pre-release with Windows, macOS and Linux zips (ADR-0009).
- ADR-0008 (display) and ADR-0009 (CI and releases) written; ADR-0006 status
  line notes the extra Change notes check.
- Open questions: Q1 and Q10 resolved; Q5, Q8 marked as applied assumptions;
  new Q12 (start fullscreen or windowed).
- Asset register and the first playtest checklist.

**Placeholder:** `icon.svg` and the engine's default font (see
`docs/design/asset-register.md`).

## What broke, and how it was found

- **`DisplayServer.screen_get_image_rect` returned an empty image under Xvfb.**
  Found on the first render run (every render failed). Fixed by capturing the
  whole screen with `screen_get_image` and cropping.
- **macOS export failed** with "Cannot export for universal or arm64 if ETC2
  ASTC texture format is disabled". Found by running the real export. Fixed by
  enabling `import_etc2_astc`.
- **Test card scale readout was wrong** (2.13x at 1366×768; actual scale 2x) and
  **the darkest palette swatches were invisible.** Found only by looking at the
  renders; all tests had passed. Fixed, and a test for the scale arithmetic
  was added.
- **`gh pr` commands fail** in this environment (GraphQL blocked) and **Actions
  logs are not readable**; only the REST API and check runs are. Hence every
  tool prints `::error` annotations.

## Test mutations (each confirmed to fail, then reverted)

Untyped declaration in `palette.gd`; null call in `boot.gd` `_ready()`;
viewport width 641; `scale_mode` fractional; Linear filter; preset renamed;
build stamp left out of a preset's include filter; a palette colour removed
(twice: one referenced by index, one not); commit shortened to 8 characters;
stamp values ignored; no test matching the filter; a test file not extending
`TestCase`; change-notes parser not stripping comments; change-notes parser
stopping at `###` subheadings.

## Found while doing this

- With whole-number scaling, windows that are not exact multiples get black
  borders, and windows smaller than 1280×720 fall to 1x (mostly black). A
  maximised window on a 1080p monitor drops to 2x. Recorded in ADR-0008 and Q12.

## Not verified

- The Windows and macOS builds have not been run on real machines; the Linux
  build ran only in a virtual display with software rendering. See
  `docs/playtests/2026-10-09-foundation-build.md`.
- The workflows were only checked for YAML syntax locally; they are proved by
  running on this pull request.
- No shell linter was available here (`bash -n` syntax checks only).
