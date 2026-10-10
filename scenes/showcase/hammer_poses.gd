extends PoseSheet
## Hammer review poses (PoseSheet): the jab, the charge and its sweet spot,
## the perfect strike's shockwave and armour break, Overstrain, Ground stamp.

const HAMMER: int = 1


func _make_panels() -> Array[Dictionary]:
	return [
		_pose("Jab", _jab, HAMMER),
		_pose("Charge in the sweet spot: the head flashes", _sweet_spot, HAMMER),
		_pose("Perfect strike: the shockwave staggers all", _shockwave, HAMMER),
		_pose("Perfect strike shatters a shell", _armour_break, HAMMER),
		_pose("Held past the sweet spot: Overstrain", _overstrain, HAMMER),
		_pose("Ground stamp: get off me", _ground_stamp, HAMMER),
	]


static func _hammer(sim: CombatSim) -> Hammer:
	return sim.player.weapon() as Hammer


## Presses heavy and holds it until the charge has been held `held` ticks.
static func _charge_to(sim: CombatSim, effects: Array[Dictionary], held: int) -> void:
	sim.step(CombatInput.press(&"heavy"))
	_step_until(sim, effects, func() -> bool: return sim.player.state_tick >= held, CombatInput.hold_heavy())


func _jab(sim: CombatSim, effects: Array[Dictionary]) -> void:
	_creature(sim, Vector2(84, 80))
	sim.step(CombatInput.press(&"light"))
	_step_until(sim, effects, func() -> bool: return sim.player.attack_phase() == &"active" and sim.hitstop > 0)


func _sweet_spot(sim: CombatSim, effects: Array[Dictionary]) -> void:
	_creature(sim, Vector2(100, 80))
	_charge_to(sim, effects, _hammer(sim).sweet_spot_ticks().x + 3)


func _shockwave(sim: CombatSim, effects: Array[Dictionary]) -> void:
	sim.player.position = Vector2(100, 76)
	sim.player.previous_position = sim.player.position
	_creature(sim, Vector2(126, 76))
	_creature(sim, Vector2(76, 82))
	_creature(sim, Vector2(100, 102))
	_charge_to(sim, effects, _hammer(sim).sweet_spot_ticks().x + 2)
	sim.step(CombatInput.new())
	_step_until(sim, effects, func() -> bool: return _effect_age(effects, "shockwave") >= 6)


func _armour_break(sim: CombatSim, effects: Array[Dictionary]) -> void:
	_creature(sim, Vector2(90, 80)).give_armour(CombatTuning.ARMOURED_CREATURE_ARMOUR)
	_charge_to(sim, effects, _hammer(sim).sweet_spot_ticks().x + 2)
	sim.step(CombatInput.new())
	_step_until(sim, effects, func() -> bool: return _effect_age(effects, "armour_break") >= 5)


func _overstrain(sim: CombatSim, effects: Array[Dictionary]) -> void:
	_creature(sim, Vector2(100, 80))
	_charge_to(sim, effects, _hammer(sim).sweet_spot_ticks().y + 12)


func _ground_stamp(sim: CombatSim, effects: Array[Dictionary]) -> void:
	_creature(sim, Vector2(74, 78))
	_creature(sim, Vector2(52, 92))
	sim.step(CombatInput.press(&"skill"))
	_step_until(sim, effects, func() -> bool: return sim.player.attack_phase() == &"active" and sim.hitstop > 0)


## Age of the newest effect of `kind`, or -1.
static func _effect_age(effects: Array[Dictionary], kind: String) -> int:
	var age: int = -1
	for e: Dictionary in effects:
		if e["kind"] == kind:
			age = int(e["age"])
	return age
