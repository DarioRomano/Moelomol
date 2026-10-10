class_name CombatSim
extends RefCounted
## The combat rules (docs/design/combat.md), as a deterministic simulation:
## call step() once per fixed 60 Hz tick with that tick's input. No Godot
## physics: positions are in layout pixels, the arena is a walkable rectangle
## with rectangular obstacles, fighters are circles. Scenes only read input
## and draw; tests drive step() directly.

const CREATURE_LUNGE_ID: StringName = &"creature_lunge"

var bounds: Rect2
var obstacles: Array[Rect2] = []
var player: Fighter
var creatures: Array[Fighter] = []
var lock_target: Fighter = null
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


func fighters() -> Array[Fighter]:
	var all: Array[Fighter] = [player]
	all.append_array(creatures)
	return all


func step(input: CombatInput) -> void:
	events.clear()
	_record_buffer(input)
	if hitstop > 0:
		hitstop -= 1
		for f: Fighter in fighters():
			f.previous_position = f.position
		return
	tick_count += 1
	for f: Fighter in fighters():
		f.previous_position = f.position
	_update_lock(input)
	_step_player(input)
	for creature: Fighter in creatures:
		_step_creature(creature)
	for f: Fighter in fighters():
		_apply_push(f)
		if f.is_alive() and not f.is_staggered():
			f.poise.tick()
	player.stamina.tick()
	if player.swap_cooldown > 0:
		player.swap_cooldown -= 1
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
			var speed: float = CombatTuning.DODGE_DISTANCE / p.state_length
			_move_with_collision(p, p.dodge_direction * speed)
			p.state_tick += 1
			if p.state_tick >= p.state_length:
				p.enter(Fighter.State.FREE)
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


## Walking slowly while holding a charge, facing the lock target or the way
## the player moves.
func _charge_move(p: Fighter, input: CombatInput) -> void:
	var direction: Vector2 = input.move.limit_length(1.0)
	if lock_target != null:
		p.facing = (lock_target.position - p.position).normalized()
	elif direction.length() > 0.1:
		p.facing = direction.normalized()
	_move_with_collision(p, direction * CombatTuning.per_tick(CombatTuning.CHARGE_MOVE_SPEED))


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
		if gap > move.reach + CombatTuning.SOFT_AIM_EXTRA_REACH:
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
	if f.attack_phase() == &"active":
		var move: CombatMove = f.move
		if move.dash > 0.0:
			_move_with_collision(f, f.facing * (move.dash / move.active_ticks()))
		for target: Fighter in _targets_of(f):
			if target in f.hit_this_move or not _in_sector(f, target, move):
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


static func _in_sector(attacker: Fighter, target: Fighter, move: CombatMove) -> bool:
	var offset: Vector2 = target.position - attacker.position
	if offset.length() - attacker.radius - target.radius > move.reach:
		return false
	if move.arc_deg >= 360.0 or offset.length() < 0.001:
		return true
	return rad_to_deg(absf(attacker.facing.angle_to(offset))) <= move.arc_deg / 2.0


func _hit(attacker: Fighter, target: Fighter, move: CombatMove) -> void:
	if target.is_invulnerable():
		events.append({"type": "dodged", "attacker": attacker, "target": target})
		return
	if target.kind == Fighter.Kind.PLAYER and target.weapon() != null:
		target.weapon().on_owner_hit(self)
	var damage: float = move.damage
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
	if target.health <= 0.0:
		_defeat(target)
		return
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


## Takes `amount` off target's health, less while it has armour (which the
## full amount chips away). Returns the damage actually taken.
func _apply_damage(target: Fighter, amount: float) -> float:
	var taken: float = amount
	if target.armour > 0.0:
		taken = amount * CombatTuning.ARMOUR_DAMAGE_TAKEN
		target.armour = maxf(0.0, target.armour - amount)
		if target.armour == 0.0:
			events.append({"type": "armour_break", "fighter": target, "position": target.position})
	target.health -= taken
	return taken


## A perfect hammer strike landing: everything within the radius (from the
## attacker's centre to the target's edge) is staggered.
func _shockwave(f: Fighter, move: CombatMove) -> void:
	events.append({"type": "shockwave", "fighter": f, "position": f.position,
		"radius": move.shockwave_radius})
	for target: Fighter in _targets_of(f):
		if target.position.distance_to(f.position) - target.radius > move.shockwave_radius:
			continue
		if target.is_invulnerable() or target.is_staggered() or not target.is_alive():
			continue
		stagger(target)


## Staggers f for `ms`, or its kind's usual stagger when 0.
func stagger(f: Fighter, ms: int = 0) -> void:
	if ms <= 0:
		ms = CombatTuning.PLAYER_STAGGER_MS if f.kind == Fighter.Kind.PLAYER else CombatTuning.CREATURE_STAGGER_MS
	f.move = null
	f.chain = 0
	f.enter(Fighter.State.STAGGERED, CombatTuning.ticks(ms))
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
			_advance_attack(c)
			if c.state == Fighter.State.FREE:
				c.cooldown = CombatTuning.ticks(CombatTuning.CREATURE_COOLDOWN_MS)
		Fighter.State.FREE:
			if c.cooldown > 0:
				c.cooldown -= 1
			if not c.ai_enabled or not player.is_alive():
				return
			var offset: Vector2 = player.position - c.position
			if offset.length() > 0.001:
				c.facing = offset.normalized()
			var gap: float = offset.length() - c.radius - player.radius
			if gap > CombatTuning.CREATURE_ATTACK_RANGE:
				_move_with_collision(c, c.facing * CombatTuning.per_tick(CombatTuning.CREATURE_SPEED))
			elif c.cooldown == 0:
				start_attack(c, _creature_lunge)


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
