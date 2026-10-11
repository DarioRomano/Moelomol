# 2026-10-11: A much bigger farm, opened by bosses

**Asked (the lead):** "Make the farm much bigger, but overgrown. Clearing
bosses unlocks more areas of the farm." This answers Q33.

## Done

Design only; nothing built.

- **`base.md` redrawn around the whole farm.**
  - The farm is 160 × 96 tiles (about 4 × 4 screens at 16:9), inside woods.
  - The homestead (the earlier 48 × 30 design) is open from the start, at
    the bottom centre by the gate to Millbrook. It gains north, west and
    east gates onto the overgrown parcels.
  - Six overgrown parcels open one per boss, in a proposed order: the great
    fields, the east pasture and big barn, the old orchard, the walled
    garden and glasshouse, the north woods and the spring, and last the
    hill and windmill, which looks over the whole world.
  - Each parcel holds a building to restore and one trace of the farm's
    past.
  - The cat is always first into a newly opened parcel.
- **How a parcel opens: Q38**, recommending C: the overgrowth is ordinary
  (the farm went wild before the calamity); each boss drops its heart;
  Clear cast on a parcel's thicket with the heart withers it all back.
  - `base.md` follows C as a working assumption.
  - C adds a Clear spell for long grass (2 Mana a tile, starting value)
    and a small backstory, both flagged for approval.
- **Bosses:** each area has one boss, defeated once, separate from the
  area's objective (`world.md`, `combat.md`). Millbrook's boar is now the
  Old Boar, the first boss. It drops the heart for the great fields and is
  still not needed for the ford (`area-millbrook.md`).
- Q33 marked resolved; Q32's note about the farm corrected (the farm is now
  larger than every view); `farming.md` points to the Clear proposal.
- **Sketches:** a new farm overview (`images/estate.png`); the homestead
  sketch gains its gates; the screen-shape sketch now shows the overgrown
  farm beyond the hedges.

## What broke, and how it was found

- **Two homestead rows came out 25 characters wide** after adding the
  gates; the sketch script's width check caught it.
- **The first overview drew the great fields' outline as a plain
  rectangle** cutting through the orchard and pasture, seen in the render.
  Borders are now drawn from the map data.
- **The great fields' size was overstated** (2,900 tiles instead of about
  2,800 with the track), found by counting the map's squares; corrected in
  `base.md` with the Mana figure.
- **The text map's digits did not match the opening order**, which would
  have confused the parcel table; the map now uses the opening order.

## Checked

- The maps in `base.md` match the script's output.
- Sizes: parcels and walking time computed from the map (the great fields
  about 2,800 tiles; 160 tiles across at 5 tiles a second, about 32 s).
- Every place the earlier docs relied on the farm being small (framing,
  camera, the old fields' upgrade, the boar) updated.
- `tools/run-tests.sh` passes; no code changed.

## Not done

- How many areas the world has (the parcel count assumes six bosses;
  `base.md` says what happens with more or fewer).
- Restoring the parcels' buildings, the Clear spell's tiers, animals.
