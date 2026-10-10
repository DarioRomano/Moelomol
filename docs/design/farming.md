# Farming and the day–night cycle

- **Status:** Draft (2026-10-10), asked for by the lead: "drafting the day /
  night mechanic that progresses crop growth" and "the farming mechanic
  itself". Every choice marked **Proposal** waits for the lead; the forks are
  Q21–Q27 in `open-questions.md`. A first playable slice is built on the
  recommended options as working assumptions (see "Built so far"), so they can
  be judged by playing and changed cheaply.
- **Binding constraints:**
  - ADR-0005: one base, the only place farming happens; peaceful, no combat
    there; no characters, so **no shops or merchants**.
  - ADR-0010: the pet cat; the cat treats recipe from the start.
  - ADR-0008 / ADR-0014: 16 px tiles, top-down ¾ view.
- **Related:** `art-direction.md` ("Light and time": dusk at the base is the
  emotional peak of the day), `story.md` (the treats, the pet's story
  moments), `combat.md` (stamina, which farming does not use).

## What farming should feel like

1. **Unhurried.** The world has ended; nothing is chasing the player at home.
   The clock gives the day a shape, not a deadline. Forgetting to water costs
   time, never the crop (Proposal, Q24).
2. **The one warm place.** The base is where things grow. Tilled soil, green
   shoots and a lit window at dusk are the warmest things on screen
   (`art-direction.md`: warmth means life).
3. **Readable at a glance.** Dry or watered soil, a crop's stage, and "ready
   to harvest" must be obvious from the tile alone, without UI.
4. **A rhythm with adventuring.** Plant in the morning, go out, come home at
   dusk, water, sleep, find things grown. Farming feeds crafting and the
   treats; adventuring brings back seeds, materials and story.

## The day–night cycle

### The clock (Proposal, Q21)

- One game day runs from **6:00 to 2:00** (20 game hours). At the
  recommended pace one game minute is 0.75 real seconds, so **a day is
  15 real minutes**.
- The clock runs everywhere, at the base and on adventures, so a long
  expedition costs farm days. The clock pauses in menus and while reading
  notes.
- Four phases give the day its shape:

| Phase | Time | What changes |
|---|---|---|
| Dawn | 6:00–7:00 | Pale, cool light warming up; crops have grown overnight |
| Day | 7:00–18:00 | Full light |
| Dusk | 18:00–20:00 | Light turns amber, then blue; the base's warm lights come on (art direction's emotional peak) |
| Night | 20:00–2:00 | Blue and dark; only the base's lights are warm |

### Ending the day (Proposal, Q22)

- **Sleeping** in the bed at the base ends the day at any time: the next day
  starts at 6:00.
- **At 2:00 the player falls asleep wherever they are** and wakes in bed at
  6:00. No lost items or money (there is no money). Recommended story touch,
  for the lead's decision: the cat is curled up on the bed when they wake, as
  if it brought them home. It never says so; it fits `story.md` (the pet
  keeps its farmer safe for the treats).
- The night is long enough to come home by and short enough not to feel
  wasted. Whether night changes adventuring (more dangerous creatures,
  things only found at night) is an adventuring design question, not decided
  here.

### Light (Proposal)

- The whole world is tinted by the time of day: one colour multiplied over
  the scene, changing smoothly through the phases. Cheap: one tint, no
  per-pixel lighting (ADR-0007).
- The HUD is never tinted.
- **Later**, with the base art: warm light sources (windows, lanterns, the
  fire) that stay warm when the world goes blue at dusk. They need 2D lights
  or glow sprites and must be measured against the performance budget
  first. The first slice tints only.

## Crop growth (Proposal, Q23)

- **Crops grow overnight.** When a new day starts, each crop whose soil was
  watered the day before grows by one day. This is the day–night cycle
  "progressing crop growth": dawn is when the farm visibly changes.
- Each crop needs a number of grown days to ripen (3–4 for the first
  crops). Its look passes through four stages: seed, sprout, growing, ripe.
- **A ripe crop waits.** It does not rot or wither; it is harvested when the
  player gets to it.
- **Watering lasts one day.** All soil dries at dawn, so a crop needs
  watering again each day it is to grow.

## Soil and actions

| Soil | How it gets there | Looks like |
|---|---|---|
| Grass | Start | The base's grass |
| Tilled | The hoe on grass | Brown furrows |
| Watered | The watering can on tilled soil | Darker, wet soil (until dawn) |
| Planted | Seeds on tilled soil (watered or not) | A seed or plant on the soil |

| Action | Tool or button | On |
|---|---|---|
| Till | Hoe | Grass (not paths, not the house) |
| Water | Watering can | Tilled soil, planted or not |
| Plant | Seeds (one kind selected) | Tilled soil with nothing on it |
| Harvest | Interact | A ripe crop: produce (and seeds, Q25) into the inventory |
| Clear (later) | Hoe | A planted, unripe crop: removes it, with a confirmation so it is never an accident. The rule exists (`FarmPlot.clear`); the hoe does not use it yet |
| Sleep | Interact | The bed |

- The player acts on **the tile in front of them** (the tile their facing
  points at), highlighted so the target is always visible. This works
  without a mouse (ADR-0013: no mouse aiming).
- **No energy bar for farming** (Proposal, Q27): time is the only budget at
  home. Combat stamina is a separate system that does not apply at the base.
- The watering can is unlimited for now. Capacity, refilling at water and
  larger watering areas are natural **farming upgrades** (ADR-0005 point 8)
  and are not built yet. The same goes for the hoe tilling several tiles,
  sprinklers and better soil.

## Seeds without shops (Q25)

There are no merchants (ADR-0005). Seeds must come from the world:

- **A starting seed tin** found in the farmhouse, with the first seeds,
  including **catmint**, the treats' crop (ADR-0010, Q14: the treats are the
  crafting tutorial).
- **Harvests give seeds back** (Proposal: every harvest returns the produce
  plus seeds, enough to replant and slowly expand).
- **New kinds of seed are found on adventures**: forage, abandoned gardens,
  seed packets beside notes. This ties farming to exploration and the story.

## Crops (placeholder content for the first slice)

Only enough to prove the system with two different growth times. Real crops
are designed with crafting and the areas.

| Crop | Days to ripen | Harvest (Proposal) | Why |
|---|---|---|---|
| Catmint | 4 | 1 catmint + 2 seeds | The cat treats ingredient (ADR-0010) |
| Radish | 3 | 1 radish + 2 seeds | A quicker second crop |

## Controls at the base (Proposal, Q26; ADR-0013: actions, all rebindable)

The base has no combat, so its actions reuse the same physical buttons with
farming meanings:

| Action | Keyboard | Controller |
|---|---|---|
| Move | W A S D | Left stick |
| Use tool | J | X / Square (the light-attack button) |
| Interact (harvest, sleep, later doors and notes) | Space | A / Cross |
| Next / previous tool | E / Q | RB / LB |

## Not decided here

Animals (named in the brief; their own design pass), seasons and weather
(Q21 discusses seasons), cooking and the treats recipe itself, the farming
skill tree and upgrades, saving the game, and how the farm looks (the base
layout is a level-layout decision for the lead).

## Built so far (2026-10-10)

**The farm test scene** (`scenes/farm/farm_test.tscn`; F2 from the title, or
`--start-scene farm_test`). It is a test field, not the base's design; the
base's layout is the lead's decision.

- **Built**, on working assumption A for Q21–Q27:
  - The clock (6:00–2:00 in 15 real minutes), its four phases and the
    time-of-day tint, with the base's windows lighting up through dusk.
  - Sleep at the farmhouse door any time; falling asleep at 2:00 and waking
    at home with nothing lost.
  - Till, water, plant; overnight growth of watered crops through four
    stages; harvest of ripe crops into a simple inventory, with seeds back.
  - Two placeholder crops (catmint, radish) and a starting seed tin.
  - Acting on the highlighted tile in front, tool switching, soft rumble per
    action, and a HUD (day and time, tool, bag, controls).
- **How:** a deterministic simulation like combat (`src/farm/`:
  `GameClock`, `FarmPlot`, `CropKind`, `Inventory`, `FarmSim`) stepped at
  60 Hz; the scene reads input and draws (`FarmDrawer`, placeholder shapes
  in the palette). Rule tests drive it directly.
- **Developer keys:** F8 sleeps now (next morning), F9 runs time 30 times
  faster.
- **Not built yet:**
  - The cat-on-the-bed wake-up (Q22: the lead's call).
  - Clearing a crop with the hoe (needs a confirmation).
  - Watering-can capacity and refilling, and the other farming upgrades.
  - Saving the game (the farm resets on quit).
  - The pet at the farm; animals; seasons and weather.
  - Real 2D lights (the tint only, until measured).
  - Pausing the clock in menus (there are no menus yet).
- Feel can only be judged by playing: `docs/playtests/2026-10-10-farming.md`.
