extends PoseSheet
## Greatsword review poses (PoseSheet).


func _make_panels() -> Array[Dictionary]:
	return [
		_pose("Sweep 3 (light chain)", _sweep_three),
		_pose("Shove into a pillar: impact", _shove_impact),
		_pose("Spin sweep hits all around", _spin),
		_pose("Lunge ends at its telegraph's edge", _telegraph),
		_pose("Heavy on a staggered creature: Follow-through", _follow_through),
		_pose("Perfect brace: thrown back, riposte", _riposte),
	]


func _sweep_three(sim: CombatSim, effects: Array[Dictionary]) -> void:
	_creature(sim, Vector2(84, 76))
	_press_then_recovery(sim, effects, &"light")
	_press_then_recovery(sim, effects, &"light")
	sim.step(CombatInput.press(&"light"))
	_step_until(sim, effects, func() -> bool:
		return sim.player.move != null and sim.player.move.id == &"light_3" \
			and sim.player.attack_phase() == &"active" and sim.hitstop > 0)


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


## The projection is the hit zone (lead, 2026-10-10): freeze on the lunge's
## last active tick, the body forward, the outline still where the lunge
## began, the player standing just outside it.
func _telegraph(sim: CombatSim, effects: Array[Dictionary]) -> void:
	var c: Fighter = sim.add_creature(Vector2(130, 80))
	c.ai_enabled = false
	var reach: float = c.radius + CombatTuning.CREATURE_LUNGE_REACH + CombatTuning.CREATURE_LUNGE_DISTANCE
	sim.player.position = Vector2(130 - reach - sim.player.radius - 2.0, 80)
	sim.player.previous_position = sim.player.position
	c.facing = Vector2.LEFT
	sim.start_attack(c, sim._creature_lunge)
	var last: int = c.move.windup_ticks() + c.move.active_ticks() - 1
	var hold: CombatInput = CombatInput.new()
	hold.lock_held = true
	_step_until(sim, effects, func() -> bool: return c.state_tick >= last, hold)


func _follow_through(sim: CombatSim, effects: Array[Dictionary]) -> void:
	var c: Fighter = _creature(sim, Vector2(82, 80))
	sim.stagger(c)
	c.state_length = 1000
	sim.step(CombatInput.press(&"heavy"))
	_step_until(sim, effects, func() -> bool: return sim.player.attack_phase() == &"active" and sim.hitstop > 0)


## Brace just before a lunge lands: the hit is negated, the creature is
## thrown back staggered, and the riposte is mid-swing.
func _riposte(sim: CombatSim, effects: Array[Dictionary]) -> void:
	var c: Fighter = sim.add_creature(Vector2(118, 80))
	c.ai_enabled = false
	c.facing = Vector2.LEFT
	sim.start_attack(c, sim._creature_lunge)
	_step_until(sim, effects, func() -> bool: return c.state_tick >= c.move.windup_ticks() - 3)
	sim.step(CombatInput.press(&"skill"))
	CombatDrawer.update_effects(effects, sim.events)
	_step_until(sim, effects, func() -> bool:
		return sim.player.move == Greatsword.BRACE_COUNTER and sim.player.attack_phase() == &"active")
