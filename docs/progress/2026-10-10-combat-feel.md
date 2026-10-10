# 2026-10-10: Combat feel changes (lead feedback)

**Asked:** after playing, five changes:
1. a stagger should reset an attack, not pause it;
2. greatsword and hammer reach about 40% more;
3. more haptic feedback, especially on the hammer charge;
4. a hammer charge in three levels, the last one overchargeable, lower levels
   weaker, a perfect level 3 sending a cone-shaped shockwave forward;
5. telegraphs that match how far a lunging attack really reaches.

## Done

What was built, per point, is recorded in `docs/design/combat.md`, "Combat
feel changes (lead, 2026-10-10)", and in the hammer table.

1. **Stagger:** a staggered creature now waits its cooldown after
   recovering, so its next attack starts from scratch. The cooldown is set
   in `CombatSim.stagger`, which every stagger goes through, Frozen
   included.
2. **Reach:** every greatsword and hammer move reaches about 40% further,
   and the drawings are longer to match.
3. **Rumble:**
   - `Haptics.sustain()` holds a rumble while something is held. The arena
     feeds it every tick from `CombatSim.player_rumble()`, which asks the
     weapon's `charge_rumble()`.
   - New effects for charge levels, overcharge, dodge, evading, Brace, armour
     break, swap and running out of stamina.
4. **Hammer:**
   - Three levels (300 / 600 / 900 ms), with the existing sweet spot as
     level 3 and overcharge past it.
   - New strike grades: tap, level 1, level 2, perfect, overcharged.
   - The shockwave is a 70° cone forward (`CombatMove.shockwave_arc_deg`).
   - The meter shows level notches and pips.
5. **Telegraph = hit zone:** `CombatSim.attack_zone()` replaced the old
   sector test. It includes the lunge, stays where the lunge starts, and
   fills as it travels. The drawer draws the same zone and its far edge.
- Review poses: hammer panel 3 now shows the cone (three creatures in it
  staggered, one behind untouched). The greatsword sheet's telegraph panel
  now freezes on a lunge's last tick, the player just outside the outline
  and unhit.
- Tests: `tests/unit/test_combat_attack_zone.gd` (new), plus hammer, arena
  and haptics tests. Suite: 214 passing.
- Playtest: `docs/playtests/2026-10-10-combat-feel.md`.

## What broke and how it was found

- **This work was started by an earlier session whose context was lost.**
  I found it uncommitted on this branch. I read every change against the
  five points before building on it, and ran the suite: 5 failures.
- **Two failures were float precision.** `Vector2` holds 32-bit floats, so
  rumble levels of 0.2 came back as 0.20000000298. The haptics tests now
  compare with a tolerance.
- **One was a test expecting the wrong thing.** The lunge zone is already
  full after the lunge's last tick, so it cannot grow on that tick. The
  test now checks the zone grows through the lunge and ends full.
- **Two were the shove tests, a real consequence of the longer reach.** The
  light swing that sets up the shove now reaches a creature 37 px away,
  which it used to miss, so the creature took 10 more damage than the test
  expected. A trace showed the shove itself hit once and there was no
  impact. The tests now measure from just before the shove.
- **Two review poses misrepresented the new rules.** Hammer panel 3 was
  still titled "staggers all", but under the cone the creatures beside and
  behind were correctly untouched, so it was restaged. The greatsword
  sheet's telegraph panel could not show point 5 at all, so it now freezes
  at the end of a lunge.
- **Deliberate breaks:** 18 in all. Two were not caught at first:
  - Removing the windup-time origin update went unnoticed, because the test
    only checked the origin during the windup. It now also checks the
    lunge starts from where the creature was shoved to.
  - Removing the arena's `sustain` call went unnoticed, because nothing
    tested the scene feeds the rumble. A new arena test holds the heavy
    button with `Input.action_press` and checks the rumble is refreshed
    each tick.
  - Every break is now caught.

## Not done (and why)

- DualSense trigger resistance for the charge: still the later ADR-0013
  prototype.
- How the rumble feels, whether the reach and the cone are right, and
  whether the outline now reads as accurate: on the playtest checklist.
