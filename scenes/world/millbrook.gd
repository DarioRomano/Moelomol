extends "res://scenes/world/area_scene.gd"
## Millbrook, the first area (docs/design/area-millbrook.md): reached down
## the lane from the farm's south gate, or with F2 / `--start-scene
## millbrook`. The ford south leads to Kettlebridge once the meadow drains.


func _area_id() -> StringName:
	return GameState.MILLBROOK
