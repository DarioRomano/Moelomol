extends TestCase
## Kettlebridge (docs/design/area-kettlebridge.md), stage 1: its map, what
## can be reached, the objective (Arthur's key, the winch house, the bridge),
## the roads to and from Millbrook, and the save.

const KETTLEBRIDGE_SCENE: PackedScene = preload("res://scenes/world/kettlebridge.tscn")
const MILLBROOK_SCENE: PackedScene = preload("res://scenes/world/millbrook.tscn")
const PATH: String = "user://test_kettlebridge_save.json"


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


func _thing(area: Area, thing_id: StringName) -> Dictionary:
	for thing: Dictionary in area.things:
		if thing["id"] == thing_id:
			return thing
	return {}


func _go_to(area: Area, thing_id: StringName) -> void:
	area.sim.player.position = _thing(area, thing_id)["position"] + Vector2(0, 4)
	area.sim.player.previous_position = area.sim.player.position


func _run(area: Area, ticks: int) -> Array[Dictionary]:
	var seen: Array[Dictionary] = []
	for i: int in range(ticks):
		area.step(CombatInput.new())
		seen.append_array(area.events)
	return seen


func _exits(seen: Array[Dictionary]) -> Array[Dictionary]:
	return seen.filter(func(e: Dictionary) -> bool: return e["type"] == "exit")


func _remove_save() -> void:
	for path: String in [PATH, PATH + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _scene(packed: PackedScene, state: GameState) -> Node2D:
	GameState.current = state
	var scene: Node2D = packed.instantiate()
	scene.set("travels", false)
	(Engine.get_main_loop() as SceneTree).root.add_child(scene)
	return scene


func _close(scene: Node) -> void:
	scene.queue_free()
	await (Engine.get_main_loop() as SceneTree).process_frame
	GameState.current = null
	_remove_save()


func _two_ticks() -> void:
	await (Engine.get_main_loop() as SceneTree).physics_frame
	await (Engine.get_main_loop() as SceneTree).physics_frame


# --- The map ---------------------------------------------------------------------------

func test_the_map_is_the_accepted_layout() -> void:
	var doc: String = FileAccess.get_file_as_string("res://docs/design/images/kettlebridge.txt").strip_edges()
	assert_eq("\n".join(KettlebridgeMap.ROWS), doc, "the code's map matches the design doc's")
	var map: AreaMap = AreaMap.new(KettlebridgeMap.ROWS, KettlebridgeMap.SOLID, KettlebridgeMap.BARRIER)
	assert_eq(map.size, Vector2i(64, 36), "64 x 36 cells (128 x 72 tiles)")
	for row: String in KettlebridgeMap.ROWS:
		assert_eq(row.length(), 64, "every row is 64 cells")


func test_what_blocks_and_what_does_not() -> void:
	var map: AreaMap = Kettlebridge.make().map
	for c: String in ["t", "H", "K", "#", "~", "i", "h", "k", "R", "+", "Z", "n"]:
		assert_true(map.is_solid(map.cells_of(c)[0]), c + " blocks")
	for c: String in [".", ",", "v", "=", "_", "O", "q"]:
		assert_false(map.is_solid(map.cells_of(c)[0]), c + " is open ground")
	var bridge: Vector2i = map.cells_of("Y")[0]
	assert_true(map.is_solid(bridge), "the raised bridge blocks")
	map.drained = true
	assert_false(map.is_solid(bridge), "until it is lowered")
	assert_false(map.is_solid(AreaMap.cell_of(Kettlebridge.ENTRANCE)), "the entrance stands on the road")


func test_every_place_and_thing_north_of_the_river_can_be_reached_and_the_south_only_by_the_bridge() -> void:
	var area: Area = Kettlebridge.make()
	var from: Vector2i = AreaMap.cell_of(Kettlebridge.ENTRANCE)
	var reach: Dictionary = _bfs(area.map, from)
	for marker: String in ["2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F", "G"]:
		var cell: Vector2i = area.map.markers[marker]
		assert_true(reach.has(cell), "place %s at %s" % [marker, cell])
	for thing: Dictionary in area.things:
		assert_true(reach.has(AreaMap.cell_of(thing["position"])), "%s can be reached" % thing["id"])
	var road_south: Vector2i = Vector2i(31, area.map.size.y - 1)
	assert_false(reach.has(road_south), "the river cuts off the road south")
	area.map.drained = true
	assert_true(_bfs(area.map, from).has(road_south), "until the bridge is down")


# --- The objective ---------------------------------------------------------------------

func test_the_winch_house_is_locked_without_the_key() -> void:
	var area: Area = Kettlebridge.make()
	_go_to(area, &"winch")
	var result: Dictionary = area.interact()
	assert_eq(result["type"], "stuck", "locked")
	assert_eq(result.get("thing", &""), &"winch", "the winch house")
	assert_false(area.objective_done, "the bridge stays up")


func test_arthur_s_key_opens_the_winch_house_and_the_bridge_lowers_over_ten_seconds() -> void:
	var area: Area = Kettlebridge.make()
	_go_to(area, &"winch_key")
	assert_eq(area.interact(), {"type": "taken", "item": &"winch_key"}, "the key from the egg stall")
	assert_eq(area.bag.count(&"winch_key"), 1, "carried")
	assert_eq(area.taken_lines[&"winch_key"], "Taken: the bridge-keeper's key.", "its line")
	_go_to(area, &"winch")
	assert_eq(area.interact()["type"], "opened", "the winch turns")
	assert_eq(area.bag.count(&"winch_key"), 0, "the key stays in the lock")
	var bridge: Vector2i = area.map.cells_of("Y")[0]
	var ticks: int = roundi(Area.DRAIN_SECONDS * Engine.physics_ticks_per_second)
	_run(area, ticks - 2)
	assert_true(area.map.is_solid(bridge), "still coming down just before ten seconds")
	var seen: Array[Dictionary] = _run(area, 3)
	assert_false(area.map.is_solid(bridge), "down: the bridge can be crossed")
	var down: Array[Dictionary] = seen.filter(func(e: Dictionary) -> bool: return e["type"] == "drained")
	assert_eq(down.size(), 1, "reported once")
	assert_eq(area.cleared_line, "The bridge is down.", "and said quietly")


func test_arthur_s_note_carries_the_loose_thread_until_the_bridge_is_down() -> void:
	var area: Area = Kettlebridge.make()
	assert_true(area.has_loose_thread(&"arthurs_door"), "about the objective")
	assert_false(area.has_loose_thread(&"market_notice"), "other notes are not")
	area.objective_done = true
	assert_false(area.has_loose_thread(&"arthurs_door"), "done")


func test_every_note_is_in_the_satchel_s_book() -> void:
	for note_id: StringName in KettlebridgeNotes.NOTES:
		assert_true(Notes.find(note_id).size() > 0, "%s can be read from the satchel" % note_id)


# --- The roads ---------------------------------------------------------------------

func test_the_road_north_leads_back_to_millbrook_and_the_bridge_south_only_once_down() -> void:
	var area: Area = Kettlebridge.make()
	area.sim.player.position = Vector2(32 * AreaMap.CELL, 4)
	var north: Array[Dictionary] = _exits(_run(area, 1))
	assert_eq(north.size(), 1, "an exit at the top of the road")
	assert_eq(north[0]["to"], &"millbrook", "to Millbrook")
	area.sim.player.position = Vector2(32 * AreaMap.CELL, area.map.rect().end.y - 4)
	assert_eq(_exits(_run(area, 2)).size(), 0, "no way south while the bridge is up")
	area.map.drained = true
	var south: Array[Dictionary] = _exits(_run(area, 2))
	assert_eq(south.size(), 1, "the road south once it is down")
	assert_eq(south[0]["to"], &"south", "to the area after (not built)")


func test_crossing_millbrook_s_ford_arrives_at_the_top_of_kettlebridge_s_road() -> void:
	_remove_save()
	var state: GameState = GameState.new_game()
	state.save_path = PATH
	state.travel(GameState.MILLBROOK, GameState.AT_GATE)
	var scene: Node2D = _scene(MILLBROOK_SCENE, state)
	var area: Area = scene.get("area")
	area.map.drained = true
	area.sim.player.position = Vector2(28 * AreaMap.CELL, area.map.rect().end.y - 4)
	await _two_ticks()
	assert_eq([state.place, state.came_from], [GameState.KETTLEBRIDGE, GameState.MILLBROOK], "on to Kettlebridge, from Millbrook")
	var saved: GameState = GameState.load_from(PATH)
	assert_true(saved != null and saved.place == GameState.KETTLEBRIDGE, "saved at the ford")
	await _close(scene)
	var town: Area = state.make_area(GameState.KETTLEBRIDGE)
	assert_eq(town.sim.player.position, Kettlebridge.ENTRANCE, "at the top of the road")
	assert_eq(town.sim.player.facing, Vector2.DOWN, "facing into the town")


func test_going_back_up_the_road_arrives_at_millbrook_s_ford_facing_north() -> void:
	_remove_save()
	var state: GameState = GameState.new_game()
	state.save_path = PATH
	var millbrook: Area = state.make_area(GameState.MILLBROOK)
	millbrook.map.drained = true
	millbrook.objective_done = true
	state.store_area(millbrook)
	state.travel(GameState.KETTLEBRIDGE, GameState.AT_GATE, GameState.MILLBROOK)
	var scene: Node2D = _scene(KETTLEBRIDGE_SCENE, state)
	var area: Area = scene.get("area")
	area.sim.player.position = Vector2(32 * AreaMap.CELL, 4)
	await _two_ticks()
	assert_eq([state.place, state.came_from], [GameState.MILLBROOK, GameState.KETTLEBRIDGE], "back to Millbrook")
	await _close(scene)
	var back: Area = state.make_area(GameState.MILLBROOK)
	var ford: Vector2i = AreaMap.cell_of(back.sim.player.position)
	assert_true(ford.y >= 29, "at the ford, not the top of the lane (%s)" % ford)
	assert_false(back.map.is_solid(ford), "on open ground")
	assert_eq(back.sim.player.facing, Vector2.UP, "facing north into the valley")
	assert_eq(back.events.filter(func(e: Dictionary) -> bool: return e["type"] == "exit").size(), 0, "not standing in an exit")
	_run(back, 2)
	assert_eq(_exits(back.events).size(), 0, "and not leaving again at once")


func test_the_town_remembers_itself_in_the_save() -> void:
	_remove_save()
	var state: GameState = GameState.new_game()
	state.save_path = PATH
	state.travel(GameState.KETTLEBRIDGE, GameState.AT_GATE, GameState.MILLBROOK)
	var area: Area = state.make_area(GameState.KETTLEBRIDGE)
	area.satchel.append(&"market_notice")
	_go_to(area, &"winch_key")
	area.interact()
	_go_to(area, &"winch")
	area.interact()
	area.drain_progress = 1.0
	area.map.drained = true
	state.store_area(area)
	assert_eq(state.save(), OK, "saved")
	var loaded: GameState = GameState.load_from(PATH)
	assert_eq(loaded.came_from, GameState.MILLBROOK, "where the player came from")
	var again: Area = loaded.make_area(GameState.KETTLEBRIDGE)
	assert_true(again.objective_done and again.map.drained, "the bridge stays down")
	assert_true(_thing(again, &"winch_key")["taken"], "the key stays taken")
	assert_true(&"market_notice" in loaded.satchel, "the note stays in the satchel")
	_remove_save()


func test_kettlebridge_is_reachable_with_f2_and_launch_option() -> void:
	var tools: GDScript = preload("res://src/core/dev_tools.gd")
	var scenes: Dictionary = tools.get("SHOWCASE_SCENES")
	assert_eq(scenes.get("kettlebridge", ""), "res://scenes/world/kettlebridge.tscn", "in the F2 list")
	var options: Dictionary = tools.call("parse_args", PackedStringArray(["--start-scene", "kettlebridge"]))
	assert_eq(options["start_scene"], "kettlebridge", "--start-scene kettlebridge")
	assert_eq(GameState.SCENES[GameState.KETTLEBRIDGE], "res://scenes/world/kettlebridge.tscn", "a place of the game")
