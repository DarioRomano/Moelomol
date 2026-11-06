extends TestCase
## The great fields (Q42 A, accepted 2026-11-06): Clear on their thicket
## with Grist's heart withers it back over about 3 s; inside are old fields
## in strips between hedgerows, the track from the north gate, and the ruined
## field shelter. Remembered in the save.

const FARM_SCENE: PackedScene = preload("res://scenes/farm/farm.tscn")


## The player on the north gate, facing the great fields' thicket, Clear
## selected.
func _at_the_north_gate(sim: FarmSim) -> void:
	var gate: Vector2i = sim.map.cells_of("G")[0]
	sim.place_player(sim.cell_centre(gate), Vector2.UP)
	sim.spell_index = sim.spells.find(FarmSim.CLEAR)
	sim.busy = 0


func test_the_sketch_is_the_accepted_one() -> void:
	var doc: String = FileAccess.get_file_as_string("res://docs/design/base.md")
	for row: String in FarmLayout.GREAT_FIELDS:
		assert_true(doc.contains(row.strip_edges()), "base.md shows the row %s" % row)


func test_every_thicket_tile_of_the_great_fields_has_something_under_it() -> void:
	var map: FarmMap = FarmMap.make_farm()
	var opened: Dictionary = FarmLayout.opened_tiles(1, map.rows)
	var thicket: int = map.cells_of("1").size() + map.cells_of("-").size()
	assert_eq(opened.size(), thicket, "every tile of parcel 1's thicket")
	assert_true(thicket > 2700, "about 2,800 tiles (base.md): %d" % thicket)
	for cell: Vector2i in opened:
		assert_true(map.char_at(cell) in ["1", "-"], "only parcel 1 (%s)" % cell)
		assert_true(opened[cell] in [":", ",", "=", "r", "F"], "a known ground (%s)" % opened[cell])
	assert_eq(FarmLayout.opened_tiles(2, map.rows).size(), 0, "the other parcels have no inside yet")
	var shelter: int = 0
	for cell: Vector2i in opened:
		if opened[cell] == "F":
			shelter += 1
	assert_eq(shelter, 6, "the ruined shelter: 3 x 2 tiles")


func test_once_open_the_great_fields_can_be_walked_from_the_north_gate() -> void:
	var sim: FarmSim = FarmSim.make_farm()
	sim.open_parcel(1)
	var map: FarmMap = sim.map
	var start: Vector2i = sim.cell_at(sim.wake_position)
	var seen: Dictionary = {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for step: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var next: Vector2i = cell + step
			if map.contains(next) and not seen.has(next) and not map.is_solid(next):
				seen[next] = true
				queue.append(next)
	var opened: Dictionary = FarmLayout.opened_tiles(1, FarmMap.make_farm().rows)
	var unreached: int = 0
	for cell: Vector2i in opened:
		if opened[cell] in [":", ",", "="] and not seen.has(cell):
			unreached += 1
	assert_eq(unreached, 0, "every strip of old field, the track and the long grass can be reached")
	for cell: Vector2i in seen:
		assert_false(map.char_at(cell) in ["2", "3", "4", "5", "6", "t"], "never into other parcels or the woods: %s" % cell)
	var near_shelter: bool = false
	for cell: Vector2i in map.cells_of("F"):
		for step: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			near_shelter = near_shelter or seen.has(cell + step)
	assert_true(near_shelter, "the shelter can be walked up to")
	var gate: Vector2i = map.cells_of("G")[0]
	assert_eq(map.char_at(gate + Vector2i.UP), "=", "the track meets the north gate")


func test_clear_without_the_heart_leaves_the_thicket() -> void:
	var sim: FarmSim = FarmSim.make_farm()
	_at_the_north_gate(sim)
	sim.step(FarmInput.press(&"use"))
	assert_eq(sim.events[0]["type"], "nothing", "too thick for Clear alone")
	assert_eq(sim.mana.current, 100.0, "no Mana spent")


func test_with_grists_heart_the_thicket_withers_back() -> void:
	var sim: FarmSim = FarmSim.make_farm()
	sim.inventory.add(&"grist_heart")
	_at_the_north_gate(sim)
	sim.step(FarmInput.press(&"use"))
	assert_eq(sim.events[0]["type"], "opening", "it begins")
	assert_eq(Haptics.effect_for_farm_event(sim.events[0]), &"farm_opening", "a long faint roll")
	assert_eq(sim.inventory.count(&"grist_heart"), 0, "the heart is used up")
	assert_eq(sim.mana.current, 98.0, "for Clear's 2 Mana")
	var thicket_at_start: int = sim.map.cells_of("1").size()
	var at: Vector2 = sim.player_position
	for i: int in range(FarmSim.WITHER_TICKS / 2):
		sim.step(FarmInput.with_move(Vector2.DOWN))
	var halfway: int = sim.map.cells_of("1").size()
	assert_true(halfway < thicket_at_start and halfway > 0, "halfway, part withered (%d of %d left)" % [halfway, thicket_at_start])
	assert_eq(sim.player_position, at, "the player stands and watches")
	var opened: Array[Dictionary] = []
	for i: int in range(FarmSim.WITHER_TICKS):
		sim.step(FarmInput.new())
		for e: Dictionary in sim.events:
			if e["type"] == "opened":
				opened.append(e)
	assert_eq(opened.size(), 1, "then it is open")
	assert_eq(sim.map.cells_of("1").size() + sim.map.cells_of("-").size(), 0, "no thicket left in the great fields")
	assert_eq(sim.parcels_open, [1] as Array[int], "remembered")
	assert_true(sim.map.cells_of("2").size() > 0, "the east pasture still overgrown")
	# Inside, Clear and Till work as on the homestead's old fields.
	var old_field: Vector2i = sim.map.cells_of(":")[0]
	assert_true(sim.can_clear(old_field), "the great fields' long grass can be cleared")


func test_the_heart_opens_only_its_own_parcel() -> void:
	var sim: FarmSim = FarmSim.make_farm()
	sim.inventory.add(&"grist_heart")
	assert_false(sim.can_open(Vector2i(110, 80)), "not the east pasture")
	assert_true(sim.can_open(Vector2i(70, 61)), "the great fields")
	sim.open_parcel(1)
	assert_false(sim.can_open(Vector2i(70, 40)), "not twice")


func test_the_save_remembers_the_opened_fields() -> void:
	var state: GameState = GameState.new_game()
	state.travel(GameState.FARM, GameState.AT_DOOR)
	var sim: FarmSim = state.make_farm()
	sim.inventory.add(&"grist_heart")
	_at_the_north_gate(sim)
	sim.step(FarmInput.press(&"use"))
	for i: int in range(10):
		sim.step(FarmInput.new())
	state.store_farm(sim)  # mid-withering: the heart is spent, so it is open
	var loaded: GameState = GameState.from_dict(JSON.parse_string(JSON.stringify(state.to_dict())))
	var again: FarmSim = loaded.make_farm()
	assert_eq(again.parcels_open, [1] as Array[int], "open after loading")
	assert_eq(again.map.cells_of("1").size(), 0, "all of it, at once")
	var field: Vector2i = again.map.cells_of(":").filter(func(c: Vector2i) -> bool: return c.y < 60)[0]
	again.clear_tile(field)
	again.plot.till(field)
	loaded.store_farm(again)
	var third: FarmSim = GameState.from_dict(JSON.parse_string(JSON.stringify(loaded.to_dict()))).make_farm()
	assert_true(third.plot.is_tilled(field), "a tilled tile inside the great fields survives the save")


func test_the_scene_follows_the_withering_and_the_cat_is_already_there() -> void:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	var state: GameState = GameState.new_game()
	state.inventory.add(&"grist_heart")
	state.travel(GameState.FARM, GameState.AT_DOOR)
	GameState.current = state
	var farm: Node2D = FARM_SCENE.instantiate()
	farm.set("travels", false)
	tree.root.add_child(farm)
	var sim: FarmSim = farm.get("sim")
	_at_the_north_gate(sim)
	var camera: FollowCamera = farm.get("camera")
	camera.snap(sim.player_position, farm.call("view_size"), sim.bounds(), farm.call("view_scale"))
	var start: Vector2 = camera.position
	Input.action_press(&"farm_use_tool")
	await tree.physics_frame
	await tree.physics_frame
	Input.action_release(&"farm_use_tool")
	assert_false(sim.withering.is_empty(), "the thicket is withering")
	assert_eq(state.cat.place, Cat.SHELTER, "the cat is already in the shelter, waiting")
	for i: int in range(FarmSim.WITHER_TICKS / 2):
		await tree.physics_frame
	assert_true(camera.position.distance_to(start) > 40.0, "the camera follows the withering out")
	for i: int in range(FarmSim.WITHER_TICKS / 2 + 60):
		await tree.physics_frame
	assert_eq(sim.parcels_open, [1] as Array[int], "open")
	assert_true(camera.position.distance_to(start) < 40.0, "and comes back to the player")
	farm.queue_free()
	await tree.process_frame
	GameState.current = null
