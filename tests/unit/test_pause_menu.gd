extends TestCase
## The pause menu (Esc / Start): it stops the whole game, says when it was
## last saved, asks before leaving, and is in every place.

const SCENES: Array[String] = [
	"res://scenes/farm/farm.tscn",
	"res://scenes/farm/house.tscn",
	"res://scenes/world/millbrook.tscn",
]


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _open_place(path: String, state: GameState) -> Node:
	GameState.current = state
	var scene: Node = (load(path) as PackedScene).instantiate()
	scene.set("travels", false)
	_tree().root.add_child(scene)
	var menu: PauseMenu = scene.get("pause_menu")
	menu.travels = false
	return scene


func _press(menu: PauseMenu, action: StringName) -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = true
	menu._unhandled_input(event)


func _close_place(scene: Node) -> void:
	_tree().paused = false
	scene.queue_free()
	await _tree().process_frame
	GameState.current = null


func _buttons(menu: PauseMenu) -> Dictionary:
	var found: Dictionary = {}
	for b: Node in menu.find_children("*", "Button", true, false):
		found[(b as Button).text] = b
	return found


func _text(menu: PauseMenu) -> String:
	var text: String = ""
	for l: Node in menu.find_children("*", "Label", true, false):
		if (l as Label).is_visible_in_tree():
			text += (l as Label).text + "\n"
	return text


func test_esc_and_start_pause_on_every_controller() -> void:
	var esc: InputEventKey = InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	assert_true(InputMap.event_is_action(esc, &"pause"), "Esc")
	var start: InputEventJoypadButton = InputEventJoypadButton.new()
	start.button_index = JOY_BUTTON_START
	start.device = 1  # not only the first controller
	start.pressed = true
	assert_true(InputMap.event_is_action(start, &"pause"), "Start")


func test_every_place_pauses_and_time_stands_still() -> void:
	for path: String in SCENES:
		var scene: Node = _open_place(path, GameState.new_game())
		var menu: PauseMenu = scene.get("pause_menu")
		var state: GameState = scene.get("state")
		await _tree().physics_frame
		_press(menu, &"pause")
		assert_true(menu.is_open(), "%s: open" % path)
		assert_true(_tree().paused, "%s: the game stops" % path)
		assert_true((_buttons(menu)["Resume"] as Button).has_focus(), "%s: Resume is chosen" % path)
		var minutes: float = state.clock.total_minutes
		for i: int in range(10):
			await _tree().physics_frame
		assert_eq(state.clock.total_minutes, minutes, "%s: the clock stands still" % path)
		_press(menu, &"pause")
		assert_false(menu.is_open(), "%s: Esc / Start again closes it" % path)
		assert_false(_tree().paused, "%s: and the game runs" % path)
		for i: int in range(3):
			await _tree().physics_frame
		assert_true(state.clock.total_minutes > minutes, "%s: the clock runs again" % path)
		await _close_place(scene)


func test_b_and_resume_close_it() -> void:
	var scene: Node = _open_place(SCENES[0], GameState.new_game())
	var menu: PauseMenu = scene.get("pause_menu")
	menu.open()
	_press(menu, &"ui_cancel")
	assert_false(menu.is_open(), "B / Esc closes")
	menu.open()
	(_buttons(menu)["Resume"] as Button).pressed.emit()
	assert_false(menu.is_open(), "Resume closes")
	assert_false(_tree().paused, "running")
	await _close_place(scene)


func test_it_says_when_the_game_was_last_saved() -> void:
	var state: GameState = GameState.new_game()
	state.save_path = "user://test_pause_save.json"
	state.save()
	var scene: Node = _open_place(SCENES[1], state)
	var menu: PauseMenu = scene.get("pause_menu")
	menu.open()
	assert_true(_text(menu).contains("Last saved: Day 1, 06:00, in the farmhouse."), _text(menu))
	menu.close()
	await _close_place(scene)
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_pause_save.json"))
	var alone: Node = _open_place(SCENES[0], GameState.new_game())
	var alone_menu: PauseMenu = alone.get("pause_menu")
	alone_menu.open()
	assert_true(_text(alone_menu).contains("not saved"), "a game opened on its own says so: %s" % _text(alone_menu))
	await _close_place(alone)


func test_back_to_title_asks_first() -> void:
	var state: GameState = GameState.new_game()
	var scene: Node = _open_place(SCENES[2], state)
	var menu: PauseMenu = scene.get("pause_menu")
	var went: Array[bool] = []
	menu.to_title.connect(func() -> void: went.append(true))
	menu.open()
	(_buttons(menu)["Back to title"] as Button).pressed.emit()
	assert_true(_text(menu).contains("Anything since the last save is lost."), "it warns")
	assert_true((_buttons(menu)["Keep playing"] as Button).has_focus(), "the safe answer first")
	assert_eq(went.size(), 0, "not yet")
	_press(menu, &"ui_cancel")
	assert_true((_buttons(menu)["Resume"] as Button).has_focus(), "B goes back to the menu")
	assert_true(menu.is_open(), "still paused")
	(_buttons(menu)["Back to title"] as Button).pressed.emit()
	(_buttons(menu)["Leave"] as Button).pressed.emit()
	assert_eq(went.size(), 1, "to the title")
	assert_false(_tree().paused, "unpaused for the title")
	assert_eq(GameState.current, null, "the game is put down")
	_press(menu, &"pause")
	assert_false(menu.is_open(), "and it cannot be opened again on the way out")
	await _close_place(scene)


func test_quit_asks_first() -> void:
	if OS.has_feature("web"):
		return
	var scene: Node = _open_place(SCENES[0], GameState.new_game())
	var menu: PauseMenu = scene.get("pause_menu")
	var quit: Array[bool] = []
	menu.quitting.connect(func() -> void: quit.append(true))
	menu.open()
	(_buttons(menu)["Quit"] as Button).pressed.emit()
	assert_eq(quit.size(), 0, "asks first")
	(_buttons(menu)["Leave"] as Button).pressed.emit()
	assert_eq(quit.size(), 1, "then quits")
	await _close_place(scene)


func test_no_pausing_while_leaving_a_place() -> void:
	var scene: Node = _open_place(SCENES[0], GameState.new_game())
	var menu: PauseMenu = scene.get("pause_menu")
	scene.call("leave", GameState.HOUSE)
	_press(menu, &"pause")
	assert_false(menu.is_open(), "not during the fade")
	menu.open()
	assert_false(menu.is_open(), "not even when asked directly")
	assert_false(_tree().paused, "running")
	await _close_place(scene)


func test_a_place_freed_while_paused_lets_the_game_run() -> void:
	# The review scene opens its menu; loading every scene once left the
	# whole test run paused.
	var scene: Node = _open_place(SCENES[0], GameState.new_game())
	(scene.get("pause_menu") as PauseMenu).open()
	assert_true(_tree().paused, "paused")
	scene.queue_free()
	await _tree().process_frame
	assert_false(_tree().paused, "running again once the place is gone")
	GameState.current = null
