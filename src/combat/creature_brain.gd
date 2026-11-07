class_name CreatureBrain
extends RefCounted
## How each kind of creature behaves (docs/design/enemies.md, "Archetypes"),
## for CombatSim. `think` runs while a creature is free to act; the hooks run
## at moments the simulation reports (an attack's active part starting, an
## attack ending, a dash running into something, a hit taken or landed).
## Deterministic like the rest of the simulation: no randomness, only ticks
## and positions.
##
## Starting values; balance needs the lead's approval.

const MOUSE_FLEE_MS: int = 600
const MOUSE_ZIGZAG: float = 0.7  # radians either side of straight at the player
const ROOK_CIRCLE_RADIUS: float = 75.0
const ROOK_ALOFT_MS: int = 1800  # between dives
const HEDGEHOG_CURL_HOLD_MS: int = 500  # curled, before it rolls
const HEDGEHOG_DAZE_MS: int = 800  # after a roll that hits a wall
const HEDGEHOG_CURLED_DAMAGE: float = 0.2
const TOAD_NEAR: float = 80.0
const TOAD_FAR: float = 140.0
const TOAD_SIGHT: float = 170.0
const TOAD_HOP_MS: int = 400
const GLOB_RADIUS: float = 14.0
const GLOB_FLIGHT_MS: int = 700
const SLICK_MS: int = 3000
const SLICK_SLOW: float = 0.6  # the player's speed on a slick
const STOOK_TRIGGER: float = 24.0  # gap at which it rises
const STOOK_RISE_MS: int = 300
const MOTH_ORBIT_RADIUS: float = 16.0
const MOTH_TRIGGER: float = 48.0  # player this close to the moth's light
const MOTH_LIGHT_RANGE: float = 200.0  # lights it will fly to, from its home
const GRIST_WALK_SPEED: float = 50.0
const GRIST_CHARGE_SPEED: float = 220.0
## A charge runs this far past the lane's end, so it always meets what ends
## the lane (and is stunned or bursts it) instead of stopping short.
const CHARGE_OVERRUN: float = 8.0
const GRIST_STUN_MS: int = 1500
const GRIST_WALLOW_MS: int = 2000
const GRIST_MUD_ARMOUR: float = 80.0
const GRIST_MAX_WALLOWS: int = 2
const GRIST_WAKE_GAP: float = 24.0
const GRIST_SACK_MICE: int = 3
const MILLSTONE_SPEED: float = 160.0
const MILLSTONE_RADIUS: float = 10.0
## Market rats: how far apart the two runts land when one splits.
const SPLIT_SPREAD: float = 7.0
## Jackdaws: how far from the player a carried runt is dropped.
const DROP_OFFSET: float = 20.0
## River pike: it surfaces to spit when the player is this close, lies at
## the surface this long after a spit, and its jet lands on a marked spot.
const PIKE_SIGHT: float = 150.0
const PIKE_SURFACED_MS: int = 1500
const JET_RADIUS: float = 12.0
const JET_FLIGHT_MS: int = 500


## A creature that is free to act: move, or start an attack.
static func think(sim: CombatSim, c: Fighter) -> void:
	match c.creature_kind.behaviour:
		CreatureKind.SWARMER:
			_swarmer(sim, c)
		CreatureKind.FLYER:
			_flyer(sim, c)
		CreatureKind.CURLER:
			_curler(sim, c)
		CreatureKind.ARTILLERY:
			_artillery(sim, c)
		CreatureKind.AMBUSHER:
			_ambusher(sim, c)
		CreatureKind.LIGHT_SEEKER:
			_light_seeker(sim, c)
		CreatureKind.BRUTE_BOSS:
			_grist(sim, c)
		CreatureKind.WATER_ARTILLERY:
			_pike(sim, c)
		_:
			_chaser(sim, c)


# --- Shared ------------------------------------------------------------------------

## True if the player has left this creature's ground (it gives up the chase).
static func player_out_of_reach(sim: CombatSim, c: Fighter) -> bool:
	return not sim.player.is_alive() or sim.player.position.distance_to(c.spawn_position) > c.creature_kind.leash


## The gap between the creature's edge and the player's.
static func gap_to_player(sim: CombatSim, c: Fighter) -> float:
	return c.position.distance_to(sim.player.position) - c.radius - sim.player.radius


static func _face_player(sim: CombatSim, c: Fighter) -> void:
	var offset: Vector2 = sim.player.position - c.position
	if offset.length() > 0.001:
		c.facing = offset.normalized()


## Walks back to its home; true once there.
static func _go_home(sim: CombatSim, c: Fighter) -> bool:
	var offset: Vector2 = c.spawn_position - c.position
	if offset.length() <= 2.0:
		return true
	c.facing = offset.normalized()
	sim.walk_creature(c, c.facing, c.creature_kind.speed)
	return false


static func _attack(sim: CombatSim, c: Fighter, move_name: StringName) -> bool:
	if c.creature_kind.id == &"training":
		return sim.start_attack(c, sim._creature_lunge, false)  # the arena's tests tune this one
	return sim.start_attack(c, c.creature_kind.moves[move_name], false)


# --- Chaser (the training creature) --------------------------------------------------

static func _chaser(sim: CombatSim, c: Fighter) -> void:
	if player_out_of_reach(sim, c):
		_go_home(sim, c)
		return
	_face_player(sim, c)
	if gap_to_player(sim, c) > c.creature_kind.attack_range:
		sim.walk_creature(c, c.facing, c.creature_kind.speed)
	elif c.cooldown == 0:
		_attack(sim, c, &"attack")


# --- Swarmer: field mice -------------------------------------------------------------

static func _swarmer(sim: CombatSim, c: Fighter) -> void:
	if c.ai_state == &"flee":
		c.ai_timer -= 1
		var away: Vector2 = (c.position - sim.player.position).normalized()
		sim.walk_creature(c, away, c.creature_kind.speed)
		if c.ai_timer <= 0:
			c.ai_state = &""
		return
	if player_out_of_reach(sim, c):
		_go_home(sim, c)
		return
	_face_player(sim, c)
	if gap_to_player(sim, c) > c.creature_kind.attack_range:
		# Zigzag in: each mouse weaves on its own beat (its home position).
		var beat: float = sim.tick_count * 0.15 + c.spawn_position.x * 0.37
		sim.walk_creature(c, c.facing.rotated(sin(beat) * MOUSE_ZIGZAG), c.creature_kind.speed)
	elif c.cooldown == 0:
		_attack(sim, c, &"attack")


# --- Flyer: rooks ---------------------------------------------------------------------

static func _flyer(sim: CombatSim, c: Fighter) -> void:
	c.airborne = true
	if player_out_of_reach(sim, c):
		_go_home(sim, c)
		return
	# Circle the player at a distance, out of melee reach.
	var from_player: Vector2 = c.position - sim.player.position
	if from_player.length() < 0.001:
		from_player = Vector2.RIGHT
	var spot: Vector2 = sim.player.position + from_player.normalized().rotated(0.05) * ROOK_CIRCLE_RADIUS
	var to_spot: Vector2 = spot - c.position
	if to_spot.length() > 1.0:
		sim.fly_creature(c, to_spot.normalized(), c.creature_kind.speed)
	c.ai_timer += 1
	if c.ai_timer >= CombatTuning.ticks(ROOK_ALOFT_MS) and c.cooldown == 0:
		c.ai_timer = 0
		if c.creature_kind.carries != &"" and c.ai_count == 0:
			drop_carried(sim, c)
			return
		_face_player(sim, c)
		c.airborne = false  # it comes down for the dive
		_attack(sim, c, &"attack")


## A jackdaw lets go of what it carries: a runt lands beside the player, on
## the side the jackdaw is (never inside a wall), and the jackdaw goes back
## to circling before its first dive.
static func drop_carried(sim: CombatSim, c: Fighter) -> Fighter:
	c.ai_count = 1
	var side: Vector2 = c.position - sim.player.position
	side = side.normalized() if side.length() > 0.001 else Vector2.RIGHT
	var at: Vector2 = sim.resolve_position(sim.player.position + side * DROP_OFFSET, 4.0)
	var dropped: Fighter = sim.add_creature(at, CreatureKind.by_id(c.creature_kind.carries))
	dropped.cooldown = CombatTuning.ticks(400)  # it lands before it bites
	sim.events.append({"type": "drop", "fighter": c, "position": at})
	return dropped


## A market rat hit hard splits: it is gone (until the next morning, like a
## defeat), and two runts take its place either side.
static func split(sim: CombatSim, c: Fighter) -> Array[Fighter]:
	var runts: Array[Fighter] = []
	var across: Vector2 = c.facing.orthogonal() if c.facing.length() > 0.001 else Vector2.RIGHT
	for side: float in [-1.0, 1.0]:
		var at: Vector2 = sim.resolve_position(c.position + across * side * SPLIT_SPREAD, 4.0)
		var runt: Fighter = sim.add_creature(at, CreatureKind.by_id(c.creature_kind.splits_into))
		runt.facing = c.facing
		runt.ai_state = &"flee"  # they scatter first
		runt.ai_timer = CombatTuning.ticks(MOUSE_FLEE_MS)
		runts.append(runt)
	sim.events.append({"type": "split", "fighter": c, "position": c.position})
	if sim.lock_target == c:
		sim.lock_target = null
	c.move = null
	c.push_ticks = 0
	c.enter(Fighter.State.GONE, CombatTuning.ticks(CombatTuning.CREATURE_RESPAWN_MS))
	return runts


# --- Curler: hedgehogs ----------------------------------------------------------------

static func _curler(sim: CombatSim, c: Fighter) -> void:
	if player_out_of_reach(sim, c):
		c.curled = false
		_go_home(sim, c)
		return
	var gap: float = gap_to_player(sim, c)
	if not c.curled:
		_face_player(sim, c)
		if gap > c.creature_kind.attack_range or c.cooldown > 0:
			sim.walk_creature(c, c.facing, c.creature_kind.speed)
			return
		c.curled = true
		c.ai_timer = CombatTuning.ticks(HEDGEHOG_CURL_HOLD_MS)
		sim.events.append({"type": "curl", "fighter": c, "position": c.position})
		return
	c.ai_timer -= 1
	if c.ai_timer <= 0:
		_face_player(sim, c)
		_attack(sim, c, &"attack")


# --- Artillery: flood toads -------------------------------------------------------------

static func _artillery(sim: CombatSim, c: Fighter) -> void:
	if c.ai_state == &"hop":
		c.ai_timer -= 1
		sim.walk_creature(c, c.facing, c.creature_kind.speed)
		if c.ai_timer <= 0:
			c.ai_state = &""
		return
	if player_out_of_reach(sim, c):
		_go_home(sim, c)
		return
	var distance: float = c.position.distance_to(sim.player.position)
	if distance < TOAD_NEAR:
		# Too close: hop back, away from the player.
		c.facing = (c.position - sim.player.position).normalized()
		c.ai_state = &"hop"
		c.ai_timer = CombatTuning.ticks(TOAD_HOP_MS)
		return
	_face_player(sim, c)
	if distance > TOAD_SIGHT:
		return
	if distance > TOAD_FAR:
		sim.walk_creature(c, c.facing, c.creature_kind.speed * 0.5)
		return
	if c.cooldown == 0:
		c.ai_target = sim.player.position  # where the glob will land
		_attack(sim, c, &"attack")


# --- Water artillery: river pike -------------------------------------------------------

## Under the water it cannot be touched and does not move. When the player is
## in sight and it is ready, it surfaces and spits at where the player
## stands; then it lies at the surface (PIKE_SURFACED_MS) before going under.
static func _pike(sim: CombatSim, c: Fighter) -> void:
	if c.ai_state == &"surfaced":
		c.ai_timer -= 1
		if c.ai_timer <= 0:
			submerge(sim, c)
		return
	c.untouchable = true
	if not sim.player.is_alive() or c.cooldown > 0:
		return
	if c.position.distance_to(sim.player.position) > PIKE_SIGHT:
		return
	_face_player(sim, c)
	c.untouchable = false
	c.ai_target = sim.player.position  # where the jet will land
	sim.events.append({"type": "surface", "fighter": c, "position": c.position})
	_attack(sim, c, &"attack")


## A pike goes back under.
static func submerge(sim: CombatSim, c: Fighter) -> void:
	c.ai_state = &""
	c.ai_timer = 0
	c.untouchable = true
	sim.events.append({"type": "submerge", "fighter": c, "position": c.position})


# --- Ambusher: stooks -------------------------------------------------------------------

static func _ambusher(sim: CombatSim, c: Fighter) -> void:
	if c.ai_state == &"rising":
		c.ai_timer -= 1
		if c.ai_timer <= 0:
			c.ai_state = &""
			_face_player(sim, c)
			_attack(sim, c, &"attack")
		return
	if c.disguised:
		if sim.player.is_alive() and gap_to_player(sim, c) <= STOOK_TRIGGER:
			reveal(sim, c)
		return
	if player_out_of_reach(sim, c):
		if _go_home(sim, c):
			c.disguised = true
			sim.events.append({"type": "disguise", "fighter": c, "position": c.position})
		return
	_face_player(sim, c)
	if gap_to_player(sim, c) > c.creature_kind.attack_range:
		sim.walk_creature(c, c.facing, c.creature_kind.speed)
	elif c.cooldown == 0:
		_attack(sim, c, &"attack")


## A stook drops its disguise: it rises, then lashes.
static func reveal(sim: CombatSim, c: Fighter) -> void:
	c.disguised = false
	c.ai_state = &"rising"
	c.ai_timer = CombatTuning.ticks(STOOK_RISE_MS)
	sim.events.append({"type": "reveal", "fighter": c, "position": c.position})


# --- Light-seeker: moths ----------------------------------------------------------------

static func _light_seeker(sim: CombatSim, c: Fighter) -> void:
	c.airborne = false
	var light: Vector2 = nearest_light(sim, c)
	# Swirl around the light.
	c.ai_timer += 1
	var angle: float = c.ai_timer * 0.08 + c.spawn_position.y * 0.5
	var spot: Vector2 = light + Vector2.from_angle(angle) * MOTH_ORBIT_RADIUS
	var to_spot: Vector2 = spot - c.position
	if to_spot.length() > 1.0:
		sim.fly_creature(c, to_spot.normalized(), c.creature_kind.speed)
	if sim.player.is_alive() and sim.player.position.distance_to(light) <= MOTH_TRIGGER and c.cooldown == 0:
		_face_player(sim, c)
		_attack(sim, c, &"attack")


## The light a moth swirls around: the nearest to its home within range, or
## its home if there is none.
static func nearest_light(sim: CombatSim, c: Fighter) -> Vector2:
	var best: Vector2 = c.spawn_position
	var best_distance: float = MOTH_LIGHT_RANGE
	for light: Vector2 in sim.lights:
		var d: float = light.distance_to(c.spawn_position)
		if d <= best_distance:
			best = light
			best_distance = d
	return best


# --- Grist, the miller's boar ---------------------------------------------------------------

static func _grist(sim: CombatSim, c: Fighter) -> void:
	if not sim.night:
		c.alerted = false
	match c.ai_state:
		&"asleep":
			if not sim.night:
				c.ai_state = &""
			elif sim.player.is_alive() and gap_to_player(sim, c) <= GRIST_WAKE_GAP:
				wake(sim, c)
			return
		&"to_wallow":
			if _walk_to(sim, c, _wallow_centre(sim, c), GRIST_WALK_SPEED * 1.6):
				c.ai_state = &"wallowing"
				c.ai_timer = CombatTuning.ticks(GRIST_WALLOW_MS)
				c.untouchable = true
				sim.events.append({"type": "wallow", "fighter": c, "position": c.position})
			return
		&"wallowing":
			c.ai_timer -= 1
			if c.ai_timer <= 0:
				c.untouchable = false
				c.give_armour(GRIST_MUD_ARMOUR)
				c.ai_count += 1
				c.ai_state = &""
				c.ai_timer = 0
				c.cooldown = 0
				sim.events.append({"type": "mud_armour", "fighter": c, "position": c.position})
			return
		&"to_stone":
			var stone: Dictionary = sim.prop_of(&"millstone_leaning")
			c.ai_timer += 1
			if stone.is_empty() or c.ai_timer > CombatTuning.ticks(4000):
				c.ai_state = &""  # gone, or out of reach: give up
				c.ai_timer = 0
				return
			var rect: Rect2 = stone["rect"]
			# Stand just in front (south) of the leaning stone, then heave it.
			if _walk_to(sim, c, Vector2(rect.get_center().x, rect.end.y + c.radius + 2.0), GRIST_WALK_SPEED * 1.6):
				c.ai_state = &""
				c.ai_timer = 0
				_face_player(sim, c)
				var heave: CombatMove = c.creature_kind.moves[&"heave"]
				heave.reach = maxf(0.0, sim.lane_length(c.position, c.facing, MILLSTONE_RADIUS) - c.radius)
				_attack(sim, c, &"heave")
			return
	# At night, unless woken, it goes to the wallow and sleeps.
	if sim.night and not c.alerted:
		if _walk_to(sim, c, _wallow_centre(sim, c), GRIST_WALK_SPEED):
			c.ai_state = &"asleep"
			sim.events.append({"type": "sleep", "fighter": c, "position": c.position})
		return
	if not sim.player.is_alive():
		return
	# Phase two at half health: the wallow, at once; again when the mud breaks.
	if c.phase == 1 and c.health <= c.max_health * 0.5:
		c.phase = 2
		c.ai_state = &"to_wallow"
		sim.events.append({"type": "phase", "fighter": c, "phase": 2, "position": c.position})
		return
	if c.phase == 2 and c.armour_max > 0.0 and c.armour <= 0.0 and c.ai_count < GRIST_MAX_WALLOWS:
		c.armour_max = 0.0
		c.ai_state = &"to_wallow"
		return
	_face_player(sim, c)
	var gap: float = gap_to_player(sim, c)
	if c.cooldown > 0:
		if gap > c.creature_kind.attack_range:
			sim.walk_creature(c, c.facing, GRIST_WALK_SPEED)
		return
	if gap <= c.creature_kind.attack_range:
		_attack(sim, c, &"gore")
		return
	c.ai_timer += 1  # charges since the last millstone
	if c.phase == 2 and c.ai_timer >= 3 and not sim.prop_of(&"millstone_leaning").is_empty():
		c.ai_timer = 0
		c.ai_state = &"to_stone"
		return
	charge(sim, c)


static func _wallow_centre(sim: CombatSim, c: Fighter) -> Vector2:
	var wallow: Dictionary = sim.prop_of(&"wallow")
	return (wallow["rect"] as Rect2).get_center() if not wallow.is_empty() else c.spawn_position


## Walks towards `spot`; true once there.
static func _walk_to(sim: CombatSim, c: Fighter, spot: Vector2, speed: float) -> bool:
	var offset: Vector2 = spot - c.position
	if offset.length() <= 4.0:
		return true
	c.facing = offset.normalized()
	sim.walk_creature(c, c.facing, speed)
	return false


## Starts a charge down the lane to the first thing in its way.
static func charge(sim: CombatSim, c: Fighter) -> bool:
	var move: CombatMove = c.creature_kind.moves[&"charge"]
	move.dash = sim.lane_length(c.position, c.facing, c.radius) + CHARGE_OVERRUN
	move.reach = 0.0
	move.active_ms = maxi(17, int(move.dash / GRIST_CHARGE_SPEED * 1000.0))
	return sim.start_attack(c, move, false)


## Grist wakes: it fights for the rest of the night.
static func wake(sim: CombatSim, c: Fighter) -> void:
	c.alerted = true
	if c.ai_state != &"asleep":
		return
	c.ai_state = &""
	c.cooldown = CombatTuning.ticks(400)
	sim.events.append({"type": "wake", "fighter": c, "position": c.position})


# --- Hooks ----------------------------------------------------------------------------

## The active part of a creature's attack starts.
static func on_active_start(sim: CombatSim, c: Fighter) -> void:
	match c.move.id:
		&"toad_lob":
			var glob: CombatMove = c.creature_kind.moves[&"glob"]
			var flight: int = CombatTuning.ticks(GLOB_FLIGHT_MS)
			sim.zones.append(Zone.make(&"glob", c, glob, c.ai_target, GLOB_RADIUS, flight, 1, 1))
			# The slick lasts from the landing for SLICK_MS (two "waves" a slick
			# apart; it hits nothing, it only slows: CombatSim.ground_speed_factor).
			sim.zones.append(Zone.make(&"slick", c, CombatMove.new(), c.ai_target, GLOB_RADIUS, flight,
				CombatTuning.ticks(SLICK_MS), 2))
			sim.events.append({"type": "lob", "fighter": c, "position": c.ai_target})
		&"pike_spit":
			var jet: CombatMove = c.creature_kind.moves[&"jet"]
			sim.zones.append(Zone.make(&"jet", c, jet, c.ai_target, JET_RADIUS, CombatTuning.ticks(JET_FLIGHT_MS), 1, 1))
			sim.events.append({"type": "spit", "fighter": c, "position": c.ai_target})
		&"grist_heave":
			var stone: Dictionary = sim.prop_of(&"millstone_leaning")
			if stone.is_empty():
				return
			sim.remove_prop(stone)
			var payload: CombatMove = c.creature_kind.moves[&"millstone"]
			var start: Vector2 = c.position + c.facing * (c.radius + MILLSTONE_RADIUS + 1.0)
			var roller: Projectile = Projectile.make(c, payload, start, c.facing,
				CombatTuning.per_tick(MILLSTONE_SPEED), 2000.0)
			roller.radius = MILLSTONE_RADIUS
			roller.pierce = true
			roller.roller = true
			roller.bounces = 1
			sim.projectiles.append(roller)
			sim.events.append({"type": "millstone", "fighter": c, "position": start})


## A creature's attack finished without being interrupted.
static func on_attack_end(sim: CombatSim, c: Fighter, move: CombatMove) -> void:
	match c.creature_kind.behaviour:
		CreatureKind.CURLER:
			c.curled = false
		CreatureKind.FLYER:
			c.airborne = true  # back up after the landing
		CreatureKind.WATER_ARTILLERY:
			c.ai_state = &"surfaced"  # lying at the surface after the spit
			c.ai_timer = CombatTuning.ticks(PIKE_SURFACED_MS)
		CreatureKind.BRUTE_BOSS:
			if c.ai_state == &"second_charge":
				c.ai_state = &""


## A creature's dash ran into something (a move with stops_at_walls).
static func on_blocked(sim: CombatSim, c: Fighter) -> void:
	var move: CombatMove = c.move
	c.move = null
	match c.creature_kind.behaviour:
		CreatureKind.CURLER:
			c.curled = false
			sim.stagger(c, HEDGEHOG_DAZE_MS)
		CreatureKind.BRUTE_BOSS:
			var second: bool = c.ai_state == &"second_charge"
			if second:
				c.ai_state = &""
			var sacks: Dictionary = sim.prop_near(&"sacks", c.position, c.radius + 6.0)
			if not sacks.is_empty():
				_burst_sacks(sim, c, sacks)
				c.enter(Fighter.State.FREE)
				c.cooldown = CombatTuning.ticks(c.creature_kind.cooldown_ms)
				return
			var stone: bool = not sim.prop_near(&"millstone_flat", c.position, c.radius + 6.0).is_empty() \
				or not sim.prop_near(&"millstone_leaning", c.position, c.radius + 6.0).is_empty()
			if c.phase == 2 and not second and not stone:
				# Phase two: it shrugs off the fence and charges again at once.
				sim.events.append({"type": "shrug", "fighter": c, "position": c.position})
				c.enter(Fighter.State.FREE)
				_face_player(sim, c)
				c.ai_state = &"second_charge"
				charge(sim, c)
				return
			sim.events.append({"type": "impact", "fighter": c, "position": c.position})
			sim.stagger(c, GRIST_STUN_MS)
		_:
			c.enter(Fighter.State.FREE)
	if move != null:
		c.cooldown = maxi(c.cooldown, CombatTuning.ticks(c.creature_kind.cooldown_ms))


static func _burst_sacks(sim: CombatSim, c: Fighter, sacks: Dictionary) -> void:
	var rect: Rect2 = sacks["rect"]
	sim.remove_prop(sacks)
	sim.events.append({"type": "sacks_burst", "fighter": c, "position": rect.get_center()})
	for i: int in range(GRIST_SACK_MICE):
		var at: Vector2 = sim.resolve_position(rect.get_center() + Vector2.from_angle(i * TAU / GRIST_SACK_MICE) * 10.0, 4.0)
		var mouse: Fighter = sim.add_creature(at, CreatureKind.field_mouse())
		mouse.creature_kind.respawns = false  # come for the grain; do not come back
		mouse.creature_kind.leash = 10000.0


## Damage a hit does to this creature, after its own defences.
static func adjust_damage(c: Fighter, move: CombatMove, damage: float) -> float:
	if c.curled and not move.heavy:
		return damage * HEDGEHOG_CURLED_DAMAGE
	return damage


## True if this hit cannot stagger the creature (a curled hedgehog shrugs off
## light hits).
static func resists_stagger(c: Fighter, move: CombatMove) -> bool:
	return c.curled and not move.heavy


## After a creature has been hit (and survived).
static func after_hit(sim: CombatSim, c: Fighter, move: CombatMove) -> void:
	match c.creature_kind.behaviour:
		CreatureKind.SWARMER:
			if move.heavy and c.creature_kind.splits_into != &"":
				split(sim, c)
				return
			if c.state == Fighter.State.FREE or c.state == Fighter.State.STAGGERED:
				c.ai_state = &"flee"
				c.ai_timer = CombatTuning.ticks(MOUSE_FLEE_MS)
		CreatureKind.CURLER:
			if c.curled and move.heavy:
				c.curled = false
				sim.events.append({"type": "uncurl", "fighter": c, "position": c.position})
				sim.stagger(c, c.creature_kind.stagger_ms)
		CreatureKind.AMBUSHER:
			if c.disguised:
				reveal(sim, c)
		CreatureKind.BRUTE_BOSS:
			wake(sim, c)


## After a creature's attack hit the player.
static func after_landed(sim: CombatSim, c: Fighter) -> void:
	if c.creature_kind.behaviour == CreatureKind.LIGHT_SEEKER:
		sim.defeat(c)  # a moth is spent on the hit


## False for creatures that look like scenery (no lock-on, no soft aim), and
## for a pike under the water.
static func can_be_aimed_at(c: Fighter) -> bool:
	return not c.disguised and not (rooted(c) and c.untouchable)


## True for a creature that nothing moves: a river pike stays in its water
## (no push from hits, no shoving by other fighters).
static func rooted(f: Fighter) -> bool:
	return f.kind == Fighter.Kind.CREATURE and f.creature_kind.behaviour == CreatureKind.WATER_ARTILLERY
