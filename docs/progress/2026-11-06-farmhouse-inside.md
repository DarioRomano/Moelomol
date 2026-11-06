# 2026-11-06: The farmhouse inside

The lead asked for the house and a pause menu, then further steps. The
lead accepted the room's layout on 2026-11-06 (`base.md`, "The farmhouse
inside") and chose Esc / Start for the pause menu (built next). This note
covers the house: `base.md`'s build order, step 2.

## Done

- **The room** (`scenes/farm/house.tscn`, `src/farm/house_layout.gd`):
  12 x 8 tiles inside its walls; its own place (ADR-0016), joined to the
  farm at the farmhouse door with the usual fade.
- **`HouseSim`**: walking, Interact on the faced tile, the clock, no
  spells and no combat.
  - **The bed** sleeps to the next 6:00 with Mana full, and saves the game
    (ADR-0017). The farm's door no longer sleeps; it leads inside.
  - **The seed tin**, on the cupboard by the door, holds the first seeds (6
    catmint, 6 radish; Q25). Taken once into the bag ("The seed tin: 6
    catmint seeds, 6 radish seeds."), then empty. The house remembers it.
- **Where the player wakes:** a new game, sleeping and falling in Millbrook
  (Q36) all start beside the bed. A new game's bag is empty: the seeds are
  in the tin.
- **Saves from before the house** (format 1 without a `"house"` entry) load
  with the tin already emptied (their seeds were given straight into the
  bag), and a save made sleeping at the farm door wakes in the house. The
  format stays 1.
- **Drawing** (`HouseDrawer`, placeholder): floorboards, the back wall with
  two double windows that show the sky (dark at night), the cup on its
  hook, the bed, the window seat, the stove with embers, the empty cat
  basket, the table with a candle and two chairs (the second pushed in),
  the cupboard and tin (lid off once taken), the rug, the doorway showing
  outside. Indoors the day's tint is softened and warmed; at dusk and night
  the candle and stove glow.
- A place opened on its own (F2, `--start-scene house`) starts with the tin
  already emptied into the bag, so the farm can be tried straight away.
- Review scenes: `house` (6:00) and `house_night` (22:00, the tin full).

## What broke, and how it was found

- **The first render** showed the stove's glow in hard concentric rings,
  spilling past the wall, and blue window panes at night. The glows now
  use ten faint steps and stay inside the room; the panes darken with the
  lights.
- A test edit of mine mixed integer and float vectors; caught reading it
  back before running.
- Deliberate breaks, all caught: the tin giving seeds every time; the
  house forgetting the tin; arriving by the door placed at the bed; old
  saves getting the seeds twice; falling sending the player to the farm
  door; the bed not saving; the farm's door still a bed; the bed not
  refilling Mana; the door never leading out; a place opened on its own
  with no seeds.

## Left out, and why

- The stove does nothing (cooking is not designed); the cat, its basket and
  window seat wait for step 4; waking with the cat on the blanket (Q36)
  comes with the cat.
- Interact is still Space / A at the farm and in the house, F / B in
  Millbrook: Q39 is open.

## Checked

- `tools/run-tests.sh`: all pass.
- Renders of the house at 16:9 and 4:3 and at night, looked at.
- Not verifiable here: how the room feels, and going in and out by the
  door: `docs/playtests/2026-11-06-farmhouse-inside.md`.
