extends PoseSheet
## Kettlebridge's creatures (PoseSheet; docs/design/area-kettlebridge.md):
## each one's idea at its telling moment.


func _make_panels() -> Array[Dictionary]:
	return [
		_pose("A heavy hit splits a market rat", _split),
		_pose("Jackdaw carrying a runt", _jackdaw_carrying),
		_pose("The runt dropped; the dive", _jackdaw_dropped),
		_pose("Pike surfaced; its jet coming", _pike),
		_pose("Gravestones; one is not", _lichen_hidden),
		_pose("A Lichen-back heaves up", _lichen_rising),
	]


func _split(sim: CombatSim, effects: Array[Dictionary]) -> void:
	var rat: Fighter = sim.add_creature(Vector2(84, 80), CreatureKind.market_rat())
	rat.facing = Vector2.LEFT
	sim.add_creature(Vector2(150, 50), CreatureKind.market_rat()).ai_enabled = false
	var heavy: CombatMove = CombatMove.make(&"pose_heavy", "Heavy", Vector3i(1, 1, 1), 10.0, 10.0, 0.0, 20.0, 90.0, 0.0)
	heavy.heavy = true
	sim._hit(sim.player, rat, heavy)
	_step_until(sim, effects, func() -> bool: return false, CombatInput.new(), 5)


func _jackdaw_carrying(sim: CombatSim, effects: Array[Dictionary]) -> void:
	sim.add_creature(Vector2(140, 60), CreatureKind.jackdaw())
	_step_until(sim, effects, func() -> bool: return false, CombatInput.new(), 30)


func _jackdaw_dropped(sim: CombatSim, effects: Array[Dictionary]) -> void:
	var bird: Fighter = sim.add_creature(Vector2(140, 60), CreatureKind.jackdaw())
	_step_until(sim, effects, func() -> bool: return bird.attack_phase() == &"windup" and bird.state_tick >= 15,
		CombatInput.new(), 600)


func _pike(sim: CombatSim, effects: Array[Dictionary]) -> void:
	var pike: Fighter = sim.add_creature(Vector2(150, 70), CreatureKind.river_pike())
	_step_until(sim, effects, func() -> bool: return not sim.zones.is_empty() and sim.zones[0].age >= 15)
	pike.facing = Vector2.LEFT


func _lichen_hidden(sim: CombatSim, effects: Array[Dictionary]) -> void:
	for at: Vector2 in [Vector2(110, 50), Vector2(150, 50), Vector2(110, 110), Vector2(150, 110)]:
		sim.add_prop(&"gravestone", Rect2(at - Vector2(6, 4), Vector2(12, 4)), true)
	sim.add_creature(Vector2(130, 80), CreatureKind.lichen_back())
	_step_until(sim, effects, func() -> bool: return false, CombatInput.new(), 5)


func _lichen_rising(sim: CombatSim, effects: Array[Dictionary]) -> void:
	for at: Vector2 in [Vector2(130, 45), Vector2(150, 115)]:
		sim.add_prop(&"gravestone", Rect2(at - Vector2(6, 4), Vector2(12, 4)), true)
	var back: Fighter = sim.add_creature(Vector2(86, 80), CreatureKind.lichen_back())
	_step_until(sim, effects, func() -> bool: return back.attack_phase() == &"windup" and back.state_tick >= 15)
