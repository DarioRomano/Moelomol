# 2026-10-11: Enemy roster, Millbrook's encounters and its boss

**Asked (the lead):** "I accept the layouts. Continue with some more varied
enemy design, the first outside levels and its themed boss." Asked how far
to go, the lead chose: design, then build Millbrook playable.

## Done (this pull request: design)

- **Layouts accepted:** the farm (`base.md`) and Millbrook
  (`area-millbrook.md`) recorded as accepted.
- **`docs/design/enemies.md`:**
  - Eight behaviour archetypes, each with one idea the player learns to
    answer: Chaser, Swarmer, Flyer, Curler, Artillery, Ambusher,
    Light-seeker, Brute.
  - Millbrook's six creatures, with starting values: field mice, rooks,
    hedgehogs, flood toads, stooks (sheaves of wheat that rise) and moths
    (night).
  - The themed boss, **Grist, the miller's boar**. It fights in the
    miller's yard with its millstones, grain sacks, mud wallow and trough:
    - charges stun it against hard things, and bursting sacks bring mice;
    - at half health it wallows for mud armour, double-charges and rolls
      millstones;
    - it sleeps at night, so the crank can be fetched without the fight.
  - New telegraph shapes the roster needs: a lane, a ground circle, all
    round.
- **`area-millbrook.md`:**
  - A zone-by-zone encounter plan, day and night, in the order a first
    visit takes. It teaches one idea at a time, ending with the boss.
  - The boar renamed Grist throughout.
- `combat.md`, `base.md`, the roadmap (new milestone with four stages), the
  docs index and `CLAUDE.md` updated.

## What broke, and how it was found

- My first draft listed stooks as day-only in one place and day-and-night
  in another, and had mice coming from a barn the yard does not have.
  Found re-reading against the map; fixed.

## Not done yet

- Stages 2–4 (creatures, the area, the objective) follow as their own pull
  requests.
- No playtest checklist: nothing new to play in this one.
