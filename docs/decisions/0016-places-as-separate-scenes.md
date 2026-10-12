# ADR-0016: The farm and each area are separate scenes, joined at exits

- **Status:** Accepted
- **Date:** 2026-10-11
- **Decided by:** Project lead (open question Q34, recommendation A accepted
  2026-10-11)

## Context

ADR-0005 says the base and adventure areas "can be built as separate scene
families", and that no combat happens at the base. The farm and Millbrook
designs (`docs/design/world.md`, `base.md`, `area-millbrook.md`) needed a
choice between separate scenes and one seamless world. The options and
trade-offs are in `docs/design/open-questions.md`, Q34.

## Decision

1. **Each place is its own scene:** the farm, the farmhouse inside, and
   each area.
2. **Places join at exits.**
   - Walking into one (the farm's south gate, the top of Millbrook's lane)
     fades the screen to the time of day's colour for about 0.3 s.
   - The player then appears at the matching entrance of the next place,
     facing away from it.
3. **The clock keeps running** through a transition (`farming.md`).
4. **The farm scene loads no combat at all:** no creatures, no combat
   simulation. Weapons are put away at the gate and drawn again in the area.

## Consequences

- Peace and danger are apart by construction (ADR-0005 point 2), not by a
  rule inside one scene.
- Each place loads, is tested and is measured against the performance
  budget (ADR-0007) on its own.
- Saving records which place the player is in and what each place
  remembers (notes found, the objective done, the boss defeated).
- The places must be drawn to continue each other visibly: the lane seen
  from the farm's gate, the farm's hedge seen at the top of the lane.
- Reversing to a seamless world would mean merging scenes, streaming, and
  moving "no combat at the base" into a border rule.

## Verification

When the first transition is built: a test walks the player through the
farm's south gate and back, and asserts the entrance position and facing on
each side, that the clock advanced, and that the farm scene contains no
combat nodes.

Implemented 2026-10-12: `tests/unit/test_places.gd` walks the player down
the farm's lane and up Millbrook's, asserting the entrance positions and
facing on each side and that the clock ran on, and checks that the farm
scene holds no combat nodes, values or code.
