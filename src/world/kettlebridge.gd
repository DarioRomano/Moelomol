class_name Kettlebridge
extends RefCounted
## Kettlebridge, the second area (docs/design/area-kettlebridge.md, accepted
## by the lead 2026-11-07): the market town on the river, south of
## Millbrook's ford. Its map, its notes, the key, the winch and the bridge,
## its exits and lights. Built in stages (roadmap): the town and the bridge
## first; its creatures and its boss, Duke, follow.

## Where the player arrives from Millbrook: the top of the road in (place 1).
const ENTRANCE: Vector2 = Vector2(32.0 * 32.0, 1.0 * 32.0 + 8.0)


static func make() -> Area:
	var map: AreaMap = AreaMap.new(KettlebridgeMap.ROWS, KettlebridgeMap.SOLID, KettlebridgeMap.BARRIER)
	var area: Area = Area.new(&"kettlebridge", map, ENTRANCE)
	area.display_name = "Kettlebridge"
	area.cleared_line = "The bridge is down."
	area.taken_lines = {&"winch_key": "Taken: the bridge-keeper's key."}
	area.entrances[&"millbrook"] = {"at": ENTRANCE, "facing": Vector2.DOWN}
	_things(area)
	_exits(area)
	# The church's windows glow at night, though nobody lit them (the doc's
	# Proposal, accepted with the design).
	for x: int in [46, 48, 50]:
		area.night_lights.append(at(x, 13) + Vector2(0, 10))
	area.start()
	return area


## The notes, the key and the winch, at the doc's numbered places. The inn,
## the chandler's, the church and the almshouses have no insides yet, so what
## the doc puts inside them is at their doors.
static func _things(area: Area) -> void:
	area.notes = KettlebridgeNotes.NOTES
	var places: Dictionary = {
		&"market_notice": at(30, 9),  # 2: the top of the high street
		&"chandlers_book": at(23, 12),  # 4: the chandler's
		&"travellers_diary": at(23, 17),  # 5: the coaching inn
		&"arthurs_door": at(30, 22),  # 8: the bridge-keeper's door
		&"toll_ledger": at(27, 22),  # the toll house, beside it
		&"font_card": at(44, 12),  # C: the church door
		&"almshouse_letter": at(55, 12),  # E: the almshouses
	}
	for note_id: StringName in places:
		area.add_thing(note_id, &"note", places[note_id])
	area.add_thing(&"winch_key", &"key", at(28, 14))  # 3: Arthur's egg stall, the cash tin
	area.add_thing(&"winch", &"winch", at(36, 22), true, &"winch_key")  # 9: the winch house door


## Back up the road to Millbrook's ford, and over the bridge south (once it
## is down; the third area is not built).
static func _exits(area: Area) -> void:
	area.add_exit(&"millbrook", Rect2(31 * AreaMap.CELL, 0, AreaMap.CELL * 2, 10), false)
	area.add_exit(&"south", Rect2(31 * AreaMap.CELL, area.map.rect().end.y - 10, AreaMap.CELL * 2, 10), true)


## A cell's centre.
static func at(x: int, y: int) -> Vector2:
	return AreaMap.centre_of(Vector2i(x, y))
