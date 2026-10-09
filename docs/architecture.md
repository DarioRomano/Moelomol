# Architecture

## Status

No code exists yet (Milestone 0). This document will describe the scene
structure, autoloads, data flow and save format as they are built. Do not
describe planned architecture here as if it exists; planned work lives in
`docs/roadmap.md` and design docs.

Constraints the architecture must honour once code exists:
- ADR-0002: Godot 4.7.2-stable only.
- ADR-0003 (proposed): statically typed GDScript only.
- ADR-0005: one base; no combat at the base; no character/dialogue systems.
- ADR-0007 (proposed): performance budget, values pending.

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
