# 2026-10-11: Millbrook's creatures and Grist, built

**Asked (the lead):** varied enemies, the first area and its themed boss;
design, then build. This is stage 2 of four (`docs/roadmap.md`): the
creatures, in the combat simulation and the arena.

## Done

- **Creature kinds:** `CreatureKind` holds each kind's data and
  `CreatureBrain` its behaviour.
  - Six creatures: field mice (swarm, zigzag, scatter), rooks (aloft out of
    melee reach, dive lane, land), hedgehogs (curl against light hits, roll
    lane, daze on walls), flood toads (lob at a marked circle, slick, hop
    back, resist Smoulder), stooks (hidden as sheaves, rise and lash, Smoulder
    at 3) and moths (swirl at lights, dart, spent on the hit).
  - The training creature now runs through the same brain as the Chaser.
- **Grist:**
  - Gore, and a charge down the lane to the first thing in its way: walls
    and stones stun it, sacks burst and bring three mice.
  - At half health it wallows (untouchable) for 80 mud armour, at most
    twice.
  - Phase two shrugs off the fence once for a second charge and heaves the
    yard's millstones, which roll, bounce once and rest as obstacles.
  - It sleeps at night unless woken by a hit or a near approach.
  - It is defeated once and leaves its heart and tusk.
- **Shared rules:** lane telegraphs (the hit zone), props, lights, night,
  rolling millstones, the slick, heavy hits (finishers, Follow-through, the
  Riposte, hammer strikes).
- **Arena:** F11 cycles creature sets; F12 toggles night. The HUD shows
  the set.
- **Review sheets:** `creature_poses` and `grist_poses`, added to the
  renders.
- **Placeholder art:** every creature is drawn in code, labelled in the
  asset register.

## What broke, and how it was found

- **The training creature had no moves of its own**, so the first run
  logged errors on every creature tick. Found by the suite's
  logged-error check.
- **Respawning reset the arena's shell creature's armour to its kind's
  (none).** An existing hammer test caught it; respawn keeps the old rule.
- **Grist's charge stopped just short of every wall** (I subtracted its
  radius twice), so it was never stunned. Found by the charge test; charges
  now run their lane plus 8 px.
- **The design's double charge could never happen** once every charge ended
  in a stun. Settled as "phase two shrugs off the fence once"; millstones
  always stun. Recorded in `enemies.md`.
- **A charge that met the fence at a slant slid along it** and was never
  stunned. Found by tracing a failing phase-two test. Charges now end when
  they stop making headway along their lane.
  - A deliberate break of that rule survived until I added a slanted-wall
    test, at an angle clear of the corners. Added to CLAUDE.md.
- **In the review render, the grain-sacks panel showed no burst.** The
  panel's sacks were off the charge's lane; moved.
- **My first creature colours used the reserved warm palette** (the
  hedgehog's body, straw, mud). Switched to the muted and changed colours
  before rendering.

## Checked

- `tools/run-tests.sh`: 315 passed, 0 failed, no leaks at exit.
- 39 deliberate breaks of the new rules, each failing its test (after the
  slanted test was added).
- Review renders at all ten sizes. Checked: creature and Grist sheets at
  1920×1080 and 1366×768, and the arena at 2560×1080.

## Not done

- Placing them in Millbrook, the night roster on the clock, creatures back
  at 6:00, drops' uses, the heart's use: stages 3 and 4.
- Feel: `docs/playtests/2026-10-11-creatures-and-grist.md`.
