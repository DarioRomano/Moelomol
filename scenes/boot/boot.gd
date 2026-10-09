extends Control
## Main scene for foundation builds (Milestone 1). There is no gameplay yet:
## this shows the title over the pixel-scale test card so the lead can judge
## scaling on real screens (see docs/playtests/).

const TEST_CARD: PackedScene = preload("res://scenes/showcase/test_card.tscn")


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(TEST_CARD.instantiate())
	var title: Label = Label.new()
	title.text = "MOELOMOL\nfoundation build - no gameplay yet"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Palette.WARMTH[3])
	title.add_theme_font_size_override("font_size", 16)
	title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 72)
	title.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(title)
