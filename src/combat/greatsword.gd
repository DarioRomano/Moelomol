class_name Greatsword
extends RefCounted
## The greatsword moveset (docs/design/combat.md, "Greatsword"): a light chain
## of three, and a heavy finisher that depends on how far into the chain the
## player is. Starting values; tuning needs the lead's approval.

## Light swings, each faster to start than the last. Each steps forward a
## little (LIGHT_STEP) so the chain follows the creature its pushes move away;
## without it the third swing missed a standing creature (found in the review
## render, 2026-10-10).
static var LIGHTS: Array[CombatMove] = [
	_light(&"light_1", "Sweep 1", Vector3i(300, 100, 300), 10.0, 15.0, 12.0),
	_light(&"light_2", "Sweep 2", Vector3i(250, 100, 300), 10.0, 15.0, 12.0),
	_light(&"light_3", "Sweep 3", Vector3i(200, 100, 350), 12.0, 18.0, 16.0),
]

## Heavy finisher by chain position: index = light swings done before it.
static var FINISHERS: Array[CombatMove] = [
	_cleave(), _shove(), _spin(), _rising(),
]

static var FOLLOW_THROUGH: CombatMove = _follow_through()
static var BRACE_COUNTER: CombatMove = _brace_counter()

const LIGHT_STEP: float = 6.0
const BRACE_MS: int = 500
const BRACE_STAMINA: float = 10.0
## How close a staggered creature must be for Follow-through.
const FOLLOW_THROUGH_REACH: float = 24.0


## The move for a light press after `chain` light swings. A fourth light starts
## the chain again.
static func light_for(chain: int) -> CombatMove:
	return LIGHTS[chain % LIGHTS.size()]


## The heavy finisher after `chain` light swings (0 to 3).
static func heavy_for(chain: int) -> CombatMove:
	return FINISHERS[clampi(chain, 0, FINISHERS.size() - 1)]


## Chain length after performing `move` from chain position `chain`.
static func chain_after(move: CombatMove, chain: int) -> int:
	if move in LIGHTS:
		return chain % LIGHTS.size() + 1
	return 0


static func _light(p_id: StringName, p_name: String, timing: Vector3i, p_damage: float,
		p_poise: float, p_push: float) -> CombatMove:
	var m: CombatMove = CombatMove.make(p_id, p_name, timing, p_damage, p_poise, p_push, 28.0, 120.0, 8.0)
	m.dash = LIGHT_STEP
	return m


static func _cleave() -> CombatMove:
	var m: CombatMove = CombatMove.make(&"cleave", "Overhead cleave", Vector3i(600, 100, 500),
		30.0, 60.0, 4.0, 32.0, 50.0, 20.0)
	m.hyper_armour = true
	m.hitstop_ms = CombatTuning.HITSTOP_HEAVY_MS
	return m


static func _shove() -> CombatMove:
	var m: CombatMove = CombatMove.make(&"shove", "Shoulder shove", Vector3i(200, 150, 300),
		6.0, 25.0, 64.0, 20.0, 70.0, 15.0)
	m.dash = 24.0
	m.hitstop_ms = CombatTuning.HITSTOP_LIGHT_MS
	return m


static func _spin() -> CombatMove:
	var m: CombatMove = CombatMove.make(&"spin", "Spin sweep", Vector3i(350, 150, 400),
		14.0, 30.0, 40.0, 30.0, 360.0, 20.0)
	m.hitstop_ms = CombatTuning.HITSTOP_HEAVY_MS
	return m


static func _rising() -> CombatMove:
	var m: CombatMove = CombatMove.make(&"rising", "Rising slash", Vector3i(300, 100, 450),
		20.0, 40.0, 8.0, 28.0, 90.0, 20.0)
	m.staggered_damage_multiplier = 2.0  # launches a staggered creature
	m.extend_stagger_ms = 300
	m.hitstop_ms = CombatTuning.HITSTOP_HEAVY_MS
	return m


static func _follow_through() -> CombatMove:
	var m: CombatMove = CombatMove.make(&"follow_through", "Follow-through", Vector3i(400, 150, 600),
		45.0, 0.0, 10.0, 28.0, 90.0, 25.0)
	m.hitstop_ms = CombatTuning.HITSTOP_BIG_MS
	return m


## The instant heavy after a successful Brace: an overhead cleave with no
## windup.
static func _brace_counter() -> CombatMove:
	var m: CombatMove = _cleave()
	m.id = &"brace_counter"
	m.display_name = "Brace counter"
	m.windup_ms = 0
	return m
