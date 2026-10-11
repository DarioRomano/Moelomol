class_name Millbrook
extends RefCounted
## Millbrook, the first area (docs/design/area-millbrook.md): its map, where
## its creatures are by day and by night (the encounter plan), Grist's yard,
## and its lights. Starting values; placement is level layout, accepted by the
## lead with the map (2026-10-11).

## Where the player arrives from the farm: the top of the lane (place 1).
const ENTRANCE_CELL: Vector2i = Vector2i(28, 1)


static func make() -> Area:
	var map: AreaMap = AreaMap.new(MillbrookMap.ROWS)
	var entrance: Vector2 = Vector2(ENTRANCE_CELL.x * AreaMap.CELL, ENTRANCE_CELL.y * AreaMap.CELL + 8.0)
	var area: Area = Area.new(&"millbrook", map, entrance)
	_roster(area)
	_yard(area)
	_field(area)
	_things(area)
	_exits(area)
	for cell: Vector2i in map.cells_of("*"):
		area.lights.append(AreaMap.centre_of(cell))  # glowing fungus in the orchard
	for cell: Vector2i in [Vector2i(17, 21), Vector2i(24, 20), Vector2i(31, 21), Vector2i(38, 20)]:
		area.night_lights.append(AreaMap.centre_of(cell))  # fireflies over the floodwater's edge
	area.start()
	return area


## The notes, the crank and the sluice (area-millbrook.md, "Places" and
## "The objective"). The mill and the cottages have no insides yet, so what
## the doc puts inside them is at their doors.
static func _things(area: Area) -> void:
	area.notes = MillbrookNotes.NOTES
	var places: Dictionary = {
		&"lost_pet_poster": at(31, 5),  # 2: on a fence post halfway down the lane
		&"my_family": at(17, 4),  # 4: the schoolhouse
		&"schoolroom_board": at(15, 6),  # the schoolhouse door
		&"kitchen_table": at(18, 11),  # the cottage by the green
		&"chapel_notices": at(39, 3),  # 7: the chapel
		&"cider_tally": at(7, 12),  # C: the cider shed
		&"hive_log": at(47, 7),  # G: the beekeeper's hives
		&"sluice_note": at(37, 18),  # 9: pinned by the sluice wheel, inside the mill door
		&"miller_calendar": MILLER_DOOR + Vector2(-26, 0),
	}
	for note_id: StringName in places:
		area.add_thing(note_id, &"note", places[note_id])
	# Shown once Grist is defeated (enemies.md: a note for after).
	area.add_thing(&"grist_apples", &"note", MILLER_DOOR + Vector2(26, 0), false)
	area.add_thing(&"sluice_crank", &"crank", MILLER_DOOR)
	area.add_thing(&"sluice", &"sluice", at(37, 17))


## Up the lane to the farm, and the ford south (once the meadow drains).
static func _exits(area: Area) -> void:
	area.add_exit(&"farm", Rect2(27 * AreaMap.CELL, 0, AreaMap.CELL * 2, 10), false)
	area.add_exit(&"south", Rect2(27 * AreaMap.CELL, area.map.rect().end.y - 10, AreaMap.CELL * 2, 10), true)


## The miller's door: below the middle of the miller's cottage (cells 48-50,
## rows 20-21), facing the yard.
const MILLER_DOOR: Vector2 = Vector2(49.5 * 32.0, 22.0 * 32.0 + 8.0)


## A cell's centre.
static func at(x: int, y: int) -> Vector2:
	return AreaMap.centre_of(Vector2i(x, y))


## The encounter plan, zone by zone (area-millbrook.md, "Creatures, zone by
## zone"). About 30 by day.
static func _roster(area: Area) -> void:
	# The lane's foot and the green: one hedgehog by day, two at night.
	area.add_to_roster(&"hedgehog", at(24, 12), &"both")
	area.add_to_roster(&"hedgehog", at(31, 11), &"night")
	# The cottage gardens: two packs of mice by day; a hedgehog at night.
	for c: Vector2i in [Vector2i(15, 14), Vector2i(15, 16), Vector2i(14, 15), Vector2i(16, 15)]:
		area.add_to_roster(&"field_mouse", AreaMap.centre_of(c), &"day")
	for c: Vector2i in [Vector2i(38, 14), Vector2i(37, 15), Vector2i(39, 15)]:
		area.add_to_roster(&"field_mouse", AreaMap.centre_of(c), &"day")
	area.add_to_roster(&"hedgehog", at(15, 17), &"night")
	# The orchard: three rooks by day; moths at the fungus at night.
	for c: Vector2i in [Vector2i(5, 5), Vector2i(9, 9), Vector2i(6, 15)]:
		area.add_to_roster(&"rook", AreaMap.centre_of(c), &"day")
	for c: Vector2i in [Vector2i(5, 7), Vector2i(4, 6), Vector2i(9, 13), Vector2i(10, 14), Vector2i(3, 17), Vector2i(4, 16)]:
		area.add_to_roster(&"moth", AreaMap.centre_of(c), &"night")
	# The wheat field: three stooks always; a pack of mice in the standing wheat by day.
	for c: Vector2i in [Vector2i(4, 22), Vector2i(9, 25), Vector2i(5, 27)]:
		area.add_to_roster(&"stook", AreaMap.centre_of(c), &"both")
	for c: Vector2i in [Vector2i(9, 21), Vector2i(10, 22), Vector2i(8, 23), Vector2i(10, 24)]:
		area.add_to_roster(&"field_mouse", AreaMap.centre_of(c), &"day")
	# The floodwater's edge: two toads by day, four at night; moths at the fireflies.
	area.add_to_roster(&"flood_toad", at(20, 20), &"both")
	area.add_to_roster(&"flood_toad", at(34, 20), &"both")
	area.add_to_roster(&"flood_toad", at(16, 21), &"night")
	area.add_to_roster(&"flood_toad", at(40, 20), &"night")
	area.add_to_roster(&"moth", at(23, 20), &"night")
	area.add_to_roster(&"moth", at(31, 20), &"night")
	# The mill: a nest of mice at its door (inside, once the mill has an inside).
	for c: Vector2i in [Vector2i(36, 18), Vector2i(35, 17), Vector2i(36, 19), Vector2i(34, 18),
			Vector2i(33, 17), Vector2i(34, 16), Vector2i(33, 15), Vector2i(32, 16)]:
		area.add_to_roster(&"field_mouse", AreaMap.centre_of(c), &"day")
	# The millpond's banks: two toads by day, three at night.
	area.add_to_roster(&"flood_toad", at(41, 12), &"both")
	area.add_to_roster(&"flood_toad", at(53, 13), &"both")
	area.add_to_roster(&"flood_toad", at(52, 10), &"night")
	# The miller's yard: Grist (asleep at night).
	area.add_to_roster(&"grist", GRIST_HOME, &"both")


## Grist's home in the yard.
const GRIST_HOME: Vector2 = Vector2(1584, 750)


## The miller's yard (enemies.md, "The arena"): inside the fence (cells
## 46-52 across, 19-25 down), with the cottage at the top.
static func _yard(area: Area) -> void:
	var sim: CombatSim = area.sim
	sim.add_prop(&"wallow", Rect2(1480, 770, 56, 40), false)
	sim.add_prop(&"trough", Rect2(1650, 620, 40, 14), true)
	sim.add_prop(&"millstone_leaning", Rect2(1546, 672, 20, 12), true)
	sim.add_prop(&"millstone_leaning", Rect2(1610, 672, 20, 12), true)
	for rect: Rect2 in [Rect2(1474, 640, 28, 20), Rect2(1666, 700, 28, 20), Rect2(1580, 806, 30, 20), Rect2(1640, 806, 28, 20)]:
		sim.add_prop(&"sacks", rect, true)


## The wheat field's real sheaves, standing in the cut half among the stooks.
static func _field(area: Area) -> void:
	for c: Vector2i in [Vector2i(3, 21), Vector2i(5, 21), Vector2i(3, 23), Vector2i(5, 23), Vector2i(6, 25),
			Vector2i(3, 25), Vector2i(4, 26), Vector2i(3, 28), Vector2i(6, 28)]:
		var centre: Vector2 = AreaMap.centre_of(c)
		area.sim.add_prop(&"sheaf", Rect2(centre - Vector2(4, 4), Vector2(8, 8)), false)
