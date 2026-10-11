# 2026-10-11: Millbrook, walkable

Stage 3 of four (`docs/roadmap.md`): Millbrook as a place to walk,
explore and fight in.

## Done

- **`AreaMap`**: reads an area's text map, says which cells are solid,
  finds the numbered places, and turns cells into positions. Floodwater is
  solid until drained.
- **Collision**: `CombatSim` takes an area map, and its solid cells block
  like obstacles.
- **`FollowCamera`** (ADR-0015):
  - a dead zone of about 2 × 1.5 tiles;
  - catches up in about 0.15 s;
  - never past the edges on any screen shape;
  - on whole screen pixels.
- **`Area`**:
  - the clock (starting 9:00);
  - day and night rosters, swapped only out of every screen's sight;
  - creatures back at 6:00, bosses never;
  - falling means waking at the entrance the next morning, since the farm
    is not built.
- **`Millbrook`**: the accepted map, the encounter plan (31 creatures by
  day), Grist's yard with its props, the fungus and firefly lights.
- **The scene**:
  - the map drawn in code;
  - creatures and the player on top;
  - the clock's tint, the night sight ring, a HUD with the time;
  - developer keys F6–F9;
  - reachable from the title (F2) and with `--start-scene millbrook`.
- **Review renders**: the lane by day, the green at night, the whole map
  with the roster.
- `CombatInput.read()` now reads the controls for both the arena and areas.

## What broke, and how it was found

- **The accepted map had two flaws**, found by a test that walks it from
  the entrance:
  - The wheat field had no way in.
  - The floodwater could be walked around, so the ford was never cut off.
  - Fixed in the sketch script: a gap in the field's hedge, and the brook
    running south from the mill race to the map's edge.
  - The docs' map, its picture and the code's map were regenerated from the
    script, and the change is noted under the map's key. These are layout
    changes, flagged to the lead.
- **Two creature spots were wrong**: a hedgehog inside the lane's safe
  radius, and a moth inside a cottage. Found by the safe-ground and
  reachability tests.
- **A boss defeated outside a simulation step was not recorded** (the area
  only listened for the event). The area now checks its bosses directly.
- **The renders showed three things**:
  - the numbered place markers drawn as plain grass squares (one on the
    green);
  - a hard two-step night ring;
  - "day 2" on the first morning (I added 1 to a day count that starts at
    1).
  - All fixed and re-rendered.
- **Three deliberate breaks survived at first**:
  - "come back only at dawn": the test counted the defeated rook as
    present;
  - "clamp after rounding": the smoothing never landed exactly on the
    edge;
  - and, the same way, the dawn test's Grist count.
  - Each test was strengthened, and the break now fails it.

## Checked

- `tools/run-tests.sh`: all pass, no leaks at exit.
- 13 deliberate breaks of the area and camera rules, each failing a test.
- Review renders at all ten sizes; checked:
  - the overview at 1920×1080;
  - the lane at 1920×1080, 1024×768 (4:3, 1x) and 5120×1440 (32:9);
  - the night green at 1920×1080 and 2560×1080.

## Not done

- Stage 4: notes and the satchel, the crank, the sluice and the flood
  draining, the ford's exit, Grist's heart, the mill's inside.
- Drawing buildings in front of fighters behind them (comes with the art).
- Feel: `docs/playtests/2026-10-11-millbrook-walkable.md`.
