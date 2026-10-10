# ADR-0014: Camera perspective: top-down ¾ view

- **Status:** Accepted
- **Date:** 2026-10-10
- **Decided by:** Project lead (open question Q18, recommendation accepted
  2026-10-10)

## Context

The perspective was never decided, although every sprite, the combat design
and level layout depend on it. Options and trade-offs:
`docs/design/open-questions.md`, Q18.

## Decision

The game is seen **top-down at a ¾ angle**: the ground from above at an
angle, characters and objects drawn slightly from the front, as in most
farming games. Movement is free in eight directions (analog on a stick).
There is no jumping.

## Consequences

- Characters and attacks are drawn in four facing directions (south, north,
  east; west mirrored), possibly eight later (`combat-art-prompts.md`).
- Objects are drawn with a lighter top face and a darker front face; draw
  order follows the y position (lower on screen is in front).
- Combat uses the whole plane: pushes, area attacks, kiting, lock-on and soft
  aim (`combat.md`).
- Camera behaviour (following the player, framing areas narrower than wide
  screens) is still to be decided with the first exploration area; it needs
  the lead's approval (CLAUDE.md). The combat arena uses a static camera.
- Reversing this would mean redrawing every sprite and redesigning combat.
