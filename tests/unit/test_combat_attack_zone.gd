extends TestCase
## Attack zones (what the telegraph shows is what hits), staggers resetting
## attacks, and the longer melee reach: the lead's combat changes of
## 2026-10-10.

const T: GDScript = preload("res://src/combat/combat_tuning.gd")


func _field(creature_positions: Array[Vector2] = []) -> CombatSim:
	var sim: CombatSim = CombatSim.new(Rect2(0, 0, 400, 300), Vector2(100, 150))
	sim.player.facing = Vector2.RIGHT
	for at: Vector2 in creature_positions:
		sim.add_creature(at).ai_enabled = false
	return sim


func _run(sim: CombatSim, ticks: int, input: CombatInput = CombatInput.new()) -> void:
	for i: int in range(ticks):
		sim.step(input)


## A creature at `at` facing left, lunging at the player.
func _lunging(sim: CombatSim, at: Vector2) -> Fighter:
	var c: Fighter = sim.add_creature(at)
	c.ai_enabled = false
	c.facing = Vector2.LEFT
	sim.start_attack(c, sim._creature_lunge)
	return c


# --- 5: the projection is the hit zone ------------------------------------------------

func test_the_telegraph_shows_the_lunge_s_full_reach() -> void:
	var sim: CombatSim = _field()
	var c: Fighter = _lunging(sim, Vector2(200, 150))
	_run(sim, 5)
	var zone: Dictionary = CombatSim.attack_zone(c)
	assert_eq(zone["origin"], c.position, "drawn from the creature during the windup")
	assert_eq(zone["full_reach"], c.radius + T.CREATURE_LUNGE_REACH + T.CREATURE_LUNGE_DISTANCE,
		"the lunge's distance is part of the projection")
	assert_eq(zone["reach"], 0.0, "nothing is hit during the windup")


func test_a_player_just_inside_the_projection_is_hit() -> void:
	var sim: CombatSim = _field()
	var reach: float = T.CREATURE_RADIUS + T.CREATURE_LUNGE_REACH + T.CREATURE_LUNGE_DISTANCE
	# The player's edge 1 px inside the drawn edge.
	var c: Fighter = _lunging(sim, Vector2(100 + reach + T.PLAYER_RADIUS - 1.0, 150))
	_run(sim, c.move.windup_ticks() + c.move.active_ticks() + 2)
	assert_true(sim.player.health < T.PLAYER_HEALTH, "hit")


func test_a_player_just_outside_the_projection_is_not_hit() -> void:
	var sim: CombatSim = _field()
	var reach: float = T.CREATURE_RADIUS + T.CREATURE_LUNGE_REACH + T.CREATURE_LUNGE_DISTANCE
	var c: Fighter = _lunging(sim, Vector2(100 + reach + T.PLAYER_RADIUS + 1.0, 150))
	_run(sim, c.move.windup_ticks() + c.move.active_ticks() + 2)
	assert_eq(sim.player.health, T.PLAYER_HEALTH, "the lunge stops short, as the telegraph showed")


func test_a_player_beside_the_lunge_path_but_outside_the_cone_is_not_hit() -> void:
	# The old hit test ran from the creature's moving body, so a lunge could
	# catch someone the starting telegraph never covered.
	var sim: CombatSim = _field()
	sim.player.position = Vector2(150, 175)  # 50 px ahead of the creature, 25 px aside
	var c: Fighter = _lunging(sim, Vector2(200, 150))
	var zone: Dictionary = CombatSim.attack_zone(c)
	zone["reach"] = zone["full_reach"]
	var inside: bool = CombatSim.in_zone(zone, sim.player)
	_run(sim, c.move.windup_ticks() + c.move.active_ticks() + 2)
	assert_eq(sim.player.health < T.PLAYER_HEALTH, inside, "hit exactly when inside the drawn zone")


func test_the_zone_fills_as_the_lunge_travels() -> void:
	var sim: CombatSim = _field()
	var c: Fighter = _lunging(sim, Vector2(250, 150))
	_run(sim, c.move.windup_ticks())
	var reaches: Array[float] = []
	for i: int in range(c.move.active_ticks()):
		sim.step(CombatInput.new())
		reaches.append(float(CombatSim.attack_zone(c)["reach"]))
	# Sampled after each tick, as the drawer sees it: it grows through the
	# lunge and is full by its last tick (where it stays into the recovery).
	var full: float = float(CombatSim.attack_zone(c)["full_reach"])
	assert_true(reaches[0] < full * 0.6, "starts small (%.1f of %.1f)" % [reaches[0], full])
	for i: int in range(1, reaches.size() - 1):
		assert_true(reaches[i] > reaches[i - 1], "grows every tick of the lunge (tick %d)" % i)
	assert_eq(reaches[reaches.size() - 1], full, "ends at the full projection")


func test_the_zone_stays_where_the_lunge_started() -> void:
	var sim: CombatSim = _field()
	var c: Fighter = _lunging(sim, Vector2(250, 150))
	_run(sim, c.move.windup_ticks())
	var origin: Vector2 = c.position
	_run(sim, c.move.active_ticks())
	assert_true(c.position.distance_to(origin) > 20.0, "the body lunged forward")
	assert_eq(CombatSim.attack_zone(c)["origin"], origin, "the zone did not move with it")


func test_a_creature_shoved_during_its_windup_takes_the_telegraph_along() -> void:
	var sim: CombatSim = _field()
	var c: Fighter = _lunging(sim, Vector2(250, 150))
	_run(sim, 5)
	c.position += Vector2(20, 0)
	_run(sim, 1)
	assert_eq(CombatSim.attack_zone(c)["origin"], c.position, "the zone follows until the lunge starts")
	var shoved_to: Vector2 = c.position
	_run(sim, c.move.windup_ticks() - 6 + 2)
	assert_eq(c.attack_phase(), &"active", "lunging")
	assert_eq(CombatSim.attack_zone(c)["origin"], shoved_to,
		"and the lunge's zone starts from where the creature was shoved to, not where it first stood")


# --- 1: a stagger resets the attack ---------------------------------------------------

func test_a_stagger_cancels_the_attack_and_the_next_one_starts_from_scratch() -> void:
	var sim: CombatSim = _field()
	var c: Fighter = _lunging(sim, Vector2(125, 150))
	c.ai_enabled = true
	_run(sim, 30)
	assert_eq(c.attack_phase(), &"windup", "telegraphing")
	sim.stagger(c)
	assert_eq(c.attack_phase(), &"", "the attack is gone")
	var stagger_ticks: int = c.state_length
	_run(sim, stagger_ticks)
	assert_eq(c.state, Fighter.State.FREE, "the stagger ended")
	assert_eq(c.attack_phase(), &"", "no attack the moment it recovers")
	var waited: int = 0
	while c.attack_phase() == &"" and waited < 200:
		sim.step(CombatInput.new())
		waited += 1
	assert_true(waited >= T.ticks(T.CREATURE_COOLDOWN_MS) - 1, "it waits its cooldown first (%d ticks)" % waited)
	assert_eq(c.attack_phase(), &"windup", "a new attack")
	assert_eq(c.state_tick, 0, "whose telegraph starts at the beginning")


func test_a_frozen_creature_also_restarts_its_attack() -> void:
	var sim: CombatSim = _field()
	var c: Fighter = _lunging(sim, Vector2(125, 150))
	_run(sim, 30)
	sim.apply_effect(c, StatusEffects.CHILL, 5)
	assert_true(c.is_staggered(), "Frozen")
	assert_eq(c.cooldown, T.ticks(T.CREATURE_COOLDOWN_MS), "with the recovery after it")


# --- 2: longer greatsword and hammer reach --------------------------------------------

func test_greatsword_and_hammer_reach_about_forty_percent_further() -> void:
	# Before 2026-10-10: light 28, cleave 32, shove 20, spin 30, rising 28,
	# Follow-through 28 (and 24 to qualify); jab 24, strike 30, stamp 12.
	var before: Dictionary = {
		Greatsword.LIGHTS[0]: 28.0, Greatsword.FINISHERS[0]: 32.0, Greatsword.FINISHERS[1]: 20.0,
		Greatsword.FINISHERS[2]: 30.0, Greatsword.FINISHERS[3]: 28.0, Greatsword.FOLLOW_THROUGH: 28.0,
		Hammer.JAB: 24.0, Hammer.GROUND_STAMP: 12.0, Hammer.new().strike_for(0): 30.0,
	}
	for move: CombatMove in before:
		var ratio: float = move.reach / float(before[move])
		assert_true(ratio > 1.35 and ratio < 1.45, "%s reaches %.0f (x%.2f)" % [move.display_name, move.reach, ratio])
	assert_true(absf(Greatsword.FOLLOW_THROUGH_REACH / 24.0 - 1.4) < 0.05, "Follow-through qualifies from further")


func test_a_light_swing_lands_at_its_new_reach() -> void:
	var gap: float = 38.0  # beyond the old reach of 28, within the new 39
	var sim: CombatSim = _field([Vector2(100 + T.PLAYER_RADIUS + gap + T.CREATURE_RADIUS, 150)])
	sim.step(CombatInput.press(&"light"))
	_run(sim, 40)
	assert_true(sim.creatures[0].health < T.CREATURE_HEALTH, "hit at %d px" % gap)
