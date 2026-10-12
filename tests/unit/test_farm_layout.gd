extends TestCase
## The farm as accepted (docs/design/base.md): the maps match the design
## doc's, the tile map is put together as the doc says, the homestead can be
## walked, and only the first field can be tilled.


func _walkable_from(map: FarmMap, start: Vector2i) -> Dictionary:
	var seen: Dictionary = {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for step: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var next: Vector2i = cell + step
			if map.contains(next) and not seen.has(next) and not map.is_solid(next):
				seen[next] = true
				queue.append(next)
	return seen


func test_the_maps_are_the_accepted_layout() -> void:
	var estate: String = FileAccess.get_file_as_string("res://docs/design/images/estate.txt").strip_edges()
	assert_eq("\n".join(FarmLayout.ESTATE), estate, "the code's farm matches the design doc's")
	var base: String = FileAccess.get_file_as_string("res://docs/design/images/base.txt").strip_edges()
	assert_eq("\n".join(FarmLayout.HOMESTEAD), base, "the code's homestead matches the design doc's")


func test_the_farm_is_160_by_96_with_the_homestead_at_the_bottom_centre() -> void:
	var map: FarmMap = FarmMap.make_farm()
	assert_eq(map.size, Vector2i(160, 96), "160 x 96 tiles")
	for row: String in map.rows:
		assert_eq(row.length(), 160, "every row is whole")
	assert_eq(map.char_at(FarmLayout.HOMESTEAD_ORIGIN), "#", "the homestead's corner hedge")
	assert_eq(map.bounds_of("H").merge(map.bounds_of("D")).size, Vector2i(10, 6), "the farmhouse is 10 x 6 tiles")
	assert_eq(map.bounds_of("T").size, Vector2i(8, 6), "the first field is 8 x 6 tiles")
	assert_eq(map.cells_of("T").size(), 48, "48 tiles")
	# The south gate in the hedge, then the lane through the woods to the edge.
	for x: int in range(78, 82):
		assert_eq(map.char_at(Vector2i(x, 90)), "G", "the south gate at %d" % x)
		assert_eq(map.char_at(Vector2i(x, 95)), "=", "the lane at the farm's edge at %d" % x)
	assert_eq(map.char_at(Vector2i(77, 95)), "t", "woods beside the lane")
	# Thicket all round the homestead, woods round the farm.
	assert_eq(map.char_at(Vector2i(70, 60)), "1", "the great fields above the north gate")
	assert_eq(map.char_at(Vector2i(50, 80)), "3", "the old orchard to the west")
	assert_eq(map.char_at(Vector2i(110, 80)), "2", "the east pasture to the east")
	assert_eq(map.char_at(Vector2i(0, 0)), "t", "woods at the corner")
	assert_true(map.is_solid(Vector2i(-1, 50)), "outside the farm is woods")


func test_the_homestead_can_be_walked_and_nothing_beyond_its_hedge() -> void:
	var sim: FarmSim = FarmSim.make_farm()
	var map: FarmMap = sim.map
	var reached: Dictionary = _walkable_from(map, sim.cell_at(sim.wake_position))
	var homestead: Rect2i = Rect2i(FarmLayout.HOMESTEAD_ORIGIN, Vector2i(48, 30))
	for cell: Vector2i in reached:
		assert_true(homestead.has_point(cell) or FarmLayout.LANE.has_point(cell),
			"%s is inside the homestead or the lane" % cell)
	for cell: Vector2i in map.cells_of("T"):
		assert_true(reached.has(cell), "the first field's tile %s can be reached" % cell)
	for c: String in [":", "f", "P", ","]:
		for cell: Vector2i in map.cells_of(c):
			assert_true(reached.has(cell), "%s at %s can be reached" % [c, cell])
	for cell: Vector2i in map.cells_of("G"):
		assert_true(reached.has(cell), "the gate tile %s can be reached" % cell)
	assert_true(reached.has(Vector2i(80, 95)), "the lane down to Millbrook")
	# Every thing to use stands next to ground the player can reach.
	for c: String in ["D", "s", "m", "n", "A", "b"]:
		var touching: bool = false
		for cell: Vector2i in map.cells_of(c):
			for step: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				touching = touching or reached.has(cell + step)
		assert_true(touching, "%s can be walked up to" % c)


func test_the_player_cannot_walk_through_hedges_thicket_or_the_house() -> void:
	var sim: FarmSim = FarmSim.make_farm()
	# Out of the north gate: thicket stops the player at the hedge line.
	var gate: Vector2i = sim.map.cells_of("G")[0]  # the north gate: the first row with a gate
	sim.place_player(sim.cell_centre(gate + Vector2i(1, 1)), Vector2.UP)
	for i: int in range(120):
		sim.step(FarmInput.with_move(Vector2.UP))
	assert_true(sim.player_position.y > gate.y * FarmSim.TILE, "not into the great fields' thicket")
	# Into the house from below the door.
	sim.place_player(sim.wake_position, Vector2.UP)
	for i: int in range(60):
		sim.step(FarmInput.with_move(Vector2.UP))
	assert_true(sim.cell_at(sim.player_position).y >= sim.map.bounds_of("D").end.y, "not through the door")


func test_only_the_first_field_can_be_tilled() -> void:
	var sim: FarmSim = FarmSim.make_farm()
	var field: Vector2i = sim.map.cells_of("T")[0]
	var old_field: Vector2i = sim.map.cells_of(":")[0]
	var grass: Vector2i = sim.map.cells_of(".")[0]
	assert_true(sim.plot.till(field), "the first field")
	assert_false(sim.plot.till(old_field), "not the old fields: they need the Clear spell first")
	assert_false(sim.plot.till(grass), "not the lawn")


func test_the_farmhouse_door_is_the_bed_for_now() -> void:
	var sim: FarmSim = FarmSim.make_farm()
	sim.clock.total_minutes += 600.0
	sim.mana.try_spend(50.0)
	sim.place_player(sim.wake_position + Vector2(0, 20), Vector2.UP)
	for i: int in range(30):
		sim.step(FarmInput.with_move(Vector2.UP))
	sim.step(FarmInput.press(&"interact"))
	assert_eq(sim.clock.day(), 2, "slept to the next morning")
	assert_eq(sim.mana.current, sim.mana.maximum, "Mana full")
	assert_eq(sim.player_position, sim.wake_position, "up in front of the door")
	assert_eq(sim.facing, Vector2.DOWN, "facing out")


func test_walking_down_the_lane_leaves_for_millbrook_once() -> void:
	var sim: FarmSim = FarmSim.make_farm()
	sim.place_player(sim.gate_position, Vector2.DOWN)
	var exits: Array[Dictionary] = []
	for i: int in range(90):
		sim.step(FarmInput.with_move(Vector2.DOWN))
		for e: Dictionary in sim.events:
			if e["type"] == "exit":
				exits.append(e)
	assert_eq(exits.size(), 1, "one exit, though the player stays in it")
	assert_eq(exits[0]["to"], &"millbrook", "to Millbrook")


func test_arriving_at_the_gate_does_not_leave_again() -> void:
	var sim: FarmSim = FarmSim.make_farm()
	sim.place_player(sim.gate_position, Vector2.UP)
	sim.step(FarmInput.new())
	assert_eq(sim.events.filter(func(e: Dictionary) -> bool: return e["type"] == "exit").size(), 0, "no exit")
	assert_true(sim.gate_position.y < sim.exits[0]["rect"].position.y, "the gate is above the exit")
