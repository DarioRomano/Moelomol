extends "res://scenes/farm/farm.gd"
## For review renders: the great fields' thicket halfway through withering
## back from the north gate (Grist's heart, Clear), at 10:00; the camera on
## the front.


func _ready() -> void:
	sim.clock.total_minutes += 4.0 * 60.0  # 10:00
	sim.inventory.add(&"grist_heart")
	var gate: Vector2i = sim.map.cells_of("G")[0]
	sim.place_player(sim.cell_centre(gate), Vector2.UP)
	sim.spell_index = sim.spells.find(FarmSim.CLEAR)
	sim.step(FarmInput.press(&"use"))
	state.cat.place = Cat.SHELTER
	for i: int in range(FarmSim.WITHER_TICKS / 2):
		sim.step(FarmInput.new())
	super()
	camera.snap(sim.withering_focus(), view_size(), sim.bounds(), view_scale())
	_camera_node.position = camera.position
	set_physics_process(false)
