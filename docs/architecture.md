# Architecture

## Status

Milestone 1: project skeleton, tests and CI. There is no gameplay code. This
document describes only what exists; planned work lives in `docs/roadmap.md`
and the design docs.

Constraints the architecture must honour:
- ADR-0002: Godot 4.7.2-stable only.
- ADR-0003 (proposed, applied): statically typed GDScript only; untyped
  declarations are parse errors.
- ADR-0005: one base; no combat at the base; no character/dialogue systems.
- ADR-0007 (proposed): performance budget, values pending.
- ADR-0008: 640×360 base, `viewport` stretch, `integer` scale, `expand` aspect.

## What exists

**Scenes**
- `scenes/boot/boot.tscn` (main scene): instances the test card and draws the
  title over it.
- `scenes/showcase/test_card.tscn`: draws a pixel-scale test pattern in
  `_draw()` from the visible viewport rect, so it adapts to `expand`.

**Code (`src/`)**
- `Palette` (`src/art/palette.gd`): the draft palette as typed constants.
- `BuildInfo` (`src/core/build_info.gd`): reads `res://build_stamp.json`,
  written by `tools/export.sh` before export and included through each
  preset's `include_filter`; returns `dev` values when absent.

**Tests (`tests/`)**
- `run_tests.gd` extends `SceneTree`: discovers `test_*.gd`, runs `test_*`
  methods (with `await`), supports `before_each`/`after_each`, and registers a
  `Logger` (`OS.add_logger`) that turns any error logged during a test into a
  failure. Exits 1 on any failure, load error, or if no tests ran.
- `TestCase`: assertion helpers; `assert_eq` also compares types.

**Tools and CI** are described in ADR-0009 and `CLAUDE.md`.

## Appendix: Godot APIs verified against the running engine

Each entry records what was checked, how, and on which version. Re-verify on any
engine upgrade.

### 2026-10-09, Godot 4.7.2.stable.official.ed1daf0bf (Linux, headless)

Method: a `SceneTree` script run with
`--headless --path <empty project> -s probe.gd`, printing
`ProjectSettings.has_setting`, the setting's default value, the property's
`hint_string`, and `ClassDB.class_exists`.

**Project settings** (name: default; allowed values)

| Setting | Default | Allowed values |
|---|---|---|
| `display/window/size/viewport_width` | 1152 | 1–7680 or greater |
| `display/window/size/viewport_height` | 648 | 1–4320 or greater |
| `display/window/stretch/mode` | `disabled` | `disabled`, `canvas_items`, `viewport` |
| `display/window/stretch/aspect` | `keep` | `ignore`, `keep`, `keep_width`, `keep_height`, `expand` |
| `display/window/stretch/scale_mode` | `fractional` | `fractional`, `integer` |
| `rendering/textures/canvas_textures/default_texture_filter` | 1 (Linear) | Nearest, Linear, Linear Mipmap, Nearest Mipmap |
| `rendering/2d/snap/snap_2d_transforms_to_pixel` | false | bool |
| `rendering/2d/snap/snap_2d_vertices_to_pixel` | false | bool |
| `rendering/renderer/rendering_method` | `forward_plus` | `forward_plus`, `mobile`, `gl_compatibility` |
| `rendering/renderer/rendering_method.web` | `gl_compatibility` | (from `--doctool` output) |
| `physics/common/physics_ticks_per_second` | 60 | 1–1000 |
| `audio/buses/default_bus_layout` | `res://default_bus_layout.tres` | `*.tres` |

Note: the default texture filter is **Linear**. Pixel art needs Nearest; this
must be set explicitly in Milestone 1.

**Classes**

| Class | Exists in 4.7.2 |
|---|---|
| `TileMapLayer` | yes |
| `TileMap` | yes (still present; its deprecation status could **not** be checked, see below) |
| `CharacterBody2D` | yes |
| `KinematicBody2D` | **no** (Godot 3 name) |
| `AudioStreamInteractive` | yes |
| `AudioStreamSynchronized` | yes |
| `AudioStreamPlaylist` | yes |
| `AudioStreamGenerator` | yes |
| `AudioStreamWAV` | yes |
| `AudioStreamOggVorbis` | yes |

Existence only. Behaviour of the audio stream classes is not yet verified.

**Limitation found:** the official release binary's `--doctool` output contains
signatures and defaults but no descriptions and no deprecation markers. It
cannot be used to check whether something is deprecated. Use `TileMapLayer`,
not `TileMap`, regardless.

### 2026-10-09 (Milestone 1), Godot 4.7.2.stable.official.ed1daf0bf

Same probe method, plus real runs of the export and render tools.

**Command-line flags** (from `--help`): `--headless`, `--import` (imports and
quits; exits non-zero on failure), `--export-release <preset> <path>`,
`--export-debug`, `--export-pack`, `--resolution WxH`, `--position X,Y`,
`--display-driver x11` with `--rendering-driver opengl3`, `--quit-after <n>`,
`-s <script>`, and `--` before user arguments (`OS.get_cmdline_user_args()`).

**Project settings**

| Setting | Default | Allowed values |
|---|---|---|
| `display/window/size/window_width_override` / `_height_override` | 0 | 0–7680 / 0–4320 |
| `debug/gdscript/warnings/untyped_declaration` | 0 | Ignore, Warn, Error (2 = error, makes it a parse error) |
| `gui/theme/default_font_antialiasing` | 1 | None, Grayscale, LCD Subpixel |
| `gui/theme/default_font_hinting` | 1 | None, Light, Normal |
| `gui/theme/default_font_subpixel_positioning` | 1 | Disabled, Auto, One Half, One Quarter |
| `rendering/textures/vram_compression/import_etc2_astc` | false | bool; **must be true** to export macOS `universal` or `arm64` |
| `application/config/version` | empty | string |

**APIs**
- `Logger` and `OS.add_logger()` / `OS.remove_logger()` exist. Overriding
  `_log_error(function, file, line, code, rationale, editor_notify, error_type,
  script_backtraces)` receives GDScript runtime errors (`error_type` 2) and
  `push_error` (0). The erroring function aborts at the error line. Verified by
  a probe and by the deliberately broken `boot.gd` in the test-mutation run.
- `DisplayServer.screen_get_image(screen)` returns the full screen under Xvfb
  with llvmpipe. `DisplayServer.screen_get_image_rect(rect)` returned an
  **empty image** in the same setup. Do not use the rect variant there.
- `Engine.get_version_info()` returns major/minor/patch/status/build/hash.
- Under Xvfb, Mesa reports "OpenGL API 4.5 Core, llvmpipe"; Godot logs a
  harmless warning that V-Sync cannot be changed.

**Export**
- Templates archive: `Godot_v4.7.2-stable_export_templates.tpz`, 1,281,349,702
  bytes, a zip with a `templates/` folder; installed to
  `~/.local/share/godot/export_templates/4.7.2.stable/`.
- Minimal presets (name, platform, filters, path, a few options) are enough;
  missing options take defaults. All four presets exported from Linux. The
  macOS export is a zip containing `Moelomol.app` with an ad-hoc signature
  (`_CodeSignature/` present). Web with `variant/thread_support=false` uses the
  `web_nothreads_*` templates.
- An exported Linux build ran 120 frames under Xvfb with exit code 0 and no
  errors; the build stamp was embedded.
- Windows and macOS builds have **not** been run (no such machines here).
