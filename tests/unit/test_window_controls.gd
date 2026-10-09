extends TestCase
## Q6d: Alt+Enter (Windows, Linux) and Ctrl+Cmd+F (macOS) toggle fullscreen.

const WindowControls: GDScript = preload("res://src/core/window_controls.gd")


func _key(keycode: Key, alt: bool = false, ctrl: bool = false, meta: bool = false,
		echo: bool = false) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = keycode
	event.alt_pressed = alt
	event.ctrl_pressed = ctrl
	event.meta_pressed = meta
	event.pressed = true
	event.echo = echo
	return event


func test_project_defines_both_actions() -> void:
	assert_true(InputMap.has_action(WindowControls.ACTION_DEFAULT), "toggle_fullscreen exists")
	assert_true(InputMap.has_action(WindowControls.ACTION_MACOS), "toggle_fullscreen_macos exists")


func test_autoload_is_registered() -> void:
	assert_eq(ProjectSettings.get_setting("autoload/WindowControls", ""),
		"*res://src/core/window_controls.gd", "WindowControls autoload")


func test_alt_enter_on_windows_and_linux() -> void:
	for platform: String in ["Windows", "Linux"]:
		assert_true(WindowControls.is_toggle_event(_key(KEY_ENTER, true), platform), "Alt+Enter on " + platform)
		assert_true(WindowControls.is_toggle_event(_key(KEY_KP_ENTER, true), platform),
			"Alt+keypad Enter on " + platform)
		assert_false(WindowControls.is_toggle_event(_key(KEY_F, false, true, true), platform),
			"Ctrl+Cmd+F does nothing on " + platform)


func test_ctrl_cmd_f_on_macos_only() -> void:
	assert_true(WindowControls.is_toggle_event(_key(KEY_F, false, true, true), "macOS"), "Ctrl+Cmd+F on macOS")
	assert_false(WindowControls.is_toggle_event(_key(KEY_ENTER, true), "macOS"), "Alt+Enter does nothing on macOS")


func test_plain_keys_and_key_repeat_do_not_toggle() -> void:
	assert_false(WindowControls.is_toggle_event(_key(KEY_ENTER), "Windows"), "plain Enter")
	assert_false(WindowControls.is_toggle_event(_key(KEY_F, false, true), "macOS"), "Ctrl+F without Cmd")
	assert_false(WindowControls.is_toggle_event(_key(KEY_ENTER, true, false, false, true), "Windows"),
		"held-down repeat of Alt+Enter")


func test_toggled_mode() -> void:
	assert_eq(WindowControls.toggled_mode(DisplayServer.WINDOW_MODE_FULLSCREEN),
		DisplayServer.WINDOW_MODE_WINDOWED, "fullscreen -> windowed")
	assert_eq(WindowControls.toggled_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN),
		DisplayServer.WINDOW_MODE_WINDOWED, "exclusive fullscreen -> windowed")
	assert_eq(WindowControls.toggled_mode(DisplayServer.WINDOW_MODE_WINDOWED),
		DisplayServer.WINDOW_MODE_FULLSCREEN, "windowed -> fullscreen")
	assert_eq(WindowControls.toggled_mode(DisplayServer.WINDOW_MODE_MAXIMIZED),
		DisplayServer.WINDOW_MODE_FULLSCREEN, "maximized -> fullscreen")


func test_shortcut_switches_the_window_twice() -> void:
	var controls: Node = WindowControls.new()
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	tree.root.add_child(controls)
	var mode: Array[DisplayServer.WindowMode] = [DisplayServer.WINDOW_MODE_FULLSCREEN]
	controls.set("os_name", "Windows")
	controls.set("get_window_mode", func() -> DisplayServer.WindowMode: return mode[0])
	controls.set("set_window_mode", func(m: DisplayServer.WindowMode) -> void: mode[0] = m)
	controls.call("_input", _key(KEY_ENTER, true))
	assert_eq(mode[0], DisplayServer.WINDOW_MODE_WINDOWED, "first press leaves fullscreen")
	controls.call("_input", _key(KEY_ENTER, true))
	assert_eq(mode[0], DisplayServer.WINDOW_MODE_FULLSCREEN, "second press returns to fullscreen")
	controls.call("_input", _key(KEY_ENTER))
	assert_eq(mode[0], DisplayServer.WINDOW_MODE_FULLSCREEN, "plain Enter changes nothing")
	controls.queue_free()
