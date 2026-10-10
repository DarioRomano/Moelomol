class_name Greatsword
extends Weapon
## The greatsword (docs/design/combat.md, "Greatsword"): a light chain of
## three, and a heavy finisher that depends on how far into the chain the
## player is; heavy on a staggered creature in reach is always
## Follow-through. The skill is Brace, a guard: hits taken while braced do
## 30% damage; a hit in its first moment is a perfect brace that negates the
## hit, staggers and repels the attacker and counters at once (guard and
## riposte, lead 2026-10-10, Q30 A). Starting values; tuning needs the lead's
## approval.

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
const BRACE_DAMAGE_TAKEN: float = 0.3  # share of a hit's damage that gets through a guard
const PERFECT_BRACE_MS: int = 150  # a hit this early in the guard is a perfect brace
const RIPOSTE_REPEL: float = 24.0  # layout px the attacker is thrown back
## How close a staggered creature must be for Follow-through.
const FOLLOW_THROUGH_REACH: float = 34.0


func _init() -> void:
	id = &"greatsword"
	display_name = "Greatsword"


func try_action(sim: CombatSim, action: StringName, _input: CombatInput) -> bool:
	var p: Fighter = sim.player
	match action:
		&"light":
			var light: CombatMove = light_for(p.chain)
			var chain_before: int = p.chain
			if sim.start_attack(p, light):
				p.chain = chain_after(light, chain_before)
				return true
			return false
		&"heavy":
			# Heavy on a staggered creature in reach is the finisher for the
			# stagger; otherwise the chain's finisher.
			var target: Fighter = staggered_creature_in_reach(sim)
			if target != null:
				p.facing = (target.position - p.position).normalized()
				if sim.start_attack(p, FOLLOW_THROUGH, false):
					p.chain = 0
					return true
				return false
			if sim.start_attack(p, heavy_for(p.chain)):
				p.chain = 0
				return true
			return false
		&"skill":
			if not p.stamina.try_spend(BRACE_STAMINA):
				sim.events.append({"type": "no_stamina"})
				return false
			p.move = null
			p.chain = 0
			p.enter(Fighter.State.BRACE, CombatTuning.ticks(BRACE_MS))
			sim.events.append({"type": "brace"})
			return true
	return false


func status_text(p: Fighter) -> String:
	return "chain %d" % p.chain


## True during the first moment of a guard, when a hit is a perfect brace.
static func in_perfect_window(p: Fighter) -> bool:
	return p.state == Fighter.State.BRACE and p.state_tick < CombatTuning.ticks(PERFECT_BRACE_MS)


static func staggered_creature_in_reach(sim: CombatSim) -> Fighter:
	for c: Fighter in sim.creatures:
		if c.is_staggered():
			var gap: float = c.position.distance_to(sim.player.position) - c.radius - sim.player.radius
			if gap <= FOLLOW_THROUGH_REACH:
				return c
	return null


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
	var m: CombatMove = CombatMove.make(p_id, p_name, timing, p_damage, p_poise, p_push, 39.0, 120.0, 8.0)
	m.dash = LIGHT_STEP
	return m


static func _cleave() -> CombatMove:
	var m: CombatMove = CombatMove.make(&"cleave", "Overhead cleave", Vector3i(600, 100, 500),
		30.0, 60.0, 4.0, 45.0, 50.0, 20.0)
	m.hyper_armour = true
	m.hitstop_ms = CombatTuning.HITSTOP_HEAVY_MS
	return m


static func _shove() -> CombatMove:
	var m: CombatMove = CombatMove.make(&"shove", "Shoulder shove", Vector3i(200, 150, 300),
		6.0, 25.0, 64.0, 28.0, 70.0, 15.0)
	m.dash = 24.0
	m.hitstop_ms = CombatTuning.HITSTOP_LIGHT_MS
	return m


static func _spin() -> CombatMove:
	var m: CombatMove = CombatMove.make(&"spin", "Spin sweep", Vector3i(350, 150, 400),
		14.0, 30.0, 40.0, 42.0, 360.0, 20.0)
	m.hitstop_ms = CombatTuning.HITSTOP_HEAVY_MS
	return m


static func _rising() -> CombatMove:
	var m: CombatMove = CombatMove.make(&"rising", "Rising slash", Vector3i(300, 100, 450),
		20.0, 40.0, 8.0, 39.0, 90.0, 20.0)
	m.staggered_damage_multiplier = 2.0  # launches a staggered creature
	m.extend_stagger_ms = 300
	m.hitstop_ms = CombatTuning.HITSTOP_HEAVY_MS
	return m


static func _follow_through() -> CombatMove:
	var m: CombatMove = CombatMove.make(&"follow_through", "Follow-through", Vector3i(400, 150, 600),
		45.0, 0.0, 10.0, 39.0, 90.0, 25.0)
	m.hitstop_ms = CombatTuning.HITSTOP_BIG_MS
	return m


## The riposte after a perfect brace: an overhead cleave with no windup,
## started at once.
static func _brace_counter() -> CombatMove:
	var m: CombatMove = _cleave()
	m.id = &"brace_counter"
	m.display_name = "Riposte"
	m.stamina = 0.0  # the perfect brace already paid for it
	m.windup_ms = 0
	return m
