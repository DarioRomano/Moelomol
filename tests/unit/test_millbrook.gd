extends TestCase
## Millbrook (docs/design/area-millbrook.md) as built: its map, collision,
## what can be reached, its roster by day and night, and falling.

const T: GDScript = preload("res://src/combat/combat_tuning.gd")


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


func _kinds(area: Area) -> Dictionary:
	var counts: Dictionary = {}
	for c: Fighter in area.sim.creatures:
		counts[c.creature_kind.id] = int(counts.get(c.creature_kind.id, 0)) + 1
	return counts


# --- The map ---------------------------------------------------------------------------

func test_the_map_is_the_accepted_layout() -> void:
	var doc: String = FileAccess.get_file_as_string("res://docs/design/images/millbrook.txt").strip_edges()
	assert_eq("\n".join(MillbrookMap.ROWS), doc, "the code's map matches the design doc's")
	var map: AreaMap = AreaMap.new(MillbrookMap.ROWS)
	assert_eq(map.size, Vector2i(56, 32), "56 x 32 cells (112 x 64 tiles)")
	assert_eq(map.rect().size, Vector2(1792, 1024), "1792 x 1024 layout px")


func test_woods_houses_water_and_fences_block_and_paths_do_not() -> void:
	var map: AreaMap = AreaMap.new(MillbrookMap.ROWS)
	for c: String in ["t", "H", "~", "#", "M", "a", "h", "K", "S"]:
		assert_true(map.is_solid(map.cells_of(c)[0]), c + " blocks")
	for c: String in [".", "=", ",", "g", "y", "u", "b", "*", "v"]:
		assert_false(map.is_solid(map.cells_of(c)[0]), c + " is open ground")
	var flood: Vector2i = map.cells_of("w")[0]
	assert_true(map.is_solid(flood), "floodwater blocks")
	map.drained = true
	assert_false(map.is_solid(flood), "until it drains")
	assert_eq(map.markers["1"], Millbrook.ENTRANCE_CELL, "place 1 is the entrance")


func test_a_fighter_cannot_walk_into_a_cottage() -> void:
	var area: Area = Millbrook.make()
	var cottage: Rect2 = AreaMap.cell_rect(area.map.cells_of("H")[0])
	var at: Vector2 = area.sim.resolve_position(cottage.get_center(), 6.0)
	assert_false(cottage.grow(5.9).has_point(at), "pushed out of the cottage (%s)" % at)


func test_every_named_place_and_every_creature_can_be_reached_from_the_lane() -> void:
	var area: Area = Millbrook.make()
	var reach: Dictionary = _bfs(area.map, Millbrook.ENTRANCE_CELL)
	for marker: String in ["2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "G"]:
		var cell: Vector2i = area.map.markers[marker]
		assert_true(reach.has(cell), "place %s at %s" % [marker, cell])
	for entry: Dictionary in area.roster:
		var cell: Vector2i = AreaMap.cell_of(entry["at"])
		assert_true(reach.has(cell), "%s at %s" % [entry["kind"], cell])
	assert_false(reach.has(area.map.markers["F"]), "the ford is cut off by the flood")
	area.map.drained = true
	assert_true(_bfs(area.map, Millbrook.ENTRANCE_CELL).has(area.map.markers["F"]), "until it drains")


# --- The roster ---------------------------------------------------------------------------

func test_by_day_about_thirty_creatures_as_the_plan_says() -> void:
	var area: Area = Millbrook.make()
	assert_false(area.is_night(), "it starts in the morning")
	var kinds: Dictionary = _kinds(area)
	assert_eq(kinds, {&"hedgehog": 1, &"field_mouse": 19, &"rook": 3, &"stook": 3, &"flood_toad": 4, &"grist": 1},
		"the day roster")
	assert_true(area.sim.creatures.size() >= 28 and area.sim.creatures.size() <= 32, "about 30")


func test_the_lane_is_safe_ground() -> void:
	var area: Area = Millbrook.make()
	for entry: Dictionary in area.roster:
		var distance: float = (entry["at"] as Vector2).distance_to(area.entrance)
		assert_true(distance > 20.0 * 16.0, "%s is %.0f px from the entrance" % [entry["kind"], distance])


func test_at_night_the_night_roster_comes_out() -> void:
	var area: Area = Millbrook.make()
	area.skip_to_next_change()  # 20:00
	area.step(CombatInput.new())
	assert_true(area.is_night(), "night")
	assert_true(area.sim.night, "the simulation knows")
	area.sync(true)  # as if the player had been away (out of sight, they swap)
	var kinds: Dictionary = _kinds(area)
	assert_eq(kinds.get(&"field_mouse", 0), 0, "the mice are gone")
	assert_eq(kinds.get(&"rook", 0), 0, "the rooks are gone")
	assert_eq(kinds.get(&"moth", 0), 8, "moths are out")
	assert_eq(kinds.get(&"flood_toad", 0), 7, "more toads")
	assert_eq(kinds.get(&"hedgehog", 0), 3, "more hedgehogs")
	assert_eq(area.sim.lights.size(), area.lights.size() + area.night_lights.size(), "the fireflies are lit")


func test_nothing_appears_or_vanishes_in_view() -> void:
	var area: Area = Millbrook.make()
	var mouse: Fighter = null
	for c: Fighter in area.sim.creatures:
		if c.creature_kind.id == &"field_mouse":
			mouse = c
			break
	area.sim.player.position = mouse.position + Vector2(40, 0)
	area.skip_to_next_change()
	for i: int in range(Area.SYNC_TICKS + 1):
		area.step(CombatInput.new())
	assert_true(mouse in area.sim.creatures, "a mouse in view stays until the player looks away")


func test_defeated_creatures_come_back_at_dawn_and_grist_never_does() -> void:
	var area: Area = Millbrook.make()
	var grist: Fighter = null
	var rook: Fighter = null
	for c: Fighter in area.sim.creatures:
		if c.creature_kind.id == &"grist":
			grist = c
		elif c.creature_kind.id == &"rook" and rook == null:
			rook = c
	area.sim.defeat(grist)
	area.sim.defeat(rook)
	for i: int in range(T.ticks(T.CREATURE_DOWN_MS) + Area.SYNC_TICKS + 1):
		area.step(CombatInput.new())
	assert_eq(rook.state, Fighter.State.GONE, "the rook is gone")
	assert_eq(_kinds(area).get(&"rook", 0), 3, "and stays counted until dawn (gone, not replaced)")
	assert_true(&"grist" in area.bosses_defeated, "Grist is recorded as defeated")
	area.sim.player.position = Vector2(1700, 980)  # far from the orchard, out of its sight
	area.clock.total_minutes = (area.clock.day() + 1) * GameClock.MINUTES_PER_DAY + GameClock.DAY_START_MINUTE - 0.01
	for i: int in range(Area.SYNC_TICKS + 2):
		area.step(CombatInput.new())
	var rooks: Array[Fighter] = area.sim.creatures.filter(func(c: Fighter) -> bool:
		return c.creature_kind.id == &"rook" and c.is_alive())
	assert_eq(rooks.size(), 3, "all three rooks back after 6:00")
	assert_eq(_kinds(area).get(&"grist", 0), 0, "Grist does not come back")


func test_falling_means_waking_the_next_morning_at_the_entrance() -> void:
	var area: Area = Millbrook.make()
	area.sim.player.position = Vector2(900, 400)
	var day: int = area.clock.day()
	area.sim.defeat(area.sim.player)
	var woke: bool = false
	for i: int in range(T.ticks(T.PLAYER_DOWN_MS) + 2):
		area.step(CombatInput.new())
		for e: Dictionary in area.events:
			woke = woke or e["type"] == "woke"
	assert_true(woke, "the player woke")
	assert_eq(area.clock.day(), day + 1, "the next day")
	assert_true(absf(area.clock.minute() - GameClock.DAY_START_MINUTE) < 1.0, "at 6:00")
	assert_eq(area.sim.player.position, area.entrance, "at the entrance (the farm is not built yet)")
	assert_eq(area.sim.player.health, area.sim.player.max_health, "rested")
