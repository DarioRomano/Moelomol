extends "res://scenes/world/kettlebridge.gd"
## Kettlebridge at night by the churchyard, for review renders: the tint,
## the sight ring and the church windows lit, though nobody lit them.


func _ready() -> void:
	area.skip_to_next_change()  # 20:00
	area.clock.total_minutes += 2.0 * 60.0  # 22:00: full night
	area.sim.player.position = Kettlebridge.at(42, 15)
	area.sim.player.previous_position = area.sim.player.position
	area.start()
	super()
