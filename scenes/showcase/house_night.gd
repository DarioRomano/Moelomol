extends "res://scenes/farm/house.gd"
## For review renders: the farmhouse at 22:00 on day 1, the seed tin still
## full, the player at the cupboard about to take it.


func _ready() -> void:
	sim.clock.total_minutes += 16.0 * 60.0  # 22:00
	sim.tin_taken = false
	sim.inventory = Inventory.new()  # the seeds still in the tin
	sim.place_player(Vector2(2.5, 7.5) * HouseSim.TILE, Vector2.LEFT)
	super()
	set_physics_process(false)
