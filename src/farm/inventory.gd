class_name Inventory
extends RefCounted
## What the player carries, as item id -> count. Minimal for the farming
## slice: seeds and produce. No capacity yet (an upgrade system later).

var _counts: Dictionary = {}


func count(item: StringName) -> int:
	return _counts.get(item, 0)


func add(item: StringName, n: int = 1) -> void:
	if n <= 0:
		return
	_counts[item] = count(item) + n


## Takes n of an item if there are that many; returns false (and takes
## nothing) otherwise.
func take(item: StringName, n: int = 1) -> bool:
	if count(item) < n:
		return false
	_counts[item] = count(item) - n
	if _counts[item] == 0:
		_counts.erase(item)
	return true


## Item ids with a count, sorted, for the HUD.
func items() -> Array[StringName]:
	var ids: Array[StringName] = []
	for item: StringName in _counts:
		ids.append(item)
	ids.sort()
	return ids


## Every item and its count, for carrying between places and the save.
func to_dict() -> Dictionary:
	var out: Dictionary = {}
	for item: StringName in _counts:
		out[String(item)] = _counts[item]
	return out


## Replaces the contents with a dictionary from to_dict(); counts that are
## not whole positive numbers are skipped.
func load_dict(counts: Dictionary) -> void:
	_counts.clear()
	for key: Variant in counts:
		var n: Variant = counts[key]
		if (n is int or n is float) and int(n) > 0:
			_counts[StringName(str(key))] = int(n)
