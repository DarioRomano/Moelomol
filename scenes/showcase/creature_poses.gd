extends PoseSheet
## Millbrook's creatures (PoseSheet; docs/design/enemies.md): each one's
## telegraph at its telling moment.


func _make_panels() -> Array[Dictionary]:
	return [
		_pose("Field mice zigzag in; one nips", _mice),
		_pose("Rook: the dive's lane", _rook),
		_pose("Hedgehog curled, about to roll", _hedgehog),
		_pose("Toad's glob: where you stood", _toad),
		_pose("Stook rises from the sheaves", _stook),
		_pose("Moths at a light; one darts", _moths),
	]


func _mice(sim: CombatSim, effects: Array[Dictionary]) -> void:
	var mice: Array[Fighter] = []
	for at: Vector2 in [Vector2(150, 45), Vector2(165, 85), Vector2(140, 115), Vector2(170, 60)]:
		mice.append(sim.add_creature(at, CreatureKind.field_mouse()))
	_step_until(sim, effects, func() -> bool:
		for m: Fighter in mice:
			if m.attack_phase() == &"windup" and m.state_tick >= 12:
				return true
		return false)


func _rook(sim: CombatSim, effects: Array[Dictionary]) -> void:
	var rook: Fighter = sim.add_creature(Vector2(150, 50), CreatureKind.rook())
	_step_until(sim, effects, func() -> bool: return rook.attack_phase() == &"windup" and rook.state_tick >= 15, CombatInput.new(), 400)


func _hedgehog(sim: CombatSim, effects: Array[Dictionary]) -> void:
	var hog: Fighter = sim.add_creature(Vector2(98, 80), CreatureKind.hedgehog())
	_step_until(sim, effects, func() -> bool: return hog.attack_phase() == &"windup" and hog.state_tick >= 20)


func _toad(sim: CombatSim, effects: Array[Dictionary]) -> void:
	sim.add_creature(Vector2(160, 80), CreatureKind.flood_toad())
	_step_until(sim, effects, func() -> bool: return not sim.zones.is_empty() and sim.zones[0].age >= 24)


func _stook(sim: CombatSim, effects: Array[Dictionary]) -> void:
	for at: Vector2 in [Vector2(120, 40), Vector2(150, 70), Vector2(130, 110), Vector2(165, 110)]:
		sim.add_prop(&"sheaf", Rect2(at - Vector2(4, 4), Vector2(8, 8)), false)
	var stook: Fighter = sim.add_creature(Vector2(92, 80), CreatureKind.stook())
	_step_until(sim, effects, func() -> bool: return stook.attack_phase() == &"windup" and stook.state_tick >= 15)


func _moths(sim: CombatSim, effects: Array[Dictionary]) -> void:
	sim.night = true
	sim.lights = [Vector2(120, 70)]
	var moths: Array[Fighter] = []
	for at: Vector2 in [Vector2(115, 60), Vector2(130, 75), Vector2(110, 80)]:
		moths.append(sim.add_creature(at, CreatureKind.moth()))
	sim.player.position = Vector2(85, 80)
	sim.player.previous_position = sim.player.position
	_step_until(sim, effects, func() -> bool:
		for m: Fighter in moths:
			if m.attack_phase() == &"windup" and m.state_tick >= 10:
				return true
		return false)
