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
- ADR-0008: 640×360 layout size, `canvas_items` stretch (full-resolution
  rendering), `integer` scale, `expand` aspect.

## What exists

**Scenes**
- `scenes/boot/boot.tscn` (main scene): instances the test card and draws the
  title over it.
- `scenes/showcase/test_card.tscn`: draws a pixel-scale test pattern in
  `_draw()` from the visible viewport rect, so it adapts to `expand`.

**Code (`src/`)**
- `Palette` (`src/art/palette.gd`): the draft palette as typed constants.
- `WindowControls` (`src/core/window_controls.gd`, **autoload**): the
  fullscreen shortcuts (Q6d): actions `toggle_fullscreen` (Alt+Enter, Windows
  and Linux) and `toggle_fullscreen_macos` (Ctrl+Cmd+F) in `project.godot`.
  Handles them in `_input` so they work over menus. No `class_name`: an
  autoload's name must not also be a class name.
- `DevTools` (`src/core/dev_tools.gd`, **autoload**) with `FrameStats`
  (`src/core/frame_stats.gd`): the performance overlay (Q16). F3 or both
  stick buttons: overlay; F2: cycle showcase scenes; F4: V-Sync. Launch
  options `--perf-overlay`, `--start-scene <name>`, `--no-vsync` (not
  `--scene`, which the render tool uses; autoloads also run under the render
  tool and the test runner).
- `BuildInfo` (`src/core/build_info.gd`): reads `res://build_stamp.json`,
  written by `tools/export.sh` before export and included through each
  preset's `include_filter`; returns `dev` values when absent.
- `GameSettings` (`src/core/game_settings.gd`): player settings in
  `user://settings.cfg`; so far only the UI width (Q15). `GameSettings.shared()`
  is the game-wide instance (a static, not an autoload); it emits `changed`.
- `UiFrame` (`src/ui/ui_frame.gd`): put HUD and menus inside one. Its rect is
  the visible area narrowed to the UI width setting, centred. Its parent must
  cover the whole view.

**Tests (`tests/`)**
- `run_tests.gd` extends `SceneTree`: discovers `test_*.gd`, runs `test_*`
  methods (with `await`), supports `before_each`/`after_each`, and registers a
  `Logger` (`OS.add_logger`) that turns any error logged during a test into a
  failure. Exits 1 on any failure, load error, or if no tests ran.
- `TestCase`: assertion helpers; `assert_eq` also compares types.

**Combat (`src/combat/`, `scenes/combat/`)**
- `CombatSim`: the combat rules as a deterministic simulation. `step(input)`
  once per 60 Hz physics tick; positions in layout pixels; the arena is a
  walkable `Rect2` with rectangular obstacles; fighters are circles with
  hand-written collision (no Godot physics bodies). Emits `events` (hit,
  impact, stagger, dodged, down, ...) for feedback.
- `Fighter` (state machine data), `CombatMove` (timing in ms, converted to
  ticks), `Greatsword` (moves and chain rules), `Poise`, `Stamina`,
  `CombatInput`, `CombatTuning` (all starting values).
- `CombatDrawer` draws a sim on any `CanvasItem` (placeholder shapes), with
  optional render interpolation between ticks (Q20).
- `scenes/combat/combat_arena.tscn`: reads InputMap actions into a
  `CombatInput` in `_physics_process`, steps the sim, plays haptics, draws.
  `CombatHud` sits in a `UiFrame`.
- `scenes/showcase/combat_poses.tscn`: scripted sims frozen at telling
  moments, for the review renders.
- `Haptics` (`src/core/haptics.gd`): named rumble effects (ADR-0013).

Why a custom simulation: every rule is testable headlessly and
deterministically (tests call `step()` directly), timing windows are exact
tick counts, and nothing depends on physics-engine behaviour that would need
separate verification.

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

### 2026-10-09 (performance overlay), Godot 4.7.2.stable.official.ed1daf0bf

Probed under Xvfb with the Compatibility renderer (llvmpipe):
- `Performance.get_monitor()` with `TIME_FPS`, `TIME_PROCESS`,
  `TIME_PHYSICS_PROCESS` (seconds), `MEMORY_STATIC`, `RENDER_VIDEO_MEM_USED`
  (bytes), `RENDER_TOTAL_DRAW_CALLS_IN_FRAME`: all return values.
- `RenderingServer.viewport_set_measure_render_time(rid, true)`, then
  `viewport_get_measured_render_time_cpu/gpu(rid)` (milliseconds): both
  return values under Compatibility.
- `RenderingServer.get_video_adapter_name/_vendor/_api_version`,
  `get_current_rendering_method()` (`gl_compatibility`),
  `get_current_rendering_driver_name()` (`opengl3`), `OS.get_processor_name`,
  `OS.get_processor_count`, `Engine.get_architecture_name()` (`x86_64`).
- `DisplayServer.screen_get_refresh_rate()` returns NaN under Xvfb.
- **Autoloads are instantiated when a script runs with `-s`** (render tool,
  test runner): `root` had a `WindowControls` child.

### 2026-10-09 (input, window, frame rate), Godot 4.7.2.stable.official.ed1daf0bf

Same probe method; plus a search of every class's methods.

**Controller input** (`Input`, existence and signatures only; nothing tested on
a real controller)
- Rumble: `start_joy_vibration(device, weak_magnitude, strong_magnitude,
  duration)`, `stop_joy_vibration`, `has_joy_vibration`, `is_joy_vibrating`,
  `get_joy_vibration_strength/duration/remaining_duration`.
- Light bar: `set_joy_light(device, color)`, `has_joy_light(device)`.
- Motion: `has_joy_motion_sensors`, `set_joy_motion_sensors_enabled`,
  `get_joy_gyroscope`, `get_joy_accelerometer`, `get_joy_gravity`, and
  calibration functions.
- Identity: `get_joy_name`, `get_joy_guid`, `get_joy_info`,
  `get_connected_joypads`, `is_joy_known`.
- **No adaptive-trigger or controller-haptics API exists:** searching every
  class's methods for "adaptive", "trigger_effect", "haptic" and "dualsense"
  found only XR/OpenXR haptics.
- Setting `input_devices/joypads/ignore_joypad_on_unfocused_application`
  (default false).

**Window**
- `display/window/size/mode`: 0 Windowed, 1 Minimized, 2 Maximized,
  3 Fullscreen, 4 Exclusive Fullscreen (`DisplayServer.WINDOW_MODE_*` match).
- Command-line `-f/--fullscreen`, `-m/--maximized`, `-w/--windowed`.
- Under Xvfb **without a window manager**, `window_get_mode()` reports 0 even
  with `--fullscreen`, and `--windowed` still fills the screen: X11 needs a
  window manager for window modes. With openbox (CI), fullscreen reports 3.

**Frame rate and physics**
- `display/window/vsync/vsync_mode`: default 1 (Enabled); Disabled, Enabled,
  Adaptive, Mailbox.
- `application/run/max_fps`: default 0 (uncapped), 0–1000.
- `physics/common/physics_ticks_per_second`: default 60.
- `physics/common/physics_interpolation`: exists, default false.
- `physics/common/max_physics_steps_per_frame`: default 8.
- `physics/common/physics_jitter_fix`: default 0.5.

### 2026-10-09 (full-resolution rendering), Godot 4.7.2.stable.official.ed1daf0bf

- With `stretch/mode = canvas_items` + `integer` + `expand`, the visible area
  (`root.get_visible_rect()`) is identical to `viewport` mode at all ten
  review sizes.
- `root.get_final_transform()` maps layout units to screen pixels, including
  the black-border offset: 1366×768 → scale 2, origin (43, 24); 1920×1080 →
  scale 3, origin (0, 0); 1024×768 → scale 1, origin (192, 144).
  `root.canvas_transform` stays identity; `get_stretch_transform()` has the
  scale without the offset.
- A rect at a fractional layout position (x + 0.5) is drawn at screen
  precision in `canvas_items` mode and snapped to whole art pixels in
  `viewport` mode (the test card's `render_checks()` relies on this).

### 2026-10-10 (combat arena), Godot 4.7.2.stable.official.ed1daf0bf

- `Engine.physics_ticks_per_second` is 60; `Engine.get_physics_interpolation_fraction()`
  exists and returns 0–1 between physics ticks (used for render interpolation).
- Joypad constants: `JOY_BUTTON_A` 0, `B` 1, `X` 2, `Y` 3,
  `RIGHT_SHOULDER` 10; `JOY_AXIS_LEFT_X` 0, `LEFT_Y` 1, `RIGHT_X` 2,
  `TRIGGER_LEFT` 4, `TRIGGER_RIGHT` 5.
- Action events created in code and saved with `ProjectSettings.save()` get
  `"device":16` (keys) and `"device":0` (joypad); **0 means the first
  controller only**. Set `-1` (any device); `InputMap.event_is_action` then
  matches events from any controller (verified with devices 1, 2 and 3).
- `InputMap.event_is_action()` matches a joypad axis at **any** value; the
  action's deadzone only applies in `InputEvent.is_action_pressed()` /
  `get_action_strength()`: with deadzone 0.3, trigger 0.25 is not pressed,
  0.35 is (strength 0.07).
- `Input.get_vector`, `Input.is_action_just_pressed`, `Input.is_action_pressed`
  exist; `is_action_just_pressed` is called in `_physics_process`.
- `CanvasItem.draw_set_transform(offset)` offsets later draw calls (combat
  poses panels).

