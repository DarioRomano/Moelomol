# 2026-10-10: Hammer, armour and weapon swap

**Asked:** "move on to the implementation of the other weapons" (after Q20 =
A). This is the first of three PRs (hammer, bow, magic).

## Done

- **Weapons as classes.** New `Weapon` base (`src/combat/weapon.gd`). The
  greatsword's light/heavy/skill code moved from `CombatSim._try_action`
  into `Greatsword` (now a `Weapon`); its moves and numbers are unchanged
  and its 46 tests pass untouched apart from the arena test (three
  creatures now). `CombatSim.start_attack` and `stagger` became public
  because weapons call them.
- **Loadout and swap (Q19).** The player carries the greatsword and the
  hammer; `weapon_swap` (Tab / RB, device -1) swaps from standing or an
  attack's recovery, 1.5 s cooldown. A swap ends the greatsword chain.
- **Charging.** New `Fighter.State.CHARGE`: the sim moves the player at
  28 px/s, pauses stamina refill, and lets dodge or skill cancel; the weapon
  decides when to release. The bow's draw will reuse it.
  `CombatInput.heavy_held` added; the arena reads it.
- **Hammer** (`src/combat/hammer.gd`): jab, charge with the 900 ms sweet spot
  and its three grades (early, perfect, Overstrain with the stamina drain and
  forced release), Rhythm (max 3, narrows the window, +25% per stack),
  perfect-strike shockwave and armour break, Ground stamp. Values and the
  readings I took of the design are in `docs/design/combat.md`, "Hammer,
  weapon swap and armour as built".
- **Armour.** `Fighter.armour`: 40% of damage gets through while the shell
  lasts, every hit chips it by its full damage (impacts too), a perfect
  strike shatters it, respawn restores it. The arena has a third training
  creature with a 60-point stone shell, bottom right. This adds a creature to
  the debug arena's layout; it is a test scene, but say if you would rather
  have it behind a developer key.
- **Accessibility:** `hammer_wide_sweet_spot` in `GameSettings` (section
  `[accessibility]`): 300 ms window, no narrowing. No options menu yet.
- **Feedback:** five rumble effects (charge hum, sweet-spot click, hammer
  hit, jab, perfect strike = heaviest pulse, checked by a test); events
  `charge_start`, `sweet_spot`, `strike`, `shockwave`, `armour_break`,
  `swap`, `swap_blocked`. Effects for the shockwave ring and shell shards;
  effect handling moved into `CombatDrawer.update_effects`, shared by the
  arena and the pose sheets.
- **Drawing:** placeholder hammer (carried, raised while charging with the
  head flashing white in the sweet spot and red past it, swing, strike), a
  charge meter above the player, the shell on the creature and its bar.
- **Review renders:** the poses scene was split into `PoseSheet` (shared) and
  two sheets: `combat_poses.tscn` (greatsword, unchanged) and the new
  `hammer_poses.tscn` (jab, sweet spot, shockwave, shell shatter,
  Overstrain, Ground stamp), added to `tools/render-showcase.sh`.
- Tests: `tests/unit/test_combat_hammer.gd` (29 tests), binding and setting
  tests in `test_combat_arena.gd`. Suite: 140 passing.
- Playtest checklist: `docs/playtests/2026-10-10-hammer.md`.

## What broke and how it was found

- **Charge stamina refilled while holding.** The first test of the charge
  expected 85 stamina after holding and found more: the regen delay ran out
  mid-charge. Decided that holding a charge pauses refill (the sim calls
  `Stamina.hold()` each charge tick).
- **Two of my own tests were wrong** at first: one held the charge past the
  sweet spot (so the drain applied) while asserting no drain; one compared
  rumble durations, where the faint 0.9 s charge hum is longer than the
  perfect strike's pulse. The second now compares strength × duration.
- **The sweet-spot zone vanished under the meter fill** in the first hammer
  render (panel 2: a full white bar, no visible zone). Fixed with notches
  above and below the zone edges, drawn over the fill; checked at 1280×720,
  1920×1080 and 3840×1080.
- **Deliberate breaks:** twelve changes to the code (no cooldown, sweet
  spot one tick longer, no shockwave, no armour break, Rhythm kept when hit,
  stamina refill while charging, wide setting ignored, stamp without its
  stagger, no drain, armour without reduction, charging at full speed,
  setting not saved), each run against the tests for that rule: every one
  makes at least one of them fail.

## Not done (and why)

- The rising tone at the sweet spot: no audio system yet.
- A perfect strike counting as a Release: needs magic's effects (magic PR).
- DualSense adaptive trigger for the charge: the later ADR-0013 prototype.
- A developer key to choose the loadout: comes with the third weapon, when
  there is a choice to make.
- Feel, timing fairness, rumble and real-machine performance: not
  verifiable headlessly; on the playtest checklist.
