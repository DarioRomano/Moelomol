extends TestCase
## The combat arena scene, its input bindings (ADR-0013) and haptics.

const ARENA: PackedScene = preload("res://scenes/combat/combat_arena.tscn")


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


func _axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var event: InputEventJoypadMotion = InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	event.device = 1
	return event


func test_default_bindings_match_the_design() -> void:
	# docs/design/combat.md, "Controls".
	var bindings: Dictionary = {
		&"move_up": [_key(KEY_W), _axis(JOY_AXIS_LEFT_Y, -1.0)],
		&"move_down": [_key(KEY_S), _axis(JOY_AXIS_LEFT_Y, 1.0)],
		&"move_left": [_key(KEY_A), _axis(JOY_AXIS_LEFT_X, -1.0)],
		&"move_right": [_key(KEY_D), _axis(JOY_AXIS_LEFT_X, 1.0)],
		&"attack_light": [_key(KEY_J), _button(JOY_BUTTON_X)],
		&"attack_heavy": [_key(KEY_K), _axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)],
		&"weapon_skill": [_key(KEY_L), _button(JOY_BUTTON_Y)],
		&"dodge": [_key(KEY_SPACE), _button(JOY_BUTTON_A)],
		&"lock_on": [_key(KEY_SHIFT), _axis(JOY_AXIS_TRIGGER_LEFT, 1.0)],
		&"target_next": [_key(KEY_E), _axis(JOY_AXIS_RIGHT_X, 1.0)],
		&"target_prev": [_key(KEY_Q), _axis(JOY_AXIS_RIGHT_X, -1.0)],
	}
	for action: StringName in bindings:
		assert_true(InputMap.has_action(action), "%s exists" % action)
		for event: InputEvent in bindings[action]:
			assert_true(InputMap.event_is_action(event, action), "%s triggers %s" % [event.as_text(), action])


func test_trigger_deadzone() -> void:
	# event_is_action() matches the axis at any value; the 0.3 deadzone decides
	# whether it counts as a press (verified against the engine, 2026-10-10).
	assert_false(_axis(JOY_AXIS_TRIGGER_RIGHT, 0.25).is_action_pressed(&"attack_heavy"), "resting trigger at 0.25")
	assert_true(_axis(JOY_AXIS_TRIGGER_RIGHT, 0.9).is_action_pressed(&"attack_heavy"), "pulled trigger at 0.9")


func test_arena_steps_the_simulation_on_physics_ticks() -> void:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	var arena: Node2D = ARENA.instantiate()
	tree.root.add_child(arena)
	var sim: CombatSim = arena.get("sim")
	var start: Vector2 = sim.creatures[0].position
	for i: int in range(30):
		await tree.physics_frame
	assert_true(sim.tick_count >= 25, "about one tick per physics frame (got %d)" % sim.tick_count)
	assert_true(sim.creatures[0].position.distance_to(sim.player.position) < start.distance_to(sim.player.position),
		"creatures walk towards the player")
	arena.queue_free()
	await tree.process_frame


func test_f6_makes_creatures_passive() -> void:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	var arena: Node2D = ARENA.instantiate()
	tree.root.add_child(arena)
	var sim: CombatSim = arena.get("sim")
	arena.call("_unhandled_input", _key(KEY_F6))
	for creature: Fighter in sim.creatures:
		assert_false(creature.ai_enabled, "passive after F6")
	arena.call("_unhandled_input", _key(KEY_F5))
	assert_false(arena.get("render_interpolation"), "F5 turns render interpolation off")
	arena.queue_free()
	await tree.process_frame


func test_arena_is_reachable_with_f2_and_launch_option() -> void:
	var tools: GDScript = preload("res://src/core/dev_tools.gd")
	var scenes: Dictionary = tools.get("SHOWCASE_SCENES")
	assert_eq(scenes.get("combat_arena", ""), "res://scenes/combat/combat_arena.tscn", "in the F2 list")
	var options: Dictionary = tools.call("parse_args", PackedStringArray(["--start-scene", "combat_arena"]))
	assert_eq(options["start_scene"], "combat_arena", "--start-scene combat_arena")


# --- Haptics --------------------------------------------------------------------

func _haptics(calls: Array[Array]) -> Haptics:
	var haptics: Haptics = Haptics.new()
	haptics.devices = func() -> Array[int]: return [0, 2]
	haptics.rumble = func(device: int, weak: float, strong: float, seconds: float) -> void:
		calls.append([device, weak, strong, seconds])
	return haptics


func test_haptics_rumble_every_connected_controller() -> void:
	var calls: Array[Array] = []
	_haptics(calls).play(&"impact")
	assert_eq(calls.size(), 2, "both controllers")
	assert_eq(calls[0], [0, 0.4, 1.0, 0.16], "impact values on controller 0")
	assert_eq(calls[1][0], 2, "controller 2")


func test_haptics_intensity_scales_and_zero_is_off() -> void:
	var calls: Array[Array] = []
	var haptics: Haptics = _haptics(calls)
	haptics.intensity = 0.5
	haptics.play(&"impact")
	assert_eq(calls[0], [0, 0.2, 0.5, 0.16], "half intensity")
	calls.clear()
	haptics.intensity = 0.0
	haptics.play(&"impact")
	assert_eq(calls.size(), 0, "off")


func test_combat_events_map_to_haptic_effects() -> void:
	var player: Fighter = Fighter.make_player(Vector2.ZERO)
	var creature: Fighter = Fighter.make_creature(Vector2.ZERO)
	assert_eq(Haptics.effect_for_event({"type": "hit", "target": creature, "move": &"light_1"}), &"greatsword_hit", "light hit")
	assert_eq(Haptics.effect_for_event({"type": "hit", "target": creature, "move": &"cleave"}), &"greatsword_heavy_hit", "heavy hit")
	assert_eq(Haptics.effect_for_event({"type": "hit", "target": player, "move": &"creature_lunge"}), &"player_hit", "player hit")
	assert_eq(Haptics.effect_for_event({"type": "impact", "fighter": creature}), &"impact", "impact")
	assert_eq(Haptics.effect_for_event({"type": "stagger", "fighter": creature}), &"stagger", "creature stagger")
	assert_eq(Haptics.effect_for_event({"type": "dodge"}), &"", "no rumble for a dodge")
	for effect: StringName in [&"greatsword_hit", &"greatsword_heavy_hit", &"player_hit", &"impact", &"stagger"]:
		assert_true(Haptics.EFFECTS.has(effect), "%s is defined" % effect)
