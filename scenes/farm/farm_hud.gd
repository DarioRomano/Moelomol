class_name FarmHud
extends Control
## The farm's HUD: the day and time, the tool in hand, what the player
## carries, and the controls. Calm and sparse (art direction); lives in a
## UiFrame, so it follows the UI width setting (ADR-0008). Never tinted by
## the time of day.

var _clock: Label
var _tool: Label
var _bag: Label
var _help: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clock = _make_label()
	_clock.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 4)
	_clock.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_tool = _make_label()
	_tool.position = Vector2(4, 2)
	_bag = _make_label()
	_bag.position = Vector2(4, 11)
	_help = _make_label()
	_help.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 4)
	_help.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_help.text = "Move WASD / stick   Use tool J / X   Interact Space / A (harvest; the door: sleep)   " \
		+ "Tools Q E / LB RB\nF8 sleep now   F9 time x30"


func _make_label() -> Label:
	var label: Label = Label.new()
	label.add_theme_font_size_override("font_size", 7)
	label.add_theme_color_override("font_color", Palette.PAPER[1])
	label.add_theme_color_override("font_shadow_color", Palette.SHADOW[0])
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(label)
	return label


func show_state(sim: FarmSim) -> void:
	_clock.text = "Day %d   %s   %s%s" % [sim.clock.day, sim.clock.time_text(), sim.clock.phase(),
		"   (time x%d)" % roundi(sim.time_scale) if sim.time_scale != 1.0 else ""]
	var tool: StringName = sim.tool()
	_tool.text = FarmSim.item_name(tool) if sim.inventory.count(tool) == 0 and CropKind.from_seed(tool) == null \
		else "%s x%d" % [FarmSim.item_name(tool), sim.inventory.count(tool)]
	var parts: PackedStringArray = PackedStringArray()
	for item: StringName in sim.inventory.items():
		if CropKind.from_seed(item) == null:
			parts.append("%s %d" % [FarmSim.item_name(item), sim.inventory.count(item)])
	_bag.text = "   ".join(parts)
