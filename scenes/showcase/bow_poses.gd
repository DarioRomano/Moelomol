extends PoseSheet
## Bow review poses (PoseSheet): the draw stages, a piercing arrow through a
## line, the heavy arrow's knockback, the dodge shot, and Volley.

const BOW: int = 1


func _make_panels() -> Array[Dictionary]:
	return [
		_pose("Drawing: stage 2 of 3", _drawing, BOW),
		_pose("Piercing arrow through a line", _piercing, BOW),
		_pose("Heavy arrow: knockback and stagger", _heavy, BOW),
		_pose("Dodge shot as the roll ends", _dodge_shot, BOW),
		_pose("Volley: the mark waits for the rain", _marked, BOW),
		_pose("Volley: rain on the mark (Flow 3)", _rain, BOW),
	]


func _pose(title: String, script: Callable, weapon_index: int = 0) -> Dictionary:
	# Every bow panel carries the greatsword and the bow.
	var wrapped: Callable = func(sim: CombatSim, effects: Array[Dictionary]) -> void:
		sim.player.weapons[1] = Bow.new()
		script.call(sim, effects)
	return super(title, wrapped, weapon_index)


static func _bow(sim: CombatSim) -> Bow:
	return sim.player.weapon() as Bow


static func _draw_to(sim: CombatSim, effects: Array[Dictionary], held: int) -> void:
	sim.step(CombatInput.press(&"heavy"))
	_step_until(sim, effects, func() -> bool: return sim.player.state_tick >= held, CombatInput.hold_heavy())


func _drawing(sim: CombatSim, effects: Array[Dictionary]) -> void:
	_creature(sim, Vector2(140, 80))
	_draw_to(sim, effects, _bow(sim).stage_ticks()[1] + 2)


func _piercing(sim: CombatSim, effects: Array[Dictionary]) -> void:
	sim.player.position = Vector2(40, 80)
	sim.player.previous_position = sim.player.position
	_creature(sim, Vector2(90, 80))
	_creature(sim, Vector2(120, 82))
	_creature(sim, Vector2(150, 78))
	_draw_to(sim, effects, _bow(sim).stage_ticks()[1] + 8)
	sim.step(CombatInput.new())
	_step_until(sim, effects, func() -> bool: return sim.creatures[1].health < sim.creatures[1].max_health)
	sim.step(CombatInput.new())


func _heavy(sim: CombatSim, effects: Array[Dictionary]) -> void:
	_creature(sim, Vector2(110, 80))
	_draw_to(sim, effects, _bow(sim).stage_ticks()[2] + 10)
	sim.step(CombatInput.new())
	_step_until(sim, effects, func() -> bool: return sim.creatures[0].is_staggered())
	_step_until(sim, effects, func() -> bool: return sim.creatures[0].push_ticks == 0)


func _dodge_shot(sim: CombatSim, effects: Array[Dictionary]) -> void:
	sim.player.position = Vector2(50, 100)
	sim.player.previous_position = sim.player.position
	_creature(sim, Vector2(140, 60))
	var lock: CombatInput = CombatInput.new()
	lock.lock_held = true
	var dodge: CombatInput = CombatInput.press(&"dodge")
	dodge.lock_held = true
	dodge.move = Vector2.UP
	sim.step(dodge)
	var heavy: CombatInput = CombatInput.press(&"heavy")
	heavy.lock_held = true
	sim.step(heavy)
	_step_until(sim, effects, func() -> bool:
		return not sim.projectiles.is_empty() and sim.projectiles[0].position.x > 80, lock)


func _marked(sim: CombatSim, effects: Array[Dictionary]) -> void:
	_creature(sim, Vector2(130, 70))
	_creature(sim, Vector2(140, 92))
	sim.step(CombatInput.press(&"skill"))
	_step_until(sim, effects, func() -> bool: return _bow(sim).mark_ticks > 0)
	_step_until(sim, effects, func() -> bool: return sim.player.state == Fighter.State.FREE)


func _rain(sim: CombatSim, effects: Array[Dictionary]) -> void:
	_creature(sim, Vector2(130, 70))
	_creature(sim, Vector2(140, 92))
	_creature(sim, Vector2(118, 96))
	_bow(sim).flow = 3
	sim.step(CombatInput.press(&"skill"))
	_step_until(sim, effects, func() -> bool: return _bow(sim).mark_ticks > 0)
	_step_until(sim, effects, func() -> bool: return sim.player.state == Fighter.State.FREE)
	_bow(sim).mark = Vector2(130, 86)  # on the group
	sim.step(CombatInput.press(&"skill"))
	_step_until(sim, effects, func() -> bool:
		return not sim.zones.is_empty() and sim.zones[0].age == sim.zones[0].delay + sim.zones[0].period + 2)
