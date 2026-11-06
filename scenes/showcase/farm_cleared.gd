extends "res://scenes/farm/farm.gd"
## For review renders: the old fields west of the path at 10:00, a strip
## cleared with Clear, some of it tilled and sown, the player mid-cast on
## the next tile of long grass.


func _ready() -> void:
	sim.clock.total_minutes += 4.0 * 60.0  # 10:00
	var old: Array[Vector2i] = sim.map.cells_of(":")
	var left: Array[Vector2i] = old.filter(func(c: Vector2i) -> bool: return c.x < 78)
	left.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	var target: Vector2i = Vector2i.ZERO
	for cell: Vector2i in left:
		if cell.y >= 78 and cell.y < 81 and cell.x >= 66:
			sim.clear_tile(cell)
			if cell.y == 78:
				sim.plot.till(cell)
				if cell.x % 2 == 0:
					sim.plot.plant(cell, &"radish")
		elif cell.y == 81 and target == Vector2i.ZERO and cell.x == 68:
			target = cell
	if target == Vector2i.ZERO:
		target = Vector2i(68, 81)
	sim.place_player(sim.cell_centre(target + Vector2i.DOWN), Vector2.UP)
	sim.spell_index = sim.spells.find(FarmSim.CLEAR)
	sim.last_action = FarmSim.CLEAR
	sim.busy = FarmSim.cast_ticks() / 2
	super()
	set_physics_process(false)
