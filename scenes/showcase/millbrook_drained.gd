extends "res://scenes/world/millbrook.gd"
## For review renders: the sluice opened and the meadow half drained, seen
## from the signpost on the south road.


func _ready() -> void:
	super()
	area.objective_done = true
	area.drain_progress = 0.5
	area.sim.player.position = Millbrook.at(27, 20)
	area.sim.player.previous_position = area.sim.player.position
	camera.snap(area.sim.player.position + Vector2(0, 80), view_size(), area.map.rect(), view_scale())
	_camera_node.position = camera.position
	set_physics_process(false)
