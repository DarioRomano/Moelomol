class_name CombatSim
extends RefCounted
## The combat rules (docs/design/combat.md), as a deterministic simulation:
## call step() once per fixed 60 Hz tick with that tick's input. No Godot
## physics: positions are in layout pixels, the arena is a walkable rectangle
## with rectangular obstacles, fighters are circles. Scenes only read input
## and draw; tests drive step() directly.

const CREATURE_LUNGE_ID: StringName = &"creature_lunge"
## Every weapon there is, in the order the arena's loadout key cycles them.
const WEAPON_IDS: Array[StringName] = [&"greatsword", &"hammer", &"bow", &"magic"]

var bounds: Rect2
var obstacles: Array[Rect2] = []
var player: Fighter
var creatures: Array[Fighter] = []
var lock_target: Fighter = null
var projectiles: Array[Projectile] = []
var zones: Array[Zone] = []
var hitstop: int = 0  # ticks left in which nothing moves
var tick_count: int = 0
## What happened during the last step, for feedback (haptics, effects).
## Each entry has at least "type".
var events: Array[Dictionary] = []

var _buffer_action: StringName = &""
var _buffer_age: int = 0
var _creature_lunge: CombatMove = _make_creature_lunge()


func _init(p_bounds: Rect2, player_at: Vector2) -> void:
	bounds = p_bounds
	player = Fighter.make_player(player_at)


## The test arena layout: fits the 640x360 view with room for the HUD.
static func make_arena() -> CombatSim:
	var sim: CombatSim = CombatSim.new(Rect2(48, 48, 544, 288), Vector2(160, 260))
	sim.obstacles.append(Rect2(176, 128, 32, 32))
	sim.obstacles.append(Rect2(432, 208, 32, 32))
	sim.add_creature(Vector2(420, 130))
	sim.add_creature(Vector2(470, 170))
	# An armoured creature (a stone shell) for the hammer's armour break.
	sim.add_creature(Vector2(520, 290)).give_armour(CombatTuning.ARMOURED_CREATURE_ARMOUR)
	return sim


func add_creature(at: Vector2) -> Fighter:
	var creature: Fighter = Fighter.make_creature(at)
	creatures.append(creature)
	return creature


static func make_weapon(weapon_id: StringName) -> Weapon:
	match weapon_id:
		&"greatsword":
			return Greatsword.new()
		&"hammer":
			return Hammer.new()
		&"bow":
			return Bow.new()
		&"magic":
			return Magic.new()
	push_error("CombatSim.make_weapon: unknown weapon %s" % weapon_id)
	return null


## Arena loadout key: replaces the weapon not in hand with the next one in
## WEAPON_IDS that is not the one in hand. Returns the new weapon.
func cycle_offhand_weapon() -> Weapon:
	var p: Fighter = player
	var off: int = 1 - p.weapon_index
	var index: int = WEAPON_IDS.find(p.weapons[off].id)
	for step: int in range(1, WEAPON_IDS.size()):
		var candidate: StringName = WEAPON_IDS[(index + step) % WEAPON_IDS.size()]
		if candidate != p.weapon().id:
			p.weapons[off] = make_weapon(candidate)
			break
	return p.weapons[off]


func fighters() -> Array[Fighter]:
	var all: Array[Fighter] = [player]
	all.append_array(creatures)
	return all


func step(input: CombatInput) -> void:
	events.clear()
	_record_buffer(input)
	for f: Fighter in fighters():
		f.previous_position = f.position
	for arrow: Projectile in projectiles:
		arrow.previous_position = arrow.position
	if hitstop > 0:
		hitstop -= 1
		return
	tick_count += 1
	_update_lock(input)
	_step_player(input)
	for creature: Fighter in creatures:
		_step_creature(creature)
	_step_projectiles()
	_step_zones()
	for f: Fighter in fighters():
		_apply_push(f)
		if f.is_alive() and not f.is_staggered():
			f.poise.tick(f.effects.poise_regen_scale())
	for c: Fighter in creatures:
		_tick_effects(c)
	player.stamina.tick()
	if player.swap_cooldown > 0:
		player.swap_cooldown -= 1
	for weapon: Weapon in player.weapons:
		weapon.tick(self)
	_separate_fighters()


# --- Input buffer -------------------------------------------------------------

func _record_buffer(input: CombatInput) -> void:
	var pressed: StringName = &""
	if input.dodge_pressed:
		pressed = &"dodge"
	elif input.swap_pressed:
		pressed = &"swap"
	elif input.skill_pressed:
		pressed = &"skill"
	elif input.heavy_pressed:
		pressed = &"heavy"
	elif input.light_pressed:
		pressed = &"light"
	if pressed != &"":
		_buffer_action = pressed
		_buffer_age = 0
	elif _buffer_action != &"" and hitstop == 0:
		_buffer_age += 1
		if _buffer_age > CombatTuning.ticks(CombatTuning.INPUT_BUFFER_MS):
			_buffer_action = &""


func _take_buffer() -> StringName:
	var action: StringName = _buffer_action
	_buffer_action = &""
	return action


# --- Player -------------------------------------------------------------------

func _step_player(input: CombatInput) -> void:
	var p: Fighter = player
	match p.state:
		Fighter.State.DOWN:
			p.state_tick += 1
			if p.state_tick >= p.state_length:
				_respawn(p)
		Fighter.State.STAGGERED:
			p.state_tick += 1
			if p.state_tick >= p.state_length:
				p.enter(Fighter.State.FREE)
		Fighter.State.DODGE:
			if _buffer_action != &"" and p.weapon().dodge_action(self, _buffer_action):
				_take_buffer()
			var speed: float = CombatTuning.DODGE_DISTANCE / p.state_length
			_move_with_collision(p, p.dodge_direction * speed)
			p.state_tick += 1
			if p.state_tick >= p.state_length:
				p.enter(Fighter.State.FREE)
				p.weapon().on_dodge_end(self)
		Fighter.State.BRACE:
			p.state_tick += 1
			if p.state_tick >= p.state_length:
				p.enter(Fighter.State.FREE)
		Fighter.State.CHARGE:
			# A dodge or the weapon skill cancels the charge (its stamina is
			# spent); other presses wait in the buffer.
			if _buffer_action in [&"dodge", &"skill"] and _try_action(_take_buffer(), input):
				return
			_charge_move(p, input)
			p.stamina.hold()  # no stamina refill while holding a charge
			p.weapon().step_charge(self, input)
			if p.state == Fighter.State.CHARGE:
				p.state_tick += 1
		Fighter.State.ATTACK:
			if p.attack_phase() == &"recovery" and _buffer_action != &"":
				if _try_action(_take_buffer(), input):
					return
			if p.move.move_speed > 0.0 and p.attack_phase() != &"active":
				_walk(p, input, p.move.move_speed)  # casting slows but never roots
			_advance_attack(p)
			if p.state == Fighter.State.FREE:
				p.chain = 0  # the chain ends when an attack finishes untouched
		Fighter.State.FREE:
			if _buffer_action != &"" and _try_action(_take_buffer(), input):
				return
			_free_move(p, input)


func _free_move(p: Fighter, input: CombatInput) -> void:
	var direction: Vector2 = input.move.limit_length(1.0)
	if lock_target != null:
		p.facing = (lock_target.position - p.position).normalized()
	elif direction.length() > 0.1:
		p.facing = direction.normalized()
	_move_with_collision(p, direction * CombatTuning.per_tick(CombatTuning.PLAYER_SPEED))


## Starts the action if the player can; returns true if it started. Dodge
## and swap are the same for every weapon; the weapon in hand decides the rest.
func _try_action(action: StringName, input: CombatInput) -> bool:
	var p: Fighter = player
	match action:
		&"dodge":
			if not p.stamina.try_spend(CombatTuning.DODGE_STAMINA):
				events.append({"type": "no_stamina"})
				return false
			p.move = null
			p.chain = 0
			p.brace_ready = false
			var direction: Vector2 = input.move.limit_length(1.0)
			p.dodge_direction = direction.normalized() if direction.length() > 0.1 else p.facing
			if lock_target == null:
				p.facing = p.dodge_direction
			if p.weapon().dodge_kind() == &"wardstep":
				_wardstep(p)
				return true
			p.iframes = Vector2i(CombatTuning.ticks(CombatTuning.DODGE_IFRAME_START_MS),
				CombatTuning.ticks(CombatTuning.DODGE_IFRAME_END_MS))
			p.enter(Fighter.State.DODGE, CombatTuning.ticks(CombatTuning.DODGE_MS))
			events.append({"type": "dodge"})
			return true
		&"swap":
			if p.weapons.size() < 2:
				return false
			if p.swap_cooldown > 0:
				events.append({"type": "swap_blocked"})
				return false
			p.weapon_index = (p.weapon_index + 1) % p.weapons.size()
			p.swap_cooldown = CombatTuning.ticks(CombatTuning.SWAP_COOLDOWN_MS)
			p.move = null
			p.chain = 0
			p.brace_ready = false
			p.enter(Fighter.State.FREE)
			events.append({"type": "swap", "weapon": p.weapon().id})
			return true
	var weapon: Weapon = p.weapon()
	return weapon != null and weapon.try_action(self, action, input)


## Magic's dodge: a blink of WARDSTEP_DISTANCE (stopped by walls), leaving
## a Chill pool where the player stood; invulnerable throughout.
func _wardstep(p: Fighter) -> void:
	var from: Vector2 = p.position
	zones.append(Zone.make(&"chill_pool", p, Magic.CHILL_PAYLOAD, from, Magic.CHILL_POOL_RADIUS, 0,
		CombatTuning.ticks(Magic.CHILL_POOL_PERIOD_MS), Magic.CHILL_POOL_WAVES))
	for i: int in range(4):
		_move_with_collision(p, p.dodge_direction * Magic.WARDSTEP_DISTANCE / 4.0)
	p.previous_position = p.position  # a blink: no in-between frames
	var length: int = CombatTuning.ticks(Magic.WARDSTEP_MS)
	p.iframes = Vector2i(0, length)
	p.dodge_direction = Vector2.ZERO
	p.enter(Fighter.State.DODGE, length)
	events.append({"type": "wardstep", "from": from, "position": p.position})


## How hard the controller should rumble right now for something held (a
## charge): (weak, strong), zero when nothing is held.
func player_rumble() -> Vector2:
	if player.state == Fighter.State.CHARGE and player.weapon() != null:
		return player.weapon().charge_rumble(player)
	return Vector2.ZERO


## Walking slowly while holding a charge, facing the lock target or the way
## the player moves.
func _charge_move(p: Fighter, input: CombatInput) -> void:
	_walk(p, input, p.weapon().charge_move_speed())


## Moves the player at `speed` px/s in the input direction, facing the lock
## target or the way they move.
func _walk(p: Fighter, input: CombatInput, speed: float) -> void:
	var direction: Vector2 = input.move.limit_length(1.0)
	if lock_target != null:
		p.facing = (lock_target.position - p.position).normalized()
	elif direction.length() > 0.1:
		p.facing = direction.normalized()
	_move_with_collision(p, direction * CombatTuning.per_tick(speed))


## Starts `move` for f if it can pay the stamina; returns true if it started.
func start_attack(f: Fighter, move: CombatMove, aim: bool = true) -> bool:
	if f.stamina != null and not f.stamina.try_spend(move.stamina):
		events.append({"type": "no_stamina"})
		return false
	if aim and f.kind == Fighter.Kind.PLAYER:
		_aim_player(move)
	f.move = move
	f.brace_ready = false
	f.hit_this_move.clear()
	f.attack_origin = f.position
	f.enter(Fighter.State.ATTACK, move.windup_ticks() + move.active_ticks() + move.recovery_ticks())
	events.append({"type": "attack", "fighter": f, "move": move.id})
	return true


## Lock-on faces the target; otherwise soft aim turns towards a creature that
## is nearly in front and within reach.
func _aim_player(move: CombatMove) -> void:
	var p: Fighter = player
	if lock_target != null:
		p.facing = (lock_target.position - p.position).normalized()
		return
	var best: Fighter = null
	var best_distance: float = INF
	for c: Fighter in creatures:
		if not c.is_alive():
			continue
		var offset: Vector2 = c.position - p.position
		var gap: float = offset.length() - p.radius - c.radius
		var aim_range: float = CombatTuning.ARROW_RANGE if move.arrow != null else move.reach + move.dash + CombatTuning.SOFT_AIM_EXTRA_REACH
		if gap > aim_range:
			continue
		if rad_to_deg(absf(p.facing.angle_to(offset))) > CombatTuning.SOFT_AIM_HALF_ANGLE_DEG:
			continue
		if offset.length() < best_distance:
			best = c
			best_distance = offset.length()
	if best != null:
		p.facing = (best.position - p.position).normalized()


# --- Attacks (shared by player and creatures) ------------------------------------

func _advance_attack(f: Fighter) -> void:
	var phase: StringName = f.attack_phase()
	if phase == &"windup":
		f.attack_origin = f.position  # the telegraph moves with a shoved creature
	if phase == &"active":
		var move: CombatMove = f.move
		if move.dash > 0.0:
			_move_with_collision(f, f.facing * (move.dash / move.active_ticks()))
		if move.arrow != null and f.state_tick == move.windup_ticks():
			fire(f, move.arrow)
		var zone: Dictionary = attack_zone(f)
		for target: Fighter in _targets_of(f):
			if not move.melee or target in f.hit_this_move or not in_zone(zone, target):
				continue
			f.hit_this_move.append(target)
			_hit(f, target, move)
		if move.shockwave_radius > 0.0 and f.state_tick == move.windup_ticks():
			_shockwave(f, move)
	f.state_tick += 1
	if f.state == Fighter.State.ATTACK and f.state_tick >= f.state_length:
		f.move = null
		f.enter(Fighter.State.FREE)


func _targets_of(f: Fighter) -> Array[Fighter]:
	var targets: Array[Fighter] = []
	if f.kind == Fighter.Kind.PLAYER:
		for c: Fighter in creatures:
			if c.is_alive():
				targets.append(c)
	elif player.is_alive():
		targets.append(player)
	return targets


## The area f's current attack covers, as one sector: the same shape decides
## hits and is drawn as the telegraph, so what the player sees is what hits.
## A lunge or step (dash) is part of it: the sector reaches the full distance
## the attack travels, measured from where the attack started. During the
## active part it fills out as the attacker travels (`reach`); `full_reach`
## is the whole projection. Radii are from the origin to the target's edge.
## Returns {origin, facing, arc, reach, full_reach}, or {} when not attacking.
static func attack_zone(f: Fighter) -> Dictionary:
	var phase: StringName = f.attack_phase()
	if phase == &"":
		return {}
	var move: CombatMove = f.move
	var full: float = f.radius + move.reach + move.dash
	var reach: float = full
	if phase == &"windup":
		reach = 0.0
	elif phase == &"active" and move.dash > 0.0:
		var progress: float = float(f.state_tick - move.windup_ticks() + 1) / move.active_ticks()
		reach = f.radius + move.reach + move.dash * minf(progress, 1.0)
	return {"origin": f.position if phase == &"windup" else f.attack_origin, "facing": f.facing,
		"arc": move.arc_deg, "reach": reach, "full_reach": full}


## True if the target's circle touches the zone's current reach.
static func in_zone(zone: Dictionary, target: Fighter) -> bool:
	var origin: Vector2 = zone["origin"]
	var offset: Vector2 = target.position - origin
	if offset.length() - target.radius > float(zone["reach"]):
		return false
	if float(zone["arc"]) >= 360.0 or offset.length() < 0.001:
		return true
	var facing: Vector2 = zone["facing"]
	return rad_to_deg(absf(facing.angle_to(offset))) <= float(zone["arc"]) / 2.0


func _hit(attacker: Fighter, target: Fighter, move: CombatMove) -> void:
	if target.is_invulnerable():
		events.append({"type": "dodged", "attacker": attacker, "target": target})
		return
	for weapon: Weapon in target.weapons:
		weapon.on_owner_hit(self)
	if attacker.kind == Fighter.Kind.PLAYER and attacker.weapon() != null:
		attacker.weapon().on_hit_landed(self, target, move)
	_interrupt_cast(target)
	var damage: float = move.damage
	var consumed: Dictionary = {}
	if move.releases_effects and target.effects.total() > 0:
		consumed = target.effects.consume()
		damage += StatusEffects.release_damage(consumed)
		events.append({"type": "release", "fighter": target, "consumed": consumed, "position": target.position})
	var was_staggered: bool = target.is_staggered()
	if was_staggered:
		damage *= move.staggered_damage_multiplier
		target.state_length += CombatTuning.ticks(move.extend_stagger_ms)
	if move.breaks_armour and target.armour > 0.0:
		target.armour = 0.0
		events.append({"type": "armour_break", "fighter": target, "position": target.position})
	damage = _apply_damage(target, damage)
	hitstop = maxi(hitstop, CombatTuning.ticks(move.hitstop_ms))
	events.append({"type": "hit", "attacker": attacker, "target": target, "move": move.id,
		"damage": damage, "position": target.position})
	if target.state == Fighter.State.BRACE:
		target.brace_ready = true
		events.append({"type": "brace_absorb", "fighter": target})
	if not consumed.is_empty():
		_release_combinations(attacker, target, consumed)
	if target.health <= 0.0:
		_defeat(target)
		return
	if move.effect != &"":
		apply_effect(target, move.effect, move.effect_stacks)
		if not target.is_alive() or target.is_staggered():
			was_staggered = true  # Frozen: no poise check on top
	if not was_staggered:
		if move.stagger_ms > 0:
			stagger(target, move.stagger_ms)
		elif target.poise.damage(move.poise_damage, target.has_hyper_armour()):
			stagger(target)
	if move.push > 0.0:
		var direction: Vector2 = target.position - attacker.position
		direction = direction.normalized() if direction.length() > 0.001 else attacker.facing
		target.push_ticks = CombatTuning.ticks(CombatTuning.PUSH_MS)
		target.push_velocity = direction * (move.push / target.push_ticks)


## Takes `amount` off target's health: more with Rot, less while it has
## armour (which the full amount chips away). Returns the damage taken.
func _apply_damage(target: Fighter, amount: float) -> float:
	amount *= target.effects.damage_taken_multiplier()
	var taken: float = amount
	if target.armour > 0.0:
		taken = amount * CombatTuning.ARMOUR_DAMAGE_TAKEN
		target.armour = maxf(0.0, target.armour - amount)
		if target.armour == 0.0:
			events.append({"type": "armour_break", "fighter": target, "position": target.position})
	target.health -= taken
	return taken


## A hit during a spell's windup (or a magic charge) stops the cast.
func _interrupt_cast(f: Fighter) -> void:
	if f.kind != Fighter.Kind.PLAYER:
		return
	var casting: bool = f.attack_phase() == &"windup" and f.move.spell
	var charging: bool = f.state == Fighter.State.CHARGE and f.weapon().charge_interruptible()
	if casting or charging:
		f.move = null
		f.enter(Fighter.State.FREE)
		events.append({"type": "interrupted", "fighter": f})


# --- Status effects ---------------------------------------------------------------

## Adds stacks of an effect to a creature. Reaching full stacks triggers the
## effect's own result: Smoulder spreads a stack to creatures nearby, Chill
## freezes (a stagger that ignores poise), Rot weakens armour.
func apply_effect(target: Fighter, kind: StringName, stacks: int) -> void:
	if target.kind != Fighter.Kind.CREATURE or not target.is_alive() or kind in target.resists:
		return
	var before: int = target.effects.add(kind, stacks)
	var after: int = target.effects.count(kind)
	events.append({"type": "effect", "fighter": target, "effect": kind, "stacks": after})
	if before >= StatusEffects.MAX_STACKS or after < StatusEffects.MAX_STACKS:
		return
	match kind:
		StatusEffects.SMOULDER:
			events.append({"type": "spread", "fighter": target, "position": target.position})
			for other: Fighter in creatures:
				if other != target and other.position.distance_to(target.position) <= StatusEffects.SPREAD_RADIUS:
					apply_effect(other, StatusEffects.SMOULDER, 1)
		StatusEffects.CHILL:
			events.append({"type": "frozen", "fighter": target, "position": target.position})
			stagger(target, StatusEffects.FROZEN_MS)
		StatusEffects.ROT:
			if target.armour > 0.0:
				target.armour *= StatusEffects.ROT_ARMOUR_KEPT
				events.append({"type": "armour_weakened", "fighter": target, "position": target.position})


## What releasing two or three effects together adds (combat.md, "Release").
func _release_combinations(attacker: Fighter, target: Fighter, consumed: Dictionary) -> void:
	var smoulder: bool = consumed.has(StatusEffects.SMOULDER)
	var chill: bool = consumed.has(StatusEffects.CHILL)
	var rot: bool = consumed.has(StatusEffects.ROT)
	if smoulder and chill:
		events.append({"type": "shatter", "fighter": target, "position": target.position,
			"radius": Magic.SHATTER_RADIUS})
		for other: Fighter in _targets_of(attacker):
			if other != target and other.position.distance_to(target.position) - other.radius <= Magic.SHATTER_RADIUS:
				_hit(attacker, other, Magic.SHATTER)
	if smoulder and rot:
		events.append({"type": "blight_bloom", "fighter": target, "position": target.position,
			"radius": Magic.BLIGHT_RADIUS})
		for other: Fighter in creatures:
			if other != target and other.position.distance_to(target.position) - other.radius <= Magic.BLIGHT_RADIUS:
				apply_effect(other, StatusEffects.ROT, Magic.BLIGHT_ROT_STACKS)
	if chill and rot and target.health > 0.0 and not target.is_staggered():
		events.append({"type": "brittle", "fighter": target, "position": target.position})
		stagger(target)


## Durations, falling stacks and damage over time for one creature.
func _tick_effects(c: Fighter) -> void:
	if not c.is_alive():
		return
	var burn: float = c.effects.tick()
	if burn <= 0.0:
		return
	var taken: float = _apply_damage(c, burn)
	events.append({"type": "dot", "fighter": c, "damage": taken, "position": c.position})
	if c.health <= 0.0:
		_defeat(c)


## A perfect hammer strike landing: everything within the radius (from the
## attacker's centre to the target's edge) is staggered.
func _shockwave(f: Fighter, move: CombatMove) -> void:
	events.append({"type": "shockwave", "fighter": f, "position": f.position,
		"radius": move.shockwave_radius, "facing": f.facing, "arc": move.shockwave_arc_deg})
	var zone: Dictionary = {"origin": f.position, "facing": f.facing, "arc": move.shockwave_arc_deg,
		"reach": move.shockwave_radius}
	for target: Fighter in _targets_of(f):
		if not in_zone(zone, target):
			continue
		if target.is_invulnerable() or target.is_staggered() or not target.is_alive():
			continue
		stagger(target)


# --- Projectiles and zones ---------------------------------------------------------

## Looses an arrow carrying `payload` from f, the way f faces.
func fire(f: Fighter, payload: CombatMove) -> Projectile:
	var speed: float = payload.projectile_speed if payload.projectile_speed > 0.0 else CombatTuning.ARROW_SPEED
	var arrow: Projectile = Projectile.make(f, payload, f.position + f.facing * (f.radius + 2.0), f.facing,
		CombatTuning.per_tick(speed), CombatTuning.ARROW_RANGE)
	arrow.pierce = payload.pierce
	arrow.marker = payload.marker
	projectiles.append(arrow)
	events.append({"type": "arrow", "fighter": f, "move": payload.id, "position": arrow.position})
	return arrow


## Moves every arrow one tick. An arrow hits creatures whose circle its path
## crosses this tick, nearest first; it stops at the first unless it
## pierces, and at walls, obstacles and the end of its range.
func _step_projectiles() -> void:
	var flying: Array[Projectile] = []
	for arrow: Projectile in projectiles:
		var from: Vector2 = arrow.position
		var to: Vector2 = from + arrow.velocity
		var stopped: bool = false
		var crossed: Array[Fighter] = []
		for target: Fighter in _targets_of(arrow.owner):
			if target in arrow.hit:
				continue
			var closest: Vector2 = Geometry2D.get_closest_point_to_segment(target.position, from, to)
			if closest.distance_to(target.position) <= target.radius + 1.0:
				crossed.append(target)
		crossed.sort_custom(func(a: Fighter, b: Fighter) -> bool:
			return a.position.distance_squared_to(from) < b.position.distance_squared_to(from))
		for target: Fighter in crossed:
			arrow.hit.append(target)
			_hit(arrow.owner, target, arrow.move)
			if not arrow.pierce:
				to = Geometry2D.get_closest_point_to_segment(target.position, from, to)
				stopped = true
				break
		arrow.position = to
		arrow.range_left -= arrow.velocity.length()
		if not stopped and (not bounds.has_point(to) or _in_obstacle(to) or arrow.range_left <= 0.0):
			arrow.position = Vector2(clampf(to.x, bounds.position.x, bounds.end.x), clampf(to.y, bounds.position.y, bounds.end.y))
			stopped = true
		if stopped:
			for weapon: Weapon in player.weapons:
				weapon.on_projectile_stopped(self, arrow)
		else:
			flying.append(arrow)
	projectiles = flying


func _in_obstacle(at: Vector2) -> bool:
	for rect: Rect2 in obstacles:
		if rect.has_point(at):
			return true
	return false


## Ages every zone a tick; on a wave, hits every creature inside.
func _step_zones() -> void:
	var lasting: Array[Zone] = []
	for zone: Zone in zones:
		if zone.wave_now():
			events.append({"type": "wave", "kind": zone.kind, "position": zone.position, "radius": zone.radius})
			for target: Fighter in _targets_of(zone.owner):
				if target.position.distance_to(zone.position) - target.radius > zone.radius:
					continue
				if zone.move.damage > 0.0 or zone.move.poise_damage > 0.0:
					_hit(zone.owner, target, zone.move)
				elif zone.move.effect != &"":
					apply_effect(target, zone.move.effect, zone.move.effect_stacks)  # a pool: no hit
		zone.age += 1
		if not zone.is_finished():
			lasting.append(zone)
	zones = lasting


## Staggers f for `ms`, or its kind's usual stagger when 0.
func stagger(f: Fighter, ms: int = 0) -> void:
	if ms <= 0:
		ms = CombatTuning.PLAYER_STAGGER_MS if f.kind == Fighter.Kind.PLAYER else CombatTuning.CREATURE_STAGGER_MS
	f.move = null
	f.chain = 0
	f.enter(Fighter.State.STAGGERED, CombatTuning.ticks(ms))
	if f.kind == Fighter.Kind.CREATURE:
		# The interrupted attack is gone: after the stagger the creature waits
		# its cooldown, then starts a new attack with its full telegraph. (It
		# used to lunge again the tick the stagger ended, which read as the
		# old attack carrying on.)
		f.cooldown = CombatTuning.ticks(CombatTuning.CREATURE_COOLDOWN_MS)
	events.append({"type": "stagger", "fighter": f})


func _defeat(f: Fighter) -> void:
	f.health = 0.0
	f.move = null
	f.push_ticks = 0
	var ms: int = CombatTuning.PLAYER_DOWN_MS if f.kind == Fighter.Kind.PLAYER else CombatTuning.CREATURE_DOWN_MS
	f.enter(Fighter.State.DOWN, CombatTuning.ticks(ms))
	if lock_target == f:
		lock_target = null
	events.append({"type": "down", "fighter": f})


func _respawn(f: Fighter) -> void:
	f.health = f.max_health
	f.poise.current = f.poise.maximum
	f.armour = f.armour_max
	f.effects.clear()
	f.tempo = 0.0
	f.position = f.spawn_position
	f.previous_position = f.spawn_position
	f.push_ticks = 0
	f.move = null
	f.chain = 0
	f.cooldown = CombatTuning.ticks(CombatTuning.CREATURE_COOLDOWN_MS)
	if f.stamina != null:
		f.stamina.current = f.stamina.maximum
	f.enter(Fighter.State.FREE)
	events.append({"type": "respawn", "fighter": f})


# --- Creatures --------------------------------------------------------------------

func _step_creature(c: Fighter) -> void:
	match c.state:
		Fighter.State.GONE:
			c.state_tick += 1
			if c.state_tick >= c.state_length:
				_respawn(c)
		Fighter.State.DOWN:
			c.state_tick += 1
			if c.state_tick >= c.state_length:
				c.enter(Fighter.State.GONE, CombatTuning.ticks(CombatTuning.CREATURE_RESPAWN_MS))
		Fighter.State.STAGGERED:
			c.state_tick += 1
			if c.state_tick >= c.state_length:
				c.enter(Fighter.State.FREE)
		Fighter.State.ATTACK:
			if not _creature_time_passes(c):
				return  # Chill: the attack plays out slower
			_advance_attack(c)
			if c.state == Fighter.State.FREE:
				c.cooldown = CombatTuning.ticks(CombatTuning.CREATURE_COOLDOWN_MS)
		Fighter.State.FREE:
			if c.cooldown > 0 and _creature_time_passes(c):
				c.cooldown -= 1
			if not c.ai_enabled or not player.is_alive():
				return
			var offset: Vector2 = player.position - c.position
			if offset.length() > 0.001:
				c.facing = offset.normalized()
			var gap: float = offset.length() - c.radius - player.radius
			if gap > CombatTuning.CREATURE_ATTACK_RANGE:
				var speed: float = CombatTuning.CREATURE_SPEED * c.effects.slow_factor()
				_move_with_collision(c, c.facing * CombatTuning.per_tick(speed))
			elif c.cooldown == 0:
				start_attack(c, _creature_lunge)


## Chill slows a creature's attacks: with slow factor s, only a share s of
## ticks count. Returns true if this tick counts.
func _creature_time_passes(c: Fighter) -> bool:
	c.tempo += c.effects.slow_factor()
	if c.tempo < 1.0:
		return false
	c.tempo -= 1.0
	return true


static func _make_creature_lunge() -> CombatMove:
	var m: CombatMove = CombatMove.make(CREATURE_LUNGE_ID, "Lunge",
		Vector3i(CombatTuning.CREATURE_WINDUP_MS, CombatTuning.CREATURE_LUNGE_MS, CombatTuning.CREATURE_RECOVERY_MS),
		CombatTuning.CREATURE_DAMAGE, CombatTuning.CREATURE_POISE_DAMAGE, 6.0,
		CombatTuning.CREATURE_LUNGE_REACH, CombatTuning.CREATURE_LUNGE_ARC_DEG, 0.0)
	m.dash = CombatTuning.CREATURE_LUNGE_DISTANCE
	return m


# --- Lock-on ----------------------------------------------------------------------

func _update_lock(input: CombatInput) -> void:
	if not input.lock_held or not player.is_alive():
		lock_target = null
		return
	var candidates: Array[Fighter] = _lock_candidates()
	if candidates.is_empty():
		lock_target = null
		return
	if lock_target == null or not (lock_target in candidates):
		lock_target = candidates[0]
	var step_by: int = (1 if input.target_next_pressed else 0) - (1 if input.target_prev_pressed else 0)
	if step_by != 0 and candidates.size() > 1:
		var index: int = candidates.find(lock_target)
		lock_target = candidates[posmod(index + step_by, candidates.size())]


## Creatures that can be locked on to, nearest first.
func _lock_candidates() -> Array[Fighter]:
	var found: Array[Fighter] = []
	for c: Fighter in creatures:
		if c.is_alive() and c.position.distance_to(player.position) <= CombatTuning.LOCK_ON_RANGE:
			found.append(c)
	found.sort_custom(func(a: Fighter, b: Fighter) -> bool:
		return a.position.distance_squared_to(player.position) < b.position.distance_squared_to(player.position))
	return found


# --- Movement and collision ------------------------------------------------------

## Moves f by delta, stopping at walls and obstacles. Returns true if it was
## mostly blocked.
func _move_with_collision(f: Fighter, delta: Vector2) -> bool:
	if delta.length() < 0.0001:
		return false
	var target: Vector2 = resolve_position(f.position + delta, f.radius)
	var moved: Vector2 = target - f.position
	f.position = target
	return moved.length() < delta.length() * 0.5


## The nearest position to `at` where a circle of radius r fits the arena.
func resolve_position(at: Vector2, r: float) -> Vector2:
	var p: Vector2 = at
	for _pass: int in range(2):
		for rect: Rect2 in obstacles:
			var closest: Vector2 = Vector2(clampf(p.x, rect.position.x, rect.end.x), clampf(p.y, rect.position.y, rect.end.y))
			var offset: Vector2 = p - closest
			var distance: float = offset.length()
			if distance >= r:
				continue
			if distance > 0.0001:
				p = closest + offset / distance * r
			else:
				# Centre inside the rectangle: leave by the nearest side.
				var exits: Array[Vector2] = [
					Vector2(rect.position.x - r, p.y), Vector2(rect.end.x + r, p.y),
					Vector2(p.x, rect.position.y - r), Vector2(p.x, rect.end.y + r)]
				exits.sort_custom(func(a: Vector2, b: Vector2) -> bool:
					return a.distance_squared_to(p) < b.distance_squared_to(p))
				p = exits[0]
		p.x = clampf(p.x, bounds.position.x + r, bounds.end.x - r)
		p.y = clampf(p.y, bounds.position.y + r, bounds.end.y - r)
	return p


func _apply_push(f: Fighter) -> void:
	if f.push_ticks <= 0 or not f.is_alive():
		return
	var remaining: float = f.push_velocity.length() * f.push_ticks
	var blocked: bool = _move_with_collision(f, f.push_velocity)
	var struck: Fighter = null
	if f.kind == Fighter.Kind.CREATURE:
		for other: Fighter in creatures:
			if other != f and other.is_alive() and other.position.distance_to(f.position) < other.radius + f.radius:
				struck = other
				break
	if (blocked or struck != null) and remaining >= CombatTuning.IMPACT_MIN_REMAINING:
		f.push_ticks = 0
		_impact(f)
		if struck != null:
			_impact(struck)
		return
	f.push_ticks -= 1


## A creature slammed into a wall, an obstacle or another creature.
func _impact(f: Fighter) -> void:
	var was_staggered: bool = f.is_staggered()
	_apply_damage(f, CombatTuning.IMPACT_DAMAGE)
	events.append({"type": "impact", "fighter": f, "position": f.position})
	if f.health <= 0.0:
		_defeat(f)
		return
	if not was_staggered and f.poise.damage(CombatTuning.IMPACT_POISE, f.has_hyper_armour()):
		stagger(f)


## Keeps fighters from overlapping. A dodging player passes through creatures.
func _separate_fighters() -> void:
	var all: Array[Fighter] = fighters()
	for i: int in range(all.size()):
		for j: int in range(i + 1, all.size()):
			var a: Fighter = all[i]
			var b: Fighter = all[j]
			if not a.is_alive() or not b.is_alive():
				continue
			if (a.state == Fighter.State.DODGE) or (b.state == Fighter.State.DODGE):
				continue
			var offset: Vector2 = b.position - a.position
			var distance: float = offset.length()
			var overlap: float = a.radius + b.radius - distance
			if overlap <= 0.0:
				continue
			var direction: Vector2 = offset / distance if distance > 0.0001 else Vector2.RIGHT
			a.position = resolve_position(a.position - direction * overlap / 2.0, a.radius)
			b.position = resolve_position(b.position + direction * overlap / 2.0, b.radius)
