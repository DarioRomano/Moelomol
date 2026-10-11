# The world: how the base and the areas fit together

- **Status:** The structure is decided (the lead's answers to Q32–Q38,
  2026-10-11). Items marked **Proposal** are still the engineer's
  suggestions. Nothing here is built.
- **Binding constraints:**
  - ADR-0005: one base, the only place farming happens; no combat there;
    the story moves forward by adventuring, fulfilling objectives and
    unlocking areas; no characters to meet; environmental storytelling only.
  - ADR-0010: the pet stays at the base.
  - ADR-0008: 640×360 layout, 16 px tiles; views up to 80 tiles wide
    (32:9) and 30 tall (4:3 at 1x); levels must not depend on one view size.
  - ADR-0014: top-down ¾, free movement, no jumping.
- **Related:**
  - `base.md`: the farm.
  - `area-millbrook.md`: the first outside area.
  - `story.md`: three stages of the truth, by distance from the base.
  - `art-direction.md`: warmth means life; the further from the base, the
    more changed.
  - `farming.md`: the clock, night.
  - `combat.md`: creatures hold their ground.
- **Decided by the lead (2026-10-11):**
  - Q32: the camera follows with a dead zone, clamped (ADR-0015).
  - Q33: the farm is much bigger but overgrown, and defeating bosses opens
    more of it (`base.md`).
  - Q34: places are separate scenes joined at exits (ADR-0016).
  - Q35: starting weapons (`combat.md`).
  - Q36: falling means waking in bed (below).
  - Q37: objectives show in the world; notes are kept to re-read (below).
  - Q38: a boss's heart opens its parcel (`base.md`).

## The shape of the world

- **The base sits at the centre, on a hill.** The world falls away from it
  in every direction, and every area is reached from the base, directly or
  through another area.
- **Areas are rings of distance.** The nearer an area, the less changed and
  the earlier its part of the story (`story.md`: ordinary loss near the
  base, the pattern further out, the recognition furthest away). Creatures
  grow stronger with distance in the same step.
- **The first area, Millbrook, lies directly below the farm gate** and is
  open from the start. Each further area is unlocked by an objective in the
  one before it (ADR-0005 point 3). Millbrook's objective opens the way
  south.
- **Each area has one boss** (the lead, 2026-10-11). Defeating it opens the
  next overgrown parcel of the farm (`base.md`). The boss is separate from
  the area's objective: the objective opens the way on, the boss gives back
  farmland. A player can press on without beating a boss and come back for
  it later.
- **No world map is designed yet.** It comes when there is a second area;
  until then the base and Millbrook are enough to build and play the
  rhythm of a day.

## Moving between places (Q34, ADR-0016)

- **Each place is its own scene**: the base, each area, the farmhouse
  inside.
- **The player walks into an exit** (the farm gate, the top of Millbrook's
  lane). The screen fades to the time of day's colour for about 0.3 s, and
  the player appears at the matching entrance of the next place, facing
  away from it.
- **The clock keeps running** through a transition.
- **The base has no combat at all** (ADR-0005): it loads no creatures and no
  combat components. Weapons are put away at the gate and drawn again at
  the top of the lane.

## Safe ground

- **The base is always safe.** Creatures never enter it.
- **Each area's entrance from the base is safe ground:** no creature spawns
  within about 20 tiles of it, and creatures that chase the player turn
  back at its edge. Coming home is never a fight.
- **Creatures hold their ground** (`combat.md`): each group has a home
  patch and gives up a chase when the player leaves it.

## Falling in an area (Q36)

- The player wakes in the farmhouse bed at the next 6:00, the cat curled on
  the blanket, keeping everything they carried (`combat.md`).
- The cost is the rest of the day. The area's creatures and forage are back
  at 6:00, and a boss is back at full health.
- How they got home is never explained (`story.md`).

## Day and night in the areas (Q21)

- **Day and night rosters:**
  - Each area has creatures that are out by day and others that come out at
    night.
  - The night roster changes at dusk (20:00) and the day roster comes back
    at dawn (6:00).
  - Creatures already in a fight finish it.
- **Sight at night** (Proposal):
  - The player sees clearly within about 7 tiles; beyond that the world
    fades into the night colour.
  - Lights carry their own pool of clear sight: glowing fungus, fireflies,
    embers, and later lights the player kindles.
  - The radius is a starting value for playtesting.
- **Warm colours still mean something** (`art-direction.md`). At night the
  only warm things out in the world are notes, artefacts and lights the
  player made, so they stand out more, not less.

## What comes back, and when (Proposal)

| Thing | Comes back |
|---|---|
| Creatures defeated | At the next 6:00, all of them |
| Forage (fruit, herbs, honey) | At the next 6:00, where it grew |
| Notes, seeds found in gardens, trinkets, the area's objective | Never: found once |
| The area's boss | Never, once defeated. A boss the player loses to is back at full health the next time they enter its ground |

- This ties the areas to the same clock as the farm: one day is one round
  of the world.
- The combat arena's 3-second respawn stays as an arena-only practice rule.

## Unlocking, and coming back later

- **Each area has one objective that opens the next area** (Q37 B).
  - The world shows it: a blocked road and something nearby that explains
    it. There is no quest log and no objective text.
  - **Every note found is kept in a satchel** the player can open and
    re-read, newest first.
  - Notes about an unfinished objective (the miller's note) carry a small
    loose-thread mark until it is done.
- **Each area also holds places the player can see but not yet reach**: an
  island, a high loft, a locked cellar. Exploration upgrades (ADR-0005
  point 8) open them later, which gives a reason to come back to old areas
  with new tools.
- **Upgrades are not designed yet.** The areas only mark where those places
  are.

## The camera and framing (Q32, ADR-0015)

- The camera follows the player with a small dead zone, clamped to the
  place's edges, at the farm and in every area.

- **Every area is at least 80 tiles wide and 30 tall**, so no screen shape
  sees past its edge. Where the playable ground is smaller, the area is
  drawn wider with scenery the player cannot walk into: woods, hedges,
  water, fields beyond a wall.
- **The farm is 160 × 96 tiles** (`base.md`), larger than every view, so it
  needs no extra scenery. Its unopened parcels are thicket the player sees
  beyond the homestead's hedges.

## Not decided here

- The world map and fast travel. Not needed while every area is one walk
  from the farm; needed by the third area at the latest.
- Weather outside the rain spell.
- Saving (`farming.md`): where and when the game saves, and whether areas
  remember what was found (they must, for notes and objectives).
- The enemy roster beyond Millbrook.
