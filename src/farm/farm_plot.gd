class_name FarmPlot
extends RefCounted
## The base's ground as a grid of 16 px tiles, and the farming rules on it
## (docs/design/farming.md, "Soil and actions" and "Crop growth"; Q23 and
## Q24, working assumption A):
## - the hoe tills grass; the watering can waters tilled soil; seeds go on
##   tilled soil with nothing on it;
## - when a new day starts, every crop on soil watered the day before grows a
##   day, then all soil dries;
## - an unwatered crop simply does not grow; a ripe crop waits; nothing
##   withers.
## Tiles that cannot be farmed (the house, paths) are marked `blocked`.

enum Soil { GRASS, TILLED }

var size: Vector2i
var _soil: PackedByteArray
var _watered: PackedByteArray
var _blocked: PackedByteArray
var _crop: Array[StringName] = []
var _grown: PackedInt32Array


func _init(p_size: Vector2i) -> void:
	size = p_size
	var n: int = size.x * size.y
	_soil.resize(n)
	_watered.resize(n)
	_blocked.resize(n)
	_grown.resize(n)
	_crop.resize(n)
	_crop.fill(&"")


func contains(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < size.x and cell.y < size.y


func _i(cell: Vector2i) -> int:
	return cell.y * size.x + cell.x


func block(rect: Rect2i) -> void:
	for y: int in range(rect.position.y, rect.end.y):
		for x: int in range(rect.position.x, rect.end.x):
			if contains(Vector2i(x, y)):
				_blocked[_i(Vector2i(x, y))] = 1


func is_blocked(cell: Vector2i) -> bool:
	return not contains(cell) or _blocked[_i(cell)] == 1


func is_tilled(cell: Vector2i) -> bool:
	return contains(cell) and _soil[_i(cell)] == Soil.TILLED


func is_watered(cell: Vector2i) -> bool:
	return contains(cell) and _watered[_i(cell)] == 1


## The crop on a tile, or &"".
func crop_at(cell: Vector2i) -> StringName:
	return _crop[_i(cell)] if contains(cell) else &""


func grown_days(cell: Vector2i) -> int:
	return _grown[_i(cell)] if contains(cell) else 0


func is_ripe(cell: Vector2i) -> bool:
	var crop: CropKind = CropKind.of(crop_at(cell))
	return crop != null and grown_days(cell) >= crop.days_to_ripen


## Drawn growth stage 0-3, or -1 for no crop.
func stage(cell: Vector2i) -> int:
	var crop: CropKind = CropKind.of(crop_at(cell))
	return crop.stage_for(grown_days(cell)) if crop != null else -1


## The hoe on grass. Returns true if the tile was tilled.
func till(cell: Vector2i) -> bool:
	if is_blocked(cell) or is_tilled(cell):
		return false
	_soil[_i(cell)] = Soil.TILLED
	return true


## The watering can on tilled soil (planted or not). Returns true if the
## tile became watered.
func water(cell: Vector2i) -> bool:
	if not is_tilled(cell) or is_watered(cell):
		return false
	_watered[_i(cell)] = 1
	return true


## Seeds on tilled soil with nothing on it.
func plant(cell: Vector2i, crop_id: StringName) -> bool:
	if not is_tilled(cell) or crop_at(cell) != &"" or CropKind.of(crop_id) == null:
		return false
	_crop[_i(cell)] = crop_id
	_grown[_i(cell)] = 0
	return true


## Picks a ripe crop: returns {item: count} (produce and seeds), and leaves
## tilled soil behind. Empty if nothing is ripe there.
func harvest(cell: Vector2i) -> Dictionary:
	if not is_ripe(cell):
		return {}
	var crop: CropKind = CropKind.of(crop_at(cell))
	_crop[_i(cell)] = &""
	_grown[_i(cell)] = 0
	var items: Dictionary = {crop.produce: crop.produce_count}
	if crop.seed_return > 0:
		items[crop.seed_item] = crop.seed_return
	return items


## The hoe on an unripe crop: removes it. Returns true if something was
## removed.
func clear(cell: Vector2i) -> bool:
	if crop_at(cell) == &"" or is_ripe(cell):
		return false
	_crop[_i(cell)] = &""
	_grown[_i(cell)] = 0
	return true


## Waters every tilled tile (rain). Returns how many became watered.
func water_all() -> int:
	var n: int = 0
	for i: int in range(_soil.size()):
		if _soil[i] == Soil.TILLED and _watered[i] == 0:
			_watered[i] = 1
			n += 1
	return n


## A new day starts: crops on watered soil grow a day (ripe ones stay ripe),
## then all soil dries. Returns how many crops grew.
func new_day() -> int:
	var grew: int = 0
	for i: int in range(_crop.size()):
		if _crop[i] != &"" and _watered[i] == 1:
			var crop: CropKind = CropKind.of(_crop[i])
			if _grown[i] < crop.days_to_ripen:
				_grown[i] += 1
				grew += 1
		_watered[i] = 0
	return grew
