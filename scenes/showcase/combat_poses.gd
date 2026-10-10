extends PoseSheet
## Greatsword review poses (PoseSheet).


func _make_panels() -> Array[Dictionary]:
	return [
		_pose("Sweep 3 (light chain)", _sweep_three),
		_pose("Overhead cleave: hyper-armour windup", _cleave_windup),
		_pose("Shove into a pillar: impact", _shove_impact),
		_pose("Spin sweep hits all around", _spin),
		_pose("Creature telegraph, locked on", _telegraph),
		_pose("Follow-through on a staggered creature", _follow_through),
	]


func _sweep_three(sim: CombatSim, effects: Array[Dictionary]) -> void:
	_creature(sim, Vector2(84, 76))
	_press_then_recovery(sim, effects, &"light")
	_press_then_recovery(sim, effects, &"light")
	sim.step(CombatInput.press(&"light"))
	_step_until(sim, effects, func() -> bool:
		return sim.player.move != null and sim.player.move.id == &"light_3" \
			and sim.player.attack_phase() == &"active" and sim.hitstop > 0)


func _cleave_windup(sim: CombatSim, effects: Array[Dictionary]) -> void:
	_creature(sim, Vector2(92, 80))
	sim.step(CombatInput.press(&"heavy"))
	_step_until(sim, effects, func() -> bool: return sim.player.state_tick >= 20)


func _shove_impact(sim: CombatSim, effects: Array[Dictionary]) -> void:
	sim.obstacles.append(Rect2(128, 56, 20, 50))
	_creature(sim, Vector2(108, 80))
	_press_then_recovery(sim, effects, &"light")
	sim.step(CombatInput.press(&"heavy"))
	var impacted: Array[bool] = [false]
	_step_until(sim, effects, func() -> bool:
		for e: Dictionary in effects:
			if e["kind"] == "impact" and int(e["age"]) >= 3:
				impacted[0] = true
		return impacted[0])


func _spin(sim: CombatSim, effects: Array[Dictionary]) -> void:
	sim.player.position = Vector2(100, 76)
	sim.player.previous_position = sim.player.position
	_creature(sim, Vector2(126, 74))
	_creature(sim, Vector2(76, 82))
	_creature(sim, Vector2(102, 100))
	_press_then_recovery(sim, effects, &"light")
	_press_then_recovery(sim, effects, &"light")
	sim.step(CombatInput.press(&"heavy"))
	_step_until(sim, effects, func() -> bool: return sim.player.attack_phase() == &"active" and sim.hitstop > 0)


func _telegraph(sim: CombatSim, effects: Array[Dictionary]) -> void:
	var c: Fighter = sim.add_creature(Vector2(120, 80))
	var hold: CombatInput = CombatInput.new()
	hold.lock_held = true
	_step_until(sim, effects, func() -> bool: return c.attack_phase() == &"windup" and c.state_tick == 20, hold)


func _follow_through(sim: CombatSim, effects: Array[Dictionary]) -> void:
	var c: Fighter = _creature(sim, Vector2(82, 80))
	sim.stagger(c)
	c.state_length = 1000
	sim.step(CombatInput.press(&"skill"))
	_step_until(sim, effects, func() -> bool: return sim.player.attack_phase() == &"active" and sim.hitstop > 0)
