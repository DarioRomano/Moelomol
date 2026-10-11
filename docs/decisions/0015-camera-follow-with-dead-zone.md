# ADR-0015: Camera: follow with a dead zone, clamped to the area

- **Status:** Accepted
- **Date:** 2026-10-11
- **Decided by:** Project lead (open question Q32, recommendation A accepted
  2026-10-11)

## Context

ADR-0014 (top-down ¾) left camera behaviour to the first exploration area.
ADR-0008 left camera smoothing and pixel snapping to the first camera work.
The farm (160 × 96 tiles) and Millbrook (112 × 64) are both larger than
every view. Views range from 40 × 22.5 tiles (16:9) through 80 × 22.5
(32:9) to 40 × 30 (4:3 at 1x), and levels must not depend on one view size
(ADR-0008). The options and trade-offs are in
`docs/design/open-questions.md`, Q32.

## Decision

At the farm and in every area:

1. **The camera follows the player with a dead zone.** It stays still while
   the player moves inside a box of about 2 × 1.5 tiles around the screen's
   centre, then follows smoothly, catching up in about 0.15 s. The box size
   and catch-up time are starting values for playtesting.
2. **It is clamped to the edges of the place,** so the screen never shows
   past them.
3. **Every place is at least 80 × 30 tiles,** drawing scenery the player
   cannot walk into where the playable ground is smaller, so no screen shape
   reaches an edge (`docs/design/world.md`).
4. **The camera's position is rounded to whole screen pixels,** not art
   pixels. Motion stays smooth at full-resolution rendering (ADR-0008,
   amendment 3), and tiles never shimmer.
5. **No look-ahead for now.** Revisit for the areas after the first
   playtest, if creatures seem to come from nowhere.

The combat test arena keeps its static camera: it is a test scene.

## Consequences

- Every area needs scenery around its playable ground for wide screens:
  more art at the edges, never a black border.
- Fights near a place's edge sit off-centre on screen.
- Lock-on, soft aim and the telegraphs (`combat.md`) do not depend on the
  camera, so nothing in combat changes.
- How the camera feels can only be judged by playing; it goes on the first
  exploration playtest checklist.
- Reversing to fixed screens would mean re-cutting every area into rooms
  and would clash with ADR-0008's "never capped".

## Verification

When the camera is built: tests drive it over a place's edges at every
screen shape in `DisplayMath` and assert it never shows past them, and that
its position is a whole screen pixel. Review renders show the farm and
Millbrook at the ten screen sizes.
