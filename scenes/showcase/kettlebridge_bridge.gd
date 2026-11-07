extends "res://scenes/world/kettlebridge.gd"
## For review renders: the winch house opened and the bridge half lowered,
## seen from the towpath by the winch house.


func _ready() -> void:
	super()
	area.objective_done = true
	area.drain_progress = 0.5
	area.sim.player.position = Kettlebridge.at(35, 22)
	area.sim.player.previous_position = area.sim.player.position
	camera.snap(area.sim.player.position + Vector2(0, 60), view_size(), area.map.rect(), view_scale())
	_camera_node.position = camera.position
	set_physics_process(false)
