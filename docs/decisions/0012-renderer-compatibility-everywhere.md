# ADR-0012: Renderer: Compatibility everywhere

- **Status:** Accepted
- **Date:** 2026-10-09
- **Decided by:** Project lead (open question Q5, option A, 2026-10-09)

## Context

Godot's web export always uses the Compatibility renderer (OpenGL 3.3 /
WebGL 2); desktop defaults to Forward+. The web build is a CI validation check
(Q7). The options are in `docs/design/open-questions.md`, Q5.

## Decision

`rendering/renderer/rendering_method = "gl_compatibility"` on every platform
(also for `.mobile`; the web default is already Compatibility).

## Consequences

- The Web build check, the desktop builds and the review renders all use the
  same renderer, so the renders represent what players see.
- Widest hardware support (OpenGL 3.3), which suits the GTX 1050 Ti minimum
  spec (ADR-0007).
- Feature check, 2026-10-09 (`scenes/showcase/renderer_features.tscn`, rendered
  on every PR): 2D lights with hard shadows, GPU particles, CPU particles,
  custom canvas shaders, screen-reading shaders with BackBufferCopy, and
  additive blending all work. Not checked: 2D glow/HDR and normal-mapped 2D
  lighting; checked if the art direction asks for them.
- Features exclusive to Forward+ are not available. Switching later is one
  setting, but every visual would need re-reviewing.

## Verification

`tests/unit/test_project_rules.gd` fails if the setting changes; the renderer
feature showcase shows a lost feature in review.
