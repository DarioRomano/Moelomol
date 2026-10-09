extends SceneTree
## Renders one scene in a real window and saves what the window shows, after
## stretch and scaling, to a PNG. Run through tools/render-showcase.sh, which
## provides a virtual display of the right size.
##
##   godot --path . --resolution 1366x768 --position 0,0 \
##     -s res://tools/render_showcase.gd -- --scene res://... --out /abs/file.png \
##     [--ui-width full|21:9|16:9]
##
## It also checks that the visible game area matches DisplayMath (ADR-0008)
## and exits 4 if it does not, so a display-setting regression fails CI even
## if nobody looks at the image. With --check-window-mode it also checks the
## window mode matches the project setting (exit 5), e.g. fullscreen (Q12).
## If the scene has render_checks(image, layout_to_screen), its problems fail
## the render (exit 6).

const SETTLE_FRAMES: int = 10


func _initialize() -> void:
	_render.call_deferred()


func _render() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var scene_path: String = _arg(args, "--scene")
	var out_path: String = _arg(args, "--out")
	if scene_path.is_empty() or out_path.is_empty():
		printerr("render_showcase ERROR: need --scene and --out")
		quit(2)
		return
	var ui_width_text: String = _arg(args, "--ui-width")
	if not ui_width_text.is_empty():
		var ui_width: int = GameSettings.parse_ui_width(ui_width_text)
		if ui_width < 0:
			printerr("render_showcase ERROR: unknown --ui-width '%s'" % ui_width_text)
			quit(2)
			return
		GameSettings.shared().set_ui_width(ui_width as GameSettings.UiWidth)
	var packed: PackedScene = load(scene_path) as PackedScene
	if packed == null:
		printerr("render_showcase ERROR: cannot load %s" % scene_path)
		quit(2)
		return
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	for i: int in range(SETTLE_FRAMES):
		await process_frame
	await RenderingServer.frame_post_draw
	# screen_get_image_rect() returns an empty image under Xvfb in 4.7.2
	# (verified 2026-10-09); capture the whole screen and crop to the window.
	var window_rect: Rect2i = Rect2i(DisplayServer.window_get_position(), DisplayServer.window_get_size())
	var screen: Image = DisplayServer.screen_get_image(DisplayServer.window_get_current_screen())
	var image: Image = null
	if screen != null and not screen.is_empty():
		image = screen.get_region(window_rect.intersection(Rect2i(Vector2i.ZERO, screen.get_size())))
	if image == null or image.is_empty():
		printerr("render_showcase ERROR: screen capture returned nothing")
		quit(3)
		return
	var error: Error = image.save_png(out_path)
	if error != OK:
		printerr("render_showcase ERROR: cannot save %s (%s)" % [out_path, error_string(error)])
		quit(3)
		return
	var view: Vector2i = Vector2i(root.get_visible_rect().size)
	var expected: Vector2i = DisplayMath.expected_view_size(window_rect.size)
	print("render_showcase: %s -> %s (window %dx%d, view %dx%d, mode %d)" % [
		scene_path, out_path, image.get_width(), image.get_height(), view.x, view.y,
		DisplayServer.window_get_mode()])
	if view != expected:
		printerr("render_showcase ERROR: view %dx%d at window %dx%d, DisplayMath expects %dx%d" % [
			view.x, view.y, window_rect.size.x, window_rect.size.y, expected.x, expected.y])
		quit(4)
		return
	# Scene-specific checks on the captured image (e.g. the test card's
	# full-resolution marker). Exit 6 on any problem.
	if scene.has_method("render_checks"):
		var problems: Array = scene.call("render_checks", image, root.get_final_transform())
		for problem: Variant in problems:
			printerr("render_showcase ERROR: %s: %s" % [scene_path, problem])
		if not problems.is_empty():
			quit(6)
			return
	# X11 only reports fullscreen when a window manager is running, so the
	# shell script passes --check-window-mode only when it started one.
	if args.has("--check-window-mode"):
		var wanted: int = ProjectSettings.get_setting("display/window/size/mode")
		if DisplayServer.window_get_mode() != wanted:
			printerr("render_showcase ERROR: window mode %d, project setting is %d" % [
				DisplayServer.window_get_mode(), wanted])
			quit(5)
			return
	quit(0)


func _arg(args: PackedStringArray, name: String) -> String:
	var index: int = args.find(name)
	return args[index + 1] if index >= 0 and index + 1 < args.size() else ""
