extends "res://scenes/farm/farm.gd"
## For review renders: the great fields opened (Q42 A) at 10:00, seen from
## the track by the ruined field shelter, the cat sitting at its doorway, a
## strip begun: cleared, part tilled.


func _ready() -> void:
	sim.clock.total_minutes += 4.0 * 60.0  # 10:00
	sim.open_parcel(1)
	state.cat.place = Cat.SHELTER
	var shelter: Rect2i = sim.map.bounds_of("F")
	for y: int in range(shelter.end.y + 2, shelter.end.y + 5):
		for x: int in range(shelter.position.x - 6, shelter.position.x):
			var cell: Vector2i = Vector2i(x, y)
			if sim.can_clear(cell):
				sim.clear_tile(cell)
				if y == shelter.end.y + 2:
					sim.plot.till(cell)
	sim.place_player(Vector2((FarmLayout.TRACK_X + 1.5) * FarmSim.TILE, (shelter.end.y + 1.5) * FarmSim.TILE), Vector2.LEFT)
	super()
	set_physics_process(false)
