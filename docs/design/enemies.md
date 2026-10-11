# Enemies: archetypes, Millbrook's creatures and its boss

- **Status:** Proposal (2026-10-11), asked for by the lead ("more varied
  enemy design"). Numbers are starting values; balance is the lead's call
  (CLAUDE.md). Built in stages after this doc (`docs/roadmap.md`).
- **Binding constraints:**
  - ADR-0005: monsters are enemies; no characters.
  - `story.md` (Q13): monsters are **wildlife and land changed by the god's
    presence**, stronger further from the farm. No gore: defeated creatures
    sink back into the land.
  - `combat.md`: every attack has a telegraph, and the telegraph is the hit
    zone; creatures hold their ground; each area has one boss (the lead,
    2026-10-11).
  - Q35: in Millbrook the player has the greatsword and the hammer, and
    later the bow. The lantern comes in the second area.

## What variety means here

Every creature has **one idea** the player learns to answer. A new creature
earns its place only if it asks the player for something the others do not:
a different way to dodge, a different weapon, a different moment to strike.
Variety comes from **behaviour first**, then from the place it lives in, and
last from numbers.

## Archetypes

Behaviour patterns, built once and dressed differently in each area. The
training creature in the arena is the plain **Chaser**.

| Archetype | Its one idea | The player answers with | Millbrook's |
|---|---|---|---|
| **Chaser** | Walks up and lunges | Dodge the lunge, punish the recovery | (the arena's training creature) |
| **Swarmer** | Many, weak, fast; scatter when hurt, regroup | Wide sweeps, the spin, staying out of corners | Field mice |
| **Flyer** | Out of reach in the air; dives along a line, then lands for a moment | Sidestep the dive, punish the landing; arrows hit it in the air | Rooks |
| **Curler** | Curls into a spiked ball that shrugs off light hits; uncurls to roll at the player | Heavy hits and hammer strikes open it | Hedgehogs |
| **Artillery** | Keeps its distance and lobs at a marked spot | Watch the ground marker, move, close the gap | Flood toads |
| **Ambusher** | Disguised as part of the scenery until the player is close | Read the scene; bait the reveal, then strike | Stooks |
| **Light-seeker** | Night only; drawn to light, swirls, dives in small groups | Keep away from lights, or use them as bait | Moths |
| **Brute** | Big, high poise, charges in straight lines | Dodge sideways, make it hit walls, break its armour | The boss, Grist |

Later areas mix and harden these. Ideas for later, not designed:
- a Swarmer that splits when hit;
- a Flyer that drops creatures;
- an Artillery that shells from water;
- an Ambusher among gravestones;
- an effect-resistant Brute of embers (`combat.md`).

## Millbrook's creatures

Millbrook was the first place taken, so its creatures are the least
changed: ordinary animals grown a little wrong. Their colours keep to the
wild-growth greens and browns, with only a touch of the changed violets
(`art-direction.md`).

Every value below is a **starting value**. For scale: the player has 100
health, the greatsword's light swings do 10–12, and the arena's training
creature has 150 health.

### Field mice (Swarmer)

- **Looks:** grey field mice the size of a fist, too many teeth, eyes a
  little too far apart.
- **Behaviour:**
  - Packs of 3–5 that scurry in zigzags and close in from different
    sides.
  - Each nips: a short dash, telegraphed for 0.35 s.
  - A mouse that is hit flees for 0.6 s, then the pack regroups.
- **Values:**
  - 18 health, 10 poise, radius 4 px, speed 70 px/s (the player walks 80).
  - Nip: 4 damage, 8 px reach after a 10 px dash, 0.4 s recovery.
- **Teaches:** sweeps and the spin; not getting cornered.
- **Drop:** grey pelt.
- **Where:** cottage gardens, the standing wheat, and inside the mill;
  three come running from burst grain sacks in the boss fight.

### Rooks (Flyer)

- **Looks:** black rooks with a pale beak, a little too large, wings that
  sound like cloth.
- **Behaviour:**
  - **Aloft:** circles 60–90 px from the player and cannot be hit by
    melee. Arrows and spells hit it.
  - **The dive:** it marks a line on the ground with its shadow for 0.5 s,
    then dives 96 px along it in 0.25 s.
  - **Landed:** after the dive it lands for 1.0 s, pecking and shaking off
    the dive. It can be hit by anything then; this is the punish window.
  - Then it rises again.
- **Values:**
  - 24 health, 12 poise, radius 5 px.
  - Dive: 8 damage, 20 poise; the line is 8 px wide.
- **Teaches:** sidestepping a line attack; waiting for the opening. With
  the bow, shooting it out of the air.
- **Drop:** a rook feather (the bow's arrows, Q35).
- **Where:** the orchard and the wheat field, in twos and threes; by day
  only.

### Hedgehogs (Curler)

- **Looks:** hedgehogs the size of a dog, spines in stiff, wrong-coloured
  tufts.
- **Behaviour:**
  - Shuffles slowly.
  - **Curl:** when the player comes within 32 px, it curls into a ball. A
    curled hedgehog takes only 20% of a hit's damage and cannot be
    staggered by light hits. A heavy hit or any hammer strike uncurls it
    and staggers it.
  - **Roll:** curled, it tilts back for 0.6 s (the telegraph: a line in
    front of it), then rolls 80 px along the line. It stops at walls and
    uncurls, dazed for 0.8 s (a punish window).
- **Values:**
  - 40 health, 30 poise, radius 6 px, speed 25 px/s.
  - Roll: 10 damage, 30 poise.
- **Teaches:** heavy attacks and the hammer, early and by necessity.
- **Drop:** quills.
- **Where:** the hedgerows along the lane's lower end, around the green
  and by the orchard. **Nocturnal:** more of them at night.

### Flood toads (Artillery)

- **Looks:** fat brown toads, warts in a faintly violet pattern, a throat
  sac that glows when it fills.
- **Behaviour:**
  - Sits at the edge of water and keeps 80–140 px from the player,
    hopping back when approached.
  - **Lob:** fills its throat for 0.6 s and marks a 14 px circle where the
    player stood. The glob lands there 0.7 s later.
  - The landed glob leaves a **slick** for 3 s that slows the player by 40%.
- **Values:**
  - 30 health, 20 poise, radius 6 px.
  - Glob: 8 damage, 15 poise.
  - Resists Smoulder (wet skin).
- **Teaches:** reading ground markers, not standing still, closing the gap.
- **Drop:** toad slime (a crafting material for later).
- **Where:** the edges of the floodwater and the millpond. More at night
  (they croak in the dark).

### Stooks (Ambusher)

- **Looks:** a sheaf of wheat stood upright in the field, like every other
  sheaf, until it straightens and something like arms unbinds from the
  straw. Land changed, not an animal.
- **Behaviour:**
  - **Disguised** among real sheaves: it does not show on lock-on or soft
    aim.
  - When the player comes within 24 px, it **rises** (0.3 s), then
    **lashes** all around for 0.5 s (the telegraph: a full circle).
  - It then hops slowly after the player. If the player leaves its patch,
    it stands still and disguises itself again.
- **Values:**
  - 50 health, 40 poise, radius 7 px.
  - Lash: 12 damage, 30 poise, reach 26 px all round.
  - Dry straw: Smoulder spreads from it at 3 stacks instead of 5.
- **Teaches:** that the scene itself can hide danger; baiting a reveal
  from a step outside its reach.
- **Drop:** straw and **wheat seeds** (a new crop; `farming.md`: seeds come
  from adventures).
- **Where:** the half-harvested wheat field only, three among a dozen real
  sheaves. Day and night.
- **Story fit:** the field was half cut when the reapers stopped. The
  sheaves they left became this.

### Moths (Light-seeker, night only)

- **Looks:** pale moths the size of a hand, dusty wings with an eye
  pattern.
- **Behaviour:**
  - At night they gather and swirl around lights: the glowing fungus,
    the fireflies.
  - When the player comes within 48 px of their light, they dive in
    groups of 2–3, each a short straight dart telegraphed for 0.3 s.
  - A moth is destroyed by any hit, and by hitting the player.
- **Values:** 6 health, radius 3 px; dart 3 damage, no poise damage.
- **Teaches:** the night: lights are where you see, and where they are.
- **Drop:** wing dust (a night material).
- **Where:** the orchard's fungus and the meadow's fireflies; from 20:00
  to 6:00.

## The boss: Grist, the miller's boar

The miller kept a pig. He called it Grist (grist for the mill), and it
grew into something that fills the yard. Grist is themed on the place it
holds: the mill's yard, with its spare millstones, grain sacks, mud wallow
and trough. **Everything in the yard is part of the fight.**

### The arena: the miller's yard

The yard is fenced, 18 × 16 tiles (`area-millbrook.md`, B). It holds:
- **two spare millstones** leaning against the cottage wall;
- **four stacks of grain sacks** by the fence;
- **a mud wallow** in one corner;
- **a water trough;**
- **the gate** on the west side, from the footbridge.

The cottage, with the sluice crank hanging inside its door, is on the
north side of the yard.

### Who it is

- **Size and values:**
  - Three times the player's width (radius 14 px).
  - 600 health, 150 poise; staggered for 1.5 s when its poise breaks.
- **Day:** awake, patrolling the yard. It attacks anything that comes in.
- **Night:** **asleep in the mud wallow.** The player can creep to the
  cottage and take the crank without a fight (it wakes only if hit, or if
  the player runs within 24 px of it). Night is the way to reach the
  objective without facing the boss, which stays optional (`world.md`).

### Phase one: the yard (100–50% health)

| Move | Telegraph | Result |
|---|---|---|
| **Gore** | 0.45 s, head down, a 120° sector 26 px deep | 14 damage, 40 poise |
| **Charge** | 0.8 s pawing the ground; the lane it will run, to the first thing in its way, is drawn on the ground | Runs the lane at 220 px/s. 20 damage, 50 poise and a big push to anyone in it |

What the charge runs into decides what happens next:
- **The fence, the cottage wall or a millstone:** it is **stunned for
  1.5 s.** The punish window, and the fight's main lesson: dodge
  sideways, and make it hit something hard.
- **A stack of grain sacks:** the sacks burst. Grain spills, and **three
  field mice** come running for it from under the cottage. The player
  should keep the charge away from the sacks.

### Phase two: the wallow (below 50% health)

1. **Grist breaks off and rolls in the mud wallow** (2 s; it cannot be
   hurt while rolling). It comes out **caked in mud:** armour of 80 that
   takes 60% off every hit until broken (the armour rule in `combat.md`).
   The hammer's perfect strike shatters it at once. Rolling in again re-cakes
   it, at most once more.
2. **Double charge:** a charge that ends against the fence or the cottage
   no longer stuns it. It shrugs, turns and charges again at once, the
   second lane shown as it turns; the second charge stuns as before. **A
   charge into a millstone always stuns it**, which is what the millstones
   it rolls are for: steer its charges into them. (Settled while building,
   2026-10-11.)
3. **The millstone:**
   - Grist shoulders one of the leaning millstones, which rolls across the
     yard along a lane shown on the ground for 1.0 s.
   - It does 25 damage to whatever it crosses, bounces off the fence once,
     and comes to rest lying flat.
   - A resting millstone is something hard for the next charge to hit.
   - After the second millstone, there are none left to throw.

### What the fight teaches

- **Lateral dodging** of straight lanes.
- **Using the arena:** walls and stones stun it; sacks bring mice.
- **Armour break:** why the hammer is in the starting kit.
- **Patience:** the big hits come in the stun windows, not before.

### When it falls

- Grist sinks back into the yard's mud like every defeated creature.
- **It leaves its heart**, a dark, root-wrapped heart, warm, beating
  faintly (`base.md`: it opens the farm's great fields with the Clear
  spell, Q38), and **a tusk** (a material).
- **It does not come back** (`world.md`). The yard stays quiet afterwards.
  The trough has water in it and the sacks are still where they were.
- **A note in the cottage, for after** (draft; `story.md` rule 1):

  > Grist is NOT to have apples from the orchard again. He gets ideas and
  > he gets out. Fence is mended. — T.

## Shared rules for all of them

- **Every attack has a telegraph, and the telegraph is the hit zone**
  (`combat.md`). New shapes this roster needs:
  - a **lane**: a straight strip, for dives, rolls, charges and the
    millstone;
  - a **ground circle**: for lobbed globs;
  - **all round**: for the stook's lash.
- **Creatures hold their ground** and give up a chase when the player
  leaves it (`combat.md`, `world.md`).
- **Defeated creatures sink back into the land** and come back at 6:00;
  bosses never come back (`world.md`).
- **Effects** (Smoulder, Chill, Rot) apply to every creature unless it
  resists; the lantern comes later (Q35), so effects matter on revisits.
- **Night** swaps the roster (`world.md`). In Millbrook:
  - mice and rooks by day;
  - moths by night;
  - stooks both;
  - more hedgehogs and toads at night;
  - Grist asleep at night.

## Built so far (2026-10-11)

In the combat simulation, playable in the combat arena: **F11** cycles the
creature sets (the training creatures, then each of Millbrook's kinds, then
Grist in a yard like the miller's), and **F12** toggles night (moths come
out, Grist sleeps).

- **How:**
  - `CreatureKind` (`src/combat/creature_kind.gd`) holds each kind's values
    and moves.
  - `CreatureBrain` (`src/combat/creature_brain.gd`) runs each archetype's
    behaviour and the hooks `CombatSim` calls: an attack's active part
    starting, an attack ending, a dash running into something, a hit taken
    or landed.
  - New shared rules in `CombatSim`:
    - lane telegraphs, which are the hit zone like every other telegraph;
    - props (the yard's millstones, sacks, wallow and trough);
    - lights;
    - night;
    - rolling millstones that bounce once and come to rest as obstacles;
    - the slick that slows the player.
- **Heavy hits:** the greatsword's heavy finishers, Follow-through, the
  Riposte and every charged hammer strike count as heavy (they uncurl
  hedgehogs). Light swings, the hammer's jab and arrows do not.
- **Placeholder art:** each creature is drawn in code from the palette,
  kept to the muted and changed colours (warm colours are reserved;
  `art-direction.md`). Review sheets: `scenes/showcase/creature_poses.tscn`
  and `grist_poses.tscn`.
- **Readings settled while building** (say if any is wrong):
  - **A charge always runs to the first thing in its way**, so in phase
    one every charge ends in a stun or burst sacks. Phase two's double
    charge is therefore "shrug off the fence once"; millstones always stun
    (above).
  - **A charge that meets a wall at a slant is over**: sliding along the
    wall does not count as moving on.
  - **A player standing in a millstone's lane is hit there and back.**
  - **A moth has 1 poise** (0 would break the poise bar's arithmetic); it
    dies to any hit anyway.
  - **Mice from burst sacks do not come back** after they are defeated.
  - **Grist goes back to the wallow to sleep at night unless woken;** once
    woken it fights until dawn.
- **Not built yet:** placing the creatures in Millbrook (the next stage),
  drops and their uses (crafting), the boss heart's use at the farm, the
  night roster swapping at 20:00 and 6:00 (the area's clock), creatures
  coming back at 6:00 (the arena keeps its 3-second respawn).
- How they feel can only be judged by playing:
  `docs/playtests/2026-10-11-creatures-and-grist.md`.
