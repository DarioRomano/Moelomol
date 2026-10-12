extends "res://scenes/farm/farm.gd"
## For review renders: the farm at 19:00 (the lights coming on), with the
## first field part sown and watered, seen from the south gate: the lane
## going down through the woods to Millbrook.


func _ready() -> void:
	sim.clock.total_minutes += 13.0 * 60.0  # 19:00
	var field: Array[Vector2i] = sim.map.cells_of("T")
	for i: int in range(field.size()):
		var cell: Vector2i = field[i]
		if i % 8 < 5:
			sim.plot.till(cell)
		if i % 8 < 3:
			sim.plot.plant(cell, &"radish" if i % 2 == 0 else &"catmint")
			for d: int in range(i % 4):
				sim.plot.water(cell)
				sim.plot.new_day()
		if i % 3 == 0:
			sim.plot.water(cell)
	sim.place_player(sim.gate_position + Vector2(0, -40), Vector2.UP)
	super()
	set_physics_process(false)
