# 2026-10-09: Ultrawide screens and fullscreen start

## What was done

Lead's decisions of 2026-10-09: support 21:9 and 32:9 at 1080p and 1440p (Q1
addition); start fullscreen (Q12).

- `display/window/size/mode = 3` (Fullscreen). ADR-0008 amended (with the
  lead's approval) with the ultrawide table and the fullscreen start.
- `DisplayMath` (`src/core/display_math.gd`): the visible area and scale the
  display settings should give for any screen. Used by the test card readout
  and the render tool; replaces the test card's own scale function.
- Renders now cover ten screens: 1280×720, 1920×1080, 2560×1440, 1366×768,
  1280×800, 2560×1080, 3440×1440, 3840×1080, 5120×1440, 1024×768.
- Every render checks its real visible area against `DisplayMath` (exit 4).
- CI's render job now runs a small window manager (`openbox`, an Ubuntu
  package installed on the runner, not a project dependency) so X11 can report
  fullscreen, and every render checks the window mode (exit 5).
- Render failures now carry the actual error line in their CI annotation.
- Playtest checklist updated for fullscreen and ultrawide.

## What broke, and how it was found

- **Division by zero in headless runs.** The test card now asks `DisplayMath`
  for the scale; headless runs report a 0×0 window. The test runner's
  error hook failed `test_every_scene_instantiates` on the first run. Fixed
  with a guard and a test for the 0×0 case.
- **Fullscreen cannot be confirmed without a window manager.** Under bare
  Xvfb, Godot reports window mode 0 even with `--fullscreen`, and even
  `--windowed` fills the screen. Found by probing. A window manager could not
  be installed here (Ubuntu mirrors blocked), so the mode check is proven only
  by forcing it on locally (it fails with mode 0, as expected) and will first
  really run in CI.

## Test mutations (each confirmed to fail, then reverted)

Visible area always the base size (4 unit tests failed and a real 3440×1440
render failed the area check, exit 4); zero-size guard removed; windowed
start; window-mode check forced on without a window manager (exit 5).

## Not verified

- That fullscreen works on real Windows, macOS and Linux desktops, and on real
  ultrawide monitors: playtest checklist items 5 and 6.
- The CI window-mode check, until the first CI run of this PR.
