# ADR-0005: Core design constraints

- **Status:** Accepted
- **Date:** 2026-10-09
- **Decided by:** Project lead (brief of 2026-10-09)

## Context

These constraints come straight from the project brief. They shape the code
architecture (what systems exist, what content pipelines are needed, what is
never built), so they are recorded as a decision rather than only as design
notes. Details, balance and content belong in design documents; this ADR holds
only the constraints themselves.

## Decision

1. **One base.** There is exactly one base, and it is the only place farming
   happens. Crops and animals are farmed there.
2. **Farming is peaceful and separate from fighting.** No combat happens at the
   base. Farming and fighting are distinct modes of play.
3. **Story through adventuring.** The player progresses the story by
   adventuring: fulfilling objectives unlocks new areas.
4. **No characters to meet.** The player character is the last remaining person
   after a calamity. There are no NPCs, companions, merchants, quest givers or
   dialogue partners. (Monsters exist as enemies; whether any non-hostile
   creatures exist is not decided here.)
5. **Environmental storytelling only.** The player learns what happened only
   through environmental hints and notes found in the world.
6. **Tone: lonely.** Art, audio, writing and systems should support the feeling
   of being the last one left.
7. **Crafting and enhancement.** Equipment is crafted and enhanced from farmed
   materials and monster drops.
8. **Upgrade systems.** There are multiple upgrade systems, covering farming,
   fighting, exploration and foraging capabilities.
9. **Skill enhancement.** There is a skill enhancement system for farming and for
   fighting.
10. **Trinkets and artefacts.** Exploration yields trinkets and artefacts that
    support differing playstyles.

## Consequences

- No dialogue system, NPC scheduling, relationship or shop-keeper systems are
  ever built. Any "trading" or "shop" idea must be expressed without a
  character (and needs the lead's approval as a design change).
- A note/document system and environmental-prop pipeline are core content
  systems, not extras.
- Base and adventure areas can be built as separate scene families with
  separate rules (for example, no combat components loaded at the base).
- How the upgrade systems, skill systems and trinkets interact is a design
  question for later milestones. Nothing here specifies numbers, counts or
  balance.
- Reversing any of points 1, 2, 4 or 5 would change the game's identity and
  would require a superseding ADR.
