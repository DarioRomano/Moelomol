# 2026-10-09: Renderer feature check (Q5)

## What was done

The lead accepted Q5 option A (Compatibility renderer everywhere). The
recommendation was conditional on checking that no needed 2D feature is
missing, so `scenes/showcase/renderer_features.tscn` now uses six 2D features
under the Compatibility renderer, each in a labelled panel, and is part of
every PR's visual review renders (30 renders per run now). The decision is
recorded as ADR-0012 in the decisions PR of the same day.

## Result (renders looked at, 1920×1080 and 5120×1440)

All six work under Compatibility in Godot 4.7.2 (Mesa llvmpipe, OpenGL 4.5
core):
1. PointLight2D with hard shadows from a LightOccluder2D, under CanvasModulate.
2. GPUParticles2D. 3. CPUParticles2D.
4. Custom canvas_item shader. 5. Screen-reading shader (`hint_screen_texture`)
   with BackBufferCopy. 6. Additive blending.

## What broke, and how it was found

- **My screen-reading panel showed a flat strip** instead of inverted bars.
  Found by looking at the render. Cause: `BackBufferCopy` defaults to copying
  a 200×200 rect around its own position, here (0,0), so the strip read stale
  pixels. Fixed with `COPY_MODE_VIEWPORT`; noted in the scene.

## Not checked

2D glow/HDR through WorldEnvironment, normal-mapped 2D lighting, and anything
on real GPUs (only Mesa's software renderer here). Real GPUs go on playtest
checklists; glow and normal maps get checked if the art direction asks for
them.
