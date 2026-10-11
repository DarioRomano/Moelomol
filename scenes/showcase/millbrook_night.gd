extends "res://scenes/world/millbrook.gd"
## Millbrook at night on the village green, for review renders: the night
## roster, the tint and the sight ring.


func _ready() -> void:
	area.skip_to_next_change()  # 20:00
	area.clock.total_minutes += 2.0 * 60.0  # 22:00: full night
	area.sim.player.position = Millbrook.at(26, 14)
	area.sim.player.previous_position = area.sim.player.position
	area.start()
	super()
