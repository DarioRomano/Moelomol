# 2026-10-11: Millbrook's objective, notes and satchel

Stage 4 of four (`docs/roadmap.md`): Millbrook's objective, its notes and
the satchel.

## Asked along the way

- **Interact and satchel buttons** (input model, the lead's call). The
  lead chose: interact on **F / B** (free in combat; Space / A is the dodge)
  and the satchel on **I / View**.
- **The two map corrections** from stage 3 were confirmed by the lead
  before PR #34 was merged.

## Done

- **Area rules:**
  - things to interact with, and the satchel (newest first);
  - the loose thread on objective notes until the objective is done;
  - the crank;
  - the sluice (stuck without the crank);
  - the floodwater draining over 10 s once it opens;
  - exits reported once on entry (the ford only once drained);
  - Grist's heart left where it falls, and the tusk with it;
  - no interacting mid-attack.
- **Millbrook:**
  - ten draft notes (`millbrook_notes.gd`; the tenth appears after Grist);
  - the crank by the miller's door;
  - the sluice and its note at the mill door (no interiors yet);
  - exits at the lane's top and the ford.
- **The scene:**
  - note paper and satchel views, with time paused while either is open;
  - an F/B prompt above what is in reach;
  - a quiet HUD line for what was taken;
  - notes drawn as warm paper;
  - the crank, the sluice wheel and the heart drawn;
  - the drain shown cell by cell.
- **Review scenes:** the miller's note open; the meadow half drained.

## What broke, and how it was found

- **Grist's heart did not appear when the boss fell outside a simulation
  step**: the area listened only for the defeat event, which the next step
  clears. Found by the heart test. The area now looks at its bosses after
  every step.
- **The first render of a note** had its "F / B" hint wrapped one letter
  per line, and ruled lines that did not match the text's line spacing.
  Fixed (no wrap on the hint; one rule under the title).

## Checked

- `tools/run-tests.sh`: 346 passed, 0 failed, no leaks at exit.
- 14 deliberate breaks of the new rules, each failing a test.
- Review renders at all ten sizes; the note checked at 1920×1080,
  1280×800 and 3840×1080, the drained meadow at 1366×768.

## Not done

- The farm (the lane's exit, waking in bed, the heart's use), the second
  area, interiors, saving, a satchel review render.
- Feel and writing: `docs/playtests/2026-10-11-millbrook-objective.md`.
