class_name CombatTuning
extends RefCounted
## Starting values for the combat test arena (docs/design/combat.md,
## "Proposed starting values"). All are for tuning; balance changes need the
## project lead's approval. Times are in milliseconds and converted to the
## fixed 60 Hz simulation ticks with ticks().

const TICK_RATE: int = 60

# Player
const PLAYER_SPEED: float = 80.0  # layout px per second
const PLAYER_RADIUS: float = 6.0
const PLAYER_HEALTH: float = 100.0
const PLAYER_POISE: float = 50.0
const PLAYER_STAGGER_MS: int = 600
const STAMINA_MAX: float = 100.0
const STAMINA_REGEN_PER_S: float = 40.0
const STAMINA_REGEN_DELAY_MS: int = 600

# Dodge
# A quick roll (lead, 2026-10-10: dodging must feel as responsive as the
# blink): short, most of the distance in its first frames, invulnerable from
# the first frame, and its end can be cancelled into any action.
const DODGE_MS: int = 240
const DODGE_IFRAME_START_MS: int = 0
const DODGE_IFRAME_END_MS: int = 180
const DODGE_CANCEL_MS: int = 80  # the last part of the roll: any action may start
const DODGE_DISTANCE: float = 40.0  # as far as the blink
const DODGE_STAMINA: float = 20.0

# Input and feedback
const INPUT_BUFFER_MS: int = 100
const HITSTOP_LIGHT_MS: int = 40
const HITSTOP_HEAVY_MS: int = 80
const HITSTOP_BIG_MS: int = 120

# Poise
const POISE_REGEN_DELAY_MS: int = 1500
const POISE_REGEN_PER_S: float = 40.0
const STAGGERED_DAMAGE_MULTIPLIER: float = 1.5

# Push and impacts
const PUSH_MS: int = 200  # a push plays out over this long
const IMPACT_MIN_REMAINING: float = 8.0  # px of push left when blocked
const IMPACT_DAMAGE: float = 10.0
const IMPACT_POISE: float = 30.0

# Aim
const SOFT_AIM_HALF_ANGLE_DEG: float = 30.0
const SOFT_AIM_EXTRA_REACH: float = 12.0
const LOCK_ON_RANGE: float = 200.0

# Training creature
const CREATURE_SPEED: float = 40.0
const CREATURE_RADIUS: float = 7.0
const CREATURE_HEALTH: float = 150.0
const CREATURE_POISE: float = 80.0
const CREATURE_STAGGER_MS: int = 1200
const CREATURE_ATTACK_RANGE: float = 26.0
const CREATURE_WINDUP_MS: int = 700
const CREATURE_LUNGE_MS: int = 150
const CREATURE_LUNGE_DISTANCE: float = 28.0
const CREATURE_LUNGE_REACH: float = 18.0
const CREATURE_LUNGE_ARC_DEG: float = 90.0
const CREATURE_RECOVERY_MS: int = 800
const CREATURE_COOLDOWN_MS: int = 600
const CREATURE_DAMAGE: float = 15.0
const CREATURE_POISE_DAMAGE: float = 30.0
const CREATURE_DOWN_MS: int = 1000  # fading back into the land
const CREATURE_RESPAWN_MS: int = 3000

# Player respawn in the arena (no death design yet)
const PLAYER_DOWN_MS: int = 2000

# Loadout (Q19: two weapons and a swap)
const SWAP_COOLDOWN_MS: int = 1500

# Charging (hammer charge; the bow's draw sets its own speed): the player walks slowly
const CHARGE_MOVE_SPEED: float = 28.0  # layout px per second

# Arrows
const ARROW_SPEED: float = 360.0  # layout px per second
const ARROW_RANGE: float = 260.0  # layout px; soft aim for shots reaches this far

# Armour (shells, bark, stone plates): reduces damage until chipped away or
# shattered by a perfect hammer strike
const ARMOUR_DAMAGE_TAKEN: float = 0.4  # share of damage that gets through
const ARMOURED_CREATURE_ARMOUR: float = 60.0  # damage the shell absorbs before it breaks


## Milliseconds to whole simulation ticks (rounded, at least 1 for > 0 ms).
static func ticks(ms: int) -> int:
	if ms <= 0:
		return 0
	return maxi(1, roundi(ms * TICK_RATE / 1000.0))


## Per-second rate to per-tick amount.
static func per_tick(per_second: float) -> float:
	return per_second / TICK_RATE
