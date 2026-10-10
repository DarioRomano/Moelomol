extends TestCase
## The farm test scene: its bindings (ADR-0013; Q26, working assumption A),
## stepping, developer keys, HUD and rumble.

const FARM: PackedScene = preload("res://scenes/farm/farm_test.tscn")


func _key(keycode: Key) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	return event


func _button(index: JoyButton) -> InputEventJoypadButton:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.button_index = index
	event.pressed = true
	event.device = 1  # any controller, not only the first
	return event


func test_bindings_match_the_design() -> void:
	# docs/design/farming.md, "Controls at the base".
	var bindings: Dictionary = {
		&"farm_use_tool": [_key(KEY_J), _button(JOY_BUTTON_X)],
		&"farm_interact": [_key(KEY_SPACE), _button(JOY_BUTTON_A)],
		&"farm_tool_next": [_key(KEY_E), _button(JOY_BUTTON_RIGHT_SHOULDER)],
		&"farm_tool_prev": [_key(KEY_Q), _button(JOY_BUTTON_LEFT_SHOULDER)],
		&"dev_farm_sleep": [_key(KEY_F8)],
		&"dev_farm_fast_time": [_key(KEY_F9)],
	}
	for action: StringName in bindings:
		assert_true(InputMap.has_action(action), "%s exists" % action)
		for event: InputEvent in bindings[action]:
			assert_true(InputMap.event_is_action(event, action), "%s triggers %s" % [event.as_text(), action])


func test_the_scene_steps_the_farm_and_its_clock() -> void:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	var farm: Node2D = FARM.instantiate()
	tree.root.add_child(farm)
	var sim: FarmSim = farm.get("sim")
	var start: float = sim.clock.minute
	for i: int in range(30):
		await tree.physics_frame
	assert_true(sim.clock.minute > start, "time passes")
	farm.queue_free()
	await tree.process_frame


func test_holding_use_tills_the_tile_in_front() -> void:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	var farm: Node2D = FARM.instantiate()
	tree.root.add_child(farm)
	var sim: FarmSim = farm.get("sim")
	sim.player_position = sim.cell_centre(Vector2i(12, 10))
	sim.facing = Vector2.RIGHT
	Input.action_press(&"farm_use_tool")
	await tree.physics_frame
	await tree.physics_frame
	Input.action_release(&"farm_use_tool")
	assert_true(sim.plot.is_tilled(Vector2i(13, 10)), "the hoe tilled the tile through the InputMap")
	farm.queue_free()
	await tree.process_frame


func test_f8_sleeps_and_f9_speeds_up_time() -> void:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	var farm: Node2D = FARM.instantiate()
	tree.root.add_child(farm)
	var sim: FarmSim = farm.get("sim")
	farm.call("_unhandled_input", _key(KEY_F8))
	assert_eq(sim.clock.day, 2, "F8: the next morning")
	farm.call("_unhandled_input", _key(KEY_F9))
	assert_true(sim.time_scale > 1.0, "F9: fast")
	farm.call("_unhandled_input", _key(KEY_F9))
	assert_eq(sim.time_scale, 1.0, "F9 again: normal")
	farm.queue_free()
	await tree.process_frame


func test_the_farm_is_reachable_with_f2_and_launch_option() -> void:
	var tools: Node = (Engine.get_main_loop() as SceneTree).root.get_node("DevTools")
	var scenes: Dictionary = tools.get("SHOWCASE_SCENES")
	assert_eq(scenes.get("farm_test", ""), "res://scenes/farm/farm_test.tscn", "in the F2 list")
	var options: Dictionary = tools.call("parse_args", PackedStringArray(["--start-scene", "farm_test"]))
	assert_eq(options["start_scene"], "farm_test", "--start-scene farm_test")


func test_farm_actions_rumble_softly() -> void:
	var expected: Dictionary = {"till": &"farm_till", "water": &"farm_water", "plant": &"farm_plant",
		"harvest": &"farm_harvest", "nothing": &"farm_nothing", "no_seeds": &"farm_nothing", "new_day": &""}
	for type: String in expected:
		assert_eq(Haptics.effect_for_farm_event({"type": type}), expected[type], type)
		if expected[type] != &"":
			assert_true(Haptics.EFFECTS.has(expected[type]), "%s is defined" % expected[type])
	var softest_combat: Array = Haptics.EFFECTS[&"greatsword_hit"]
	for effect: StringName in [&"farm_till", &"farm_water", &"farm_plant", &"farm_harvest", &"farm_nothing"]:
		var values: Array = Haptics.EFFECTS[effect]
		assert_true(float(values[1]) < float(softest_combat[1]), "%s is softer than a sword hit" % effect)


func test_the_scene_plays_rumble_for_farm_events() -> void:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	var farm: Node2D = FARM.instantiate()
	tree.root.add_child(farm)
	var sim: FarmSim = farm.get("sim")
	var haptics: Haptics = farm.get("haptics")
	var calls: Array[Array] = []
	haptics.devices = func() -> Array[int]: return [0] as Array[int]
	haptics.rumble = func(device: int, weak: float, strong: float, seconds: float) -> void:
		calls.append([device, weak, strong, seconds])
	sim.player_position = sim.cell_centre(Vector2i(12, 10))
	sim.facing = Vector2.RIGHT
	Input.action_press(&"farm_use_tool")
	await tree.physics_frame
	await tree.physics_frame
	Input.action_release(&"farm_use_tool")
	assert_eq(calls.size(), 1, "one soft pulse for the till")
	farm.queue_free()
	await tree.process_frame


func test_the_hud_shows_day_time_tool_and_bag() -> void:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	var farm: Node2D = FARM.instantiate()
	tree.root.add_child(farm)
	await tree.process_frame
	var sim: FarmSim = farm.get("sim")
	sim.inventory.add(&"radish", 3)
	sim.tool_index = sim.tools.find(&"catmint_seeds")
	await tree.process_frame
	var text: String = ""
	for label: Node in farm.find_children("*", "Label", true, false):
		text += (label as Label).text + "\n"
	assert_true(text.contains("Day 1"), "the day")
	assert_true(text.contains("06:0"), "the time")
	assert_true(text.contains("Catmint seeds x6"), "the tool in hand with its count")
	assert_true(text.contains("Radish 3"), "the produce carried")
	farm.queue_free()
	await tree.process_frame
