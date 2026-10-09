# 2026-10-09: Render at full resolution

## What was done

The lead changed the resolution requirement: the scene renders at full
screen resolution for readable text and clear movement; the pixel style is art
direction. ADR-0008 Amendment 3 records it.

- `display/window/stretch/mode`: `viewport` → `canvas_items`.
- Default font settings restored to the engine's (antialiasing, hinting,
  subpixel positioning); the low-resolution settings left uneven spacing.
- Test card: a row of squares offset by quarter art pixels (visual), and a
  half-pixel marker checked automatically by `render_checks()` on every
  review render (exit 6 if the scene is not drawn at full resolution).
- `tools/render_showcase.gd` calls a scene's `render_checks(image,
  layout_to_screen)` when it has one.
- Settings tests updated; playtest item 9 updated.

Unchanged: layout size 640×360, integer scaling, expand, ultrawide table, UI
width setting. Whether to switch to fractional scaling is a fork for the lead
(Q17, in the decisions PR).

## What broke, and how it was found

Nothing broke: every review render kept the same visible area, so
`DisplayMath` still holds.

## Verified

- The full-resolution check passes at 1920×1080, 1366×768, 5120×1440 (and is
  skipped at 1024×768, scale 1); with `viewport` stretch it fails at all three
  (exit 6, naming the pixel).
- Font settings compared on enlarged crops of the same line at 1920×1080.

## Test mutations (each confirmed to fail, then reverted)

Stretch mode back to `viewport` (unit test and render check); font
antialiasing off.

## Not verified

How smooth movement looks in motion, and text on real monitors: playtest.
The GPU cost of full-resolution lights and shaders on a GTX 1050 Ti: nothing
heavy exists yet to measure.
