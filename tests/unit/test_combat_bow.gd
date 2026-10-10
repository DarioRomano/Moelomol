extends TestCase
## The bow (docs/design/combat.md, "Bow: movement and flow"): arrows, the
## three-stage draw, clean release, dodge shot, Flow and Volley, in the pure
## simulation.

const T: GDScript = preload("res://src/combat/combat_tuning.gd")


## Open 400x300 field, player at (100, 150) facing right with the bow in
## hand (greatsword in the other slot), passive creatures where asked.
func _field(creature_positions: Array[Vector2] = []) -> CombatSim:
	var sim: CombatSim = CombatSim.new(Rect2(0, 0, 400, 300), Vector2(100, 150))
	sim.player.facing = Vector2.RIGHT
	sim.player.weapons[1] = Bow.new()
	sim.player.weapon_index = 1
	for at: Vector2 in creature_positions:
		sim.add_creature(at).ai_enabled = false
	return sim


func _bow(sim: CombatSim) -> Bow:
	return sim.player.weapon() as Bow


func _run(sim: CombatSim, ticks: int, input: CombatInput = CombatInput.new()) -> Array[Dictionary]:
	var seen: Array[Dictionary] = []
	for i: int in range(ticks):
		sim.step(input)
		seen.append_array(sim.events)
	return seen


## Runs until no arrow is in flight and the player is free again.
func _settle(sim: CombatSim) -> Array[Dictionary]:
	var seen: Array[Dictionary] = []
	for i: int in range(400):
		if sim.projectiles.is_empty() and sim.zones.is_empty() and sim.player.state == Fighter.State.FREE and sim.hitstop == 0:
			break
		sim.step(CombatInput.new())
		seen.append_array(sim.events)
	return seen


## Press heavy, hold `held` ticks, release; returns the events on the way.
func _draw_and_release(sim: CombatSim, held: int) -> Array[Dictionary]:
	var seen: Array[Dictionary] = []
	sim.step(CombatInput.press(&"heavy"))
	seen.append_array(sim.events)
	seen.append_array(_run(sim, held, CombatInput.hold_heavy()))
	sim.step(CombatInput.new())
	seen.append_array(sim.events)
	return seen


func _count(events: Array[Dictionary], type: String) -> int:
	var n: int = 0
	for e: Dictionary in events:
		if e["type"] == type:
			n += 1
	return n


func _hits_with(events: Array[Dictionary], move_id: StringName) -> int:
	var n: int = 0
	for e: Dictionary in events:
		if e["type"] == "hit" and e["move"] == move_id:
			n += 1
	return n


# --- Arrows ------------------------------------------------------------------------

func test_quick_shot_flies_and_hits_the_creature_in_front() -> void:
	var sim: CombatSim = _field([Vector2(220, 150)])
	sim.step(CombatInput.press(&"light"))
	assert_eq(sim.player.move, Bow.QUICK_SHOT, "quick shot")
	var seen: Array[Dictionary] = _run(sim, Bow.QUICK_SHOT.windup_ticks() + 1)
	assert_eq(_count(seen, "arrow"), 1, "one arrow loosed after the short windup")
	seen.append_array(_settle(sim))
	assert_eq(sim.creatures[0].health, T.CREATURE_HEALTH - Bow.arrow(0, false).damage, "the arrow hits once")
	assert_true(sim.projectiles.is_empty(), "and stops in the creature")


func test_arrow_takes_time_to_arrive() -> void:
	var sim: CombatSim = _field([Vector2(280, 150)])
	sim.step(CombatInput.press(&"light"))
	var ticks_to_hit: int = 0
	for i: int in range(120):
		sim.step(CombatInput.new())
		ticks_to_hit += 1
		if sim.creatures[0].health < T.CREATURE_HEALTH:
			break
	var flight: float = (280.0 - 7.0 - 108.0) / T.per_tick(T.ARROW_SPEED)
	assert_true(absf(ticks_to_hit - Bow.QUICK_SHOT.windup_ticks() - flight) <= 2.0,
		"hits after the windup plus ~%.0f ticks of flight (took %d)" % [flight, ticks_to_hit])


func test_arrows_stop_at_obstacles_and_walls() -> void:
	var sim: CombatSim = _field([Vector2(260, 150)])
	sim.obstacles.append(Rect2(160, 130, 20, 40))
	sim.step(CombatInput.press(&"light"))
	_settle(sim)
	assert_eq(sim.creatures[0].health, T.CREATURE_HEALTH, "the pillar took the arrow")
	sim.player.facing = Vector2.UP
	sim.step(CombatInput.press(&"light"))
	var steps: int = 0
	while not sim.projectiles.is_empty() or steps < 10:
		sim.step(CombatInput.new())
		steps += 1
		if steps > 200:
			break
	assert_true(steps < 60, "an arrow into the wall stops at the wall (%d ticks)" % steps)


func test_arrows_fly_only_so_far() -> void:
	var sim: CombatSim = CombatSim.new(Rect2(0, 0, 1000, 300), Vector2(100, 150))
	sim.player.facing = Vector2.RIGHT
	sim.player.weapons[1] = Bow.new()
	sim.player.weapon_index = 1
	sim.add_creature(Vector2(100 + 8 + T.ARROW_RANGE + 30, 150)).ai_enabled = false
	sim.step(CombatInput.press(&"light"))
	_settle(sim)
	assert_eq(sim.creatures[0].health, T.CREATURE_HEALTH, "a creature beyond range is not hit")


func test_shots_soft_aim_at_range() -> void:
	# 20 degrees off the facing, 150 px away: inside the cone, beyond melee.
	var at: Vector2 = Vector2(100, 150) + Vector2.from_angle(deg_to_rad(20.0)) * 150.0
	var sim: CombatSim = _field([at])
	sim.step(CombatInput.press(&"light"))
	_settle(sim)
	assert_true(sim.creatures[0].health < T.CREATURE_HEALTH, "the shot turned towards the creature")


func test_the_shot_itself_never_hits_in_melee() -> void:
	# A creature touching the player straight ahead: only the arrow hits it.
	var sim: CombatSim = _field([Vector2(113, 150)])
	sim.step(CombatInput.press(&"light"))
	var seen: Array[Dictionary] = _settle(sim)
	assert_eq(_hits_with(seen, &"quick_shot"), 0, "no melee hit from the shot")
	assert_eq(_hits_with(seen, &"arrow_quick"), 1, "the arrow hits")


func test_shots_miss_creatures_behind() -> void:
	var sim: CombatSim = _field([Vector2(40, 150)])
	sim.step(CombatInput.press(&"light"))
	_settle(sim)
	assert_eq(sim.creatures[0].health, T.CREATURE_HEALTH, "nothing behind is hit")


# --- The draw ----------------------------------------------------------------------

func test_draw_stages_are_reached_and_announced() -> void:
	var sim: CombatSim = _field()
	assert_eq(_bow(sim).stage_ticks(), [18, 42, 72] as Array[int], "300, 700, 1200 ms")
	sim.step(CombatInput.press(&"heavy"))
	assert_eq(sim.player.state, Fighter.State.CHARGE, "drawing")
	assert_eq(sim.player.stamina.current, T.STAMINA_MAX - Bow.DRAW_STAMINA, "the draw costs stamina")
	var stages: Array[int] = []
	var at: Array[int] = []
	for i: int in range(80):
		sim.step(CombatInput.hold_heavy())
		for e: Dictionary in sim.events:
			if e["type"] == "draw_stage":
				stages.append(int(e["stage"]))
				at.append(i)
	assert_eq(stages, [1, 2, 3] as Array[int], "three stages, in order")
	assert_eq(at, [18, 42, 72] as Array[int], "at the stage times")


func test_release_before_stage_one_is_a_weak_arrow() -> void:
	var sim: CombatSim = _field([Vector2(200, 150)])
	var seen: Array[Dictionary] = _draw_and_release(sim, 5)
	seen.append_array(_settle(sim))
	assert_eq(_hits_with(seen, &"arrow_quick"), 1, "the quick-shot arrow")


func test_stage_one_is_a_strong_arrow() -> void:
	var sim: CombatSim = _field([Vector2(200, 150)])
	var seen: Array[Dictionary] = _draw_and_release(sim, _bow(sim).stage_ticks()[0] + 10)
	seen.append_array(_settle(sim))
	assert_eq(_hits_with(seen, &"arrow_strong"), 1, "strong arrow")
	assert_eq(sim.creatures[0].health, T.CREATURE_HEALTH - Bow.arrow(1, false).damage, "its damage")


func test_stage_two_pierces_a_line_of_creatures() -> void:
	var sim: CombatSim = _field([Vector2(150, 150), Vector2(185, 152), Vector2(220, 148)])
	var seen: Array[Dictionary] = _draw_and_release(sim, _bow(sim).stage_ticks()[1] + 10)
	seen.append_array(_settle(sim))
	assert_eq(_hits_with(seen, &"arrow_piercing"), 3, "one arrow, three creatures")


func test_a_strong_arrow_stops_at_the_first_creature() -> void:
	var sim: CombatSim = _field([Vector2(150, 150), Vector2(185, 152)])
	var seen: Array[Dictionary] = _draw_and_release(sim, _bow(sim).stage_ticks()[0] + 10)
	seen.append_array(_settle(sim))
	assert_eq(sim.creatures[1].health, T.CREATURE_HEALTH, "the second creature is untouched")


func test_stage_three_is_a_heavy_arrow_that_staggers_and_knocks_back() -> void:
	var sim: CombatSim = _field([Vector2(180, 150)])
	var seen: Array[Dictionary] = _draw_and_release(sim, _bow(sim).stage_ticks()[2] + 10)
	seen.append_array(_settle(sim))
	seen.append_array(_run(sim, T.ticks(T.PUSH_MS)))  # let the push play out
	assert_eq(_hits_with(seen, &"arrow_heavy"), 1, "heavy arrow")
	assert_true(sim.creatures[0].is_staggered(), "a training creature is staggered")
	assert_true(sim.creatures[0].position.x > 195.0, "knocked back (now at x=%.0f)" % sim.creatures[0].position.x)


func test_clean_release_adds_a_bonus() -> void:
	var bow: Bow = Bow.new()
	var stage_two: int = bow.stage_ticks()[1]
	var clean_window: int = T.ticks(Bow.CLEAN_RELEASE_MS)
	assert_true(bow.is_clean(stage_two), "on the stage tick")
	assert_true(bow.is_clean(stage_two + clean_window - 1), "last tick of the 80 ms moment")
	assert_false(bow.is_clean(stage_two + clean_window), "just after")
	assert_false(bow.is_clean(5), "nothing to be clean about before stage 1")
	var sim: CombatSim = _field([Vector2(200, 150)])
	_draw_and_release(sim, _bow(sim).stage_ticks()[0] + 1)
	_settle(sim)
	assert_eq(sim.creatures[0].health, T.CREATURE_HEALTH - Bow.arrow(1, false).damage * (1.0 + Bow.CLEAN_RELEASE_BONUS),
		"+25% damage for a clean release")


func test_holding_stage_three_drains_stamina_until_the_arrow_flies() -> void:
	var sim: CombatSim = _field()
	var stage_three: int = _bow(sim).stage_ticks()[2]
	sim.step(CombatInput.press(&"heavy"))
	_run(sim, stage_three, CombatInput.hold_heavy())
	assert_eq(sim.player.stamina.current, T.STAMINA_MAX - Bow.DRAW_STAMINA, "no cost before stage 3")
	_run(sim, 60, CombatInput.hold_heavy())
	var expected: float = T.STAMINA_MAX - Bow.DRAW_STAMINA - Bow.STAGE_3_DRAIN_PER_S
	assert_true(absf(sim.player.stamina.current - expected) < 0.01, "a second at stage 3 costs 15")
	sim.player.stamina.current = 0.1
	var seen: Array[Dictionary] = _run(sim, 3, CombatInput.hold_heavy())
	assert_eq(_count(seen, "shot"), 1, "out of stamina: the arrow is loosed")


func test_drawing_slows_but_does_not_stop() -> void:
	var sim: CombatSim = _field()
	sim.step(CombatInput.press(&"heavy"))
	var start: Vector2 = sim.player.position
	_run(sim, 30, CombatInput.hold_heavy(Vector2.DOWN))
	var moved: float = sim.player.position.distance_to(start)
	assert_true(absf(moved - Bow.DRAW_MOVE_SPEED / 2.0) < 0.5, "half a second at draw speed (moved %.1f px)" % moved)


# --- Flow --------------------------------------------------------------------------

func test_arrow_hits_build_flow_up_to_five() -> void:
	var sim: CombatSim = _field([Vector2(200, 150)])
	for i: int in range(7):
		sim.player.stamina.current = T.STAMINA_MAX
		sim.step(CombatInput.press(&"light"))
		_settle(sim)
		sim.creatures[0].health = T.CREATURE_HEALTH
		sim.creatures[0].position = Vector2(200, 150)
	assert_eq(_bow(sim).flow, Bow.MAX_FLOW, "Flow stops at 5")


func test_flow_makes_drawing_faster() -> void:
	var bow: Bow = Bow.new()
	bow.flow = 5
	assert_eq(bow.stage_ticks(), [T.ticks(180), T.ticks(420), T.ticks(720)] as Array[int], "40% faster at Flow 5")


func test_getting_hit_loses_all_flow_even_with_the_other_weapon_in_hand() -> void:
	var sim: CombatSim = _field([Vector2(120, 150)])
	_bow(sim).flow = 4
	var bow: Bow = _bow(sim)
	sim.player.weapon_index = 0  # greatsword in hand
	var creature: Fighter = sim.creatures[0]
	creature.facing = Vector2.LEFT
	sim.start_attack(creature, sim._creature_lunge)
	_run(sim, creature.move.windup_ticks() + creature.move.active_ticks() + 10)
	assert_true(sim.player.health < T.PLAYER_HEALTH, "the lunge landed")
	assert_eq(bow.flow, 0, "Flow lost")


func test_melee_hits_do_not_build_flow() -> void:
	var sim: CombatSim = _field([Vector2(125, 150)])
	var bow: Bow = _bow(sim)
	sim.player.weapon_index = 0
	sim.step(CombatInput.press(&"light"))
	_settle(sim)
	assert_true(sim.creatures[0].health < T.CREATURE_HEALTH, "the sword hit")
	assert_eq(bow.flow, 0, "no Flow from the greatsword")


# --- Dodge shot --------------------------------------------------------------------

func test_heavy_during_a_dodge_looses_a_piercing_arrow_as_the_roll_ends() -> void:
	var sim: CombatSim = _field([Vector2(250, 150)])
	var dodge: CombatInput = CombatInput.press(&"dodge")
	dodge.move = Vector2.RIGHT
	sim.step(dodge)
	_run(sim, 5)
	sim.step(CombatInput.press(&"heavy"))
	assert_eq(sim.player.state, Fighter.State.DODGE, "still rolling")
	var seen: Array[Dictionary] = []
	while sim.player.state == Fighter.State.DODGE:
		sim.step(CombatInput.new())
		seen.append_array(sim.events)
	assert_eq(sim.player.move.id, &"dodge_shot", "the shot starts as the roll ends")
	assert_eq(sim.player.stamina.current, T.STAMINA_MAX - T.DODGE_STAMINA - Bow.DRAW_STAMINA, "it costs a draw")
	seen.append_array(_settle(sim))
	assert_eq(_hits_with(seen, &"arrow_piercing"), 1, "a piercing (stage 2) arrow")


func test_a_dodge_without_heavy_shoots_nothing() -> void:
	var sim: CombatSim = _field()
	sim.step(CombatInput.press(&"dodge"))
	var seen: Array[Dictionary] = _run(sim, 40)
	assert_eq(_count(seen, "arrow"), 0, "no arrow")


# --- Volley ------------------------------------------------------------------------

func test_volley_marks_then_rains_on_the_mark() -> void:
	var sim: CombatSim = _field([Vector2(200, 150), Vector2(214, 160), Vector2(200, 230)])
	sim.step(CombatInput.press(&"skill"))
	assert_eq(sim.player.move, Bow.MARKER_SHOT, "first press: the marker arrow")
	var seen: Array[Dictionary] = _settle(sim)
	assert_eq(_count(seen, "mark"), 1, "the mark is set where it stopped")
	var bow: Bow = _bow(sim)
	assert_true(bow.mark.distance_to(Vector2(200, 150)) < 10.0, "on the creature it hit")
	bow.flow = 2
	sim.step(CombatInput.press(&"skill"))
	assert_eq(sim.player.move, Bow.VOLLEY_CALL, "second press: the rain")
	assert_eq(sim.zones.size(), 1, "a rain zone")
	assert_eq(sim.zones[0].radius, Bow.VOLLEY_RADIUS + Bow.VOLLEY_RADIUS_PER_FLOW * 2, "wider for the Flow spent")
	assert_eq(bow.flow, 0, "Flow spent")
	seen = _settle(sim)
	assert_eq(_count(seen, "wave"), Bow.VOLLEY_WAVES, "three waves")
	assert_eq(_hits_with(seen, &"volley_rain"), Bow.VOLLEY_WAVES * 2, "both marked creatures, every wave")
	assert_eq(sim.creatures[2].health, T.CREATURE_HEALTH, "the creature outside the rain is untouched")
	assert_eq(bow.flow, 0, "rain hits build no Flow")


func test_rain_waits_before_the_first_wave() -> void:
	var sim: CombatSim = _field([Vector2(200, 150)])
	var bow: Bow = _bow(sim)
	bow.mark = Vector2(200, 150)
	bow.mark_ticks = 100
	sim.step(CombatInput.press(&"skill"))
	var first: int = -1
	for i: int in range(60):
		sim.step(CombatInput.new())
		if _count(sim.events, "wave") > 0:
			first = i
			break
	assert_eq(first, T.ticks(Bow.VOLLEY_DELAY_MS) - 1, "the first wave after 400 ms")


func test_rain_zone_ends_with_its_last_wave() -> void:
	var zone: Zone = Zone.make(&"volley", null, Bow.RAIN, Vector2.ZERO, 20.0, 24, 18, 3)
	var waves: int = 0
	var lifetime: int = 0
	while not zone.is_finished():
		if zone.wave_now():
			waves += 1
		zone.age += 1
		lifetime += 1
		if lifetime > 500:
			break
	assert_eq(waves, 3, "three waves")
	assert_eq(lifetime, 24 + 18 * 2 + 1, "gone right after the third wave")
	zone.age = 24 + 18 * 3
	assert_false(zone.wave_now(), "no fourth wave, even if it lingered")


func test_the_mark_expires() -> void:
	var sim: CombatSim = _field()
	var bow: Bow = _bow(sim)
	bow.mark = Vector2(200, 150)
	bow.mark_ticks = T.ticks(Bow.VOLLEY_MARK_MS)
	_run(sim, T.ticks(Bow.VOLLEY_MARK_MS))
	sim.step(CombatInput.press(&"skill"))
	assert_eq(sim.player.move, Bow.MARKER_SHOT, "after 4 s, skill marks again")


# --- Loadout and feedback ----------------------------------------------------------

func test_loadout_key_cycles_the_weapon_not_in_hand() -> void:
	var sim: CombatSim = CombatSim.new(Rect2(0, 0, 400, 300), Vector2(100, 150))
	var seen: Array[StringName] = []
	for i: int in range(4):
		seen.append(sim.cycle_offhand_weapon().id)
		assert_eq(sim.player.weapon().id, &"greatsword", "the weapon in hand stays")
	assert_eq(seen, [&"bow", &"magic", &"hammer", &"bow"] as Array[StringName], "every weapon but the one in hand, in turn")


func test_bow_events_map_to_haptic_effects() -> void:
	var p: Fighter = Fighter.make_player(Vector2.ZERO)
	var c: Fighter = Fighter.make_creature(Vector2.ZERO)
	assert_eq(Haptics.effect_for_event({"type": "draw_stage", "fighter": p, "stage": 1}), &"bow_stage", "stage tick")
	assert_eq(Haptics.effect_for_event({"type": "arrow", "fighter": p}), &"bow_release", "release snap")
	assert_eq(Haptics.effect_for_event({"type": "hit", "target": c, "move": &"arrow_strong"}), &"bow_hit", "arrow hit")
	assert_eq(Haptics.effect_for_event({"type": "hit", "target": c, "move": &"arrow_heavy"}), &"bow_heavy_hit", "heavy hit")
	assert_eq(Haptics.effect_for_event({"type": "hit", "target": c, "move": &"volley_rain"}), &"", "no rumble per rain hit")
	for effect: StringName in [&"bow_stage", &"bow_release", &"bow_hit", &"bow_heavy_hit"]:
		assert_true(Haptics.EFFECTS.has(effect), "%s is defined" % effect)
