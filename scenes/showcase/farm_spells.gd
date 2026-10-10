extends Node2D
## Farming spell review renders (debug scene): the watering spell's tiers
## while casting (the area it covers is outlined), and the farm in the rain
## of its final tier, so the renders show what each tier waters and that
## rain reads (Q23, decided 2026-10-10).

const PANEL: Vector2 = Vector2(304, 160)
const GAP: Vector2 = Vector2(10, 14)
const TITLES: Array[String] = ["Water (tier 1): 4 tiles", "Water II: 3 x 3", "Water III: 5 x 5",
	"Rain (final tier): the whole farm"]

var _sims: Array[FarmSim] = []


func _ready() -> void:
	for i: int in range(TITLES.size()):
		_sims.append(_casting(i))
		var label: Label = Label.new()
		label.text = "%d %s" % [i + 1, TITLES[i]]
		label.position = _origin(i) + Vector2(2, PANEL.y - 2)
		label.add_theme_font_size_override("font_size", 7)
		label.add_theme_color_override("font_color", Palette.PAPER[1])
		add_child(label)
	queue_redraw()


func _origin(index: int) -> Vector2:
	return Vector2(GAP.x + (index % 2) * (PANEL.x + GAP.x), 8 + (index / 2) * (PANEL.y + GAP.y))


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(640, 360)), Palette.SHADOW[0])
	for i: int in range(_sims.size()):
		draw_set_transform(_origin(i))
		FarmDrawer.draw(self, _sims[i], 1.0, FarmDrawer.world_tint(_sims[i]))
	draw_set_transform(Vector2.ZERO)


## An 18 x 8 farm with a tilled, sown block, the player casting the watering
## spell at `tier`, frozen halfway through the cast.
static func _casting(tier: int) -> FarmSim:
	var sim: FarmSim = FarmSim.new(Vector2(8, 8), Vector2i(18, 8))
	var house: Rect2i = Rect2i(1, 1, 5, 3)
	sim.plot.block(house)
	sim.solids.append(sim.cell_rect(house))
	sim.door_cell = Vector2i(3, 3)
	for y: int in range(1, 7):
		for x: int in range(8, 17):
			var cell: Vector2i = Vector2i(x, y)
			sim.plot.till(cell)
			if (x + y) % 3 != 0:
				sim.plot.plant(cell, &"radish" if y % 2 == 0 else &"catmint")
	sim.clock.total_minutes = 10 * 60
	sim.water_tier = tier
	sim.spell_index = sim.spells.find(FarmSim.WATER)
	sim.player_position = sim.cell_centre(Vector2i(7, 3))
	sim.previous_position = sim.player_position
	sim.facing = Vector2.RIGHT
	var input: FarmInput = FarmInput.press(&"use")
	sim.step(input)
	for i: int in range(FarmSim.cast_ticks() / 2):
		sim.step(FarmInput.new())
	return sim
