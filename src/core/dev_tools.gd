extends Node
## Developer tools for performance checks (autoload "DevTools"; Q16).
##
## - F3, or both stick buttons together on a controller: show or hide the
##   performance overlay.
## - F2: switch between the showcase scenes (boot, test card, renderer
##   features, combat arena), so devices can be measured on something heavier
##   than the title.
## - F4: V-Sync on/off. With V-Sync on, the frame rate is capped at the
##   screen's refresh rate; off shows the real headroom.
## - Launch options (after `--` on the command line, or in Steam's launch
##   options): `--perf-overlay`, `--start-scene <boot|test_card|renderer_features|combat_arena>`,
##   `--no-vsync`. (`--scene` is already used by the render tool.)
##
## Available in every build: the lead tests release builds on real devices.

const ACTION_OVERLAY: StringName = &"dev_toggle_perf_overlay"
const ACTION_NEXT_SCENE: StringName = &"dev_next_showcase_scene"
const ACTION_VSYNC: StringName = &"dev_toggle_vsync"
const SHOWCASE_SCENES: Dictionary = {
	"boot": "res://scenes/boot/boot.tscn",
	"test_card": "res://scenes/showcase/test_card.tscn",
	"renderer_features": "res://scenes/showcase/renderer_features.tscn",
	"combat_arena": "res://scenes/combat/combat_arena.tscn",
}
const REFRESH_SECONDS: float = 0.25

var stats: FrameStats = FrameStats.new()
var _layer: CanvasLayer
var _label: Label
var _since_refresh: float = REFRESH_SECONDS  # first frame refreshes at once
var _scene_index: int = 0
var _sticks_were_down: bool = false


## Reads the launch options this tool understands.
static func parse_args(args: PackedStringArray) -> Dictionary:
	var options: Dictionary = {"overlay": false, "start_scene": "", "vsync": true}
	for i: int in range(args.size()):
		match args[i]:
			"--perf-overlay":
				options["overlay"] = true
			"--no-vsync":
				options["vsync"] = false
			"--start-scene":
				if i + 1 < args.size() and SHOWCASE_SCENES.has(args[i + 1]):
					options["start_scene"] = args[i + 1]
	return options


## The overlay text for one set of measurements (all times in milliseconds).
static func format_report(m: Dictionary) -> String:
	var refresh: float = m.get("refresh_hz", 0.0)
	var refresh_text: String = "%d Hz" % roundi(refresh) if refresh > 0.0 and not is_nan(refresh) else "unknown Hz"
	return "\n".join([
		"FPS %d   frame avg %.2f ms   max %.2f ms   over 8.33 ms budget: %d of %d frames" % [
			roundi(m["fps"]), m["frame_avg_ms"], m["frame_max_ms"], m["over_budget"], m["frames"]],
		"logic %.2f ms   physics %.2f ms   render CPU %.2f ms   render GPU %.2f ms" % [
			m["process_ms"], m["physics_ms"], m["render_cpu_ms"], m["render_gpu_ms"]],
		"memory %d MB   video memory %d MB   draw calls %d" % [
			roundi(m["memory_mb"]), roundi(m["video_memory_mb"]), m["draw_calls"]],
		"screen %dx%d at %dx   view %dx%d   V-Sync %s   %s" % [
			m["window"].x, m["window"].y, m["scale"], m["view"].x, m["view"].y,
			"on" if m["vsync"] else "off", refresh_text],
		"%s %s | %s (%d threads) | %s | %s" % [
			m["os"], m["arch"], m["cpu"], m["threads"], m["gpu"], m["renderer"]],
		"%s   scene: %s   F2 next scene, F3 hide, F4 V-Sync" % [m["build"], m["scene"]],
	])


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	_build_overlay()
	var options: Dictionary = parse_args(OS.get_cmdline_user_args())
	_layer.visible = options["overlay"]
	if not options["vsync"]:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	if not str(options["start_scene"]).is_empty():
		_scene_index = SHOWCASE_SCENES.keys().find(options["start_scene"])
		get_tree().change_scene_to_file.call_deferred(SHOWCASE_SCENES[options["start_scene"]])


func _build_overlay() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 100
	add_child(_layer)
	var frame: UiFrame = UiFrame.new()
	_layer.add_child(frame)
	var panel: PanelContainer = PanelContainer.new()
	panel.position = Vector2(4, 4)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(Palette.SHADOW[0], 0.85)
	style.set_content_margin_all(3)
	panel.add_theme_stylebox_override("panel", style)
	frame.add_child(panel)
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 6)
	_label.add_theme_color_override("font_color", Palette.PAPER[1])
	panel.add_child(_label)


func _process(delta: float) -> void:
	stats.add(delta * 1000.0)
	_since_refresh += delta
	if _layer.visible and _since_refresh >= REFRESH_SECONDS:
		_since_refresh = 0.0
		_label.text = format_report(_measure())


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(ACTION_OVERLAY, false) or _sticks_pressed_together(event):
		_layer.visible = not _layer.visible
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(ACTION_NEXT_SCENE, false):
		_scene_index = (_scene_index + 1) % SHOWCASE_SCENES.size()
		get_tree().change_scene_to_file(SHOWCASE_SCENES.values()[_scene_index])
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(ACTION_VSYNC, false):
		var on: bool = DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED if on else DisplayServer.VSYNC_ENABLED)
		get_viewport().set_input_as_handled()


## True once when both stick buttons become held on the same controller.
func _sticks_pressed_together(event: InputEvent) -> bool:
	if not event is InputEventJoypadButton:
		return false
	var device: int = event.device
	var both: bool = Input.is_joy_button_pressed(device, JOY_BUTTON_LEFT_STICK) \
		and Input.is_joy_button_pressed(device, JOY_BUTTON_RIGHT_STICK)
	var fire: bool = both and not _sticks_were_down
	_sticks_were_down = both
	return fire


func _measure() -> Dictionary:
	var rid: RID = get_viewport().get_viewport_rid()
	var window: Vector2i = DisplayServer.window_get_size()
	var scene: Node = get_tree().current_scene
	return {
		"fps": Performance.get_monitor(Performance.TIME_FPS),
		"frame_avg_ms": stats.average_ms(),
		"frame_max_ms": stats.max_ms(),
		"over_budget": stats.over_budget(),
		"frames": stats.count(),
		"process_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		"physics_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		"render_cpu_ms": RenderingServer.viewport_get_measured_render_time_cpu(rid),
		"render_gpu_ms": RenderingServer.viewport_get_measured_render_time_gpu(rid),
		"memory_mb": Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		"video_memory_mb": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
		"draw_calls": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		"window": window,
		"scale": DisplayMath.expected_scale(window),
		"view": Vector2i(get_viewport().get_visible_rect().size),
		"vsync": DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED,
		"refresh_hz": DisplayServer.screen_get_refresh_rate(),
		"os": OS.get_name(),
		"arch": Engine.get_architecture_name(),
		"cpu": OS.get_processor_name(),
		"threads": OS.get_processor_count(),
		"gpu": RenderingServer.get_video_adapter_name(),
		"renderer": RenderingServer.get_current_rendering_method(),
		"build": BuildInfo.label(),
		"scene": scene.scene_file_path.get_file() if scene != null else "none",
	}
