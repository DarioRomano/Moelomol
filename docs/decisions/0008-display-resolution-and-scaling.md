# ADR-0008: Display: 640×360 base, 16 px tiles, whole-number scaling

- **Status:** Accepted
- **Date:** 2026-10-09
- **Decided by:** Project lead (open question Q1, recommendation accepted 2026-10-09)

## Context

Pixel art needs one fixed internal resolution scaled up by whole numbers. The
options and trade-offs are in `docs/design/open-questions.md`, Q1.

## Decision

| Setting | Value |
|---|---|
| Base resolution (`display/window/size/viewport_width/height`) | 640 × 360 |
| Tile size | 16 × 16 px |
| `display/window/stretch/mode` | `viewport` |
| `display/window/stretch/scale_mode` | `integer` |
| `display/window/stretch/aspect` | `expand` |
| Default window size (`window_width/height_override`) | 1280 × 720 |
| `rendering/textures/canvas_textures/default_texture_filter` | 0 (Nearest) |
| Default font antialiasing, hinting, subpixel positioning | all off |

Changing any of these needs the lead's approval and a superseding ADR.

## Consequences

Seen in the 2026-10-09 renders (`tools/render-showcase.sh`):

- 1280×720, 1920×1080 (and by arithmetic 2560×1440 and 3840×2160) fill the
  window exactly at 2x, 3x, 4x, 6x.
- 16:10 windows show more world rather than bars: 1280×800 gives a 640×400
  view at 2x. Ultrawide 2560×1080 gives 853×360 at 3x.
- **Windows that are not a whole multiple get black borders.** 1366×768 shows a
  640×360 view at 2x with 43 px side bars and 24 px top and bottom bars;
  `expand` does not grow the view into that leftover space.
- **Below 1280×720 the game drops to 1x.** A 1024×768 window shows a 640×480
  view at 1x, so most of the window is black. Small windows are therefore a
  poor experience; fullscreen on any common monitor is fine.
- Because the visible area varies (640×360 up to 853×360 or 640×400 and more),
  UI must anchor to screen edges and level framing must not depend on an exact
  view size.
- Text is drawn at the base resolution. The engine's default font with
  antialiasing off is legible but unevenly spaced; a proper pixel font is
  needed (placeholder until art is provided, see the asset register).
- Pixel snapping of moving objects and camera smoothing are not decided here;
  they belong with the first camera work and need the lead's approval.
- The macOS export for Apple Silicon needs
  `rendering/textures/vram_compression/import_etc2_astc = true` (found when the
  first macOS export failed); it is set in `project.godot`.

## Verification

`tests/unit/test_display_settings.gd` fails if any value in the table changes.
`tests/unit/test_test_card.gd` checks the expected scale at common window sizes.
The test card (`scenes/showcase/test_card.tscn`) is rendered on every pull
request at six window sizes for visual review.
