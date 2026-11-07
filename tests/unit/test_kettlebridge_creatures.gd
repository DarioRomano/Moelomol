extends TestCase
## Kettlebridge's creatures (docs/design/area-kettlebridge.md, "Creatures,
## zone by zone"): market rats that split, jackdaws that drop runts, river
## pike that spit from the water, Lichen-backs among the graves; and the
## encounter plan as placed in the town.


func _sim() -> CombatSim:
	var sim: CombatSim = CombatSim.new(Rect2(0, 0, 640, 360), Vector2(100, 180))
	sim.player.facing = Vector2.RIGHT
	return sim


func _heavy() -> CombatMove:
	var move: CombatMove = CombatMove.make(&"test_heavy", "Heavy", Vector3i(1, 1, 1), 10.0, 10.0, 0.0, 20.0, 90.0, 0.0)
	move.heavy = true
	return move


func _light() -> CombatMove:
	return CombatMove.make(&"test_light", "Light", Vector3i(1, 1, 1), 5.0, 5.0, 0.0, 20.0, 90.0, 0.0)


func _of(sim: CombatSim, kind: StringName) -> Array[Fighter]:
	var found: Array[Fighter] = []
	for c: Fighter in sim.creatures:
		if c.creature_kind.id == kind and c.is_alive():
			found.append(c)
	return found


func _count(area: Area) -> Dictionary:
	var counts: Dictionary = {}
	for c: Fighter in area.sim.creatures:
		counts[c.creature_kind.id] = int(counts.get(c.creature_kind.id, 0)) + 1
	return counts


func _run(sim: CombatSim, ticks: int, input: CombatInput = CombatInput.new()) -> Array[Dictionary]:
	var seen: Array[Dictionary] = []
	for i: int in range(ticks):
		sim.step(input)
		seen.append_array(sim.events)
	return seen


func _bfs(map: AreaMap, from: Vector2i) -> Dictionary:
	var seen: Dictionary = {from: true}
	var queue: Array[Vector2i] = [from]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + d
			if not seen.has(next) and next.x >= 0 and next.y >= 0 and next.x < map.size.x and next.y < map.size.y \
					and not map.is_solid(next):
				seen[next] = true
				queue.append(next)
	return seen


# --- Market rats -------------------------------------------------------------------

func test_every_new_kind_is_known_by_its_id() -> void:
	for id: StringName in [&"market_rat", &"rat_runt", &"jackdaw", &"river_pike", &"lichen_back"]:
		assert_eq(CreatureKind.by_id(id).id, id, "%s by id" % id)


func test_a_heavy_hit_splits_a_market_rat_into_two_runts() -> void:
	var sim: CombatSim = _sim()
	var rat: Fighter = sim.add_creature(Vector2(130, 180), CreatureKind.market_rat())
	sim._hit(sim.player, rat, _heavy())
	assert_eq(rat.state, Fighter.State.GONE, "the rat is gone")
	var runts: Array[Fighter] = _of(sim, &"rat_runt")
	assert_eq(runts.size(), 2, "two runts")
	for runt: Fighter in runts:
		assert_true(runt.position.distance_to(Vector2(130, 180)) < 12.0, "where the rat was (%s)" % runt.position)
		assert_false(runt.creature_kind.respawns, "a runt does not come back")
		assert_eq(runt.creature_kind.splits_into, &"", "and does not split again")
	assert_true(runts[0].position.distance_to(runts[1].position) > 4.0, "either side")
	assert_true(sim.events.any(func(e: Dictionary) -> bool: return e["type"] == "split"), "reported")


func test_a_light_hit_does_not_split_a_rat_and_a_runt_never_splits() -> void:
	var sim: CombatSim = _sim()
	var rat: Fighter = sim.add_creature(Vector2(130, 180), CreatureKind.market_rat())
	sim._hit(sim.player, rat, _light())
	assert_true(rat.is_alive(), "still one rat")
	assert_eq(_of(sim, &"rat_runt").size(), 0, "no runts")
	var runt: Fighter = sim.add_creature(Vector2(200, 180), CreatureKind.rat_runt())
	sim._hit(sim.player, runt, _heavy())
	assert_eq(_of(sim, &"rat_runt"), [runt], "a runt hit hard stays one runt")


func test_a_heavy_hit_that_kills_does_not_split() -> void:
	var sim: CombatSim = _sim()
	var rat: Fighter = sim.add_creature(Vector2(130, 180), CreatureKind.market_rat())
	rat.health = 5.0
	sim._hit(sim.player, rat, _heavy())
	assert_eq(rat.state, Fighter.State.DOWN, "defeated")
	assert_eq(_of(sim, &"rat_runt").size(), 0, "no runts from a dead rat")


func test_a_split_rat_comes_back_the_next_morning_like_a_defeated_one() -> void:
	var area: Area = Kettlebridge.make()
	var entry: Dictionary = {}
	for e: Dictionary in area.roster:
		if e["kind"] == &"market_rat" and e["fighter"] != null:
			entry = e
			break
	var rat: Fighter = entry["fighter"]
	CreatureBrain.split(area.sim, rat)
	area.sync(false)
	assert_eq(int(entry["defeated_day"]), area.clock.day(), "counted as defeated today")


# --- Jackdaws ----------------------------------------------------------------------

func test_a_jackdaw_drops_its_runt_beside_the_player_once_then_dives() -> void:
	var sim: CombatSim = _sim()
	var bird: Fighter = sim.add_creature(Vector2(200, 180), CreatureKind.jackdaw())
	var aloft: int = CombatTuning.ticks(CreatureBrain.ROOK_ALOFT_MS)
	var seen: Array[Dictionary] = _run(sim, aloft + 2)
	var drops: Array[Dictionary] = seen.filter(func(e: Dictionary) -> bool: return e["type"] == "drop")
	assert_eq(drops.size(), 1, "one runt dropped")
	var runts: Array[Fighter] = _of(sim, &"rat_runt")
	assert_eq(runts.size(), 1, "a runt on the ground")
	if runts.size() == 1:
		assert_true(runts[0].position.distance_to(sim.player.position) <= CreatureBrain.DROP_OFFSET + 1.0,
			"beside the player (%.0f px)" % runts[0].position.distance_to(sim.player.position))
	assert_eq(bird.state, Fighter.State.FREE, "no dive yet: it let go instead")
	seen = _run(sim, aloft + 2)
	assert_eq(seen.filter(func(e: Dictionary) -> bool: return e["type"] == "drop").size(), 0, "never a second runt")
	assert_true(bird.state == Fighter.State.ATTACK or bird.cooldown > 0, "then it dives")


func test_a_runt_is_never_dropped_inside_a_wall() -> void:
	var area: Area = Kettlebridge.make()
	var sim: CombatSim = area.sim
	# The player against the wall of a house on the square; the bird over the house.
	sim.player.position = sim.resolve_position(Kettlebridge.at(30, 11) + Vector2(0, -20), sim.player.radius)
	var bird: Fighter = sim.add_creature(sim.player.position + Vector2(0, -40), CreatureKind.jackdaw())
	var runt: Fighter = CreatureBrain.drop_carried(sim, bird)
	assert_false(area.map.is_solid(AreaMap.cell_of(runt.position)), "on open ground (%s)" % runt.position)


# --- River pike --------------------------------------------------------------------

func test_a_pike_under_the_water_cannot_be_hit_or_locked_on() -> void:
	var sim: CombatSim = _sim()
	var pike: Fighter = sim.add_creature(Vector2(500, 180), CreatureKind.river_pike())
	_run(sim, 2)
	assert_true(pike.untouchable, "under the water")
	assert_false(CreatureBrain.can_be_aimed_at(pike), "nothing to lock on to")
	var health: float = pike.health
	sim._hit(sim.player, pike, _heavy())
	assert_eq(pike.health, health, "an arrow cannot reach it")


func test_a_pike_surfaces_spits_at_the_player_and_lies_at_the_surface_a_while() -> void:
	var sim: CombatSim = _sim()
	var pike: Fighter = sim.add_creature(Vector2(200, 180), CreatureKind.river_pike())
	var marked: Vector2 = sim.player.position
	var seen: Array[Dictionary] = _run(sim, 3)
	assert_true(seen.any(func(e: Dictionary) -> bool: return e["type"] == "surface"), "it surfaces")
	assert_false(pike.untouchable, "and can be hit")
	assert_true(CreatureBrain.can_be_aimed_at(pike), "and locked on to")
	seen = _run(sim, CombatTuning.ticks(700) + 2)
	var spits: Array[Dictionary] = seen.filter(func(e: Dictionary) -> bool: return e["type"] == "spit")
	assert_eq(spits.size(), 1, "one spit")
	assert_eq(spits[0]["position"], marked, "at where the player stood")
	var health: float = sim.player.health
	_run(sim, CombatTuning.ticks(CreatureBrain.JET_FLIGHT_MS) + 2)
	assert_true(sim.player.health < health, "the jet lands on a player who stays")
	_run(sim, CombatTuning.ticks(CreatureBrain.PIKE_SURFACED_MS) - CombatTuning.ticks(CreatureBrain.JET_FLIGHT_MS) - 20)
	assert_false(pike.untouchable, "still at the surface")
	seen = _run(sim, 60)
	assert_true(seen.any(func(e: Dictionary) -> bool: return e["type"] == "submerge"), "then it goes under")
	assert_true(pike.untouchable, "out of reach again")


func test_a_pike_out_of_sight_stays_under() -> void:
	var sim: CombatSim = _sim()
	var pike: Fighter = sim.add_creature(sim.player.position + Vector2(CreatureBrain.PIKE_SIGHT + 20.0, 0), CreatureKind.river_pike())
	var seen: Array[Dictionary] = _run(sim, 120)
	assert_false(seen.any(func(e: Dictionary) -> bool: return e["type"] == "surface"), "no surfacing")
	assert_true(pike.untouchable, "under")


func test_nothing_moves_a_pike_out_of_its_water() -> void:
	var area: Area = Kettlebridge.make()
	var sim: CombatSim = area.sim
	for c: Fighter in sim.creatures:
		c.ai_enabled = false
	var pike: Fighter = sim.add_creature(Kettlebridge.at(20, 23), CreatureKind.river_pike())
	pike.ai_enabled = false
	pike.untouchable = false
	var home: Vector2 = pike.position
	var shove: CombatMove = _heavy()
	shove.push = 60.0
	sim.player.position = Kettlebridge.at(20, 22)
	sim._hit(sim.player, pike, shove)
	var runt: Fighter = sim.add_creature(home + Vector2(2, 0), CreatureKind.rat_runt())
	runt.ai_enabled = false
	_run(sim, 20)
	assert_eq(pike.position, home, "not pushed or shoved onto the bank")
	assert_eq(area.map.char_at(AreaMap.cell_of(pike.position)), "~", "still in the river")


func test_a_blade_on_the_towpath_reaches_a_pike_lying_at_the_surface() -> void:
	var area: Area = Kettlebridge.make()
	var sim: CombatSim = area.sim
	for c: Fighter in sim.creatures:
		c.ai_enabled = false
	var pike: Fighter = null
	for c: Fighter in sim.creatures:
		if c.creature_kind.id == &"river_pike":
			pike = c
			break
	pike.untouchable = false
	sim.player.position = sim.resolve_position(Vector2(pike.position.x, pike.position.y - 20.0), sim.player.radius)
	sim.player.previous_position = sim.player.position
	sim.player.facing = Vector2.DOWN
	var health: float = pike.health
	sim.step(CombatInput.press(&"light"))
	_run(sim, 40)
	assert_true(pike.health < health, "the light swing reaches it from the bank's edge")


# --- Lichen-backs ------------------------------------------------------------------

func test_a_lichen_back_is_a_gravestone_until_the_player_comes_close() -> void:
	var sim: CombatSim = _sim()
	var back: Fighter = sim.add_creature(Vector2(200, 180), CreatureKind.lichen_back())
	assert_true(back.disguised, "a gravestone")
	assert_false(CreatureBrain.can_be_aimed_at(back), "nothing to lock on to")
	_run(sim, 30)
	assert_true(back.disguised, "still, while the player keeps away")
	sim.player.position = Vector2(200 - back.radius - sim.player.radius - CreatureBrain.STOOK_TRIGGER + 2.0, 180)
	var seen: Array[Dictionary] = _run(sim, 2)
	assert_false(back.disguised, "close: it heaves up")
	assert_true(seen.any(func(e: Dictionary) -> bool: return e["type"] == "reveal"), "reported")


# --- The encounter plan ------------------------------------------------------------

func test_by_day_the_plan_s_creatures_are_out() -> void:
	var area: Area = Kettlebridge.make()
	assert_false(area.is_night(), "it starts in the morning")
	assert_eq(_count(area), {&"market_rat": 16, &"jackdaw": 2, &"lichen_back": 4, &"river_pike": 2}, "the day roster")


func test_at_night_the_night_roster_comes_out() -> void:
	var area: Area = Kettlebridge.make()
	area.skip_to_next_change()  # 20:00
	area.step(CombatInput.new())
	area.sync(true)
	assert_eq(_count(area), {&"market_rat": 8, &"lichen_back": 6, &"river_pike": 3, &"moth": 5}, "the night roster")


func test_the_road_in_is_safe_ground() -> void:
	var area: Area = Kettlebridge.make()
	for entry: Dictionary in area.roster:
		var distance: float = (entry["at"] as Vector2).distance_to(Kettlebridge.ENTRANCE)
		assert_true(distance > 6.0 * AreaMap.CELL, "%s is %.0f px from the entrance" % [entry["kind"], distance])


func test_every_creature_can_be_reached_and_every_pike_is_at_the_towpath_s_edge() -> void:
	var area: Area = Kettlebridge.make()
	var reach: Dictionary = _bfs(area.map, AreaMap.cell_of(Kettlebridge.ENTRANCE))
	for entry: Dictionary in area.roster:
		var cell: Vector2i = AreaMap.cell_of(entry["at"])
		if entry["kind"] == &"river_pike":
			assert_eq(area.map.char_at(cell), "~", "a pike in the river at %s" % cell)
			assert_true(reach.has(cell + Vector2i.UP), "with the towpath above it at %s" % cell)
		else:
			assert_true(reach.has(cell), "%s at %s can be reached" % [entry["kind"], cell])
