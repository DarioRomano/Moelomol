extends TestCase
## Farming rules (docs/design/farming.md; Q23-Q25, working assumption A): the
## plot on its own, then the whole test farm driven tick by tick.


func _plot() -> FarmPlot:
	var plot: FarmPlot = FarmPlot.new(Vector2i(8, 6))
	plot.block(Rect2i(0, 0, 2, 2))
	return plot


## A tilled, planted tile at (3, 3).
func _planted(crop: StringName = &"radish") -> FarmPlot:
	var plot: FarmPlot = _plot()
	plot.till(Vector2i(3, 3))
	plot.plant(Vector2i(3, 3), crop)
	return plot


# --- Soil ------------------------------------------------------------------------

func test_the_hoe_tills_grass_but_not_blocked_ground() -> void:
	var plot: FarmPlot = _plot()
	assert_true(plot.till(Vector2i(3, 3)), "grass tills")
	assert_true(plot.is_tilled(Vector2i(3, 3)), "tilled")
	assert_false(plot.till(Vector2i(3, 3)), "already tilled")
	assert_false(plot.till(Vector2i(1, 1)), "not the house or path")
	assert_false(plot.till(Vector2i(20, 3)), "not outside the plot")


func test_only_tilled_soil_takes_water() -> void:
	var plot: FarmPlot = _plot()
	assert_false(plot.water(Vector2i(3, 3)), "grass does not")
	plot.till(Vector2i(3, 3))
	assert_true(plot.water(Vector2i(3, 3)), "tilled soil does")
	assert_true(plot.is_watered(Vector2i(3, 3)), "watered")


func test_seeds_go_on_tilled_soil_with_nothing_on_it() -> void:
	var plot: FarmPlot = _plot()
	assert_false(plot.plant(Vector2i(3, 3), &"radish"), "not on grass")
	plot.till(Vector2i(3, 3))
	assert_true(plot.plant(Vector2i(3, 3), &"radish"), "on tilled soil")
	assert_false(plot.plant(Vector2i(3, 3), &"catmint"), "not on top of another crop")
	assert_false(plot.plant(Vector2i(4, 4), &"no_such_crop"), "only real crops")


# --- Growth (Q23, Q24) ---------------------------------------------------------------

func test_a_watered_crop_grows_one_day_each_new_day() -> void:
	var plot: FarmPlot = _planted()
	plot.water(Vector2i(3, 3))
	assert_eq(plot.new_day(), 1, "one crop grew")
	assert_eq(plot.grown_days(Vector2i(3, 3)), 1, "a day of growth")


func test_an_unwatered_crop_does_not_grow_and_does_not_wither() -> void:
	var plot: FarmPlot = _planted()
	for i: int in range(10):
		plot.new_day()
	assert_eq(plot.grown_days(Vector2i(3, 3)), 0, "no growth without water")
	assert_eq(plot.crop_at(Vector2i(3, 3)), &"radish", "still there after ten dry days")


func test_soil_dries_overnight() -> void:
	var plot: FarmPlot = _planted()
	plot.water(Vector2i(3, 3))
	plot.new_day()
	assert_false(plot.is_watered(Vector2i(3, 3)), "dry in the morning")
	plot.new_day()
	assert_eq(plot.grown_days(Vector2i(3, 3)), 1, "so the next day needs watering again")


func test_a_crop_ripens_after_its_days_and_waits() -> void:
	var plot: FarmPlot = _planted(&"radish")
	var days: int = CropKind.of(&"radish").days_to_ripen
	for i: int in range(days):
		assert_false(plot.is_ripe(Vector2i(3, 3)), "not ripe after %d days" % i)
		plot.water(Vector2i(3, 3))
		plot.new_day()
	assert_true(plot.is_ripe(Vector2i(3, 3)), "ripe after %d watered days" % days)
	for i: int in range(5):
		plot.water(Vector2i(3, 3))
		plot.new_day()
	assert_true(plot.is_ripe(Vector2i(3, 3)), "and still ripe days later")
	assert_eq(plot.grown_days(Vector2i(3, 3)), days, "it stops growing when ripe")


func test_stages_run_from_seed_to_ripe() -> void:
	for crop: CropKind in CropKind.all().values():
		var stages: Array[int] = []
		for grown: int in range(crop.days_to_ripen + 1):
			stages.append(crop.stage_for(grown))
		assert_eq(stages[0], 0, "%s starts as a seed" % crop.display_name)
		assert_eq(stages[stages.size() - 1], CropKind.STAGES - 1, "%s ends ripe" % crop.display_name)
		for i: int in range(1, stages.size()):
			assert_true(stages[i] >= stages[i - 1], "%s never goes back a stage" % crop.display_name)
		assert_eq(stages.count(CropKind.STAGES - 1), 1, "%s looks ripe only when it is" % crop.display_name)


func test_harvest_gives_produce_and_seeds_and_leaves_tilled_soil() -> void:
	var plot: FarmPlot = _planted(&"catmint")
	assert_true(plot.harvest(Vector2i(3, 3)).is_empty(), "nothing before it is ripe")
	for i: int in range(CropKind.of(&"catmint").days_to_ripen):
		plot.water(Vector2i(3, 3))
		plot.new_day()
	var items: Dictionary = plot.harvest(Vector2i(3, 3))
	assert_eq(items, {&"catmint": 1, &"catmint_seeds": 2}, "a catmint and two seeds")
	assert_eq(plot.crop_at(Vector2i(3, 3)), &"", "the tile is empty")
	assert_true(plot.is_tilled(Vector2i(3, 3)), "and still tilled, ready to replant")


func test_catmint_the_treats_crop_exists_from_the_start() -> void:
	var sim: FarmSim = FarmSim.make_test_farm()
	assert_true(CropKind.of(&"catmint") != null, "catmint is a crop")
	assert_true(sim.inventory.count(&"catmint_seeds") > 0, "and the seed tin holds its seeds")


# --- The test farm, tick by tick --------------------------------------------------

func _farm() -> FarmSim:
	return FarmSim.make_test_farm()


func _run(sim: FarmSim, ticks: int, input: FarmInput = FarmInput.new()) -> Array[Dictionary]:
	var seen: Array[Dictionary] = []
	for i: int in range(ticks):
		sim.step(input)
		seen.append_array(sim.events)
	return seen


## Walks the player to stand on a cell's centre, facing `toward`.
func _stand(sim: FarmSim, cell: Vector2i, toward: Vector2) -> void:
	sim.player_position = sim.cell_centre(cell)
	sim.facing = toward


func _press(sim: FarmSim, action: StringName) -> Array[Dictionary]:
	sim.step(FarmInput.press(action))
	var seen: Array[Dictionary] = sim.events.duplicate()
	seen.append_array(_run(sim, FarmSim.tool_use_ticks()))
	return seen


func _select(sim: FarmSim, tool: StringName) -> void:
	sim.tool_index = sim.tools.find(tool)


func _types(events: Array[Dictionary]) -> Array[String]:
	var types: Array[String] = []
	for e: Dictionary in events:
		types.append(e["type"])
	return types


func test_the_player_acts_on_the_tile_in_front() -> void:
	var sim: FarmSim = _farm()
	_stand(sim, Vector2i(10, 10), Vector2.RIGHT)
	assert_eq(sim.target_cell(), Vector2i(11, 10), "right")
	sim.facing = Vector2.UP
	assert_eq(sim.target_cell(), Vector2i(10, 9), "up")
	sim.facing = Vector2(1, 1).normalized()
	assert_eq(sim.target_cell(), Vector2i(11, 11), "diagonal")


func test_till_water_plant_with_the_tools() -> void:
	var sim: FarmSim = _farm()
	_stand(sim, Vector2i(10, 10), Vector2.RIGHT)
	var target: Vector2i = Vector2i(11, 10)
	_select(sim, FarmSim.HOE)
	assert_true("till" in _types(_press(sim, &"use")), "the hoe tills")
	_select(sim, FarmSim.WATERING_CAN)
	assert_true("water" in _types(_press(sim, &"use")), "the can waters")
	_select(sim, &"radish_seeds")
	var before: int = sim.inventory.count(&"radish_seeds")
	assert_true("plant" in _types(_press(sim, &"use")), "seeds plant")
	assert_eq(sim.plot.crop_at(target), &"radish", "a radish")
	assert_eq(sim.inventory.count(&"radish_seeds"), before - 1, "one seed used")


func test_the_player_stands_still_while_using_a_tool() -> void:
	var sim: FarmSim = _farm()
	_stand(sim, Vector2i(10, 10), Vector2.RIGHT)
	sim.step(FarmInput.press(&"use"))
	var at: Vector2 = sim.player_position
	_run(sim, FarmSim.tool_use_ticks() - 1, FarmInput.with_move(Vector2.DOWN))
	assert_eq(sim.player_position, at, "no walking mid-swing")
	_run(sim, 5, FarmInput.with_move(Vector2.DOWN))
	assert_true(sim.player_position.y > at.y, "then free to walk")


func test_no_seeds_left_plants_nothing() -> void:
	var sim: FarmSim = _farm()
	_stand(sim, Vector2i(10, 10), Vector2.RIGHT)
	sim.plot.till(Vector2i(11, 10))
	_select(sim, &"radish_seeds")
	sim.inventory.take(&"radish_seeds", sim.inventory.count(&"radish_seeds"))
	assert_true("no_seeds" in _types(_press(sim, &"use")), "reported")
	assert_eq(sim.plot.crop_at(Vector2i(11, 10)), &"", "nothing planted")


func test_tool_switching_wraps_both_ways() -> void:
	var sim: FarmSim = _farm()
	assert_eq(sim.tool(), FarmSim.HOE, "the hoe first")
	sim.step(FarmInput.press(&"tool_prev"))
	assert_eq(sim.tool_index, sim.tools.size() - 1, "back to the last")
	sim.step(FarmInput.press(&"tool_next"))
	assert_eq(sim.tool(), FarmSim.HOE, "forward to the first")


func test_interacting_with_a_ripe_crop_harvests_it_into_the_inventory() -> void:
	var sim: FarmSim = _farm()
	_stand(sim, Vector2i(10, 10), Vector2.RIGHT)
	var target: Vector2i = Vector2i(11, 10)
	sim.plot.till(target)
	sim.plot.plant(target, &"radish")
	for i: int in range(CropKind.of(&"radish").days_to_ripen):
		sim.plot.water(target)
		sim.plot.new_day()
	var seeds: int = sim.inventory.count(&"radish_seeds")
	assert_true("harvest" in _types(_press(sim, &"interact")), "harvested")
	assert_eq(sim.inventory.count(&"radish"), 1, "a radish in the bag")
	assert_eq(sim.inventory.count(&"radish_seeds"), seeds + 2, "and two seeds")


func test_sleeping_at_the_door_starts_the_next_day_and_grows_the_farm() -> void:
	var sim: FarmSim = _farm()
	var cell: Vector2i = Vector2i(10, 10)
	sim.plot.till(cell)
	sim.plot.plant(cell, &"catmint")
	sim.plot.water(cell)
	_stand(sim, Vector2i(4, 5), Vector2.UP)
	assert_eq(sim.target_cell(), sim.door_cell, "facing the door")
	var seen: Array[Dictionary] = _press(sim, &"interact")
	assert_true("slept" in _types(seen) and "new_day" in _types(seen), "slept into a new day")
	assert_eq(sim.clock.day, 2, "day 2")
	assert_eq(sim.clock.time_text(), "06:00", "at 6:00")
	assert_eq(sim.plot.grown_days(cell), 1, "the watered catmint grew overnight")


func test_at_two_the_player_falls_asleep_and_wakes_at_home() -> void:
	var sim: FarmSim = _farm()
	_stand(sim, Vector2i(30, 15), Vector2.RIGHT)
	sim.clock.minute = GameClock.DAY_END_MINUTE - 0.01
	var seen: Array[Dictionary] = _run(sim, 2)
	assert_true("passed_out" in _types(seen), "fell asleep")
	assert_eq(sim.clock.day, 2, "a new day")
	assert_eq(sim.player_position, sim.wake_position, "at home")
	assert_eq(sim.inventory.count(&"catmint_seeds"), FarmSim.STARTING_SEEDS[&"catmint_seeds"], "nothing lost")


func test_time_passes_at_the_clock_s_pace() -> void:
	var sim: FarmSim = _farm()
	_run(sim, 60 * 45)  # 45 real seconds
	assert_eq(sim.clock.time_text(), "07:00", "an hour of game time")


func test_the_house_is_solid_and_the_field_has_edges() -> void:
	var sim: FarmSim = _farm()
	_stand(sim, Vector2i(4, 6), Vector2.UP)
	_run(sim, 120, FarmInput.with_move(Vector2.UP))
	var house_bottom: float = sim.solids[0].end.y
	assert_true(sim.player_position.y >= house_bottom + FarmSim.PLAYER_RADIUS - 0.01, "stopped by the house")
	_stand(sim, Vector2i(36, 18), Vector2.RIGHT)
	_run(sim, 120, FarmInput.with_move(Vector2(1, 1)))
	assert_true(sim.bounds().grow(-FarmSim.PLAYER_RADIUS + 0.01).has_point(sim.player_position), "inside the field")


func test_the_path_and_house_cannot_be_tilled() -> void:
	var sim: FarmSim = _farm()
	assert_false(sim.plot.till(Vector2i(4, 6)), "the path")
	assert_false(sim.plot.till(sim.door_cell), "the house")
	assert_true(sim.plot.till(Vector2i(8, 6)), "the grass beside the path")


func test_the_test_farm_fits_the_view() -> void:
	var sim: FarmSim = _farm()
	assert_true(Rect2(0, 0, 640, 360).encloses(sim.bounds()), "inside 640x360")
