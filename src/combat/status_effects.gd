class_name StatusEffects
extends RefCounted
## Stacking effects on one fighter (docs/design/combat.md, "Status effects"
## and "The three effects"): Smoulder, Chill and Rot. Each application adds
## stacks (max 5) and refreshes the duration; when the duration runs out the
## stacks fall off one per second. A fighter can carry all three at once.
## What reaching 5 stacks does (spread, Frozen, armour weakened) is in
## CombatSim.apply_effect, because it reaches other fighters.
##
## Starting values; tuning needs the lead's approval.

const SMOULDER: StringName = &"smoulder"
const CHILL: StringName = &"chill"
const ROT: StringName = &"rot"
const KINDS: Array[StringName] = [SMOULDER, CHILL, ROT]

const MAX_STACKS: int = 5
const DURATION_MS: int = 6000  # refreshed by every application
const DECAY_MS: int = 1000  # then one stack is lost per this long
const DOT_PERIOD_MS: int = 1000

const SMOULDER_DAMAGE_PER_STACK: float = 2.0  # per second
const ROT_DAMAGE_PER_STACK: float = 1.0  # per second
const ROT_DAMAGE_TAKEN_PER_STACK: float = 0.05  # +5% damage from everything
const ROT_POISE_REGEN_LOSS_PER_STACK: float = 0.15
const CHILL_SLOW_PER_STACK: float = 0.1  # movement and attacks

## At full stacks (CombatSim.apply_effect).
const SPREAD_RADIUS: float = 32.0  # Smoulder spreads a stack this far
const FROZEN_MS: int = 1000  # Chill: Frozen, a stagger that ignores poise
const ROT_ARMOUR_KEPT: float = 0.5  # Rot: armour weakened to half

## Release (CombatSim._hit): each stack consumed is worth more than the last.
const RELEASE_BASE: float = 4.0
const RELEASE_STEP: float = 2.0

var stacks: Dictionary = {SMOULDER: 0, CHILL: 0, ROT: 0}
var _timers: Dictionary = {SMOULDER: 0, CHILL: 0, ROT: 0}
var _dot_wait: int = 0


## Adds n stacks of kind (capped) and refreshes its duration. Returns the
## stack count before.
func add(kind: StringName, n: int) -> int:
	var before: int = stacks[kind]
	stacks[kind] = mini(before + n, MAX_STACKS)
	_timers[kind] = CombatTuning.ticks(DURATION_MS)
	if before == 0 and _dot_wait == 0:
		_dot_wait = CombatTuning.ticks(DOT_PERIOD_MS)
	return before


func count(kind: StringName) -> int:
	return stacks[kind]


func total() -> int:
	var n: int = 0
	for kind: StringName in KINDS:
		n += int(stacks[kind])
	return n


## The kinds with at least one stack, in KINDS order.
func present() -> Array[StringName]:
	var found: Array[StringName] = []
	for kind: StringName in KINDS:
		if int(stacks[kind]) > 0:
			found.append(kind)
	return found


## Removes every stack and returns what was there ({kind: stacks}, only
## kinds that had any).
func consume() -> Dictionary:
	var taken: Dictionary = {}
	for kind: StringName in KINDS:
		if int(stacks[kind]) > 0:
			taken[kind] = stacks[kind]
		stacks[kind] = 0
		_timers[kind] = 0
	return taken


func clear() -> void:
	consume()
	_dot_wait = 0


## One simulation tick: durations run down and stacks fall off. Returns the
## damage-over-time due this tick (0 on most ticks).
func tick() -> float:
	for kind: StringName in KINDS:
		if int(stacks[kind]) == 0:
			continue
		_timers[kind] = int(_timers[kind]) - 1
		if int(_timers[kind]) <= 0:
			stacks[kind] = int(stacks[kind]) - 1
			_timers[kind] = CombatTuning.ticks(DECAY_MS) if int(stacks[kind]) > 0 else 0
	var burning: float = SMOULDER_DAMAGE_PER_STACK * int(stacks[SMOULDER]) + ROT_DAMAGE_PER_STACK * int(stacks[ROT])
	if burning <= 0.0:
		_dot_wait = 0
		return 0.0
	_dot_wait -= 1
	if _dot_wait > 0:
		return 0.0
	_dot_wait = CombatTuning.ticks(DOT_PERIOD_MS)
	return burning


## Rot: more damage taken from everything.
func damage_taken_multiplier() -> float:
	return 1.0 + ROT_DAMAGE_TAKEN_PER_STACK * int(stacks[ROT])


## Rot: poise refills slower.
func poise_regen_scale() -> float:
	return 1.0 - ROT_POISE_REGEN_LOSS_PER_STACK * int(stacks[ROT])


## Chill: share of normal speed for movement and attacks.
func slow_factor() -> float:
	return 1.0 - CHILL_SLOW_PER_STACK * int(stacks[CHILL])


## The burst for stacks consumed by a Release: each stack worth RELEASE_STEP
## more than the one before, times the number of different effects (one
## effect x1, two x2, three x3: +100% and +200%).
static func release_damage(consumed: Dictionary) -> float:
	var sum: float = 0.0
	for kind: StringName in consumed:
		var n: int = consumed[kind]
		sum += n * RELEASE_BASE + RELEASE_STEP * n * (n - 1) / 2.0
	return sum * consumed.size()
