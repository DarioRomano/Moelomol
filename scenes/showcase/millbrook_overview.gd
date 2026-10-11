extends Node2D
## Millbrook's whole map at a glance, for review renders: the map drawn small,
## with every creature of the day roster as a coloured dot and the yard's
## props. Not a game screen.

const KIND_COLOURS: Dictionary = {
	&"field_mouse": Color("#a9b0bf"), &"rook": Color("#0e0f16"), &"hedgehog": Color("#4a3f52"),
	&"flood_toad": Color("#47573f"), &"stook": Color("#8f8a6a"), &"moth": Color("#f0ece1"), &"grist": Color("#c2584a"),
}

var area: Area = Millbrook.make()


func _ready() -> void:
	var title: Label = Label.new()
	title.text = "Millbrook, by day: the accepted map (with its two fixes) and the day roster"
	title.position = Vector2(8, 2)
	title.add_theme_font_size_override("font_size", 8)
	title.add_theme_color_override("font_color", Palette.PAPER[1])
	add_child(title)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-400, -400, 1600, 1200), Palette.SHADOW[0])
	var scale: float = 0.33
	draw_set_transform(Vector2(24, 16), 0.0, Vector2(scale, scale))
	AreaDrawer.draw(self, area.map, area.map.rect(), 0)
	CombatDrawer._draw_props(self, area.sim)
	for c: Fighter in area.sim.creatures:
		draw_circle(c.position, 12.0, Palette.SHADOW[0])
		draw_circle(c.position, 9.0, KIND_COLOURS.get(c.creature_kind.id, Palette.PAPER[1]))
	draw_circle(area.entrance, 14.0, Palette.WARMTH[3])
	draw_set_transform(Vector2.ZERO)
