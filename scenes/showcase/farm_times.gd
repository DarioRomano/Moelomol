extends Node2D
## Farm review renders (debug scene): the same small farm at dawn, midday,
## dusk and night, with crops at every growth stage on dry and watered soil,
## so the renders show the time-of-day tint, the base's lights coming on,
## and whether soil and crops still read at night.

const PANEL: Vector2 = Vector2(304, 160)
const GAP: Vector2 = Vector2(10, 14)
const TIMES: Array[int] = [6 * 60 + 15, 12 * 60, 19 * 60, 23 * 60]
const TITLES: Array[String] = ["Dawn 6:15: crops grew overnight", "Midday", "Dusk 19:00: the lights come on",
	"Night 23:00"]

var _sims: Array[FarmSim] = []


func _ready() -> void:
	for i: int in range(TIMES.size()):
		var sim: FarmSim = _small_farm()
		sim.clock.total_minutes = TIMES[i]
		_sims.append(sim)
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


## An 18 x 8 tile farm: the house, a row of each crop at every stage (the
## left half watered), the player watering.
static func _small_farm() -> FarmSim:
	var sim: FarmSim = FarmSim.new(Vector2(8, 8), Vector2i(18, 8))
	var house: Rect2i = Rect2i(1, 1, 5, 3)
	sim.plot.block(house)
	sim.solids.append(sim.cell_rect(house))
	sim.door_cell = Vector2i(3, 3)
	sim.wake_position = sim.cell_centre(Vector2i(3, 4))
	# Each crop in a row at every stage: cell x has been watered x days.
	# Plant all first, then advance the days together (new_day grows and dries
	# every tile at once). The left copy of each row is watered today.
	var rows: Dictionary = {&"catmint": 2, &"radish": 5}
	var wanted: Dictionary = {}  # cell -> days of growth
	for crop_id: StringName in rows:
		var crop: CropKind = CropKind.of(crop_id)
		for x: int in range(crop.days_to_ripen + 1):
			for half: int in range(2):
				var cell: Vector2i = Vector2i(8 + x + half * 5, int(rows[crop_id]))
				sim.plot.till(cell)
				sim.plot.plant(cell, crop_id)
				wanted[cell] = x
	for day: int in range(CropKind.of(&"catmint").days_to_ripen):
		for cell: Vector2i in wanted:
			if int(wanted[cell]) > day:
				sim.plot.water(cell)
		sim.plot.new_day()
	for cell: Vector2i in wanted:
		if cell.x < 13:
			sim.plot.water(cell)
	for x: int in range(8, 13):
		sim.plot.till(Vector2i(x, 3))  # bare tilled soil, dry
	sim.player_position = sim.cell_centre(Vector2i(7, 6))
	sim.previous_position = sim.player_position
	sim.facing = Vector2.RIGHT
	sim.busy = 5
	sim.last_action = FarmSim.WATER
	sim.spell_index = sim.spells.find(FarmSim.WATER)
	return sim
