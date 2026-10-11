extends PoseSheet
## Grist, the miller's boar (PoseSheet; docs/design/enemies.md): its moves and
## what the yard does to them.


func _make_panels() -> Array[Dictionary]:
	return [
		_pose("Charge: the lane to the first thing in its way", _charge),
		_pose("Stunned against a millstone", _stunned),
		_pose("Grain sacks burst: mice come running", _sacks),
		_pose("Half health: wallowing for mud", _wallow),
		_pose("Asleep at night in the wallow", _asleep),
		_pose("Caked in mud, heaving a millstone", _millstone),
	]


static func _grist(sim: CombatSim, at: Vector2) -> Fighter:
	return sim.add_creature(at, CreatureKind.grist())


func _charge(sim: CombatSim, effects: Array[Dictionary]) -> void:
	var g: Fighter = _grist(sim, Vector2(150, 50))
	_step_until(sim, effects, func() -> bool: return g.attack_phase() == &"windup" and g.state_tick >= 30)


func _stunned(sim: CombatSim, effects: Array[Dictionary]) -> void:
	sim.add_prop(&"millstone_flat", Rect2(20, 92, 20, 20), true)
	var g: Fighter = _grist(sim, Vector2(150, 50))
	_step_until(sim, effects, func() -> bool: return g.attack_phase() == &"windup")
	sim.player.position = Vector2(60, 40)  # sidestep; the charge runs into the stone
	sim.player.previous_position = sim.player.position
	_step_until(sim, effects, func() -> bool: return g.is_staggered() and g.state_tick >= 12)


func _sacks(sim: CombatSim, effects: Array[Dictionary]) -> void:
	sim.add_prop(&"sacks", Rect2(18, 108, 28, 20), true)  # on the lane past the player
	var g: Fighter = _grist(sim, Vector2(150, 40))
	sim.player.position = Vector2(60, 100)
	sim.player.previous_position = sim.player.position
	_step_until(sim, effects, func() -> bool: return g.attack_phase() == &"windup")
	sim.player.position = Vector2(150, 115)  # sidestep; the charge runs into the sacks
	sim.player.previous_position = sim.player.position
	var burst: Array[int] = [-1]
	_step_until(sim, effects, func() -> bool:
		for e: Dictionary in sim.events:
			if e["type"] == "sacks_burst":
				burst[0] = sim.tick_count
		return burst[0] >= 0 and sim.tick_count >= burst[0] + 20)


func _wallow(sim: CombatSim, effects: Array[Dictionary]) -> void:
	sim.add_prop(&"wallow", Rect2(110, 20, 56, 40), false)
	var g: Fighter = _grist(sim, Vector2(110, 90))
	g.health = 290.0
	_step_until(sim, effects, func() -> bool: return g.ai_state == &"wallowing" and g.ai_timer <= 90)


func _asleep(sim: CombatSim, effects: Array[Dictionary]) -> void:
	sim.night = true
	sim.add_prop(&"wallow", Rect2(110, 20, 56, 40), false)
	var g: Fighter = _grist(sim, Vector2(138, 40))
	_step_until(sim, effects, func() -> bool: return g.ai_state == &"asleep" and sim.tick_count >= 40)


func _millstone(sim: CombatSim, effects: Array[Dictionary]) -> void:
	sim.add_prop(&"millstone_leaning", Rect2(130, 16, 20, 12), true)
	var g: Fighter = _grist(sim, Vector2(110, 60))
	g.phase = 2
	g.health = 280.0
	g.give_armour(CreatureBrain.GRIST_MUD_ARMOUR)
	g.ai_count = 1
	g.ai_timer = 3  # due a millstone
	_step_until(sim, effects, func() -> bool:
		return not sim.projectiles.is_empty() and sim.projectiles[0].position.distance_to(g.position) > 40.0, CombatInput.new(), 600)
