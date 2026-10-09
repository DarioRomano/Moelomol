# 2026-10-09: Frame-time overlay (Q16)

## What was done

The lead will measure on the Ryzen 7 5800X and on the Steam Frame, through
FEX (x86 build) and natively (ARM64 test build). This PR gives those runs
numbers:

- Autoload `DevTools`: overlay with FPS, frame time average and maximum over
  the last 120 frames, frames over the 8.33 ms budget, logic, physics, render
  CPU and render GPU times, memory, video memory, draw calls, screen and
  scale, V-Sync and refresh rate, OS, CPU architecture, CPU, GPU, renderer,
  build label, scene.
- F3 (or both stick buttons) toggles it; F2 cycles title, test card and
  renderer features; F4 toggles V-Sync. Launch options `--perf-overlay`,
  `--start-scene`, `--no-vsync`. In every build, since the lead tests release
  builds.
- Two review renders with the overlay shown.
- 8 tests; playtest checklist `docs/playtests/2026-10-09-performance-devices.md`.

## What broke, and how it was found

- **One of my tests could not detect what it was named for.** The check that
  the overlay ignores the render tool's `--scene` used a file path, which is
  rejected anyway; the deliberate break slipped through. Now uses a valid
  scene name and fails on the break.
- **Name clash avoided:** autoloads also run under the render tool and the
  test runner (probed), so a `--scene` launch option would have hijacked
  every review render. The option is `--start-scene`.
- **I lost and recovered my own work.** While trial-merging with the
  full-resolution PR, uncommitted work went into a temporary commit on a
  branch I then deleted. Recovered from git's reflog before anything was
  pushed; tests rerun.
- On this branch alone (without the full-resolution PR) the overlay's 6-pixel
  text is unreadable. Checked with both PRs merged locally: readable at
  1920×1080 and 5120×1440.

## Verified

- Every API used exists and returns values under the Compatibility renderer
  (probe; architecture appendix of this date). The refresh rate reads NaN
  under the virtual display; the overlay shows "unknown Hz".
- Rendered at 5120×1440 vs 1920×1080 (software renderer), the render GPU time
  roughly doubled (131 vs 56 ms): full-resolution GPU cost grows with screen
  size, as noted in ADR-0008 Amendment 3.

## Test mutations (each confirmed to fail, then reverted)

Frame window never wrapping; every frame counted over budget; accepting
`--scene`; NaN refresh shown as a number; F3 doing nothing; autoload removed.

## Not verified

Everything on real devices: playtest checklist.
