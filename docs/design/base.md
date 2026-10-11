# The base: the farm

- **Status:** Proposal (2026-10-11), for the lead. The layout is the lead's
  decision (CLAUDE.md, level layout); nothing here is built. The farm test
  scene (`scenes/farm/farm_test.tscn`) stays a test field until this is
  accepted.
- **Binding constraints:**
  - ADR-0005: the only place farming happens; peaceful; no combat.
  - ADR-0010: the pet lives here.
  - `farming.md`: Q21–Q27, all decided: the clock, farming by spells paid in
    Mana, the watering tiers up to rain, seeds without shops, the bed.
  - `art-direction.md`: the base is the one warm place; dusk is the
    emotional peak.
- **Open questions:**
  - Q33: how big the base is (this draft assumes the recommendation, about
    one and a half screens).
  - Q32: the camera.
  - Q34: whether the gate is a scene change.

## What the farm should feel like

- **One glance, one home.** From the porch the player sees almost the whole
  farm: the field, the pond, the gate. Nothing important is ever more than
  a few seconds' walk away (the player walks 5 tiles a second; the gate is
  about 22 tiles from the door, under five seconds).
- **Lived in, but by one person.** Everything is sized for one farmer: one
  bed, one chair at the table, one cup on the hook. A second chair is
  there, pushed in, never used (a quiet touch, never explained).
- **Wilder towards the edges.** The house and the field are tended; the
  corners of the farm are long grass and old fields. Bringing them back is
  part of progress.
- **The world can be seen from it.** The gate looks down the lane towards
  Millbrook. On wide screens the wild country beyond the fences shows: the
  farm is small in a large, empty land.

## The layout

North is up. The farm is 48 × 30 tiles of ground inside a hedge and a fence,
with woods behind it to the north and the gate in the south.

![The farm, proposal sketch](images/base.png)

Each character below is 2 × 2 tiles (the picture shows the same map):

```text
tttttttttttttttttttttttt
#,,......HHHHH...~~~~.,#
#.BBB....HHHHHA.~~~~~,,#
#.BBB....HHDHH..~~~~~,,#
#.BbB......=L...~~~~.f,#
#.s============.n.ff.f,#
#,,,:::TTTT=::::.fffff,#
#C,,:::TTTT=::::.ffoff,#
#PPP:::TTTT=::::.fffff,#
#PPP:::::::=::::..fff,,#
#PPP:::::::=::::...ff,,#
#,,,:::::::=,,,,....,,,#
#,,,,,,....=.....,,,,,,#
#,,,,,,....=m....,,,,,,#
###########GG###########
```

| Key | What | Key | What |
|---|---|---|---|
| `t` | Woods (the north edge, not walkable) | `#` | Hedge and fence |
| `.` | Grass | `,` | Long grass, walkable |
| `=` | Path | `H` `D` | Farmhouse and its door |
| `B` `b` | Workshop and its door | `s` | Storage chest |
| `T` | The first field (can be tilled from the start) | `:` | Old field under long grass (tilled once cleared) |
| `~` | Pond | `n` | Bench by the pond |
| `A` | The old apple tree | `L` | Porch lamp |
| `P` `C` | Animal pen and coop (empty, broken) | `f` `o` | Wildflower meadow, a rock |
| `m` | Mailbox | `G` | The gate, out to the lane |

### What each place is for

Numbers match the sketch.

1. **The farmhouse** (10 × 6 tiles). The door opens on one room (below).
   Its windows light up at dusk (already built in the test scene).
2. **The workshop.** Where crafting and weapon enhancement will happen
   (ADR-0005 point 7). Neither is designed yet; the building is reserved
   for them. The player's weapons hang inside on pegs.
3. **The first field: 8 × 6 tiles (48 tiles)**, next to the path and close
   to the door.
   - It can be tilled from the start.
   - That is more than one day's Mana can till and water at once
     (`farming.md`: Till 2 per tile, the first watering spell 4 per 4
     tiles; Mana 100), so the first days are about choosing what to plant.
4. **The old fields: about 180 more tiles** under long grass, west and
   east of the path.
   - They are cleared a patch at a time through a farming upgrade (not
     designed yet; Proposal).
   - Then they can be tilled like the first field.
   - The rain spell waters all of it.
5. **The animal pen and coop.**
   - Empty and broken at the start: their fence is down, the coop door
     hangs open.
   - The first animal can come from Millbrook (`area-millbrook.md`, the
     hen; Proposal).
   - Animals are not designed yet; this is where they will live.
6. **The pond and its bench.**
   - The bench faces west, into the sunset: the place to watch dusk
     (`art-direction.md`, the emotional peak).
   - Nothing to do there but sit. Sitting fast-forwards the clock gently
     while the player watches, as a quiet alternative to sleeping through
     to morning (Proposal).
7. **The old apple tree.**
   - A forage tree: a few apples every day.
   - **The cat's tree**: one of the places it sits.
8. **The wildflower meadow.** Open ground with a rock. Space for later
   things (beehives if honey becomes a crop, a drying rack), kept empty on
   purpose for now.
9. **The mailbox** by the gate.
   - It is always empty. Interacting shows the empty box: no text.
   - It is one of the loneliest objects in the game, and it costs nothing.
   - Reserved for one uncanny story moment late on (Proposal; `story.md`).
10. **A, the gate:** out to the lane and Millbrook.
11. **B, the porch lamp.** Lit at dusk with the windows.
12. **C, the storage chest:** outside the workshop, for materials.

### The farmhouse inside (Proposal)

One room, about 12 × 8 tiles, entered by the door:
- **the bed** (sleep; `farming.md`);
- **the stove** (cooking, when it is designed; the cat treats are made
  here first);
- **the seed tin** (the starting seeds, catmint included; `farming.md`);
- **a table with two chairs**, one never used;
- **a basket by the stove** for the cat;
- **a window seat**, another of the cat's places.

From inside, the windows show the time of day.

## The pet's places

ADR-0010: the cat lives here and wanders. It has favourite spots:
- the porch step;
- the old apple tree;
- the pond bench (beside the player when they sit);
- the window seat;
- the basket by the stove;
- the top of the workshop roof.

The roof is a place a cat could reach, but the player never sees it climb
up. `story.md`'s small impossible things happen in these places, rarely:
the cat sitting in two of them a moment apart, a shadow that does not
match it. Its behaviour is a separate design pass; the layout only gives
it the places.

## Light and the day

- **By day** the farm is the warmest thing on screen: amber house, green
  crops, brown soil (`art-direction.md`).
- **At dusk** the windows and the porch lamp come on. The bench looks into
  the sunset, and the lane beyond the gate goes blue first.
- **At night** the warm lights stay untinted; the rest of the farm sits in
  the night colour (`farming.md`, "Light").
- **Rain** (the watering spell's final tier) falls over the whole farm,
  inside the fences only (Proposal: the farm's own weather, a hint that the
  farm is not quite natural).

## On every screen (depends on Q32, Q33)

![The farm on each screen shape](images/base_views.png)

| Screen | Sees (tiles) | The farm |
|---|---|---|
| 16:9 | 40 × 22.5 | Almost all of it; the camera moves a little (8 tiles across, 7.5 up and down) |
| 16:10 | 40 × 25 | Almost all of it |
| 21:9 | 53 × 22.5 | All its width, with the hedges and a strip of wild land either side |
| 32:9 | 80 × 22.5 | All its width and 16 tiles of wild country beyond each side |
| 4:3 at 1x (1024×768) | 40 × 30 | All its height |

- **Beyond the fence is scenery**, drawn but never walkable: wild fields
  and hedgerows going grey-green with distance, the woods to the north,
  and the lane leaving the gate.
- **The base scene therefore draws 84 × 36 tiles**, so no screen sees an
  edge.

## Built later, in this order (Proposal)

1. **The farm layout** replaces the test field: the house, the first field,
   the pond, the paths, the gate (exit only, until Millbrook exists).
2. **The house inside** with the bed and the seed tin.
3. **The pet** in its places (ADR-0010).
4. **Then**, with their own design passes: the old fields' clearing
   upgrade, the workshop's crafting, the stove's cooking, the pen's
   animals.

Nothing in this list is scheduled until the lead accepts the layout.
