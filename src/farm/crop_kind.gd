class_name CropKind
extends RefCounted
## One kind of crop (docs/design/farming.md, "Crops"). Placeholder content:
## enough crops to prove the system with two growth times; real crops are
## designed with crafting and the areas. Harvest yields are placeholder
## balance (Q25, working assumption A: every harvest returns seeds).

## Growth stages as drawn: 0 seed, 1 sprout, 2 growing, 3 ripe.
const STAGES: int = 4

var id: StringName
var display_name: String
var days_to_ripen: int  # watered days of growth until ripe
var produce: StringName  # inventory item a harvest gives
var produce_count: int
var seed_item: StringName  # inventory item planted (and returned by a harvest)
var seed_return: int

static var _all: Dictionary = _make_all()


static func make(p_id: StringName, p_name: String, days: int, produce_count_: int, seed_return_: int) -> CropKind:
	var c: CropKind = CropKind.new()
	c.id = p_id
	c.display_name = p_name
	c.days_to_ripen = days
	c.produce = p_id
	c.produce_count = produce_count_
	c.seed_item = StringName("%s_seeds" % p_id)
	c.seed_return = seed_return_
	return c


## Every crop kind by id.
static func all() -> Dictionary:
	return _all


static func of(crop_id: StringName) -> CropKind:
	return _all.get(crop_id, null)


## The crop planted from a seed item, or null.
static func from_seed(seed_id: StringName) -> CropKind:
	for crop: CropKind in _all.values():
		if crop.seed_item == seed_id:
			return crop
	return null


## Drawn stage after `grown_days` of growth: the last stage only when ripe.
func stage_for(grown_days: int) -> int:
	if grown_days >= days_to_ripen:
		return STAGES - 1
	return clampi(grown_days * (STAGES - 1) / days_to_ripen, 0, STAGES - 2)


static func _make_all() -> Dictionary:
	var crops: Dictionary = {}
	for c: CropKind in [
		make(&"catmint", "Catmint", 4, 1, 2),  # the cat treats' crop (ADR-0010)
		make(&"radish", "Radish", 3, 1, 2),
	]:
		crops[c.id] = c
	return crops
