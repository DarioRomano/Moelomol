# 2026-10-10: The lead's farming decisions built (Q21–Q27)

**Asked:**
- Merge my own pull requests at my own judgement (see
  `2026-10-10-merge-at-own-judgement.md`).
- Resolve the conflicts on #23.
- Q21: a 20-minute day that fully cycles, with no requirement to sleep; no
  hunger; cooking for buffs; night impairs sight and spawns different
  monsters; environmental effects light spaces. (Q22 is answered by it.)
- Q23: A, plus watering by a spell for up to 4 crops, upgraded later, its
  final form rain that waters the whole farm.
- Q24, Q25, Q26: A.
- Q27: all farming is magic and costs Mana, refilled by sleep and food;
  enhanced weapon skills cost Mana, basic magic attacks do not.

## Done

- **#23 conflicts resolved** by merging `main` (with #22) into the farming
  branch. Both conflicts were lists that both sides added to (the haptics
  table, the API appendix). #23 and #24 are merged.
- **Q21–Q27 resolved** in `open-questions.md`. `farming.md` is rewritten
  around them; `combat.md` gains a "Mana" section.
- **Q28 opened:** where farming magic comes from and whether it shows the
  god's violet. Working assumption C: warm green and gold now, a violet
  thread as the story advances.
- **Clock:** a 24-hour cycle in 20 real minutes (50 s per game hour).
  - The day turns over at 6:00 on its own: crops grow and the count rises.
  - Sleeping skips to the next 6:00.
  - Falling asleep at 2:00 is gone.
  - Windows light at dusk and go out at dawn; the night tint wraps through
    midnight.
- **Mana** (`src/core/mana.gd`): 100. No passive refill; sleep refills it
  fully; `restore()` is there for food.
- **Farming spells:**
  - Till (2 Mana), Water by tier, Sow (1 Mana per seed).
  - Harvest by hand, free.
  - A spell that would do nothing costs nothing and buzzes. Without enough
    Mana nothing happens.
- **Watering spell tiers:**
  - Water, 2 × 2 (4 tiles, 4 Mana): ahead and to the player's right.
  - Water II, 3 × 3 (9 tiles, 8 Mana).
  - Water III, 5 × 5 (25 tiles, 16 Mana).
  - Rain (30 Mana): waters every tilled tile until 6:00, including tiles
    tilled during the rain.
  - Tiers are unlocked by upgrades, which do not exist yet; F10 steps
    through them.
- **Drawing:**
  - A cast glow at the hands, with a mark on the target: an earth puff,
    droplets over the whole watering area, or a falling seed.
  - The watering area outlined; rain streaks, with the world dimmed and
    cooled.
  - A Mana bar and spell costs in the HUD.
- **Review sheet:** `scenes/showcase/farm_spells.tscn` shows the four
  watering tiers mid-cast and the farm in the rain.
- **Readings taken,** listed in `farming.md` (R1–R4):
  - R1: no combat move costs Mana until enhanced skills exist.
  - R2: harvesting is free.
  - R3: the day turns over at 6:00.
  - R4: no passive Mana refill.
- **Tests:** 261 passing. The clock, farm rules and farm scene tests were
  rewritten for the decisions.
- **Placeholders:** all farm art stays placeholder (asset register updated).

## What broke and how it was found

- **The farm pace test showed "06:59" after 50 real seconds.** 3,000
  tick-sized steps sum to 59.99999 game minutes. The display now adds 0.001
  before flooring.
- **My first watering-area code rounded the facing before taking its
  sign.** A shallow diagonal would have given a zero direction, and the
  area would have collapsed onto one tile. I caught it reading the code
  back, before any test ran; it now uses the sign of the stronger axis.
- **One deliberate break survived at first.** Replacing that logic with
  plain rounding still passed: the shallow-diagonal test covered four tiles
  either way. A true-diagonal test now checks the area is a square on the
  grid.
- **The new review sheet's scene file failed to load.** My `sed` replaced
  only the first match on a line, leaving the resource id and its reference
  different. The render tool's load error showed it.
- **Deliberate breaks:** 23 in all, one per new rule:
  - pace, day turnover, sleep target, night past midnight, lights at dawn,
    night tint;
  - growth without sleep, Mana refill on sleep, spell costs, free no-ops,
    the 2 × 2 shape, the player's right, centring, the facing axis;
  - rain watering the farm, rain on new tilling, no double rain, rain
    stopping at 6:00, rain only on tilled soil;
  - Mana's limit, the no-Mana buzz, F10, the HUD's Mana.
  - Every one makes a test fail.

## Not done (and why)

- **Cooking and food:** a design pass of its own. Food is meant to restore
  Mana and give buffs; `Mana.restore()` exists for it.
- **Mana costs in combat:** reading R1. There are no enhanced weapon skills
  yet, and combat and farming don't share a player until there is a save
  or world model.
- **Night sight and night monsters in the areas:** adventuring work.
  Recorded in `farming.md`, "Night".
- **The upgrades that unlock the watering tiers:** the upgrade system is
  not designed.
- **Not checkable here:** the pace of a 20-minute day, Mana balance and the
  feel of casting. They are on the playtest checklist.
