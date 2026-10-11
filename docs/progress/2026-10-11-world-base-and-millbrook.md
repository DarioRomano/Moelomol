# 2026-10-11: Designing the farm and the first area

**Asked (the lead):** "Alright, now let's design the farm and the first
outside area."

## Done

Design only; nothing built (level layout, the camera and balance are the
lead's decisions).

- **`docs/design/world.md`:** the rules every area shares.
  - The base at the centre; areas in rings of distance.
  - Exits and transitions.
  - Safe ground at each area's entrance from the base.
  - Day and night rosters, sight at night.
  - What comes back at 6:00 (creatures, forage) and what never does
    (notes, seeds, trinkets).
  - Places to come back to with later upgrades.
  - Framing for screens up to 80 tiles wide.
- **`docs/design/base.md`:** the farm, 48 × 30 tiles.
  - The house with one room inside, and the workshop (reserved for
    crafting).
  - A first field of 48 tiles, and about 180 more under long grass for a
    clearing upgrade.
  - The pen and coop (empty), the pond with a sunset bench, the cat's apple
    tree, an always-empty mailbox, the gate.
  - The cat's places, light through the day, and how the farm looks on
    every screen shape.
- **`docs/design/area-millbrook.md`:** the hamlet below the farm, 112 × 64
  tiles.
  - Lane, green, school, chapel, orchard, wheat field, beehives, the mill
    and the miller's yard.
  - The objective: the south road is under floodwater because the mill's
    sluice is shut; the crank is in the miller's cottage, in a boar's
    yard; opening the sluice drains the meadow and opens the ford south.
  - Creatures (field mice, crows, the boar, night moths), notes with three
    drafts, rewards, and places to reach later.
- **Q32–Q37** in `open-questions.md`, each with a recommendation: camera,
  base size, separate scenes, starting weapons, falling in an area, how
  objectives are shown.
- **Sketches:** `docs/design/images/` holds the two layout maps and the
  farm on each screen shape, plus the script that draws them
  (`make_sketches.py`, `make_screen_views.py`; Pillow).

## What broke, and how it was found

- **Images in `docs/` were being imported by Godot.** The importer wrote a
  `.png.import` beside each sketch, since `docs/` is inside the project.
  Exports already exclude `docs/`; an empty `docs/.gdignore` now stops the
  import. Checked: three `.import` files without it, none with it.
  Recorded in the architecture appendix and in CLAUDE.md's layout table.
- **First Millbrook sketch:** the render showed problems I then fixed.
  - The school overlapped the cider shed.
  - The path to the chapel ran through a cottage.
  - The mill race and footbridge were muddled.
  - The north-east was empty; the beehives went there.
- **The screen-shape sketch** hid the 16:9 outline under the 4:3 one and
  overlapped the labels; it now uses a legend.
- **Two numbers in the drafts were wrong:**
  - The gate is about 22 tiles from the farmhouse door, not 12.
  - Millbrook's whole lane, not its top third, is inside the 20-tile safe
    radius.
  - Both were found by checking the docs against the maps; both fixed.

## Checked

- Every map in the docs matches the script's output (the docs' maps are
  pasted from it).
- Numbers checked against the maps and existing values:
  - walking speed 5 tiles/s;
  - views 40/53/80 × 22.5 tiles and 40 × 30;
  - Mana costs from `farming.md`;
  - the first field's 48 tiles.
- Story rules (`story.md` rules 1–5, stage 1 near the base) checked
  against every note and hint in Millbrook: the only cats are a lost-pet
  poster and a child's drawing.
- `tools/run-tests.sh` passes; no code changed.

## Not done

- The second area (only its edge, beyond the ford), the world map and
  fast travel, crops behind Millbrook's seeds, creature stats, the pet's
  behaviour, animals, crafting, saving.
- No playtest checklist: there is nothing new to play.
