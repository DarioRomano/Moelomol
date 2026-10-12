extends Control
## The title screen, the game's main scene: Continue (the one save, ADR-0017)
## or a new game at the farm, and Quit. Keyboard, mouse and controller
## (ADR-0013): arrows / W S / D-pad / stick to choose, Enter / Space / A to
## press, Escape / B to go back.
##
## Behind the menu, drawn in code (placeholder): the farmhouse on its hill
## at dusk, one window lit, and the cat on the roof.
##
## F2 still cycles the test scenes (DevTools).

## Emitted when a game starts; the fade to its place follows unless
## `travels` is false (tests).
signal starting(state: GameState)

## The save this screen reads and new games write (tests use their own).
var save_path: String = GameState.SAVE_PATH
var travels: bool = true

var _saved: GameState = null
var _menu: VBoxContainer
var _continue: Button
var _new: Button
var _quit: Button
var _summary: Label
var _confirm: VBoxContainer
var _confirm_yes: Button
var _confirm_no: Button
var _started: bool = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var frame: UiFrame = UiFrame.new()
	add_child(frame)
	var column: VBoxContainer = VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE)
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.position.y = 64
	column.alignment = BoxContainer.ALIGNMENT_BEGIN
	column.add_theme_constant_override("separation", 2)
	frame.add_child(column)
	var title: Label = _label("MOELOMOL", 32, Palette.WARMTH[3])
	column.add_child(title)
	_summary = _label("", 7, Palette.PAPER[0])
	column.add_child(_summary)
	column.add_child(_spacer(14))
	_menu = VBoxContainer.new()
	_menu.add_theme_constant_override("separation", 1)
	column.add_child(_menu)
	_continue = _button("Continue", _on_continue)
	_new = _button("New game", _on_new)
	_quit = _button("Quit", func() -> void: get_tree().quit())
	for b: Button in [_continue, _new, _quit]:
		_menu.add_child(b)
	_quit.visible = not OS.has_feature("web")  # a web page cannot quit
	_confirm = VBoxContainer.new()
	_confirm.add_theme_constant_override("separation", 1)
	_confirm.visible = false
	column.add_child(_confirm)
	_confirm.add_child(_label("Start a new farm? The saved one will be lost.", 8, Palette.PAPER[1]))
	_confirm.add_child(_spacer(4))
	_confirm_yes = _button("Start anew", start_new_game)
	_confirm_no = _button("Keep it", close_confirm)
	_confirm.add_child(_confirm_yes)
	_confirm.add_child(_confirm_no)
	var hint: Label = _label("F2 test scenes   F3 performance", 6, Palette.STONE[1])
	hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 6)
	hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	frame.add_child(hint)
	refresh()


## Reads the save again and sets the menu to match.
func refresh() -> void:
	var exists: bool = GameState.has_save(save_path)
	_saved = GameState.load_from(save_path) if exists else null
	_continue.visible = exists
	_continue.disabled = _saved == null
	if _saved != null:
		_summary.text = _saved.summary()
	elif exists:
		_summary.text = "The save could not be read: %s." % GameState.last_load_error
		push_warning("Title: %s" % GameState.last_load_error)
	else:
		_summary.text = ""
	(_continue if _saved != null else _new).grab_focus.call_deferred()


func _label(text: String, size: int, colour: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	label.add_theme_color_override("font_shadow_color", Palette.SHADOW[0])
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	return label


func _spacer(height: float) -> Control:
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	return spacer


## A quiet menu line: paper-coloured text, warm with a soft band when
## chosen (by keys, stick or mouse).
func _button(text: String, pressed: Callable) -> Button:
	var b: Button = Button.new()
	b.text = text
	b.flat = false
	b.custom_minimum_size = Vector2(120, 14)
	b.add_theme_font_size_override("font_size", 9)
	b.add_theme_color_override("font_color", Palette.PAPER[0])
	b.add_theme_color_override("font_hover_color", Palette.WARMTH[3])
	b.add_theme_color_override("font_focus_color", Palette.WARMTH[3])
	b.add_theme_color_override("font_pressed_color", Palette.WARMTH[2])
	b.add_theme_color_override("font_disabled_color", Palette.STONE[0])
	var plain: StyleBoxEmpty = StyleBoxEmpty.new()
	var chosen: StyleBoxFlat = StyleBoxFlat.new()
	chosen.bg_color = Color(Palette.WARMTH[0], 0.45)
	chosen.border_color = Palette.WARMTH[2]
	chosen.border_width_left = 2
	for style: String in ["normal", "disabled"]:
		b.add_theme_stylebox_override(style, plain)
	for style: String in ["hover", "focus", "pressed"]:
		b.add_theme_stylebox_override(style, chosen)
	b.pressed.connect(pressed)
	b.mouse_entered.connect(func() -> void:
		if not b.disabled:
			b.grab_focus())
	return b


func _on_continue() -> void:
	if _saved != null:
		start(_saved)


func _on_new() -> void:
	if GameState.has_save(save_path):
		_menu.visible = false
		_confirm.visible = true
		_confirm_no.grab_focus()  # the safe choice first
	else:
		start_new_game()


func close_confirm() -> void:
	_confirm.visible = false
	_menu.visible = true
	_new.grab_focus()


## A new game at the farm, saved at once so Continue finds it.
func start_new_game() -> void:
	var state: GameState = GameState.new_game()
	state.save_path = save_path
	state.save()
	start(state)


## Plays `state`: the fade to its place.
func start(state: GameState) -> void:
	if _started:
		return
	_started = true
	GameState.current = state
	starting.emit(state)
	if travels:
		Fade.to_scene(get_tree(), state.scene_path(), Fade.colour_at(state.clock))


func is_confirming() -> bool:
	return _confirm.visible


func _unhandled_input(event: InputEvent) -> void:
	# W / S choose too (the arrows, D-pad and stick are the engine's ui_up and
	# ui_down, handled by the buttons before this).
	if event.is_action_pressed(&"move_up", false) and not event.is_action(&"ui_up"):
		_move_focus(SIDE_TOP)
	elif event.is_action_pressed(&"move_down", false) and not event.is_action(&"ui_down"):
		_move_focus(SIDE_BOTTOM)
	elif event.is_action_pressed(&"ui_cancel", false) and _confirm.visible:
		close_confirm()
	else:
		return
	get_viewport().set_input_as_handled()


func _move_focus(side: Side) -> void:
	var focused: Control = get_viewport().gui_get_focus_owner()
	if focused == null:
		return
	var next: Control = focused.find_valid_focus_neighbor(side)
	if next != null:
		next.grab_focus()


# --- The picture behind the menu ------------------------------------------------------

func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var size_now: Vector2 = size
	var horizon: float = size_now.y * 0.72
	# The dusk sky in bands: deep blue overhead, amber at the hill line.
	var bands: int = 12
	for i: int in range(bands):
		var t: float = float(i) / (bands - 1)
		var colour: Color = Palette.SHADOW[0].lerp(Palette.SHADOW[2], t * 0.8)
		if i >= bands - 3:
			colour = colour.lerp(Palette.WARMTH[0], float(i - (bands - 4)) / 4.0)
		draw_rect(Rect2(0, horizon * t, size_now.x, horizon / bands + 1), colour)
	# A few stars, fixed.
	for i: int in range(28):
		var x: float = fposmod(i * 97.3, 1.0 * 641) / 641.0 * size_now.x
		var y: float = fposmod(i * 53.7, 1.0 * 131) / 131.0 * horizon * 0.5
		draw_rect(Rect2(roundf(x), roundf(y), 1, 1), Color(Palette.PAPER[1], 0.35 + 0.3 * float(i % 3) / 2.0))
	# The hill and the farm on it.
	var ground: Color = Palette.SHADOW[0].lerp(Palette.WILD[0], 0.35)
	draw_rect(Rect2(0, horizon, size_now.x, size_now.y - horizon), ground)
	var hill: PackedVector2Array = PackedVector2Array()
	for i: int in range(33):
		var x: float = size_now.x * i / 32.0
		hill.append(Vector2(x, horizon - 18.0 * sin(PI * i / 32.0) - 4.0 * sin(i * 0.9)))
	hill.append(Vector2(size_now.x, size_now.y))
	hill.append(Vector2(0, size_now.y))
	draw_colored_polygon(hill, ground)
	var house: Vector2 = Vector2(roundf(size_now.x * 0.5) - 26, roundf(horizon) - 32)
	var dark: Color = Palette.SHADOW[0]
	draw_rect(Rect2(house + Vector2(0, 14), Vector2(52, 20)), dark)
	draw_colored_polygon(PackedVector2Array([house + Vector2(-5, 15), house + Vector2(26, -2), house + Vector2(57, 15)]), dark)
	draw_rect(Rect2(house + Vector2(38, 0), Vector2(6, 10)), dark)  # the chimney
	draw_rect(Rect2(house + Vector2(10, 20), Vector2(7, 6)), Palette.WARMTH[3])  # one window lit
	draw_rect(Rect2(house + Vector2(13, 20), Vector2(1, 6)), Palette.WARMTH[1])
	draw_rect(Rect2(house + Vector2(4, 30), Vector2(18, 4)), Color(Palette.WARMTH[2], 0.25))  # its light on the grass
	# The cat on the roof, against the sky.
	var cat: Vector2 = house + Vector2(30, 1)
	draw_rect(Rect2(cat + Vector2(0, 2), Vector2(6, 3)), dark)
	draw_rect(Rect2(cat + Vector2(4, 0), Vector2(3, 3)), dark)
	draw_rect(Rect2(cat + Vector2(4, -1), Vector2(1, 1)), dark)
	draw_rect(Rect2(cat + Vector2(6, -1), Vector2(1, 1)), dark)
	draw_rect(Rect2(cat + Vector2(-2, 1), Vector2(2, 1)), dark)  # the tail
	# A lone tree on the hill's shoulder.
	var tree: Vector2 = Vector2(roundf(size_now.x * 0.5) + 70, roundf(horizon) - 16)
	draw_rect(Rect2(tree + Vector2(-1, 4), Vector2(2, 10)), dark)
	draw_circle(tree, 8.0, dark)
