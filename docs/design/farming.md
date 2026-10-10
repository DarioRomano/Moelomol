# Farming and the day–night cycle

- **Status:** Decided by the lead on 2026-10-10 (Q21–Q27 in
  `open-questions.md`). Values marked **starting value** are the engineer's
  placeholders for tuning; Q28 (where farming magic comes from) is open.
- **Binding constraints:**
  - ADR-0005: one base, the only place farming happens; peaceful, no combat
    there; no characters, so **no shops or merchants**.
  - ADR-0010: the pet cat; the cat treats recipe from the start.
  - ADR-0008 / ADR-0014: 16 px tiles, top-down ¾ view.
- **Related:** `art-direction.md` ("Light and time": dusk at the base is the
  emotional peak of the day), `story.md` (the treats, the pet's story
  moments), `combat.md` (stamina; Mana and enhanced weapon skills).

## What farming should feel like

1. **Unhurried.** The world has ended; nothing is chasing the player at home.
   The clock gives the day a shape, not a deadline. Forgetting to water costs
   time, never the crop (Q24).
2. **The one warm place.** The base is where things grow. Tilled soil, green
   shoots and a lit window at dusk are the warmest things on screen
   (`art-direction.md`: warmth means life).
3. **Readable at a glance.** Dry or watered soil, a crop's stage, and "ready
   to harvest" must be obvious from the tile alone, without UI.
4. **A rhythm with adventuring.** Plant in the morning, go out, come home at
   dusk, water, sleep, find things grown. Farming feeds crafting and cooking;
   adventuring brings back seeds, materials and story.
5. **Farming is magic** (Q27). The player tills, waters and sows with spells,
   paid for in Mana. A day's farming is a day's Mana.

## The day–night cycle (Q21, Q22)

### The clock

- **A full day, 24 game hours, lasts 20 real minutes**: one game hour is
  50 real seconds.
- **The day fully cycles.** Sleep is never required; nothing forces the day
  to end. The player can stay up through the night.
- **The new day starts at 6:00**, whether the player is asleep or not. That
  is when crops grow (below) and the day count goes up.
- The clock runs everywhere, at the base and on adventures. It pauses in
  menus and while reading notes (once those exist).
- There is **no hunger**. Eating is never required (see "Food and
  cooking").

| Phase | Time | What changes |
|---|---|---|
| Dawn | 6:00–7:00 | Pale, cool light warming up; crops have grown |
| Day | 7:00–18:00 | Full light |
| Dusk | 18:00–20:00 | Light turns amber, then blue; the base's warm lights come on (art direction's emotional peak) |
| Night | 20:00–6:00 | Blue and dark; only lights are warm |

### Sleep

- **Sleeping** in the bed at the base, at any time, skips to the next 6:00
  and **refills Mana** (Q27).
- Staying up costs nothing in itself; it just means no Mana refill.

### Night (Q21; mostly for adventuring)

- **Sight is impaired at night.** At the base this is the night tint. Out
  in the areas, how far the player sees is designed with the areas (for
  example a smaller lit circle around the player).
- **Different monsters spawn at night.** Their roster comes with the areas
  and the enemy design.
- **Environmental effects can light up spaces at night**: glowing plants,
  embers, the base's windows. They are both mood and a tool: a place to see
  by.

### Light

- The whole world is tinted by the time of day: one colour multiplied over
  the scene, changing smoothly through the phases. Cheap: no per-pixel
  lighting (ADR-0007).
- The HUD is never tinted.
- **Lights** (windows now; lanterns, glowing plants later) are drawn
  untinted, so they stay warm when the world goes blue.
- Real 2D light sources need the base art and a measurement against the
  performance budget first.

## Mana (Q27)

- **All farming is done with magic and costs Mana.**
- **Mana refills from sleep (fully) and from food** (a meal restores some;
  amounts come with cooking). There is **no passive refill**.
- **Mana is shared with fighting:**
  - **enhanced weapon skills consume Mana**;
  - **basic attacks, including magic's basic spells, do not**.
  - This keeps magic a viable fighting style when farming has spent Mana.
  - How this lands in combat is in `combat.md`, "Mana" (reading R1).
- Starting values: Mana 100.

## Farming spells

| Spell | Mana (starting value) | On | Result |
|---|---|---|---|
| **Till** | 2 | Grass (not paths, not the house) | Tilled soil (brown furrows) |
| **Water** | by tier (below) | Tilled soil in its area, planted or not | Watered, darker soil until the next 6:00 |
| **Sow** (one per seed kind) | 1 | Tilled soil with nothing on it | Plants one seed from the bag |
| Harvest | free (by hand) | A ripe crop | Produce and seeds into the bag |
| Sleep | free | The bed (the farmhouse door in the test scene) | The next 6:00; Mana full |

- The player casts on **the tile in front of them**, highlighted (Q26:
  works without a mouse, ADR-0013). For the watering spell the whole area is
  highlighted.
- **Harvest is by hand** (reading R2): picking a ripe crop is not a spell.
- Not enough Mana: the spell does not happen, with a dull rumble and the Mana
  bar flashing. Planting also needs a seed of the kind.

### The watering spell (Q23)

It starts small and grows with **farming upgrades**. The upgrade system
itself is not designed yet (ADR-0005 point 8).

| Tier | Area | Mana (starting value) |
|---|---|---|
| 1 (start) | **4 tiles**: 2 × 2, from the target tile forward and to the right | 4 |
| 2 | 9 tiles: 3 × 3, centred across the target, reaching forward | 8 |
| 3 | 25 tiles: 5 × 5 | 16 |
| 4 (final) | **Rain**: the weather turns rainy until the next 6:00, which waters every tilled tile on the farm, including tiles tilled later that day | 30 |

- The area extends from the target tile in the direction the player faces,
  so the player aims it by where they stand.
- Rain is the first piece of weather. Other weather is not designed.

## Crop growth (Q23, Q24)

- **Crops grow overnight.** At 6:00, each crop whose soil was watered since
  the last 6:00 grows by one day; then all soil dries.
- Each crop needs a number of grown days to ripen (3–4 for the first
  crops). Its look passes through four stages: seed, sprout, growing, ripe.
- **A ripe crop waits.** It does not rot or wither.
- **An unwatered crop does not grow that day**, and nothing worse happens.

## Seeds without shops (Q25)

There are no merchants (ADR-0005). Seeds come from the world:

- **A starting seed tin** in the farmhouse, with the first seeds, including
  **catmint**, the treats' crop (ADR-0010, Q14: the treats are the crafting
  tutorial).
- **Harvests give seeds back** (starting value: 2 per harvest).
- **New kinds of seed are found on adventures**: forage, abandoned gardens,
  seed packets beside notes. This ties farming to exploration and the story.

## Food and cooking (Q21, Q27)

- **Grown crops can be cooked for buffs.** Eating is never required (no
  hunger).
- **Food also restores Mana**, so cooking feeds both farming and fighting.
- The cooking system and its recipes (the cat treats first) are their own
  design pass. Nothing is built yet.

## Crops (placeholder content)

Only enough to prove the system with two different growth times. Real crops
are designed with crafting, cooking and the areas.

| Crop | Days to ripen | Harvest (starting value) | Why |
|---|---|---|---|
| Catmint | 4 | 1 catmint + 2 seeds | The cat treats ingredient (ADR-0010) |
| Radish | 3 | 1 radish + 2 seeds | A quicker second crop |

## Controls at the base (Q26; ADR-0013: actions, all rebindable)

The base has no combat, so its actions reuse the same physical buttons with
farming meanings:

| Action | Keyboard | Controller |
|---|---|---|
| Move | W A S D | Left stick |
| Cast the selected spell | J | X / Square (the light-attack button) |
| Interact (harvest, sleep, later doors and notes) | Space | A / Cross |
| Next / previous spell | E / Q | RB / LB |

## Readings taken (say if any is wrong)

- **R1. Combat and Mana.** "Enhanced weapon skills" is read as weapon skills
  improved through the weapon skill trees (`combat.md`, progression hooks).
  None exist yet, so no combat move costs Mana today. The existing weapon
  skills (Brace, Ground stamp, Volley, Release) and magic's Focus stay as
  they are. If you meant the current skill-button moves, it is a small
  change: give each a Mana cost.
- **R2. Harvesting is by hand**, free; only tilling, watering and sowing are
  spells.
- **R3. The day turns over at 6:00.** Crops grow and the day count rises
  then, asleep or awake. Sleeping skips to the next 6:00.
- **R4. Mana has no passive refill**: only sleep and food.

## Not decided here

- Animals (named in the brief; their own design pass).
- Seasons; weather beyond the rain spell.
- Cooking and the treats recipe.
- The farming skill tree and the upgrades that unlock the watering tiers.
- Saving the game.
- Where farming magic comes from (Q28).
- How the farm looks: the base layout is a level-layout decision for the
  lead.

## Built so far (2026-10-10)

**The farm test scene** (`scenes/farm/farm_test.tscn`; F2 from the title, or
`--start-scene farm_test`). It is a test field, not the base's design.

- **Built:**
  - The clock: a 24-hour cycle in 20 real minutes, its phases, the
    time-of-day tint and the windows lighting up through dusk.
  - The day turns over at 6:00 on its own; sleep at the farmhouse door
    skips to it and refills Mana.
  - Mana and the farming spells: Till, Water (all four tiers, rain
    included), Sow.
  - Overnight growth of watered crops through four stages, and harvest by
    hand with seeds back.
  - Two placeholder crops and a starting seed tin.
  - A HUD with the day and time, the selected spell and its cost, Mana,
    the bag and the controls; soft rumble for each spell.
- **How:**
  - A deterministic simulation like combat (`src/farm/`: `GameClock`,
    `FarmPlot`, `CropKind`, `Inventory`, `FarmSim`; `src/core/mana.gd`),
    stepped at 60 Hz.
  - The scene reads input and draws (`FarmDrawer`, placeholder shapes in
    the palette).
  - Rule tests drive the simulation directly.
- **Developer keys:**
  - F8: sleep now.
  - F9: time 30 times faster.
  - F10: next watering tier, since there is no upgrade system to unlock
    them yet.
- **Not built yet:**
  - food and cooking;
  - Mana costs in combat (R1);
  - the farming upgrades;
  - clearing a crop (it needs a confirmation);
  - saving;
  - the pet at the farm;
  - animals;
  - night sight and monsters in the areas;
  - real 2D lights;
  - pausing the clock in menus.
- Feel can only be judged by playing: `docs/playtests/2026-10-10-farming.md`.
