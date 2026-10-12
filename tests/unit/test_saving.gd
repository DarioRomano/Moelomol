extends TestCase
## Saving (ADR-0017): one save, written when the player sleeps, falls or
## passes the gate either way; read back exactly; a broken save is reported,
## never trusted. And the title screen that continues it or starts anew.

const PATH: String = "user://test_save.json"
const FARM_SCENE: PackedScene = preload("res://scenes/farm/farm.tscn")
const MILLBROOK_SCENE: PackedScene = preload("res://scenes/world/millbrook.tscn")
const TITLE_SCENE: PackedScene = preload("res://scenes/title/title.tscn")


func _remove_save() -> void:
	for path: String in [PATH, PATH + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _write(text: String) -> void:
	var file: FileAccess = FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(text)
	file.close()


## A game with something in every part: crops, a trip to Millbrook, Grist
## defeated, notes, things carried, Mana spent, time passed.
func _played_game() -> GameState:
	var state: GameState = GameState.new_game()
	state.save_path = PATH
	var farm: FarmSim = state.make_farm()
	var field: Array[Vector2i] = farm.map.cells_of("T")
	farm.plot.till(field[0])
	farm.plot.plant(field[0], &"catmint")
	farm.plot.water(field[0])
	farm.plot.till(field[5])
	farm.raining = true
	state.store_farm(farm)
	state.travel(GameState.MILLBROOK, GameState.AT_GATE)
	var area: Area = state.make_area(GameState.MILLBROOK)
	area.satchel.append(&"sluice_note")
	area.satchel.append(&"my_family")
	area.objective_done = true
	for c: Fighter in area.sim.creatures:
		if c.creature_kind.id == &"grist":
			area.sim.defeat(c)
	area.step(CombatInput.new())
	area.bag.add(&"tusk", 2)
	state.store_area(area)
	state.mana.try_spend(37.5)
	state.clock.total_minutes += 300.0
	return state


func _without_time(d: Dictionary) -> Dictionary:
	var copy: Dictionary = d.duplicate(true)
	copy.erase("saved_at")
	return copy


func test_a_game_comes_back_exactly_as_saved() -> void:
	_remove_save()
	var state: GameState = _played_game()
	assert_eq(state.save(), OK, "saved")
	var loaded: GameState = GameState.load_from(PATH)
	assert_true(loaded != null, "loaded: %s" % GameState.last_load_error)
	if loaded == null:
		return
	# JSON keeps numbers as floats; compare through JSON both ways.
	var before: Variant = JSON.parse_string(JSON.stringify(_without_time(state.to_dict())))
	var after: Variant = JSON.parse_string(JSON.stringify(_without_time(loaded.to_dict())))
	assert_eq(JSON.stringify(after), JSON.stringify(before), "every value back")
	assert_eq(loaded.save_path, PATH, "it saves back to the same file")
	assert_eq(loaded.place, GameState.MILLBROOK, "in Millbrook")
	assert_eq(loaded.clock.total_minutes, state.clock.total_minutes, "the same moment")
	assert_eq(loaded.mana.current, 62.5, "Mana as it was")
	assert_eq(loaded.inventory.count(&"tusk"), 2, "the bag as it was")
	# The places built from the loaded game.
	var area: Area = loaded.make_area(GameState.MILLBROOK)
	assert_eq(area.satchel, [&"sluice_note", &"my_family"] as Array[StringName], "the satchel, in the order found")
	assert_true(area.objective_done, "the sluice open")
	assert_eq(area.sim.creatures.filter(func(c: Fighter) -> bool: return c.creature_kind.id == &"grist").size(), 0,
		"Grist still defeated")
	assert_eq(area.things.filter(func(t: Dictionary) -> bool: return t["id"] == &"grist_heart").size(), 1, "its heart there")
	var farm: FarmSim = loaded.make_farm()
	var field: Array[Vector2i] = farm.map.cells_of("T")
	assert_eq(farm.plot.crop_at(field[0]), &"catmint", "the catmint")
	assert_true(farm.plot.is_watered(field[0]), "still watered (no 6:00 since)")
	assert_true(farm.plot.is_tilled(field[5]), "the tilled tile")
	assert_true(farm.raining, "still raining")
	_remove_save()


func test_saving_replaces_the_old_save_and_leaves_no_temporary_file() -> void:
	_remove_save()
	var state: GameState = GameState.new_game()
	state.save_path = PATH
	state.save()
	state.clock.total_minutes += GameClock.MINUTES_PER_DAY
	state.save()
	assert_false(FileAccess.file_exists(PATH + ".tmp"), "no temporary file left")
	assert_eq(GameState.load_from(PATH).clock.day(), 2, "the newer save")
	_remove_save()


func test_a_game_without_a_save_path_never_writes() -> void:
	_remove_save()
	var state: GameState = GameState.new_game()
	assert_eq(state.save(), OK, "nothing to do")
	assert_false(FileAccess.file_exists(PATH), "no file")
	GameState.current = null
	assert_eq(GameState.ensure().save_path, "", "a place opened on its own is never saved")
	GameState.current = null


func test_a_broken_save_is_reported_not_trusted() -> void:
	_remove_save()
	assert_eq(GameState.load_from(PATH), null, "no save")
	assert_eq(GameState.last_load_error, "there is no save", "said why")
	_write("{ half a save")
	assert_eq(GameState.load_from(PATH), null, "not JSON")
	assert_true(GameState.last_load_error.begins_with("the save could not be read"), GameState.last_load_error)
	_write("[1, 2]")
	assert_eq(GameState.load_from(PATH), null, "not an object")
	var good: Dictionary = GameState.new_game().to_dict()
	var wrong_format: Dictionary = good.duplicate(true)
	wrong_format["format"] = 99
	_write(JSON.stringify(wrong_format))
	assert_eq(GameState.load_from(PATH), null, "a format this build does not read")
	assert_true(GameState.last_load_error.contains("format"), GameState.last_load_error)
	var nowhere: Dictionary = good.duplicate(true)
	nowhere["place"] = "atlantis"
	_write(JSON.stringify(nowhere))
	assert_eq(GameState.load_from(PATH), null, "a place this build does not know")
	var no_clock: Dictionary = good.duplicate(true)
	no_clock.erase("minutes")
	_write(JSON.stringify(no_clock))
	assert_eq(GameState.load_from(PATH), null, "no clock")
	_write(JSON.stringify(good))
	assert_true(GameState.load_from(PATH) != null, "and a good one reads")
	_remove_save()


# --- When the game saves ---------------------------------------------------------------

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


func test_sleeping_saves_at_the_bed_the_next_morning() -> void:
	_remove_save()
	var state: GameState = GameState.new_game()
	state.save_path = PATH
	var farm: Node2D = _scene(FARM_SCENE, state)
	var sim: FarmSim = farm.get("sim")
	sim.place_player(sim.wake_position, Vector2.UP)  # against the door
	Input.action_press(&"farm_interact")
	await (Engine.get_main_loop() as SceneTree).physics_frame
	await (Engine.get_main_loop() as SceneTree).physics_frame
	Input.action_release(&"farm_interact")
	var saved: GameState = GameState.load_from(PATH)
	assert_true(saved != null, "saved on sleeping")
	if saved != null:
		assert_eq(saved.clock.day(), 2, "the next morning")
		assert_eq([saved.place, saved.arrival], [GameState.FARM, GameState.AT_BED], "at the bed")
	await _close(farm)


func test_the_developer_sleep_key_saves_too() -> void:
	_remove_save()
	var state: GameState = GameState.new_game()
	state.save_path = PATH
	var farm: Node2D = _scene(FARM_SCENE, state)
	var key: InputEventKey = InputEventKey.new()
	key.keycode = KEY_F8
	key.pressed = true
	farm.call("_unhandled_input", key)
	assert_eq(GameState.load_from(PATH).clock.day(), 2, "F8 slept and saved")
	await _close(farm)


func test_leaving_the_farm_saves_on_the_way_to_millbrook() -> void:
	_remove_save()
	var state: GameState = GameState.new_game()
	state.save_path = PATH
	var farm: Node2D = _scene(FARM_SCENE, state)
	var sim: FarmSim = farm.get("sim")
	sim.plot.till(sim.map.cells_of("T")[0])
	farm.call("leave", GameState.MILLBROOK)
	var saved: GameState = GameState.load_from(PATH)
	assert_eq([saved.place, saved.arrival], [GameState.MILLBROOK, GameState.AT_GATE], "saved arriving in Millbrook")
	assert_eq(saved.farm_state["cells"].size(), 1, "with the farm as it was left")
	await _close(farm)


func test_leaving_millbrook_saves_on_the_way_home() -> void:
	_remove_save()
	var state: GameState = GameState.new_game()
	state.save_path = PATH
	state.travel(GameState.MILLBROOK, GameState.AT_GATE)
	var scene: Node2D = _scene(MILLBROOK_SCENE, state)
	var area: Area = scene.get("area")
	area.satchel.append(&"lost_pet_poster")
	area.sim.player.position = area.entrance + Vector2(0, -34)
	await (Engine.get_main_loop() as SceneTree).physics_frame
	await (Engine.get_main_loop() as SceneTree).physics_frame
	var saved: GameState = GameState.load_from(PATH)
	assert_true(saved != null, "saved")
	if saved != null:
		assert_eq([saved.place, saved.arrival], [GameState.FARM, GameState.AT_GATE], "arriving home at the gate")
		assert_eq(saved.area_states[GameState.MILLBROOK]["satchel"], ["lost_pet_poster"], "with Millbrook as it was left")
	await _close(scene)


func test_falling_saves_in_the_farm_bed() -> void:
	_remove_save()
	var state: GameState = GameState.new_game()
	state.save_path = PATH
	state.travel(GameState.MILLBROOK, GameState.AT_GATE)
	var scene: Node2D = _scene(MILLBROOK_SCENE, state)
	var area: Area = scene.get("area")
	for c: Fighter in area.sim.creatures:
		c.ai_enabled = false
	area.sim.defeat(area.sim.player)
	for i: int in range(CombatTuning.ticks(CombatTuning.PLAYER_DOWN_MS) + 3):
		await (Engine.get_main_loop() as SceneTree).physics_frame
	var saved: GameState = GameState.load_from(PATH)
	assert_true(saved != null, "saved")
	if saved != null:
		assert_eq([saved.place, saved.arrival], [GameState.FARM, GameState.AT_BED], "in the farm bed")
		assert_eq(saved.clock.day(), 2, "the next morning")
	await _close(scene)


# --- The title screen ------------------------------------------------------------------

func _title() -> Control:
	var title: Control = TITLE_SCENE.instantiate()
	title.set("save_path", PATH)
	title.set("travels", false)
	(Engine.get_main_loop() as SceneTree).root.add_child(title)
	return title


func _buttons(title: Control) -> Dictionary:
	var found: Dictionary = {}
	for b: Node in title.find_children("*", "Button", true, false):
		found[(b as Button).text] = b
	return found


func _text(title: Control) -> String:
	var text: String = ""
	for label: Node in title.find_children("*", "Label", true, false):
		text += (label as Label).text + "\n"
	return text


func test_the_title_is_the_main_scene_and_in_the_f2_list() -> void:
	assert_eq(ProjectSettings.get_setting("application/run/main_scene"), "res://scenes/title/title.tscn", "main scene")
	var tools: GDScript = preload("res://src/core/dev_tools.gd")
	assert_eq((tools.get("SHOWCASE_SCENES") as Dictionary).get("title", ""), "res://scenes/title/title.tscn", "F2")


func test_menus_answer_the_controller() -> void:
	# ADR-0013: every menu works with a controller. Godot 4.7.2's ui_accept
	# has no controller button of its own.
	var a: InputEventJoypadButton = InputEventJoypadButton.new()
	a.button_index = JOY_BUTTON_A
	a.device = 1
	a.pressed = true
	assert_true(InputMap.event_is_action(a, &"ui_accept"), "A presses")
	var b: InputEventJoypadButton = InputEventJoypadButton.new()
	b.button_index = JOY_BUTTON_B
	b.device = 1
	b.pressed = true
	assert_true(InputMap.event_is_action(b, &"ui_cancel"), "B goes back")
	for key: Key in [KEY_ENTER, KEY_SPACE]:
		var k: InputEventKey = InputEventKey.new()
		k.keycode = key
		k.pressed = true
		assert_true(InputMap.event_is_action(k, &"ui_accept"), "%s presses" % OS.get_keycode_string(key))


func test_with_no_save_new_game_starts_at_the_farm_and_saves() -> void:
	_remove_save()
	GameState.current = null
	var title: Control = _title()
	await (Engine.get_main_loop() as SceneTree).process_frame
	var buttons: Dictionary = _buttons(title)
	assert_false((buttons["Continue"] as Button).visible, "nothing to continue")
	assert_true((buttons["New game"] as Button).has_focus(), "New game is chosen")
	var started: Array[GameState] = []
	title.connect("starting", func(s: GameState) -> void: started.append(s))
	(buttons["New game"] as Button).pressed.emit()
	assert_eq(started.size(), 1, "a game starts")
	assert_eq(GameState.current, started[0], "it is the game in play")
	assert_eq([started[0].place, started[0].arrival], [GameState.FARM, GameState.AT_BED], "at the farm, by the door")
	assert_eq(started[0].clock.day(), 1, "day 1")
	assert_true(GameState.has_save(PATH), "saved at once, so Continue finds it")
	await _close(title)


func test_with_a_save_continue_resumes_it() -> void:
	_remove_save()
	var state: GameState = GameState.new_game()
	state.save_path = PATH
	state.clock.total_minutes += GameClock.MINUTES_PER_DAY + 12 * 60 + 40
	state.travel(GameState.MILLBROOK, GameState.AT_GATE)
	state.save()
	var title: Control = _title()
	await (Engine.get_main_loop() as SceneTree).process_frame
	var buttons: Dictionary = _buttons(title)
	assert_true((buttons["Continue"] as Button).visible and not (buttons["Continue"] as Button).disabled, "Continue")
	assert_true((buttons["Continue"] as Button).has_focus(), "chosen first")
	assert_true(_text(title).contains("Day 2, 18:40, in Millbrook"), "says where and when: %s" % _text(title))
	var started: Array[GameState] = []
	title.connect("starting", func(s: GameState) -> void: started.append(s))
	(buttons["Continue"] as Button).pressed.emit()
	assert_eq(started.size(), 1, "the game starts")
	assert_eq(started[0].place, GameState.MILLBROOK, "in Millbrook")
	assert_eq(started[0].clock.total_minutes, state.clock.total_minutes, "at the saved moment")
	await _close(title)


func test_new_game_over_a_save_asks_first() -> void:
	_remove_save()
	var state: GameState = GameState.new_game()
	state.save_path = PATH
	state.clock.total_minutes += 3 * GameClock.MINUTES_PER_DAY
	state.save()
	var title: Control = _title()
	await (Engine.get_main_loop() as SceneTree).process_frame
	var started: Array[GameState] = []
	title.connect("starting", func(s: GameState) -> void: started.append(s))
	var buttons: Dictionary = _buttons(title)
	(buttons["New game"] as Button).pressed.emit()
	assert_true(title.call("is_confirming"), "asks")
	assert_true((buttons["Keep it"] as Button).has_focus(), "the safe answer is chosen first")
	assert_eq(started.size(), 0, "nothing started yet")
	var cancel: InputEventAction = InputEventAction.new()
	cancel.action = &"ui_cancel"
	cancel.pressed = true
	title.call("_unhandled_input", cancel)
	assert_false(title.call("is_confirming"), "B / Escape goes back")
	assert_eq(GameState.load_from(PATH).clock.day(), 4, "the save is untouched")
	(buttons["New game"] as Button).pressed.emit()
	(buttons["Start anew"] as Button).pressed.emit()
	assert_eq(started.size(), 1, "a new game")
	assert_eq(GameState.load_from(PATH).clock.day(), 1, "the save is the new game now")
	await _close(title)


func test_a_broken_save_cannot_be_continued_and_says_so() -> void:
	_remove_save()
	_write("{ half a save")
	var title: Control = _title()
	await (Engine.get_main_loop() as SceneTree).process_frame
	var buttons: Dictionary = _buttons(title)
	assert_true((buttons["Continue"] as Button).visible, "Continue is there")
	assert_true((buttons["Continue"] as Button).disabled, "but cannot be pressed")
	assert_true(_text(title).contains("The save could not be read"), "and the title says why")
	assert_true((buttons["New game"] as Button).has_focus(), "New game is chosen")
	(buttons["New game"] as Button).pressed.emit()
	assert_true(title.call("is_confirming"), "a new game still asks before replacing the file")
	await _close(title)


func test_w_and_s_move_between_the_choices() -> void:
	_remove_save()
	var title: Control = _title()
	await (Engine.get_main_loop() as SceneTree).process_frame
	await (Engine.get_main_loop() as SceneTree).process_frame
	var buttons: Dictionary = _buttons(title)
	if not OS.has_feature("web"):
		var s: InputEventKey = InputEventKey.new()
		s.keycode = KEY_S
		s.pressed = true
		title.call("_unhandled_input", s)
		assert_true((buttons["Quit"] as Button).has_focus(), "S: down to Quit")
		var w: InputEventKey = InputEventKey.new()
		w.keycode = KEY_W
		w.pressed = true
		title.call("_unhandled_input", w)
		assert_true((buttons["New game"] as Button).has_focus(), "W: back up")
	await _close(title)
