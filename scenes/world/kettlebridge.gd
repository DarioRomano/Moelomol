extends "res://scenes/world/area_scene.gd"
## Kettlebridge, the second area (docs/design/area-kettlebridge.md): over
## Millbrook's ford and down the road, or F2 / `--start-scene kettlebridge`.
## The bridge south lowers once the winch house is opened with Arthur's key.


func _area_id() -> StringName:
	return GameState.KETTLEBRIDGE
