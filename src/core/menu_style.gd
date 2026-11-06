class_name MenuStyle
extends RefCounted
## The game's quiet menu style, shared by the title and the pause menu:
## paper-coloured lines that warm, with a soft band, when chosen by keys,
## stick or mouse (ADR-0013: every menu works with all three).


static func label(text: String, size: int, colour: Color) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", colour)
	l.add_theme_color_override("font_shadow_color", Palette.SHADOW[0])
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	return l


static func spacer(height: float) -> Control:
	var s: Control = Control.new()
	s.custom_minimum_size = Vector2(0, height)
	return s


static func button(text: String, pressed: Callable) -> Button:
	var b: Button = Button.new()
	b.text = text
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


## W / S move between buttons too (the arrows, D-pad and stick are the
## engine's ui_up / ui_down, which the buttons handle themselves). Returns
## true if the event was used.
static func move_focus_with_keys(event: InputEvent, viewport: Viewport) -> bool:
	var side: int = -1
	if event.is_action_pressed(&"move_up", false) and not event.is_action(&"ui_up"):
		side = SIDE_TOP
	elif event.is_action_pressed(&"move_down", false) and not event.is_action(&"ui_down"):
		side = SIDE_BOTTOM
	if side < 0:
		return false
	var focused: Control = viewport.gui_get_focus_owner()
	if focused != null:
		var next: Control = focused.find_valid_focus_neighbor(side as Side)
		if next != null:
			next.grab_focus()
	return true
