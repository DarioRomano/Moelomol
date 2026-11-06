extends "res://scenes/farm/farm.gd"
## For review renders: dusk (19:00) at the pond, the cat on the bench where
## it watches the sunset, the player beside it, facing it.


func _ready() -> void:
	sim.clock.total_minutes += 13.0 * 60.0  # 19:00
	state.cat.place = Cat.BENCH
	var cat_at: Vector2 = Cat.farm_position(Cat.BENCH, sim.map)
	sim.place_player(cat_at + Vector2(-34, 6), Vector2.RIGHT)
	super()
	set_physics_process(false)
