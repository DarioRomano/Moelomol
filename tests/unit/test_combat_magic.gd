extends TestCase
## Magic and the status-effect system (docs/design/combat.md, "Magic: stack,
## then cash in" and "Status effects"), in the pure simulation.

const T: GDScript = preload("res://src/combat/combat_tuning.gd")
const S: StringName = StatusEffects.SMOULDER
const C: StringName = StatusEffects.CHILL
const R: StringName = StatusEffects.ROT


## Open 400x300 field, player at (100, 150) facing right with magic in hand
## (greatsword in the other slot), passive creatures where asked.
func _field(creature_positions: Array[Vector2] = []) -> CombatSim:
	var sim: CombatSim = CombatSim.new(Rect2(0, 0, 400, 300), Vector2(100, 150))
	sim.player.facing = Vector2.RIGHT
	sim.player.weapons[1] = Magic.new()
	sim.player.weapon_index = 1
	for at: Vector2 in creature_positions:
		sim.add_creature(at).ai_enabled = false
	return sim


func _magic(sim: CombatSim) -> Magic:
	return sim.player.weapon() as Magic


func _run(sim: CombatSim, ticks: int, input: CombatInput = CombatInput.new()) -> Array[Dictionary]:
	var seen: Array[Dictionary] = []
	for i: int in range(ticks):
		sim.step(input)
		seen.append_array(sim.events)
	return seen


func _settle(sim: CombatSim) -> Array[Dictionary]:
	var seen: Array[Dictionary] = []
	for i: int in range(400):
		if sim.projectiles.is_empty() and sim.player.state == Fighter.State.FREE and sim.hitstop == 0:
			break
		sim.step(CombatInput.new())
		seen.append_array(sim.events)
	return seen


func _count(events: Array[Dictionary], type: String) -> int:
	var n: int = 0
	for e: Dictionary in events:
		if e["type"] == type:
			n += 1
	return n


## Presses heavy and holds until the Siphon forms (its first pull lands),
## then for `periods` more pulls, then lets go and lets the beam play out.
func _siphon(sim: CombatSim, periods: int, release: bool = true) -> Array[Dictionary]:
	sim.step(CombatInput.press(&"heavy"))
	var seen: Array[Dictionary] = sim.events.duplicate()
	for i: int in range(60):
		if _magic(sim).siphoning:
			break
		sim.step(CombatInput.hold_heavy())
		seen.append_array(sim.events)
	seen.append_array(_run(sim, T.ticks(Magic.SIPHON_PERIOD_MS) * periods, CombatInput.hold_heavy()))
	if release:
		sim.step(CombatInput.new())
		seen.append_array(sim.events)
		seen.append_array(_settle(sim))
	return seen


# --- The effect system --------------------------------------------------------------

func test_stacks_cap_at_five_and_refresh_their_duration() -> void:
	var e: StatusEffects = StatusEffects.new()
	e.add(S, 3)
	e.add(S, 4)
	assert_eq(e.count(S), 5, "capped at 5")
	for i: int in range(T.ticks(StatusEffects.DURATION_MS) - 1):
		e.tick()
	assert_eq(e.count(S), 5, "all five until the duration runs out")
	e.add(S, 1)  # refresh
	for i: int in range(T.ticks(StatusEffects.DURATION_MS) - 1):
		e.tick()
	assert_eq(e.count(S), 5, "a new application restarts the duration")
	e.tick()
	assert_eq(e.count(S), 4, "then one stack falls off")
	for i: int in range(T.ticks(StatusEffects.DECAY_MS)):
		e.tick()
	assert_eq(e.count(S), 3, "and one more every second")


func test_smoulder_and_rot_deal_damage_every_second() -> void:
	var e: StatusEffects = StatusEffects.new()
	e.add(S, 3)
	e.add(R, 2)
	var total: float = 0.0
	var ticks_with_damage: int = 0
	for i: int in range(T.ticks(1000) * 3):
		var d: float = e.tick()
		if d > 0.0:
			total += d
			ticks_with_damage += 1
	assert_eq(ticks_with_damage, 3, "once per second")
	assert_eq(total, 3 * (3 * StatusEffects.SMOULDER_DAMAGE_PER_STACK + 2 * StatusEffects.ROT_DAMAGE_PER_STACK),
		"more stacks, more damage per second")


func test_rot_increases_damage_taken_and_slows_poise_refill() -> void:
	var e: StatusEffects = StatusEffects.new()
	e.add(R, 4)
	assert_eq(e.damage_taken_multiplier(), 1.2, "+5% per stack")
	assert_true(absf(e.poise_regen_scale() - 0.4) < 0.0001, "poise refills at 40%")
	var sim: CombatSim = _field([Vector2(125, 150)])
	var c: Fighter = sim.creatures[0]
	sim.apply_effect(c, R, 4)
	sim._hit(sim.player, c, Greatsword.LIGHTS[0])
	assert_eq(c.health, T.CREATURE_HEALTH - Greatsword.LIGHTS[0].damage * 1.2, "a sword hit lands 20% harder")


func test_release_damage_grows_per_stack_and_per_effect() -> void:
	assert_eq(StatusEffects.release_damage({S: 1}), 4.0, "one stack")
	assert_eq(StatusEffects.release_damage({S: 5}), 40.0, "five stacks: 4+6+8+10+12")
	assert_eq(StatusEffects.release_damage({S: 5, C: 5}), 160.0, "two effects: +100%")
	assert_eq(StatusEffects.release_damage({S: 5, C: 5, R: 5}), 360.0, "three effects: +200%")


# --- Spells -------------------------------------------------------------------------

func test_ember_bolt_applies_smoulder_and_costs_focus() -> void:
	var sim: CombatSim = _field([Vector2(200, 150)])
	sim.step(CombatInput.press(&"light"))
	assert_eq(sim.player.move, Magic.EMBER_BOLT, "Ember bolt")
	assert_true(absf(_magic(sim).focus - (Magic.FOCUS_MAX - Magic.EMBER_FOCUS)) < 0.5, "Focus spent")
	_settle(sim)
	assert_eq(sim.creatures[0].effects.count(S), 1, "one Smoulder stack")


func test_heavy_tap_is_a_frost_shard_with_two_chill() -> void:
	var sim: CombatSim = _field([Vector2(200, 150)])
	sim.step(CombatInput.press(&"heavy"))
	_run(sim, 3, CombatInput.hold_heavy())
	sim.step(CombatInput.new())
	assert_eq(sim.player.move, Magic.FROST_SHARD, "a short press is the Frost shard")
	_settle(sim)
	assert_eq(sim.creatures[0].effects.count(C), 2, "two Chill stacks")


func test_skill_places_a_rot_pool_that_gives_rot_without_hitting() -> void:
	var sim: CombatSim = _field([Vector2(140, 150), Vector2(220, 150)])
	sim.step(CombatInput.press(&"skill"))
	var seen: Array[Dictionary] = sim.events.duplicate()
	assert_eq(_count(seen, "pool"), 1, "a pool at once")
	assert_eq(sim.player.move, Magic.ROT_POOL, "the cast's recovery")
	assert_true(absf(_magic(sim).focus - (Magic.FOCUS_MAX - Magic.POOL_FOCUS)) < 0.5, "Focus spent")
	assert_true(sim.zones[0].position.distance_to(Vector2(140, 150)) < 1.0, "40 px in front")
	seen = _run(sim, T.ticks(Magic.POOL_PERIOD_MS) * 3)
	assert_eq(sim.creatures[0].effects.count(R), 4, "a Rot stack as it lands, then one every half second")
	assert_eq(sim.creatures[1].effects.count(R), 0, "nothing outside the pool")
	assert_eq(_count(seen, "hit"), 0, "standing in a pool is not a hit")


func test_casting_slows_but_never_roots() -> void:
	var sim: CombatSim = _field()
	var input: CombatInput = CombatInput.press(&"light")
	input.move = Vector2.DOWN
	sim.step(input)
	var start: Vector2 = sim.player.position
	_run(sim, 6, CombatInput.with_move(Vector2.DOWN))
	var moved: float = sim.player.position.distance_to(start)
	assert_true(absf(moved - 6 * T.per_tick(Magic.CAST_MOVE_SPEED)) < 0.1, "walks at cast speed (%.2f px)" % moved)


func test_a_hit_during_the_windup_interrupts_the_cast() -> void:
	var sim: CombatSim = _field([Vector2(250, 150)])
	sim.step(CombatInput.press(&"light"))
	assert_eq(sim.player.move, Magic.EMBER_BOLT, "Ember bolt winding up")
	var lunge: CombatMove = sim._creature_lunge
	lunge.poise_damage = 0.0  # no stagger: the interruption alone
	sim._hit(sim.creatures[0], sim.player, lunge)
	lunge.poise_damage = T.CREATURE_POISE_DAMAGE
	assert_eq(sim.player.state, Fighter.State.FREE, "the cast is gone")
	assert_eq(sim.events.filter(func(e: Dictionary) -> bool: return e["type"] == "interrupted").size(), 1, "reported")


func test_a_hit_while_holding_heavy_interrupts_too() -> void:
	var sim: CombatSim = _field([Vector2(250, 150)])
	sim.step(CombatInput.press(&"heavy"))
	_run(sim, 5, CombatInput.hold_heavy())
	var lunge: CombatMove = sim._creature_lunge
	lunge.poise_damage = 0.0
	sim._hit(sim.creatures[0], sim.player, lunge)
	lunge.poise_damage = T.CREATURE_POISE_DAMAGE
	assert_eq(sim.player.state, Fighter.State.FREE, "no Siphon, no shard")


# --- Full stacks ----------------------------------------------------------------------

func test_full_smoulder_spreads_a_stack_to_creatures_nearby() -> void:
	var sim: CombatSim = _field([Vector2(200, 150), Vector2(220, 160), Vector2(260, 150)])
	sim.apply_effect(sim.creatures[0], S, 5)
	assert_eq(sim.creatures[1].effects.count(S), 1, "the neighbour catches one stack")
	assert_eq(sim.creatures[2].effects.count(S), 0, "too far to catch")
	sim.apply_effect(sim.creatures[0], S, 1)
	assert_eq(sim.creatures[1].effects.count(S), 1, "only reaching five spreads, not staying there")


func test_full_chill_freezes_whatever_the_poise() -> void:
	var sim: CombatSim = _field([Vector2(200, 150)])
	var c: Fighter = sim.creatures[0]
	sim.apply_effect(c, C, 5)
	assert_true(c.is_staggered(), "Frozen")
	assert_eq(c.state_length, T.ticks(StatusEffects.FROZEN_MS), "for a second")
	assert_eq(c.poise.current, c.poise.maximum, "without touching poise")


func test_chill_slows_creature_movement_and_attacks() -> void:
	var sim: CombatSim = _field([Vector2(250, 150)])
	var c: Fighter = sim.creatures[0]
	c.ai_enabled = true
	sim.apply_effect(c, C, 4)
	var start: Vector2 = c.position
	_run(sim, 30)
	var moved: float = start.distance_to(c.position)
	assert_true(absf(moved - 30 * T.per_tick(T.CREATURE_SPEED) * 0.6) < 0.5, "60%% speed at 4 Chill (moved %.1f)" % moved)
	var slow: Fighter = sim.add_creature(Vector2(120, 100))
	slow.ai_enabled = false
	sim.apply_effect(slow, C, 4)
	slow.facing = Vector2.DOWN
	sim.start_attack(slow, sim._creature_lunge)
	var ticks_to_active: int = 0
	while slow.attack_phase() == &"windup" and ticks_to_active < 200:
		sim.step(CombatInput.new())
		ticks_to_active += 1
	var normal: int = sim._creature_lunge.windup_ticks()
	assert_true(ticks_to_active >= int(normal / 0.6) - 1, "the telegraph lasts longer (%d vs %d ticks)" % [ticks_to_active, normal])


func test_full_rot_weakens_armour() -> void:
	var sim: CombatSim = _field([Vector2(200, 150)])
	var c: Fighter = sim.creatures[0]
	c.give_armour(60.0)
	sim.apply_effect(c, R, 5)
	assert_eq(c.armour, 30.0, "armour halved")


func test_creatures_can_resist_an_effect() -> void:
	var sim: CombatSim = _field([Vector2(200, 150)])
	var c: Fighter = sim.creatures[0]
	c.resists = [S] as Array[StringName]
	sim.apply_effect(c, S, 3)
	sim.apply_effect(c, C, 1)
	assert_eq(c.effects.count(S), 0, "ignores Smoulder")
	assert_eq(c.effects.count(C), 1, "still takes Chill")


func test_damage_over_time_can_defeat_a_creature() -> void:
	var sim: CombatSim = _field([Vector2(200, 150)])
	var c: Fighter = sim.creatures[0]
	c.health = 5.0
	sim.apply_effect(c, S, 5)
	_run(sim, T.ticks(1000) + 1)
	assert_false(c.is_alive(), "burnt down")


func test_effects_are_cleared_when_a_creature_returns() -> void:
	var sim: CombatSim = _field([Vector2(200, 150)])
	var c: Fighter = sim.creatures[0]
	sim.apply_effect(c, R, 3)
	sim._respawn(c)
	assert_eq(c.effects.total(), 0, "a clean start")


# --- Siphon (heavy hold) and its beam ----------------------------------------------------

func test_holding_heavy_siphons_the_creature_in_front() -> void:
	var sim: CombatSim = _field([Vector2(125, 150)])
	var c: Fighter = sim.creatures[0]
	sim.apply_effect(c, S, 3)
	sim.apply_effect(c, R, 2)
	var seen: Array[Dictionary] = _siphon(sim, 0, false)
	var magic: Magic = _magic(sim)
	assert_eq(_count(seen, "siphon"), 1, "the Siphon forms")
	assert_eq(magic.siphon_target, c, "tethered to the creature in front")
	assert_eq(magic.drained, {S: 1, R: 1}, "the first pull: one of each kind")
	assert_eq([c.effects.count(S), c.effects.count(R)], [2, 1], "taken off the creature")
	assert_true(absf(magic.focus - (Magic.FOCUS_MAX - Magic.SIPHON_FOCUS)) < 1.0, "Focus spent (%.1f)" % magic.focus)
	assert_eq(sim.player.state, Fighter.State.CHARGE, "still holding")


func test_the_siphon_pulls_one_of_each_kind_every_200_ms() -> void:
	var sim: CombatSim = _field([Vector2(125, 150)])
	var c: Fighter = sim.creatures[0]
	sim.apply_effect(c, S, 3)
	sim.apply_effect(c, C, 1)
	_siphon(sim, 1, false)
	assert_eq(_magic(sim).drained, {S: 2, C: 1}, "two pulls; Chill ran out after one")
	_run(sim, T.ticks(Magic.SIPHON_PERIOD_MS) - 1, CombatInput.hold_heavy())
	assert_eq(_magic(sim).drained, {S: 2, C: 1}, "not before the next 200 ms")
	_run(sim, 1, CombatInput.hold_heavy())
	assert_eq(_magic(sim).drained, {S: 3, C: 1}, "then the third")
	assert_eq(c.effects.total(), 0, "drained dry")


func test_letting_go_fires_a_beam_with_the_drained_burst() -> void:
	var sim: CombatSim = _field([Vector2(125, 150)])
	var c: Fighter = sim.creatures[0]
	sim.apply_effect(c, S, 3)
	sim.apply_effect(c, R, 2)
	var seen: Array[Dictionary] = _siphon(sim, 2)
	var expected: float = StatusEffects.release_damage({S: 3, R: 2})
	assert_eq(_count(seen, "beam"), 1, "one beam")
	assert_eq(_count(seen, "release"), 1, "one burst")
	assert_true(absf(c.health - (T.CREATURE_HEALTH - expected)) < 0.01,
		"the burst (%.1f expected, %.1f taken)" % [expected, T.CREATURE_HEALTH - c.health])
	assert_eq(c.effects.count(S), 1, "drained Smoulder sets what it hits smouldering again")
	assert_false(_magic(sim).siphoning, "the lantern is empty")


func test_the_beam_fires_by_itself_after_a_second_and_a_half() -> void:
	var sim: CombatSim = _field([Vector2(125, 150)])
	sim.apply_effect(sim.creatures[0], S, 5)
	var seen: Array[Dictionary] = _siphon(sim, 0, false)
	seen.append_array(_run(sim, T.ticks(Magic.SIPHON_MAX_MS) - 1, CombatInput.hold_heavy()))
	assert_eq(_count(seen, "beam"), 0, "not yet")
	seen.append_array(_run(sim, 1, CombatInput.hold_heavy()))
	assert_eq(_count(seen, "beam"), 1, "fired while still held")


func test_the_beam_hits_the_line_behind_for_half() -> void:
	var sim: CombatSim = _field([Vector2(125, 150), Vector2(200, 152), Vector2(200, 190)])
	sim.apply_effect(sim.creatures[0], S, 2)
	_siphon(sim, 1)
	var burst: float = StatusEffects.release_damage({S: 2})
	assert_true(absf(sim.creatures[1].health - (T.CREATURE_HEALTH - burst * Magic.BEAM_SPLASH_SHARE)) < 0.01,
		"the creature behind takes half (%.1f)" % (T.CREATURE_HEALTH - sim.creatures[1].health))
	assert_eq(sim.creatures[2].health, T.CREATURE_HEALTH, "one off the line is untouched")


func test_a_beam_with_nothing_drained_is_weak() -> void:
	var sim: CombatSim = _field([Vector2(125, 150)])
	var seen: Array[Dictionary] = _siphon(sim, 1)
	assert_eq(_count(seen, "beam"), 1, "the beam still fires")
	assert_eq(sim.creatures[0].health, T.CREATURE_HEALTH - Magic.BEAM_WEAK_DAMAGE, "a weak hit")


func test_the_siphon_takes_the_lock_target_or_the_nearest_in_front() -> void:
	var sim: CombatSim = _field([Vector2(60, 150), Vector2(170, 150), Vector2(140, 150)])
	assert_eq(Magic.siphon_target_for(sim), sim.creatures[2], "the nearest in front, not the one behind")
	sim.lock_target = sim.creatures[1]
	assert_eq(Magic.siphon_target_for(sim), sim.creatures[1], "the lock target when in range")
	sim.lock_target = null
	sim.creatures[2].position = Vector2(100 + T.PLAYER_RADIUS + T.CREATURE_RADIUS + Magic.SIPHON_RANGE + 1.0, 150)
	sim.creatures[1].position = Vector2(300, 150)
	assert_eq(Magic.siphon_target_for(sim), null, "nothing beyond the range")


func test_a_hit_while_siphoning_loses_what_was_drained() -> void:
	var sim: CombatSim = _field([Vector2(125, 150)])
	sim.apply_effect(sim.creatures[0], S, 3)
	_siphon(sim, 1, false)
	var lunge: CombatMove = sim._creature_lunge
	lunge.poise_damage = 0.0
	sim._hit(sim.creatures[0], sim.player, lunge)
	lunge.poise_damage = T.CREATURE_POISE_DAMAGE
	assert_eq(sim.player.state, Fighter.State.FREE, "interrupted")
	assert_true(_magic(sim).drained.is_empty(), "the lantern is empty")
	var seen: Array[Dictionary] = _run(sim, 30)
	assert_eq(_count(seen, "beam"), 0, "no beam")


func test_the_tether_snaps_when_the_creature_gets_too_far() -> void:
	var sim: CombatSim = _field([Vector2(125, 150)])
	sim.apply_effect(sim.creatures[0], S, 5)
	_siphon(sim, 0, false)
	sim.creatures[0].position = Vector2(100 + Magic.SIPHON_BREAK_RANGE + 10.0, 150)
	var seen: Array[Dictionary] = _run(sim, T.ticks(Magic.SIPHON_PERIOD_MS), CombatInput.hold_heavy())
	assert_eq(_count(seen, "siphon_snap"), 1, "snapped")
	assert_eq(_magic(sim).drained, {S: 1}, "keeps what it had, drains no more")


func test_drained_chill_freezes_the_first_creature() -> void:
	var sim: CombatSim = _field([Vector2(125, 150)])
	sim.apply_effect(sim.creatures[0], C, 3)
	var seen: Array[Dictionary] = _siphon(sim, 2, false)
	sim.step(CombatInput.new())
	seen.append_array(sim.events)
	assert_eq(_count(seen, "frozen"), 1, "Frozen")
	assert_true(sim.creatures[0].is_staggered(), "and staggered")


func test_drained_rot_rots_the_others_on_the_line() -> void:
	var sim: CombatSim = _field([Vector2(125, 150), Vector2(230, 150)])
	sim.apply_effect(sim.creatures[0], R, 1)
	_siphon(sim, 0)
	assert_eq(sim.creatures[1].effects.count(R), Magic.BEAM_ROT_STACKS, "the one behind gains Rot")
	assert_eq(sim.creatures[0].effects.count(R), 0, "not the first")


func test_smoulder_and_chill_shatter_onto_creatures_around() -> void:
	var sim: CombatSim = _field([Vector2(125, 150), Vector2(150, 170), Vector2(200, 190)])
	sim.apply_effect(sim.creatures[0], S, 2)
	sim.apply_effect(sim.creatures[0], C, 2)
	var seen: Array[Dictionary] = _siphon(sim, 1)
	assert_eq(_count(seen, "shatter"), 1, "Shatter")
	assert_eq(sim.creatures[1].health, T.CREATURE_HEALTH - Magic.SHATTER.damage, "the neighbour is hit")
	assert_eq(sim.creatures[2].health, T.CREATURE_HEALTH, "a creature beyond the blast is not")


func test_smoulder_and_rot_bloom_rot_onto_creatures_nearby() -> void:
	var sim: CombatSim = _field([Vector2(125, 150), Vector2(160, 170), Vector2(240, 200)])
	sim.apply_effect(sim.creatures[0], S, 2)
	sim.apply_effect(sim.creatures[0], R, 2)
	var seen: Array[Dictionary] = _siphon(sim, 1)
	assert_eq(_count(seen, "blight_bloom"), 1, "Blight bloom")
	assert_eq(sim.creatures[1].effects.count(R), Magic.BLIGHT_ROT_STACKS, "Rot spreads to the neighbour")
	assert_eq(sim.creatures[2].effects.count(R), 0, "not to a distant creature")


func test_chill_and_rot_make_the_target_brittle() -> void:
	var sim: CombatSim = _field([Vector2(125, 150)])
	sim.apply_effect(sim.creatures[0], C, 1)
	sim.apply_effect(sim.creatures[0], R, 1)
	var seen: Array[Dictionary] = _siphon(sim, 0, false)
	sim.step(CombatInput.new())
	seen.append_array(sim.events)
	assert_eq(_count(seen, "brittle"), 1, "Brittle")
	assert_true(sim.creatures[0].is_staggered(), "the target is staggered")


func test_a_perfect_hammer_strike_counts_as_a_release() -> void:
	var sim: CombatSim = _field([Vector2(125, 150)])
	sim.player.weapons[1] = Hammer.new()
	var c: Fighter = sim.creatures[0]
	sim.apply_effect(c, S, 4)
	sim.step(CombatInput.press(&"heavy"))
	_run(sim, T.ticks(Hammer.SWEET_SPOT_START_MS), CombatInput.hold_heavy())
	sim.step(CombatInput.new())
	var seen: Array[Dictionary] = _settle(sim)
	assert_eq(_count(seen, "release"), 1, "the strike released the stacks")
	assert_eq(c.effects.total(), 0, "consumed")


# --- Focus and Wardstep -------------------------------------------------------------

func test_spells_need_focus() -> void:
	var sim: CombatSim = _field()
	_magic(sim).focus = Magic.EMBER_FOCUS - 1.0
	sim.step(CombatInput.press(&"light"))
	assert_eq(sim.player.state, Fighter.State.FREE, "no cast")
	assert_eq(sim.events[0]["type"], "no_focus", "reported")


func test_focus_refills_faster_after_a_few_seconds_unhit() -> void:
	var sim: CombatSim = _field([Vector2(300, 150)])
	var magic: Magic = _magic(sim)
	magic.focus = 0.0
	_run(sim, 60)
	assert_true(absf(magic.focus - Magic.FOCUS_FAST_REGEN_PER_S) < 0.5, "fast when untouched (%.1f)" % magic.focus)
	var lunge: CombatMove = sim._creature_lunge
	sim._hit(sim.creatures[0], sim.player, lunge)
	magic.focus = 0.0
	_run(sim, 60)
	assert_true(absf(magic.focus - Magic.FOCUS_REGEN_PER_S) < 0.5, "slow right after a hit (%.1f)" % magic.focus)
	_run(sim, T.ticks(Magic.FOCUS_FAST_AFTER_MS))
	assert_eq(magic.focus_regen_per_s(), Magic.FOCUS_FAST_REGEN_PER_S, "fast again after 3 s")


func test_wardstep_blinks_and_leaves_a_chill_pool() -> void:
	var sim: CombatSim = _field([Vector2(100, 150)])
	var c: Fighter = sim.creatures[0]
	sim.player.position = Vector2(110, 150)
	sim._separate_fighters()
	var from: Vector2 = sim.player.position
	var blink: CombatInput = CombatInput.press(&"dodge")
	blink.move = Vector2.RIGHT
	sim.step(blink)
	assert_true(absf(sim.player.position.x - from.x - Magic.WARDSTEP_DISTANCE) < 0.01, "40 px at once")
	assert_eq(sim.player.state, Fighter.State.DODGE, "in the blink")
	assert_true(sim.player.is_invulnerable(), "invulnerable from the first tick")
	_run(sim, T.ticks(Magic.WARDSTEP_MS) - 2)
	assert_true(sim.player.is_invulnerable(), "and to the last")
	assert_eq(sim.zones.size(), 1, "a pool where the player stood")
	_run(sim, T.ticks(Magic.CHILL_POOL_PERIOD_MS) * 2)
	assert_true(c.effects.count(C) >= 2, "the creature standing there is chilled")


func test_wardstep_stops_at_walls() -> void:
	var sim: CombatSim = _field()
	sim.player.position = Vector2(380, 150)
	var blink: CombatInput = CombatInput.press(&"dodge")
	blink.move = Vector2.RIGHT
	sim.step(blink)
	assert_eq(sim.player.position.x, 400.0 - T.PLAYER_RADIUS, "against the wall, not through it")


# --- Feedback -------------------------------------------------------------------------

func test_magic_events_map_to_haptic_effects() -> void:
	var p: Fighter = Fighter.make_player(Vector2.ZERO)
	var c: Fighter = Fighter.make_creature(Vector2.ZERO)
	assert_eq(Haptics.effect_for_event({"type": "cast", "fighter": p}), &"spell_cast", "faint cast buzz")
	assert_eq(Haptics.effect_for_event({"type": "hit", "target": c, "move": &"ember"}), &"spell_hit", "bolt hit")
	assert_eq(Haptics.effect_for_event({"type": "release", "consumed": {S: 3}}), &"release", "small release")
	assert_eq(Haptics.effect_for_event({"type": "release", "consumed": {S: 5, C: 2}}), &"release_big", "big release")
	assert_eq(Haptics.effect_for_event({"type": "hit", "target": c, "move": &"siphon_beam"}), &"", "no double pulse")
	assert_eq(Haptics.effect_for_event({"type": "siphon", "fighter": p}), &"spell_cast", "the tether forms")
	assert_eq(Haptics.effect_for_event({"type": "siphon_drain", "taken": {S: 1}}), &"siphon_drain", "a tug per pull")
	assert_eq(Haptics.effect_for_event({"type": "wardstep"}), &"wardstep", "blink")
