extends TestCase
## Q15: the world fills the screen; HUD and menus can be held to a 21:9 or
## 16:9 frame. Covers GameSettings (saving and loading the choice) and UiFrame
## (where the frame ends up).

const TEMP: String = "user://test_settings.cfg"
const FULL: GameSettings.UiWidth = GameSettings.UiWidth.FULL
const W21: GameSettings.UiWidth = GameSettings.UiWidth.WIDE_21_9
const W16: GameSettings.UiWidth = GameSettings.UiWidth.WIDE_16_9


func after_each() -> void:
	if FileAccess.file_exists(TEMP):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP))


func _frame(view: Vector2i, width: GameSettings.UiWidth) -> Rect2i:
	return UiFrame.frame_rect(view, width)


func test_full_width_is_the_whole_view() -> void:
	assert_eq(_frame(Vector2i(1280, 360), FULL), Rect2i(0, 0, 1280, 360), "32:9 full")
	assert_eq(_frame(Vector2i(640, 360), FULL), Rect2i(0, 0, 640, 360), "16:9 full")


func test_super_ultrawide_frames() -> void:
	assert_eq(_frame(Vector2i(1280, 360), W21), Rect2i(210, 0, 860, 360), "32:9 at 21:9")
	assert_eq(_frame(Vector2i(1280, 360), W16), Rect2i(320, 0, 640, 360), "32:9 at 16:9")


func test_21_9_setting_changes_nothing_on_real_21_9_screens() -> void:
	# 3440x1440 shows 860x360, 2560x1080 shows 853x360 (ADR-0008).
	assert_eq(_frame(Vector2i(860, 360), W21), Rect2i(0, 0, 860, 360), "3440x1440")
	assert_eq(_frame(Vector2i(853, 360), W21), Rect2i(0, 0, 853, 360), "2560x1080")
	assert_eq(_frame(Vector2i(860, 360), W16), Rect2i(110, 0, 640, 360), "3440x1440 at 16:9")


func test_narrower_screens_are_never_narrowed() -> void:
	assert_eq(_frame(Vector2i(640, 400), W16), Rect2i(0, 0, 640, 400), "16:10")
	assert_eq(_frame(Vector2i(640, 480), W16), Rect2i(0, 0, 640, 480), "4:3")


func test_default_is_full() -> void:
	assert_eq(GameSettings.new().ui_width, FULL, "default UI width")


func test_choice_survives_save_and_load() -> void:
	var saved: GameSettings = GameSettings.new()
	saved.set_ui_width(W16)
	assert_eq(saved.save_to(TEMP), OK, "save")
	var loaded: GameSettings = GameSettings.new()
	loaded.load_from(TEMP)
	assert_eq(loaded.ui_width, W16, "loaded UI width")


func test_file_uses_readable_names() -> void:
	var settings: GameSettings = GameSettings.new()
	settings.set_ui_width(W21)
	settings.save_to(TEMP)
	assert_true(FileAccess.get_file_as_string(TEMP).contains('ui_width="21:9"'), "file says 21:9")


func test_unknown_value_falls_back_to_full() -> void:
	var file: FileAccess = FileAccess.open(TEMP, FileAccess.WRITE)
	file.store_string('[display]\nui_width="ultra"\n')
	file.close()
	var settings: GameSettings = GameSettings.new()
	settings.set_ui_width(W16)
	settings.load_from(TEMP)
	assert_eq(settings.ui_width, FULL, "unknown value")


func test_missing_file_keeps_defaults() -> void:
	var settings: GameSettings = GameSettings.new()
	settings.load_from("user://no_such_settings.cfg")
	assert_eq(settings.ui_width, FULL, "missing file")


func test_change_is_announced_once() -> void:
	var settings: GameSettings = GameSettings.new()
	var count: Array[int] = [0]
	settings.changed.connect(func() -> void: count[0] += 1)
	settings.set_ui_width(W21)
	settings.set_ui_width(W21)
	assert_eq(count[0], 1, "changed emitted once for one real change")


func test_frame_follows_the_setting_in_a_real_viewport() -> void:
	# A 1280x360 viewport stands in for a 32:9 screen.
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(1280, 360)
	tree.root.add_child(viewport)
	var holder: Control = Control.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport.add_child(holder)
	var frame: UiFrame = UiFrame.new()
	frame.settings = GameSettings.new()
	holder.add_child(frame)
	await tree.process_frame
	assert_eq(Rect2i(frame.get_global_rect()), Rect2i(0, 0, 1280, 360), "full")
	frame.settings.set_ui_width(W16)
	await tree.process_frame
	assert_eq(Rect2i(frame.get_global_rect()), Rect2i(320, 0, 640, 360), "after switching to 16:9")
	viewport.queue_free()
	await tree.process_frame


func test_test_card_hud_fills_its_frame() -> void:
	# Found in the renders, 2026-10-09: the HUD corner layer used
	# set_anchors_preset(), which keeps a new control's zero size, so only one
	# corner marker showed. Tests on frame_rect alone could not see it.
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	var shared: GameSettings = GameSettings.shared()
	var previous: GameSettings.UiWidth = shared.ui_width
	shared.set_ui_width(W16)
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(1280, 360)
	tree.root.add_child(viewport)
	var card: Control = (load("res://scenes/showcase/test_card.tscn") as PackedScene).instantiate()
	viewport.add_child(card)
	await tree.process_frame
	await tree.process_frame
	var frame: UiFrame = null
	for child: Node in card.get_children():
		if child is UiFrame:
			frame = child
	assert_true(frame != null, "test card has a UiFrame")
	if frame != null:
		assert_eq(Rect2i(frame.get_global_rect()), Rect2i(320, 0, 640, 360), "HUD frame at 16:9")
		var layers: int = 0
		for child: Node in frame.get_children():
			if child is Control and not child is Label:
				layers += 1
				assert_eq(Vector2i((child as Control).size), Vector2i(640, 360), "corner layer fills the frame")
		assert_eq(layers, 1, "one full-frame layer (the corners) besides the labels")
	shared.set_ui_width(previous)
	viewport.queue_free()
	await tree.process_frame
