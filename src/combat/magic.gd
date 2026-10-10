class_name Magic
extends Weapon
## Magic, the lantern (docs/design/combat.md, "Magic: stack, then cash in").
##
## Light: Ember bolt (a fast bolt, 1 Smoulder). Heavy tap: Frost shard (a
## slower shard, 2 Chill). Heavy hold: Rot pool (a patch that gives Rot to
## whatever stands in it). Skill: Release, a short cone that consumes every
## stack on the creatures it hits and turns them into one burst (rules in
## CombatSim._hit and StatusEffects.release_damage). Spells cost Focus, which
## refills faster after a few seconds without being hit. Casting slows the
## player but never roots, and a hit during a cast's windup interrupts it.
## The dodge becomes Wardstep: a short blink that leaves a Chill pool.
##
## Starting values; tuning needs the lead's approval.

const FOCUS_MAX: float = 100.0
const FOCUS_REGEN_PER_S: float = 6.0
const FOCUS_FAST_REGEN_PER_S: float = 20.0
const FOCUS_FAST_AFTER_MS: int = 3000  # without being hit
const EMBER_FOCUS: float = 5.0
const FROST_FOCUS: float = 12.0
const POOL_FOCUS: float = 20.0
const RELEASE_FOCUS: float = 10.0

const CAST_MOVE_SPEED: float = 48.0  # layout px/s while casting (60%)
## Holding heavy this long makes a Rot pool instead of a Frost shard.
const POOL_HOLD_MS: int = 250
const POOL_DISTANCE: float = 40.0  # from the player, the way they face
const POOL_RADIUS: float = 22.0
const POOL_PERIOD_MS: int = 500  # one Rot stack per creature inside, this often
const POOL_WAVES: int = 8  # 4 s

const WARDSTEP_DISTANCE: float = 40.0
const WARDSTEP_MS: int = 200  # invulnerable throughout
const CHILL_POOL_RADIUS: float = 18.0
const CHILL_POOL_PERIOD_MS: int = 500
const CHILL_POOL_WAVES: int = 4  # 2 s

const EMBER_SPEED: float = 300.0
const FROST_SPEED: float = 200.0

## Release combinations.
const SHATTER_RADIUS: float = 36.0  # around the target
const BLIGHT_RADIUS: float = 48.0
const BLIGHT_ROT_STACKS: int = 3

static var EMBER_BOLT: CombatMove = _spell(&"ember_bolt", "Ember bolt", Vector3i(150, 17, 150),
	_bolt(&"ember", 3.0, 4.0, StatusEffects.SMOULDER, 1, EMBER_SPEED))
static var FROST_SHARD: CombatMove = _spell(&"frost_shard", "Frost shard", Vector3i(100, 17, 200),
	_bolt(&"frost", 4.0, 6.0, StatusEffects.CHILL, 2, FROST_SPEED))
static var ROT_POOL: CombatMove = _spell(&"rot_pool", "Rot pool", Vector3i(0, 17, 300), null)
static var RELEASE: CombatMove = _release()
static var SHATTER: CombatMove = CombatMove.make(&"shatter", "Shatter", Vector3i.ZERO, 20.0, 30.0, 16.0, 0.0, 0.0, 0.0)
static var POOL_PAYLOAD: CombatMove = _pool_payload(&"rot_pool_tick", StatusEffects.ROT)
static var CHILL_PAYLOAD: CombatMove = _pool_payload(&"chill_pool_tick", StatusEffects.CHILL)

var focus: float = FOCUS_MAX
var _since_hit: int = 0  # ticks since the player was last hit


func _init() -> void:
	id = &"magic"
	display_name = "Magic"
	_since_hit = CombatTuning.ticks(FOCUS_FAST_AFTER_MS)


func try_action(sim: CombatSim, action: StringName, _input: CombatInput) -> bool:
	var p: Fighter = sim.player
	match action:
		&"light":
			return _cast(sim, EMBER_BOLT, EMBER_FOCUS)
		&"heavy":
			# Tap or hold decides the spell; the Focus is paid when it is known.
			if focus < FROST_FOCUS:
				sim.events.append({"type": "no_focus"})
				return false
			p.move = null
			p.enter(Fighter.State.CHARGE)
			return true
		&"skill":
			return _cast(sim, RELEASE, RELEASE_FOCUS)
	return false


func charge_move_speed() -> float:
	return CAST_MOVE_SPEED


func charge_interruptible() -> bool:
	return true


func dodge_kind() -> StringName:
	return &"wardstep"


func step_charge(sim: CombatSim, input: CombatInput) -> void:
	var p: Fighter = sim.player
	if not input.heavy_held:
		p.enter(Fighter.State.FREE)
		_cast(sim, FROST_SHARD, FROST_FOCUS)
		return
	if p.state_tick >= CombatTuning.ticks(POOL_HOLD_MS):
		p.enter(Fighter.State.FREE)
		if _cast(sim, ROT_POOL, POOL_FOCUS):
			var at: Vector2 = sim.resolve_position(p.position + p.facing * POOL_DISTANCE, 0.0)
			sim.zones.append(Zone.make(&"rot_pool", p, POOL_PAYLOAD, at, POOL_RADIUS, 0,
				CombatTuning.ticks(POOL_PERIOD_MS), POOL_WAVES))
			sim.events.append({"type": "pool", "kind": &"rot", "position": at, "radius": POOL_RADIUS})


func on_owner_hit(_sim: CombatSim) -> void:
	_since_hit = 0


func tick(_sim: CombatSim) -> void:
	if _since_hit < CombatTuning.ticks(FOCUS_FAST_AFTER_MS):
		_since_hit += 1
	focus = minf(FOCUS_MAX, focus + CombatTuning.per_tick(focus_regen_per_s()))


## Focus refill per second right now: fast after a few seconds unhit.
func focus_regen_per_s() -> float:
	return FOCUS_FAST_REGEN_PER_S if _since_hit >= CombatTuning.ticks(FOCUS_FAST_AFTER_MS) else FOCUS_REGEN_PER_S


func status_text(_p: Fighter) -> String:
	return "focus %d%s" % [floori(focus), "  (refilling fast)" if focus < FOCUS_MAX and focus_regen_per_s() == FOCUS_FAST_REGEN_PER_S else ""]


func _cast(sim: CombatSim, spell: CombatMove, cost: float) -> bool:
	if focus < cost:
		sim.events.append({"type": "no_focus"})
		return false
	if not sim.start_attack(sim.player, spell):
		return false
	focus -= cost
	sim.events.append({"type": "cast", "fighter": sim.player, "spell": spell.id})
	return true


static func _spell(p_id: StringName, p_name: String, timing: Vector3i, payload: CombatMove) -> CombatMove:
	var m: CombatMove = CombatMove.make(p_id, p_name, timing, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
	m.melee = false
	m.spell = true
	m.move_speed = CAST_MOVE_SPEED
	m.arrow = payload
	return m


static func _bolt(p_id: StringName, damage: float, poise: float, effect: StringName, stacks: int,
		speed: float) -> CombatMove:
	var m: CombatMove = CombatMove.make(p_id, p_id.capitalize(), Vector3i.ZERO, damage, poise, 0.0, 0.0, 0.0, 0.0)
	m.effect = effect
	m.effect_stacks = stacks
	m.projectile_speed = speed
	m.hitstop_ms = 0
	return m


static func _release() -> CombatMove:
	var m: CombatMove = CombatMove.make(&"release", "Release", Vector3i(200, 100, 350), 0.0, 0.0, 6.0, 28.0, 90.0, 0.0)
	m.spell = true
	m.move_speed = CAST_MOVE_SPEED
	m.releases_effects = true
	m.hitstop_ms = CombatTuning.HITSTOP_BIG_MS
	return m


## A pool's wave: no damage, one stack of its effect.
static func _pool_payload(p_id: StringName, effect: StringName) -> CombatMove:
	var m: CombatMove = CombatMove.make(p_id, "Pool", Vector3i.ZERO, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
	m.effect = effect
	m.effect_stacks = 1
	m.hitstop_ms = 0
	return m
