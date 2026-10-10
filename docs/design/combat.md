# Combat design

- **Status:** Draft approved by the lead (2026-10-10: "I approve your
  recommendations"). Built so far: the shared foundation and the greatsword,
  in the combat test arena (see "Built so far" at the end). Everything marked
  **Proposal** is still open to change; all numbers are starting values for
  tuning, and balance changes need the lead's approval.
- **Lead's brief (2026-10-10):** combat with depth; weapons that fit different
  playstyles. Greatsword: heavy combat, lots of pushing and staggering,
  combos into different moves. Hammer: charged attacks that need precise
  timing for full damage. Bow: flowing play with multi-stage attacks. Magic:
  damage-over-time and debuffs; stacking different effects and cashing in
  multiple stacks for big damage, while avoiding damage as you apply them.
- **Binding constraints:** ADR-0005 (fighting only away from the base; story
  through adventuring; crafting and enhancement from farmed materials and
  monster drops; skill system for fighting; trinkets that support playstyles),
  ADR-0007 (120 fps budget), ADR-0013 (keyboard plays, mouse only in menus;
  rumble on all controllers; DualSense triggers later), `story.md` (monsters
  are wildlife changed by the god; no bodies), `art-direction.md`.
- **Decided:** top-down ¾ view (Q18, ADR-0014); two weapons equipped with a
  swap (Q19).
- **Art prompts** for everything here: `combat-art-prompts.md`.

## What combat should feel like

1. **One person, a few creatures.** Fights are small and deliberate: one to
   five changed animals, never hordes. Every enemy matters. This fits the
   lonely tone and the 120 fps budget.
2. **Readable.** Every enemy attack is telegraphed (wind-up pose, sound, a
   brief flash of `#c2584a`); every player hit is confirmed (hit-stop, a
   sound, haptics). At full-resolution rendering (ADR-0008 Amendment 3),
   movement and effects are smooth while sprites keep their pixel look.
3. **Each weapon is a different game.** Not the same moves with different
   numbers: the greatsword is about position and momentum, the hammer about
   timing, the bow about movement and rhythm, magic about preparation and
   payoff.
4. **Mastery shows.** A new player can win with basic attacks; a skilled
   player clears the same fight faster, safer and with less stamina.
5. **Quiet afterwards.** When a fight ends, the creature returns to the land
   (it fades into a drop and a patch of ordinary grass or moss: no corpse,
   per the art direction) and the ambience comes back. **Proposal.**

## Shared foundation

Everything every weapon is built on.

### Controls (ADR-0013: actions, never keys; all rebindable)

**Proposal** for the default bindings:

| Action | Keyboard | Controller (Xbox / PlayStation) |
|---|---|---|
| Move (8 directions, analog on a stick) | W A S D | Left stick |
| Light attack | J | X / Square |
| Heavy / charge (hold) | K | RT / R2 (analog; adaptive trigger on DualSense later) |
| Weapon skill | L | Y / Triangle |
| Dodge | Space | A / Cross |
| Lock on (hold or toggle, setting) | Left Shift | LT / L2 |
| Switch target while locked | Q / E | Right stick flick |
| Swap weapon (Q19) | Tab | RB / R1 |

Heavy attacks sit on the trigger because the hammer and bow are "hold and
release" weapons, and that is what an analog trigger (and, later, the
DualSense adaptive trigger) is for.

### Aiming without a mouse

ADR-0013 rules out mouse aiming, so aiming must be good with eight keyboard
directions:

- Attacks go where the character faces.
- **Soft aim:** ranged attacks and spells snap to the nearest enemy inside a
  narrow cone in front of the character (about 30°). Melee attacks turn the
  character slightly towards an enemy within reach.
- **Lock-on:** keeps facing on one target while moving freely (strafing,
  circling). Essential for the bow and magic, useful for the hammer.
- An accessibility setting adjusts the soft-aim cone.

### Stamina, health and focus

- **Stamina** (one bar, all weapons): dodging, heavy and charged attacks and
  holding a bow draw cost stamina; it refills quickly when not spent. It
  stops button-mashing and makes defence a choice.
- **Health:** no regeneration in combat. How healing works (food from the farm
  is the obvious link to ADR-0005) is designed with the healing system, not
  here.
- **Focus** (magic only): spells cost Focus, which refills slowly over time
  and quickly while the player stays out of harm's way; see Magic.

### Dodge

- A quick roll, about 2 art tiles, with a brief invulnerable window in the
  middle. Costs stamina. Can cancel the recovery of most attacks, not their
  wind-up.
- Weapons hook into it: the bow's dodge shot, magic's Wardstep.

### Poise and stagger (the backbone)

Every creature, and the player, has **poise**: a hidden bar that attacks
wear down.

- Each attack deals damage *and* poise damage. When poise reaches zero the
  target is **staggered**: it stops what it is doing, cannot act for a moment,
  and takes extra damage. Poise then refills.
- Small creatures have little poise and stagger often; big ones need
  sustained pressure, a heavy weapon, or a cashed-in effect.
- Some attacks give **hyper-armour**: the attacker is not interrupted while
  swinging (greatsword heavies, enemy charges).
- Being staggered yourself is the main punishment for greed.

The greatsword is built around dealing poise damage; the hammer around one
huge poise hit; magic can freeze a target (a stagger that ignores poise).

### Hit feedback

- **Hit-stop:** the game pauses for a few hundredths of a second on a solid
  hit (longer for heavier hits). Cheap and very effective.
- **Haptics** per weapon (ADR-0013; table at the end).
- **Sound** is sparse (audio direction): weighty impacts, no music stings for
  normal hits.
- Screen shake only for the biggest hits, and an accessibility setting turns
  it off.

### Timing (engineering consequence)

Godot runs physics at 60 ticks a second by default (verified), so combat
timing is defined in milliseconds and evaluated on fixed 16.7 ms ticks: a
"100 ms window" is 6 ticks, on every machine and frame rate. Inputs are
buffered for about 100 ms, so a button pressed just before an attack ends
still counts. Rendering at 120 fps with 60 Hz logic needs physics
interpolation, which was already flagged to come to the lead with the first
moving character (ADR-0007).

### Status effects (shared system)

A general system of **stacking effects** on any creature: each effect has
stacks, a duration, and rules for what happens per stack and when stacks are
consumed. Magic is built on it, and other weapons can apply effects through
crafted enhancements and trinkets (see Progression hooks). Defined in the
Magic section because that is where it matters most.

## Greatsword: momentum and stagger

> *A long, heavy blade forged from a plough's share. Slow to start,
> impossible to stop.*

**Playstyle:** in the thick of it. Hits hard, shoves creatures around, breaks
their guard, and rewards knowing which finisher to use when.

**Light attack: a chain of three.** Wide horizontal sweeps; each pushes
creatures back a little. Slow start, but each swing in the chain is faster
than the last.

**Heavy attack: a finisher that depends on where you are in the chain.**
This is "combo into different moves":

| Input | Finisher | What it is for |
|---|---|---|
| Heavy alone | **Overhead cleave**: slow, huge poise damage, hyper-armour | Opening on a big target |
| Light → Heavy | **Shoulder shove**: short dash that pushes a creature far | Making space, pushing into walls |
| Light, Light → Heavy | **Spin sweep**: hits all around, pushes everything out | Surrounded |
| Light, Light, Light → Heavy | **Rising slash**: launches a staggered creature, big damage | The payoff for a full chain |

**Push is a weapon.** A creature shoved into a wall, rock, tree or another
creature takes an **impact**: extra damage and poise damage. Fights become
about position: herd creatures into corners, knock them into each other.

**Stagger payoff: Follow-through.** Pressing the weapon skill next to a
staggered creature performs a heavy two-handed finisher that deals large
damage. It costs stamina and leaves the player briefly open.

**Weapon skill (when nothing is staggered): Brace.** Plant the blade and take
the next hit without being staggered (hyper-armour for a moment); if a hit
lands during Brace, the next heavy attack comes out instantly.

**Mastery:** reading which finisher the moment needs; using walls; timing
Brace on a big creature's charge; chaining shoves into impacts.

**Weaknesses:** slow wind-ups get interrupted by fast creatures; heavy
stamina use; poor against anything flying or far away.

## Hammer: timing is everything

> *A fence-post maul banded with iron. Swing it right and the ground answers.*

**Playstyle:** patient and precise. Few attacks, each a decision. A perfect
charged strike is the biggest single hit in the game; a sloppy one is
mediocre.

**Light attack:** short, quick jabs with the hammer's head. Low damage; for
interrupting small creatures and building Rhythm (below).

**Heavy attack: the charge.** Hold to raise the hammer; the charge passes
three levels (lead, 2026-10-10). Level 3 is a short **sweet spot**, and
holding past it overcharges:

| Release | Result |
|---|---|
| Before level 1 | A tap: a weak strike |
| Level 1, level 2 | Stronger strikes, still well short of full damage |
| **Level 3 (the sweet spot)** | **Perfect strike:** full damage, a **cone-shaped shockwave forward** that staggers what it reaches, and armour break (below) |
| Overcharged (held past level 3) | **Overstrain:** the strike lands weak and the player loses extra stamina; holding forever is never safe |

The sweet spot is signalled three ways, so it never depends on one sense: the
hammer head flashes, a rising tone peaks, and the controller gives a click
(on a DualSense later: the trigger's resistance ramps up and then "gives",
which is exactly what the ADR-0013 adaptive-trigger prototype is for).

**Rhythm.** Each consecutive perfect strike adds a Rhythm stack (up to 3):
more damage and a bigger shockwave, but the sweet spot gets narrower. Any
non-perfect strike or getting hit resets Rhythm. This is the hammer's skill
ceiling.

**Armour break.** Some changed creatures grow shells, bark or stone plates
(armour that reduces damage). A perfect strike shatters armour; other
weapons have to chip at it.

**Weapon skill: Ground stamp.** A small, fast stomp that briefly staggers
creatures right next to you: the hammer's "get off me" while charging is not
possible.

**Charge while moving:** the player can walk slowly while charging, so
positioning for the release is part of the skill.

**Mastery:** releasing perfectly under pressure; keeping Rhythm through a
fight; positioning shockwaves to catch several creatures.

**Weaknesses:** long commitment; weak if timing is off; poor against fast
small creatures without good use of jabs and Ground stamp.

**Accessibility:** a setting widens the sweet spot (and disables the Rhythm
narrowing).

## Bow: movement and flow

> *A recurve of orchard wood and gut string. Never stand still.*

**Playstyle:** keep moving, keep shooting. Rewards rhythm, dodging well and
using all three draw stages.

**Light attack: quick shot.** Tap to loose an arrow immediately. Low damage,
fast, good for finishing and for interrupting.

**Heavy attack: a three-stage draw.** Hold to draw; the bow passes through
three stages, each with a brief flash when it is reached. Release at any
time:

| Stage | Arrow | Notes |
|---|---|---|
| 1 | Strong arrow | Fast to reach |
| 2 | **Piercing arrow:** passes through and hits everything in a line | Lines of creatures |
| 3 | **Heavy arrow:** big damage and knockback, staggers small creatures | Holding costs stamina each second |

Releasing in the brief flash as a stage is reached ("clean release") adds a
small bonus. Drawing slows movement but does not stop it.

**Dodge shot.** Pressing heavy during a dodge looses a stage-2 piercing arrow
instantly as the roll ends. Dodging *towards* danger and shooting out of it
is the bow's signature move.

**Flow.** Consecutive hits without being hit build **Flow** stacks (up to 5):
each makes drawing faster. Getting hit loses all Flow. The bow at full Flow
is very strong; the skill is staying untouched.

**Weapon skill: Volley (multi-stage).**
1. Tap: fire a **marker arrow** at the target.
2. Within a few seconds, press again: arrows **rain** on the marked spot.
3. The rain's size grows with Flow stacks spent.

**Arrows: Proposal.** Basic arrows are unlimited (ammo collecting would fight
the flow and the lonely, unhurried tone). **Crafted arrowheads** (farm and
monster materials) are a limited, chosen extra: they apply status effects
(Smoulder, Chill, Rot; see Magic), linking the bow to the stacking system.

**Mastery:** dodge shots through attacks; holding Flow at 5; picking the right
stage for the moment; Volley on a group herded together.

**Weaknesses:** low damage up close; Flow collapses when hit; drawing to
stage 3 is slow and costly.

## Magic: stack, then cash in

> *A lantern that burns with the changed land's light. What it holds, it
> spreads.*

**Playstyle:** prepare, keep away, then pay off. Layer effects on creatures
from a distance, dodge their attacks while they build up, then step in and
**cash in** every stack at once for a huge burst.

**Story fit (Proposal):** the lantern is crafted from changed materials
(monster drops), so magic is the god's own influence, turned against its
creatures. Visually, magic uses the "changed land" violets of the palette,
the only player-side thing that does. The player does not know what this
implies; the reveal in `story.md` can use it.

### The three effects

| Effect | Per stack | At full stacks (5) | Colour |
|---|---|---|---|
| **Smoulder** (burning) | Damage over time; more stacks, more damage per second | Spreads one stack to creatures nearby | Warm ember `#e0a95b` |
| **Chill** (cold) | Slows movement and attacks | **Frozen:** stopped for a moment; counts as a stagger, ignores poise | Pale blue `#4f8296` |
| **Rot** (decay) | Small damage over time; the creature takes more damage from everything and recovers poise slower | Armour weakens (like a partial armour break) | Violet `#6e5b73` |

- Each application adds stacks and refreshes the duration; stacks fall off
  one at a time when the duration runs out, so pressure must be kept up.
- A creature can carry all three effects at once. That is the point.
- Some creatures resist an effect (a creature of fire ignores Smoulder), so
  the player must mix.

### Spells (the light, heavy and skill buttons)

Each effect has its own way of being applied, so there is nothing to cycle
through and each button is a different tactic:

| Button | Spell | Use |
|---|---|---|
| Light | **Ember bolt:** fast projectile, 1 Smoulder stack | Steady pressure on one target |
| Heavy (tap) | **Frost shard:** slower projectile, 2 Chill stacks | Slowing the one that is closing in |
| Heavy (hold) | **Rot pool:** a patch on the ground; anything standing in it gains Rot stacks | Area denial, kiting creatures through it |
| Skill | **Release:** cash in every stack on creatures in a short cone in front | The payoff |

### Release: cashing in

**Release** consumes all stacks of every effect on the creatures it hits and
turns them into one burst:

- Damage grows with the number of stacks consumed (each stack worth more than
  the last), so waiting for full stacks pays.
- **Each different effect present multiplies the burst.** One effect: normal.
  Two: much larger. All three: the largest burst in the game.
- **Combinations add a special result:**

| Effects released together | Extra result |
|---|---|
| Smoulder + Chill | **Shatter:** an explosion that hits creatures around the target |
| Smoulder + Rot | **Blight bloom:** Rot spreads to every creature nearby |
| Chill + Rot | **Brittle:** massive poise damage; the target is staggered |
| All three | All of the above |

### Risk and avoidance (the brief's "while avoiding damage")

- **Release is short range.** Stacks are applied from a distance; cashing in
  means stepping in close. That is the risk.
- **Casting slows but never roots** the player: dodging is always possible.
- **Wardstep (magic's dodge):** with the lantern equipped, the dodge becomes a
  short blink that leaves a small Chill pool behind. Escaping *is* applying.
- **Focus** (the spell resource) refills faster while the player has not been
  hit for a few seconds, rewarding clean kiting.
- Getting hit while casting interrupts the cast (no hyper-armour on spells).

**Mastery:** keeping three effects at high stacks on several creatures at once,
stepping in at the right moment, steering Shatter and Blight bloom into
groups, never getting hit.

**Weaknesses:** slow to kill anything alone; weak against effect-resistant
creatures; fragile up close.

## How weapons combine (depends on Q19)

If two weapons can be equipped and swapped (Q19, recommended), the weapons
become parts of one kit:

- **Magic + greatsword:** Rot to soften, then shoves and Follow-through.
- **Magic + hammer:** Chill to slow, then a perfect strike on a frozen,
  stationary target; a perfect strike counts as a Release for the effects on
  the creatures it hits (**Proposal**).
- **Bow + hammer:** Volley pins a group in place; a perfect strike's
  shockwave catches them all.
- **Bow + magic:** crafted arrowheads apply stacks at range; Release up close.

Swapping has a short cooldown so swaps are a decision, not a spam.

## Enemies (implications only; the roster is designed with the areas)

Monsters are wildlife and land changed by the god's presence (`story.md`),
stronger further from the base. Combat needs a mix that tests each weapon:

| Creature role | Example | Tests |
|---|---|---|
| Swarmer | Changed field mice, many and fast, little poise | Greatsword sweeps, bow quick shots |
| Armoured | A beetle or tortoise grown a stone shell | Hammer armour break, Rot |
| Brute | A changed boar or stag, high poise, charges | Greatsword stagger, Brace, Chill freeze |
| Skirmisher | A changed crow or fox, keeps away, dodges | Bow, soft aim, lock-on |
| Effect-resistant | A creature of embers (ignores Smoulder) | Mixing effects, not relying on one |

Every creature attack has a telegraph. Creatures do not chase forever;
fights end when the player leaves their ground (fitting "changed wildlife").
No combat at the base (ADR-0005): the base has no combat scenes at all.

## Progression hooks (not designed here)

Named so later systems fit; each is its own design pass.

- **Fighting skills** (ADR-0005): one skill tree per weapon. Examples:
  greatsword "impacts chain into a second impact"; hammer "Rhythm keeps 1
  stack after a miss"; bow "dodge shot can be stage 3"; magic "Release
  leaves 1 stack of each effect behind".
- **Enhancement** (ADR-0005): each weapon is enhanced with farmed materials
  and monster drops; enhancements can add effects (a Smoulder-edged
  greatsword).
- **Trinkets and artefacts** (ADR-0005): supporting playstyles, for example
  "perfect hammer strikes apply 2 Chill", "Flow is not lost on the first
  hit", "Brace also reflects projectiles".
- **Upgrades:** stamina, Focus, dodge distance.

## Haptics per weapon (ADR-0013)

Rumble on every controller with motors; DualSense adaptive triggers are the
later prototype.

| Moment | Rumble (now) | DualSense trigger (prototype, later) |
|---|---|---|
| Greatsword hit | Strong, short, low | — |
| Greatsword impact (wall) | Strong double pulse | — |
| Hammer charge | Held rumble: rises through levels 1 and 2, a steady hum at level 3, a rough pulse when overcharged; a click at each level, a sharper one at level 3, a jolt on overcharge | Resistance rises with the charge |
| Hammer sweet spot | (the level-3 click above) | Trigger "gives" at the sweet spot |
| Hammer perfect strike | Heaviest pulse in the game | — |
| Bow draw stages | A tick at each stage | Tension rising per stage, release snap |
| Spell cast | Faint buzz | Light resistance on the Pool hold |
| Release | Pulse scaled by stacks consumed | — |
| Player hit | Medium, sharp | — |
| Dodge; an attack passing through it | Light pulse; a tick | — |
| Brace taking a hit; armour breaking | Firm pulse; strong pulse | — |
| Swap; out of stamina | Tiny tick; dull buzz | — |

## Proposed starting values (Proposal; tuning needs the lead's approval)

| Value | Start |
|---|---|
| Dodge invulnerable window | 200 ms (12 ticks) of a 400 ms roll |
| Input buffer | 100 ms |
| Hit-stop | 40 ms light, 80 ms heavy, 120 ms perfect hammer / Release |
| Hammer charge to sweet spot | 900 ms; sweet spot 150 ms; narrows by 25 ms per Rhythm stack |
| Bow draw stages | 300 / 700 / 1200 ms; clean-release window 80 ms |
| Flow | max 5 stacks; draw time −8% per stack |
| Effect stacks | max 5; duration 6 s, refreshed per application; one stack lost per second after it runs out |
| Release multiplier | +100% for a second effect, +200% for a third |
| Weapon swap cooldown | 1.5 s |

Further starting values chosen while building the arena (all in
`src/combat/combat_tuning.gd` and `src/combat/greatsword.gd`):

| Value | Start |
|---|---|
| Player | speed 80 px/s, health 100, poise 50, stagger 0.6 s |
| Stamina | 100; refills 40/s after 0.6 s; light 8, heavy finishers 15–20, Follow-through 25, Brace 10, dodge 20 |
| Poise refill | 40/s after 1.5 s without poise damage; staggered targets take ×1.5 damage |
| Push | plays out over 0.2 s; an impact needs at least 8 px of push left: 10 damage, 30 poise |
| Light swings | 10 / 10 / 12 damage, step forward 6 px each (so the chain follows a pushed creature) |
| Finishers | cleave 30 dmg 60 poise (hyper-armour); shove 6 dmg, pushes 64 px, dashes 24 px; spin 14 dmg, all round; rising 20 dmg, ×2 on staggered, +0.3 s stagger |
| Follow-through | 45 damage; staggered creature within 34 px (24 before 2026-10-10's +40% reach) |
| Training creature | speed 40 px/s, health 150, poise 80, stagger 1.2 s; lunge 0.7 s telegraph, 15 damage, 30 poise; 0.8 s recovery (the punish window) |
| Defeated creature | fades over 1 s, returns after 3 s (arena only) |

## What this draft does not decide

Death and its consequences, healing, enemy roster and AI, numbers beyond
the starting values, each weapon's skill tree, enhancement recipes, which
weapons are available when (a story and progression question), and the
combat camera (follows Q18).

## Built so far (2026-10-10)

**The combat test arena** (`scenes/combat/combat_arena.tscn`; F2 from the
title, or `--start-scene combat_arena`). Never at the base.

- Built: movement, dodge with invulnerable frames, stamina, poise and
  stagger, hyper-armour, input buffer, hit-stop, soft aim, lock-on with
  target switching, push and impacts (walls, pillars, other creatures), the
  full greatsword (light chain, four finishers, Follow-through, Brace and its
  counter), the hammer, the bow and magic with the status-effect system
  (below), armour, the two-weapon loadout with swap,
  three training creatures with a telegraphed lunge (one with a stone
  shell), rumble through the haptics service, and a HUD.
- How: a deterministic simulation (`src/combat/combat_sim.gd`) stepped at
  60 Hz; the scene only reads input and draws. Each weapon is a `Weapon`
  subclass (`greatsword.gd`, `hammer.gd`, `bow.gd`, `magic.gd`). Rule tests drive the simulation
  directly. Placeholder shapes from the palette stand in for art.
- Developer keys: F5 render interpolation (Q20), F6 creatures passive (for
  practising combos), F7 changes the weapon not in hand (greatsword, hammer,
  bow, magic).
- Not built yet: crafted arrowheads and effect enhancements (need crafting;
  any move can already carry an effect), effect-resistant creatures in the
  arena (the rule exists; the roster comes with the areas), the hammer's
  rising tone (no audio system yet), the
  hold/toggle setting for lock-on and an options menu for the wide sweet
  spot (come with the options menu), DualSense triggers (later prototype),
  death and healing.
- Feel can only be judged by playing:
  `docs/playtests/2026-10-10-combat-arena.md`,
  `docs/playtests/2026-10-10-hammer.md`,
  `docs/playtests/2026-10-10-bow.md` and
  `docs/playtests/2026-10-10-magic.md`.

### Hammer, weapon swap and armour as built

Starting values (in `src/combat/hammer.gd` and `combat_tuning.gd`; tuning
needs the lead's approval):

| Value | Start |
|---|---|
| Loadout | greatsword and hammer; swap (Tab / RB) from standing or an attack's recovery; 1.5 s cooldown; a swap ends the greatsword chain |
| Jab | 150 ms windup, 6 damage, 12 poise, 5 stamina, reach 34 px (was 24) |
| Charge | 15 stamina when it starts; walk at 28 px/s (35%); no stamina refill while holding |
| Charge levels | level 1 after 300 ms held, level 2 after 600 ms, level 3 (the sweet spot) after 900 ms |
| Sweet spot (level 3) | 150 ms wide; each Rhythm stack shortens it by 25 ms from its end (150, 125, 100, 75 ms); past it the charge is overcharged |
| Strike by level | all strikes reach 42 px (was 30): tap 20% of full damage and poise, level 1 35%, level 2 60% |
| Perfect strike (level 3) | 40 damage, 70 poise, +25% damage per Rhythm stack (Rhythm counts strikes before this one); shatters armour; a **70° cone shockwave forward reaching 64 px** (+8 px per Rhythm) that staggers but does no damage; 120 ms hit-stop |
| Overcharged (Overstrain) | 40% damage, 15 extra stamina; holding past level 3 drains 25 stamina/s, and the hammer comes down by itself when stamina runs out |
| Ground stamp | 100 ms windup, all round within 17 px (was 12), 4 damage, a certain 0.4 s stagger, 12 stamina |
| Armour | the shelled creature's shell absorbs 60 damage; 40% of a hit gets through while it lasts; each hit chips it by its full damage; returns on respawn |
| Wide sweet spot (accessibility) | 300 ms, no narrowing; `hammer_wide_sweet_spot=true` in `[accessibility]` of `user://settings.cfg` until the options menu exists |

Readings of the design taken while building (say if any is wrong):

- **Jabs neither build nor break Rhythm.** The design says jabs are "for
  building Rhythm" and also that only perfect strikes add stacks; jabs
  keeping Rhythm alive lets you jab between perfect strikes.
- **Dodge or Ground stamp cancel a charge** (its stamina is lost). Light
  presses during a charge are ignored.
- **The shockwave staggers but does no damage**, and the armour break only
  applies to creatures the strike itself hits.
- **The sweet-spot tone** is not built (no audio system); the flash, a
  charge meter above the player with the sweet spot marked, and the rumble
  click are.

### Bow as built

Starting values (in `src/combat/bow.gd`; arrow speed and range in
`combat_tuning.gd`; tuning needs the lead's approval):

| Value | Start |
|---|---|
| Arrows | 360 px/s, up to 260 px; stop at walls, pillars and the first creature (piercing arrows fly on); soft aim for shots reaches the full range in the 30° cone |
| Quick shot | 80 ms windup, 5 damage, 8 poise, 4 stamina |
| Draw | 8 stamina when it starts; walk at 48 px/s (60%) |
| Stages | 300 / 700 / 1200 ms (at Flow 0). Released before stage 1: the quick-shot arrow. Stage 1 strong: 12 damage, 20 poise. Stage 2 piercing: 16 damage, 25 poise, through every creature on its line. Stage 3 heavy: 30 damage, 80 poise (staggers a training creature), 24 px knockback |
| Clean release | within 80 ms of reaching a stage: +25% damage |
| Holding stage 3 | 15 stamina/s; the arrow flies by itself when stamina runs out |
| Dodge shot | heavy during a dodge: a stage-2 piercing arrow as the roll ends; costs a draw (8 stamina) |
| Flow | +1 per arrow that hits (max 5); each stack makes every stage 8% faster; lost entirely when hit, whichever weapon is in hand |
| Volley | marker arrow (8 stamina) marks where it stops, for 4 s; skill again calls the rain (10 stamina): radius 20 px + 6 px per Flow spent (all Flow is spent), first wave after 0.4 s, 3 waves 0.3 s apart, each 6 damage and 20 poise per creature inside |

Readings of the design taken while building (say if any is wrong):

- **Only arrows build Flow:** quick shots, drawn arrows, dodge shots. The
  marker and the rain do not (the rain spends Flow; building it back from
  the rain would loop).
- **"Staggers small creatures"** is done with poise: the heavy arrow's 80
  poise breaks a training creature's 80. Creatures have no size classes yet;
  bigger ones will simply have more poise.
- **"Volley pins a group in place"** is done with the rain's poise damage:
  three waves (60 poise) plus any other hit stagger a training creature.
- **The mark stays where the marker stopped** (on the creature it hit, or at
  a wall or the end of its range); it does not follow a creature.

### Magic and status effects as built

Starting values (in `src/combat/magic.gd` and `status_effects.gd`; tuning
needs the lead's approval):

| Value | Start |
|---|---|
| Stacks | max 5 per effect; 6 s, refreshed by each application; then one stack lost per second |
| Smoulder | 2 damage per second per stack; reaching 5 spreads 1 stack to creatures within 32 px |
| Chill | −10% movement and attack speed per stack (a slowed creature's telegraph lasts longer); reaching 5 freezes: a 1 s stagger that ignores poise |
| Rot | 1 damage per second per stack; +5% damage taken from everything and −15% poise refill per stack; reaching 5 halves armour |
| Ember bolt (light) | 150 ms cast, 300 px/s, 3 damage, 1 Smoulder, 5 Focus |
| Frost shard (heavy, released within 250 ms) | 100 ms cast, 200 px/s, 4 damage, 2 Chill, 12 Focus |
| Rot pool (heavy, held 250 ms) | 40 px in front, 22 px radius, 4 s; 1 Rot as it lands and every 0.5 s to each creature inside (not a hit); 20 Focus |
| Release (skill) | 200 ms cast, cone 90° reaching 28 px, 10 Focus; consumes all stacks: each stack is worth 4, 6, 8, 10, 12; ×2 for two effects, ×3 for three (5/5/5 = 360) |
| Shatter (Smoulder + Chill) | 20 damage, 30 poise to every creature within 36 px of the target |
| Blight bloom (Smoulder + Rot) | 3 Rot to every creature within 48 px |
| Brittle (Chill + Rot) | the target is staggered |
| Perfect hammer strike | counts as a Release on the creatures it hits (the combinations included) |
| Casting | the player walks at 48 px/s (60%) during a cast; a hit during a cast's windup or the heavy hold interrupts it (Focus is lost) |
| Focus | 100; refills 6/s, 20/s after 3 s without being hit |
| Wardstep (magic's dodge) | 40 px blink at once (stopped by walls), invulnerable for its 200 ms, 20 stamina; leaves an 18 px Chill pool for 2 s (1 Chill every 0.5 s) |

Readings of the design taken while building (say if any is wrong):

- **Full stacks act once**, on reaching 5: staying at 5 does not keep
  spreading or re-freezing. Freezing does not consume the Chill, so Chill +
  Rot (Brittle) still works on a Frozen creature.
- **Release's burst ignores Rot's +damage taken**: the Rot is consumed by
  the same Release.
- **Brittle is a stagger** (the "massive poise damage" breaks poise at
  once); it does nothing extra to a creature that is already staggered.
- **Pools are not hits**: they add stacks without hit-stop, rumble or
  breaking a Brace.
- **Effects only land on creatures** for now: no creature applies effects to
  the player yet.

### Combat feel changes (lead, 2026-10-10)

After playing the arena, the lead asked for five changes. As built:

1. **A stagger resets an attack, it does not pause it.** A creature that is
   staggered (or Frozen) mid-attack loses the attack. When the stagger ends
   it waits its normal cooldown (0.6 s) and then starts a new attack with
   its full telegraph. Before, it started a new lunge the moment it
   recovered, which read as the old attack carrying on.
2. **Greatsword and hammer reach about 40% further.**
   - Greatsword: light swings 39 px (was 28), cleave 45 (32), shove 28 (20),
     spin 42 (30), rising slash 39 (28), Follow-through 39 (28) and
     qualifies from 34 px (24).
   - Hammer: jab 34 (24), all strikes 42 (30), Ground stamp 17 (12).
   - The blade and hammer drawings are longer to match.
3. **More rumble.**
   - The hammer charge holds a rumble while the button is held (see the
     haptics table), with a click at each level.
   - The bow's draw tightens per stage and strains at stage 3; magic's
     heavy hold hums faintly.
   - New one-shot pulses: dodge, an attack passing through a dodge, Brace
     taking a hit, armour breaking, swap, out of stamina.
   - The held rumble is refreshed every tick and never cuts a one-shot
     short. Intensity scales and switches off both.
4. **Hammer charge in three levels**, the last one overchargeable; lower
   levels do less damage; a perfect level 3 sends a cone-shaped shockwave
   forward. Values in the hammer table above.
   - The charge meter has notches at levels 1 and 2, the sweet spot marked,
     and three level pips above it, red when overcharged.
5. **The telegraph is the hit zone.** Every attack hits inside one sector,
   and that sector is what the telegraph draws.
   - **The sector includes the attack's lunge or step.** The creature lunge
     covers 7 + 18 + 28 = 53 px from where the lunge starts.
   - **During the windup** the zone follows the creature, so a shoved
     creature takes its telegraph along.
   - **From the lunge on** the zone stays where the lunge began, and fills
     as the lunge travels.
   - **Before**, hits were measured from the creature's moving body, so a
     lunge reached 28 px past what the telegraph showed.
   - The red outline marks the zone's far edge.
   - The same rule covers the player's own stepping attacks, which changes
     nothing they can reach.

Readings taken (say if any is wrong):

- **The shockwave's reach is longer than 40% more.** The old all-round
  shockwave reached 36 px. A 70° cone reaching only 50 px (36 + 40%) would
  barely pass the strike's own 42 px reach, so it would add almost nothing;
  64 px makes the cone the reason to hit perfectly. This is a balance number
  for your approval.
- **"Overcharged" is the old Overstrain**, with the same weak strike,
  stamina cost and drain.
- **Level 3 has no "imperfect" release.** Releasing anywhere in the level-3
  window is perfect; the window is what narrows with Rhythm.

### Mana (lead, 2026-10-10, Q27)

- **Mana is the player's magic pool, shared by farming and fighting.**
  Farming spells cost it (`farming.md`). **Enhanced weapon skills consume
  Mana. Basic attacks, including magic's basic spells (Ember bolt, Frost
  shard, Rot pool), do not.** This keeps magic a viable fighting style when
  farming has spent Mana.
- Mana refills from sleep and food only.
- **Reading R1** (`farming.md`): "enhanced weapon skills" are the improved
  skills that the weapon skill trees will give (progression hooks, above).
  None exist yet, so no combat move costs Mana today. Brace and
  Follow-through, Ground stamp, Volley and Release stay free. Magic's Focus
  stays: it is the fight-paced resource of the magic weapon, separate from
  Mana. If the lead meant the current skill-button moves, each gets a Mana
  cost instead.
- The arena does not show Mana yet: combat and farming run in separate test
  scenes with no shared player state until there is a save or world model.
