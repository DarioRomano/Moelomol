extends "res://scenes/showcase/great_fields_open.gd"
## For review renders: the field book from the great fields' shelter, open.


func _ready() -> void:
	super()
	reader.found(&"field_almanac")
