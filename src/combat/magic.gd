class_name Magic
extends Weapon
## Magic, the lantern (docs/design/combat.md, "Magic: stack, then cash in").
##
## Light: Ember bolt (a fast bolt, 1 Smoulder). Heavy tap: Frost shard (a
## slower shard, 2 Chill). Heavy hold: Siphon (lead, 2026-10-10, Q29): a
## tether to the creature in front that drains its stacks into the lantern
## while the button is held, then a beam on release that turns what was
## drained into one burst (rules in _fire_beam and StatusEffects.release_damage).
## Skill: Rot pool, an interim until the lead picks its rework (Q31). Spells
## cost Focus, which refills faster after a few seconds without being hit.
## Casting slows the player but never roots, and a hit during a cast's windup
## or while holding heavy interrupts it (and loses whatever was drained).
## The dodge becomes Wardstep: a short blink that leaves a Chill pool.
##
## Starting values; tuning needs the lead's approval.

const FOCUS_MAX: float = 100.0
const FOCUS_REGEN_PER_S: float = 6.0
const FOCUS_FAST_REGEN_PER_S: float = 20.0
const FOCUS_FAST_AFTER_MS: int = 3000  # without being hit
const EMBER_FOCUS: float = 5.0
const FROST_FOCUS: float = 12.0
const SIPHON_FOCUS: float = 10.0
const POOL_FOCUS: float = 20.0

const CAST_MOVE_SPEED: float = 48.0  # layout px/s while casting (60%)

## Holding heavy this long starts the Siphon instead of a Frost shard.
const SIPHON_HOLD_MS: int = 250
const SIPHON_RANGE: float = 96.0  # gap to the creature when the tether forms
const SIPHON_HALF_ANGLE_DEG: float = 60.0  # in front of the player
const SIPHON_BREAK_RANGE: float = 144.0  # the tether snaps beyond this (what was drained is kept)
const SIPHON_PERIOD_MS: int = 200  # one stack of each kind, this often
const SIPHON_MAX_MS: int = 1500  # then the beam fires by itself
const BEAM_LENGTH: float = 160.0
const BEAM_HALF_WIDTH: float = 4.0
const BEAM_WEAK_DAMAGE: float = 4.0  # nothing drained
const BEAM_POISE: float = 20.0
const BEAM_SPLASH_SHARE: float = 0.5  # creatures behind the first on the line
const BEAM_FREEZE_CHILL: int = 3  # this much Chill drained freezes the first creature
const BEAM_ROT_STACKS: int = 2  # drained Rot gives this to the others on the line

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

## Release combinations (CombatSim.release_combinations), used by the beam
## and the perfect hammer strike.
const SHATTER_RADIUS: float = 36.0  # around the target
const BLIGHT_RADIUS: float = 48.0
const BLIGHT_ROT_STACKS: int = 3

static var EMBER_BOLT: CombatMove = _spell(&"ember_bolt", "Ember bolt", Vector3i(150, 17, 150),
	_bolt(&"ember", 3.0, 4.0, StatusEffects.SMOULDER, 1, EMBER_SPEED))
static var FROST_SHARD: CombatMove = _spell(&"frost_shard", "Frost shard", Vector3i(100, 17, 200),
	_bolt(&"frost", 4.0, 6.0, StatusEffects.CHILL, 2, FROST_SPEED))
static var ROT_POOL: CombatMove = _spell(&"rot_pool", "Rot pool", Vector3i(0, 17, 300), null)
## The beam's recovery; the beam itself hits at once (_fire_beam).
static var SIPHON_BEAM: CombatMove = _spell(&"siphon_beam", "Siphon beam", Vector3i(0, 17, 250), null)
static var SHATTER: CombatMove = CombatMove.make(&"shatter", "Shatter", Vector3i.ZERO, 20.0, 30.0, 16.0, 0.0, 0.0, 0.0)
static var POOL_PAYLOAD: CombatMove = _pool_payload(&"rot_pool_tick", StatusEffects.ROT)
static var CHILL_PAYLOAD: CombatMove = _pool_payload(&"chill_pool_tick", StatusEffects.CHILL)

var focus: float = FOCUS_MAX
## The Siphon: whether the hold has become one, its target (null when the
## tether has nothing or has snapped), what it has drained ({kind: stacks})
## and for how long.
var siphoning: bool = false
var siphon_target: Fighter = null
var drained: Dictionary = {}
var siphon_ticks: int = 0
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
			_end_siphon()
			p.move = null
			p.enter(Fighter.State.CHARGE)
			return true
		&"skill":
			# Interim (Q31): the old Rot pool until its rework is decided.
			if not _cast(sim, ROT_POOL, POOL_FOCUS):
				return false
			var at: Vector2 = sim.resolve_position(p.position + p.facing * POOL_DISTANCE, 0.0)
			sim.zones.append(Zone.make(&"rot_pool", p, POOL_PAYLOAD, at, POOL_RADIUS, 0,
				CombatTuning.ticks(POOL_PERIOD_MS), POOL_WAVES))
			sim.events.append({"type": "pool", "kind": &"rot", "position": at, "radius": POOL_RADIUS})
			return true
	return false


func charge_move_speed() -> float:
	return CAST_MOVE_SPEED


## A faint hum while deciding between Frost shard and Siphon; during the
## Siphon, a pull that grows with what has been drained.
func charge_rumble(_p: Fighter) -> Vector2:
	if not siphoning:
		return Vector2(0.06, 0.0)
	return Vector2(0.1, minf(0.5, 0.08 + 0.04 * drained_total()))


func charge_interruptible() -> bool:
	return true


func dodge_kind() -> StringName:
	return &"wardstep"


func step_charge(sim: CombatSim, input: CombatInput) -> void:
	var p: Fighter = sim.player
	if not siphoning:
		if not input.heavy_held:
			p.enter(Fighter.State.FREE)
			_cast(sim, FROST_SHARD, FROST_FOCUS)
		elif p.state_tick >= CombatTuning.ticks(SIPHON_HOLD_MS):
			_begin_siphon(sim)
		return
	siphon_ticks += 1
	if siphon_target != null and (not siphon_target.is_alive()
			or siphon_target.position.distance_to(p.position) > SIPHON_BREAK_RANGE):
		siphon_target = null  # the tether snaps; what was drained stays in the lantern
		sim.events.append({"type": "siphon_snap", "position": p.position})
	if siphon_target != null:
		p.facing = (siphon_target.position - p.position).normalized()
		if siphon_ticks % CombatTuning.ticks(SIPHON_PERIOD_MS) == 0:
			_drain(sim)
	if not input.heavy_held or siphon_ticks >= CombatTuning.ticks(SIPHON_MAX_MS):
		_fire_beam(sim)


## Stacks drained so far, all kinds together.
func drained_total() -> int:
	var n: int = 0
	for kind: StringName in drained:
		n += int(drained[kind])
	return n


## True while the player is holding a Siphon (for the drawer and the HUD).
func is_siphoning(p: Fighter) -> bool:
	return siphoning and p.state == Fighter.State.CHARGE


## The creature the tether goes to: the lock target if it is in range,
## otherwise the nearest creature in front within range; null for none.
static func siphon_target_for(sim: CombatSim) -> Fighter:
	var p: Fighter = sim.player
	var lock: Fighter = sim.lock_target
	if lock != null and lock.is_alive() and lock.position.distance_to(p.position) - lock.radius - p.radius <= SIPHON_RANGE:
		return lock
	var best: Fighter = null
	for c: Fighter in sim.creatures:
		if not c.is_alive():
			continue
		var offset: Vector2 = c.position - p.position
		if offset.length() - c.radius - p.radius > SIPHON_RANGE:
			continue
		if rad_to_deg(absf(p.facing.angle_to(offset))) > SIPHON_HALF_ANGLE_DEG:
			continue
		if best == null or offset.length() < best.position.distance_to(p.position):
			best = c
	return best


func _begin_siphon(sim: CombatSim) -> void:
	var p: Fighter = sim.player
	if focus < SIPHON_FOCUS:
		p.enter(Fighter.State.FREE)
		sim.events.append({"type": "no_focus"})
		return
	focus -= SIPHON_FOCUS
	siphoning = true
	drained = {}
	siphon_ticks = 0
	siphon_target = siphon_target_for(sim)
	sim.events.append({"type": "siphon", "fighter": p, "target": siphon_target, "position": p.position})
	if siphon_target != null:
		p.facing = (siphon_target.position - p.position).normalized()
		_drain(sim)  # the first pull lands as the tether forms


## One stack of each kind the target carries, into the lantern.
func _drain(sim: CombatSim) -> void:
	var taken: Dictionary = {}
	for kind: StringName in StatusEffects.KINDS:
		var n: int = siphon_target.effects.take(kind, 1)
		if n > 0:
			taken[kind] = n
			drained[kind] = int(drained.get(kind, 0)) + n
	if not taken.is_empty():
		sim.events.append({"type": "siphon_drain", "fighter": siphon_target, "taken": taken,
			"position": siphon_target.position})


## The beam: a line from the player the way they face. The first creature on
## it takes the drained stacks as one burst (as Release did) with their
## combinations; the others on the line take half. Drained Smoulder sets
## everything hit smouldering, enough Chill freezes the first creature, and
## Rot rots the others.
func _fire_beam(sim: CombatSim) -> void:
	var p: Fighter = sim.player
	var spent: Dictionary = drained
	_end_siphon()
	p.enter(Fighter.State.FREE)
	var from: Vector2 = p.position
	var to: Vector2 = from + p.facing * BEAM_LENGTH
	to = Vector2(clampf(to.x, sim.bounds.position.x, sim.bounds.end.x), clampf(to.y, sim.bounds.position.y, sim.bounds.end.y))
	var on_line: Array[Fighter] = []
	for c: Fighter in sim.creatures:
		if not c.is_alive():
			continue
		var closest: Vector2 = Geometry2D.get_closest_point_to_segment(c.position, from, to)
		if closest.distance_to(c.position) <= c.radius + BEAM_HALF_WIDTH:
			on_line.append(c)
	on_line.sort_custom(func(a: Fighter, b: Fighter) -> bool:
		return a.position.distance_squared_to(from) < b.position.distance_squared_to(from))
	sim.events.append({"type": "beam", "fighter": p, "from": from, "position": to, "drained": spent})
	var burst_at: Vector2 = on_line[0].position if not on_line.is_empty() else to
	sim.events.append({"type": "release", "fighter": p, "consumed": spent, "position": burst_at})
	sim.start_attack(p, SIPHON_BEAM, false)
	var burst: float = StatusEffects.release_damage(spent) if not spent.is_empty() else BEAM_WEAK_DAMAGE
	for i: int in range(on_line.size()):
		var c: Fighter = on_line[i]
		var first: bool = i == 0
		var hit: CombatMove = CombatMove.make(&"siphon_beam", "Siphon beam", Vector3i.ZERO,
			burst if first else burst * BEAM_SPLASH_SHARE, BEAM_POISE if first else BEAM_POISE * BEAM_SPLASH_SHARE,
			0.0, 0.0, 0.0, 0.0)
		hit.hitstop_ms = CombatTuning.HITSTOP_BIG_MS if first and not spent.is_empty() else 0
		sim._hit(p, c, hit)
		if first:
			# Even when the burst kills (as Release did): found in the review
			# render, where a full-stack beam killed its target and nothing
			# bloomed.
			sim.release_combinations(p, c, spent)
		if not c.is_alive():
			continue
		if spent.has(StatusEffects.SMOULDER):
			sim.apply_effect(c, StatusEffects.SMOULDER, 1)
		if first:
			if int(spent.get(StatusEffects.CHILL, 0)) >= BEAM_FREEZE_CHILL and c.health > 0.0 and not c.is_staggered():
				sim.events.append({"type": "frozen", "fighter": c, "position": c.position})
				sim.stagger(c, StatusEffects.FROZEN_MS)
		elif spent.has(StatusEffects.ROT):
			sim.apply_effect(c, StatusEffects.ROT, BEAM_ROT_STACKS)


func _end_siphon() -> void:
	siphoning = false
	siphon_target = null
	drained = {}
	siphon_ticks = 0


func on_owner_hit(_sim: CombatSim) -> void:
	_since_hit = 0
	_end_siphon()  # an interrupted Siphon loses what it drained


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


## A pool's wave: no damage, one stack of its effect.
static func _pool_payload(p_id: StringName, effect: StringName) -> CombatMove:
	var m: CombatMove = CombatMove.make(p_id, "Pool", Vector3i.ZERO, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
	m.effect = effect
	m.effect_stacks = 1
	m.hitstop_ms = 0
	return m
