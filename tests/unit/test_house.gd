extends TestCase
## The farmhouse inside (base.md; layout accepted 2026-11-06): the room can
## be walked, the bed sleeps, the seed tin gives the first seeds once, the
## door joins the farm both ways, and old saves come in by the bed.

const HOUSE_SCENE: PackedScene = preload("res://scenes/farm/house.tscn")
const PATH: String = "user://test_house_save.json"
## Standing on the floor in front of the cupboard, facing it.
const BY_THE_TIN: Vector2 = Vector2(2.5, 7.5) * 16.0


func test_the_room_is_the_accepted_layout() -> void:
	var doc: String = FileAccess.get_file_as_string("res://docs/design/base.md")
	for row: String in HouseLayout.ROWS:
		assert_true(doc.contains(row), "base.md shows the row %s" % row)
	var map: FarmMap = FarmMap.new(HouseLayout.ROWS, HouseLayout.SOLID)
	assert_eq(map.size, Vector2i(14, 10), "12 x 8 tiles inside its walls")
	for c: String in ["B", "S", "O", "k", "T", "c", "u", "D", "w", "h"]:
		assert_true(map.cells_of(c).size() > 0, "it has its %s" % c)
	assert_eq(map.cells_of("B").size(), 6, "one bed (2 x 3)")
	assert_eq(map.cells_of("h").size(), 1, "one cup on the hook")
	assert_eq(map.cells_of("c").size(), 2, "two chairs")


func test_the_room_can_be_walked_to_everything() -> void:
	var sim: HouseSim = HouseSim.new()
	var map: FarmMap = sim.map
	var start: Vector2i = sim.cell_at(sim.bed_position)
	var seen: Dictionary = {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for step: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var next: Vector2i = cell + step
			if map.contains(next) and not seen.has(next) and not map.is_solid(next):
				seen[next] = true
				queue.append(next)
	for c: String in [".", "_", "D"]:
		for cell: Vector2i in map.cells_of(c):
			assert_true(seen.has(cell), "%s at %s can be reached from the bed" % [c, cell])
	for c: String in ["B", "u", "S", "O", "k", "T"]:
		var touching: bool = false
		for cell: Vector2i in map.cells_of(c):
			for step: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				touching = touching or seen.has(cell + step)
		assert_true(touching, "%s can be walked up to" % c)


func test_the_bed_sleeps_to_the_next_morning() -> void:
	var sim: HouseSim = HouseSim.new()
	sim.clock.total_minutes += 14 * 60
	sim.mana.try_spend(70.0)
	sim.place_player(sim.bed_position + Vector2(10, 0), Vector2.LEFT)
	for i: int in range(20):
		sim.step(FarmInput.with_move(Vector2.LEFT))
	assert_eq(sim.target_kind(), &"bed", "facing the bed")
	sim.step(FarmInput.press(&"interact"))
	assert_eq(sim.clock.day(), 2, "the next day")
	assert_true(absf(sim.clock.minute() - GameClock.DAY_START_MINUTE) < 1.0, "at 6:00")
	assert_eq(sim.mana.current, sim.mana.maximum, "Mana full")
	assert_eq(sim.player_position, sim.bed_position, "up beside the bed")


func test_the_seed_tin_gives_the_first_seeds_once() -> void:
	var state: GameState = GameState.new_game()
	assert_eq(state.inventory.items().size(), 0, "a new game's bag is empty")
	var sim: HouseSim = state.make_house()
	sim.place_player(BY_THE_TIN, Vector2.LEFT)
	assert_eq(sim.target_kind(), &"seed_tin", "facing the seed tin")
	sim.step(FarmInput.press(&"interact"))
	assert_eq(sim.events[0]["type"], "seed_tin", "taken")
	assert_eq(state.inventory.count(&"catmint_seeds"), 6, "catmint, the treats' crop (Q25)")
	assert_eq(state.inventory.count(&"radish_seeds"), 6, "and radish")
	sim.step(FarmInput.press(&"interact"))
	assert_eq(sim.events[0]["type"], "seed_tin_empty", "the second time, empty")
	assert_eq(state.inventory.count(&"catmint_seeds"), 6, "no more seeds")
	state.store_house(sim)
	var again: HouseSim = state.make_house()
	assert_true(again.tin_taken, "the house remembers")


func test_through_the_farmhouse_door_and_back() -> void:
	var state: GameState = GameState.new_game()
	state.travel(GameState.FARM, GameState.AT_GATE)
	var farm: FarmSim = state.make_farm()
	farm.place_player(farm.wake_position, Vector2.UP)
	farm.step(FarmInput.press(&"interact"))
	assert_eq(farm.events[0], {"type": "exit", "to": &"house"}, "in through the door")
	state.store_farm(farm)
	state.travel(GameState.HOUSE, GameState.AT_DOOR)
	var house: HouseSim = state.make_house()
	assert_eq(house.player_position, house.door_position, "just inside, on the rug")
	assert_eq(house.facing, Vector2.UP, "facing into the room")
	assert_eq(house.map.char_at(house.cell_at(house.door_position)), "_", "the rug")
	var went: Array[StringName] = []
	for i: int in range(40):
		house.step(FarmInput.with_move(Vector2.DOWN))
		for e: Dictionary in house.events:
			if e["type"] == "exit":
				went.append(e["to"])
		if not went.is_empty():
			break
	assert_eq(went, [&"farm"] as Array[StringName], "out through the door")
	state.store_house(house)
	state.travel(GameState.FARM, GameState.AT_DOOR)
	var back: FarmSim = state.make_farm()
	assert_eq(back.player_position, back.wake_position, "on the farm in front of the door")
	assert_eq(back.facing, Vector2.DOWN, "facing away from it")


func test_the_house_scene_saves_on_sleeping_and_loads_no_combat() -> void:
	for path: String in [PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var state: GameState = GameState.new_game()
	state.save_path = PATH
	GameState.current = state
	var house: Node2D = HOUSE_SCENE.instantiate()
	house.set("travels", false)
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	tree.root.add_child(house)
	for node: Node in house.find_children("*", "", true, false):
		var script: Script = node.get_script()
		assert_true(script == null or not script.resource_path.contains("/combat/"), "%s is not combat" % node.name)
	assert_false((house.get_script() as GDScript).source_code.contains("Combat"), "no combat in the house")
	var sim: HouseSim = house.get("sim")
	sim.place_player(BY_THE_TIN, Vector2.LEFT)
	sim.interact()
	house.call("_handle", sim.events[0])
	var key: InputEventKey = InputEventKey.new()
	key.keycode = KEY_F8
	key.pressed = true
	house.call("_unhandled_input", key)
	var saved: GameState = GameState.load_from(PATH)
	assert_eq([saved.place, saved.arrival], [GameState.HOUSE, GameState.AT_BED], "saved beside the bed")
	assert_eq(saved.house_state.get("tin_taken"), true, "with the tin taken")
	assert_eq(saved.inventory.count(&"radish_seeds"), 6, "and its seeds in the bag")
	house.queue_free()
	await tree.process_frame
	GameState.current = null
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


func test_saves_from_before_the_house_come_in_by_the_bed() -> void:
	# Format 1 saves made before 2026-11-06 slept at the farmhouse door and
	# had the seeds in the bag already.
	var old: Dictionary = GameState.new_game().to_dict()
	old.erase("house")
	old["place"] = "farm"
	old["arrival"] = "bed"
	old["items"] = {"radish_seeds": 6, "catmint_seeds": 6}
	var state: GameState = GameState.from_dict(JSON.parse_string(JSON.stringify(old)))
	assert_eq([state.place, state.arrival], [GameState.HOUSE, GameState.AT_BED], "waking in the farmhouse now")
	assert_eq(state.house_state, {"tin_taken": true}, "the tin already emptied: no seeds twice")
	old["place"] = "millbrook"
	old["arrival"] = "gate"
	var travelling: GameState = GameState.from_dict(JSON.parse_string(JSON.stringify(old)))
	assert_eq([travelling.place, travelling.arrival], [GameState.MILLBROOK, GameState.AT_GATE], "a trip stays a trip")
	assert_true(travelling.house_state["tin_taken"], "the tin emptied")
	assert_eq(GameState.new_game().summary(), "Day 1, 06:00, in the farmhouse", "the title says where")
