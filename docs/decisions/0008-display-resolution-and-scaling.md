# ADR-0008: Display: 640×360 base, 16 px tiles, whole-number scaling

- **Status:** Accepted
- **Date:** 2026-10-09
- **Decided by:** Project lead (open question Q1, recommendation accepted 2026-10-09)
- **Amended:** 2026-10-09 by the project lead: 21:9 and 32:9 screens at 1080p
  and 1440p are supported targets; the game starts fullscreen (Q12). See
  "Amendment" below. Amended again 2026-10-09 (Q15): 32:9 shows the whole
  world; UI width setting. See "Amendment 2".

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

## Amendment (2026-10-09, project lead)

**Supported screen shapes** now explicitly include ultrawide and super
ultrawide at 1080p and 1440p. With the settings above (unchanged), the renders
show:

| Screen | Shape | Visible area | Scale | Borders |
|---|---|---|---|---|
| 2560×1080 | 21:9, 1080p | 853 × 360 | 3x | 1 px column |
| 3440×1440 | 21:9, 1440p | 860 × 360 | 4x | none |
| 3840×1080 | 32:9, 1080p | 1280 × 360 | 3x | none |
| 5120×1440 | 32:9, 1440p | 1280 × 360 | 4x | none |

32:9 shows twice the width of 16:9 (80 tiles instead of 40); see Amendment 2.

**The game starts fullscreen** (Q12): `display/window/size/mode = 3`
(Fullscreen; 4 would be Exclusive Fullscreen). Fullscreen makes the window the
size of the screen, so every screen in the table above and every common 16:9
monitor is shown at a whole-number scale with no bars. A way to leave
fullscreen (options menu, shortcut) belongs with the input model (Q6).
Developers can start windowed with Godot's `--windowed` flag.

How the display settings behave is captured in `src/core/display_math.gd`
(`DisplayMath`): the visible area keeps 360 (or 640) base pixels on the short
side and grows on the long side to the screen's aspect ratio, rounded down;
the scale is the largest whole number that fits.

## Amendment 2 (2026-10-09, project lead, Q15)

**The world is never capped:** 32:9 screens see the full 1280×360. Level
layout and the camera must cope with views up to 80 tiles wide; how areas
narrower than the view are framed is decided with the first level layout and
camera work.

**UI width setting:** HUD and menus sit in a `UiFrame` whose width the player
sets to full (default), 21:9 or 16:9. "21:9" is 43:18 (3440×1440), the widest
common 21:9 panel, so it changes nothing on real 21:9 monitors and on 32:9
matches a 3440×1440 screen. Stored in `user://settings.cfg`
(`GameSettings`). The options menu that changes it comes with the first menu.

## Verification

`tests/unit/test_display_settings.gd` fails if any value in the table changes,
including the fullscreen start. `tests/unit/test_display_math.gd` pins the
visible area and scale for every screen named above.
`tools/render_showcase.gd` checks every render's real visible area against
`DisplayMath` (fails with exit 4) and, when a window manager runs (CI), that
the window really is fullscreen (exit 5).
The test card (`scenes/showcase/test_card.tscn`) is rendered on every pull
request at ten screen sizes for visual review.
