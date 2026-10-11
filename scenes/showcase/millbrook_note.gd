extends "res://scenes/world/millbrook.gd"
## For review renders: the miller's note open, with its loose thread, by the
## mill door.


func _ready() -> void:
	super()
	for thing: Dictionary in area.things:
		if thing["id"] == &"sluice_note":
			area.sim.player.position = (thing["position"] as Vector2) + Vector2(0, 4)
	area.sim.player.previous_position = area.sim.player.position
	camera.snap(area.sim.player.position, view_size(), area.map.rect(), view_scale())
	_camera_node.position = camera.position
	press_interact()
