extends "res://scenes/showcase/farm_dusk.gd"
## For review renders: the pause menu over the farm at dusk, with a save.


func _ready() -> void:
	state.save_path = "user://review_pause_save.json"
	state.last_saved = "Day 3, 06:00, in the farmhouse"
	super()
	pause_menu.open()
