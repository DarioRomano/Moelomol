extends TestCase
## Q16: the performance overlay and its controls.

const DevTools: GDScript = preload("res://src/core/dev_tools.gd")


func _key(keycode: Key) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	return event


func _sample() -> Dictionary:
	return {
		"fps": 118.6, "frame_avg_ms": 8.43, "frame_max_ms": 9.12, "over_budget": 7, "frames": 120,
		"process_ms": 0.41, "physics_ms": 0.12, "render_cpu_ms": 0.2, "render_gpu_ms": 0.55,
		"memory_mb": 31.4, "video_memory_mb": 7.9, "draw_calls": 12,
		"window": Vector2i(1920, 1080), "scale": 3, "view": Vector2i(640, 360),
		"vsync": true, "refresh_hz": 119.96, "os": "Linux", "arch": "arm64",
		"cpu": "Snapdragon", "threads": 8, "gpu": "Adreno", "renderer": "gl_compatibility",
		"build": "v0.1.0 build 9 (abc1234)", "scene": "renderer_features.tscn",
	}


func test_frame_stats_average_max_and_budget() -> void:
	var stats: FrameStats = FrameStats.new()
	for ms: float in [8.0, 8.0, 10.0, 6.0]:
		stats.add(ms)
	assert_eq(stats.count(), 4, "count")
	assert_eq(stats.average_ms(), 8.0, "average")
	assert_eq(stats.max_ms(), 10.0, "max")
	assert_eq(stats.over_budget(), 1, "frames over 8.33 ms")


func test_frame_stats_keeps_only_the_last_window() -> void:
	var stats: FrameStats = FrameStats.new()
	stats.add(50.0)
	for i: int in range(FrameStats.WINDOW):
		stats.add(5.0)
	assert_eq(stats.count(), FrameStats.WINDOW, "window size")
	assert_eq(stats.max_ms(), 5.0, "the old 50 ms frame has dropped out")


func test_empty_stats_are_zero() -> void:
	var stats: FrameStats = FrameStats.new()
	assert_eq(stats.average_ms(), 0.0, "average of nothing")
	assert_eq(stats.max_ms(), 0.0, "max of nothing")


func test_launch_options() -> void:
	var none: Dictionary = DevTools.parse_args(PackedStringArray())
	assert_eq(none, {"overlay": false, "start_scene": "", "vsync": true}, "defaults")
	var all: Dictionary = DevTools.parse_args(PackedStringArray(
		["--perf-overlay", "--start-scene", "renderer_features", "--no-vsync"]))
	assert_eq(all, {"overlay": true, "start_scene": "renderer_features", "vsync": false}, "all options")
	assert_eq(DevTools.parse_args(PackedStringArray(["--start-scene", "nowhere"]))["start_scene"], "",
		"unknown scene ignored")
	assert_eq(DevTools.parse_args(PackedStringArray(["--scene", "test_card"]))["start_scene"], "",
		"the render tool's --scene is not ours")


func test_report_contains_every_measurement() -> void:
	var text: String = DevTools.format_report(_sample())
	for expected: String in ["FPS 119", "avg 8.43 ms", "max 9.12 ms", "7 of 120", "logic 0.41 ms",
			"render GPU 0.55 ms", "memory 31 MB", "draw calls 12", "screen 1920x1080 at 3x",
			"V-Sync on", "120 Hz", "Linux arm64", "Snapdragon (8 threads)", "Adreno",
			"gl_compatibility", "build 9", "renderer_features.tscn"]:
		assert_true(text.contains(expected), "report shows '%s'" % expected)


func test_report_survives_unknown_refresh_rate() -> void:
	var sample: Dictionary = _sample()
	sample["refresh_hz"] = NAN  # seen under the virtual display
	assert_true(DevTools.format_report(sample).contains("unknown Hz"), "NaN refresh rate")


func test_autoload_and_keys_are_registered() -> void:
	assert_eq(ProjectSettings.get_setting("autoload/DevTools", ""), "*res://src/core/dev_tools.gd", "autoload")
	var expected: Dictionary = {
		DevTools.ACTION_OVERLAY: KEY_F3, DevTools.ACTION_NEXT_SCENE: KEY_F2, DevTools.ACTION_VSYNC: KEY_F4}
	for action: StringName in expected:
		assert_true(InputMap.event_is_action(_key(expected[action]), action), "%s is on its F key" % action)


func test_f3_toggles_the_overlay() -> void:
	var tools: Node = DevTools.new()
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	tree.root.add_child(tools)
	var layer: CanvasLayer = tools.get("_layer")
	assert_false(layer.visible, "hidden by default")
	tools.call("_input", _key(KEY_F3))
	assert_true(layer.visible, "shown after F3")
	tools.call("_input", _key(KEY_F3))
	assert_false(layer.visible, "hidden after second F3")
	tools.queue_free()
	await tree.process_frame
