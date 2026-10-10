extends TestCase
## Combat rules (docs/design/combat.md) in the pure simulation. Each test builds
## a small open field and drives CombatSim.step() tick by tick.

const T: GDScript = preload("res://src/combat/combat_tuning.gd")


## An open 400x300 field, player at (100, 150), passive creatures where asked.
func _field(creature_positions: Array[Vector2] = []) -> CombatSim:
	var sim: CombatSim = CombatSim.new(Rect2(0, 0, 400, 300), Vector2(100, 150))
	sim.player.facing = Vector2.RIGHT
	for at: Vector2 in creature_positions:
		sim.add_creature(at).ai_enabled = false
	return sim


func _run(sim: CombatSim, ticks: int, input: CombatInput = CombatInput.new()) -> void:
	for i: int in range(ticks):
		sim.step(input)


## Runs until the player is free again (or gives up after max_ticks).
func _until_free(sim: CombatSim, max_ticks: int = 300) -> void:
	for i: int in range(max_ticks):
		if sim.player.state == Fighter.State.FREE and sim.hitstop == 0:
			return
		sim.step(CombatInput.new())


func _press(sim: CombatSim, action: StringName) -> void:
	sim.step(CombatInput.press(action))


func _move_id(sim: CombatSim) -> StringName:
	return sim.player.move.id if sim.player.move != null else &""


## Steps until the player's attack reaches its recovery phase.
func _to_recovery(sim: CombatSim) -> void:
	for i: int in range(200):
		if sim.player.attack_phase() == &"recovery":
			return
		sim.step(CombatInput.new())


func _events_of(sim: CombatSim, type: String) -> int:
	var n: int = 0
	for e: Dictionary in sim.events:
		if e["type"] == type:
			n += 1
	return n


# --- Basics ------------------------------------------------------------------------

func test_ticks_convert_milliseconds_at_60_hz() -> void:
	assert_eq(CombatTuning.ticks(100), 6, "100 ms")
	assert_eq(CombatTuning.ticks(400), 24, "400 ms")
	assert_eq(CombatTuning.ticks(150), 9, "150 ms")
	assert_eq(CombatTuning.ticks(1), 1, "any positive time is at least one tick")
	assert_eq(CombatTuning.ticks(0), 0, "zero")


func test_stamina_spends_and_refills_after_a_delay() -> void:
	var stamina: Stamina = Stamina.new(100.0)
	assert_true(stamina.try_spend(30.0), "spend 30")
	assert_false(stamina.try_spend(80.0), "cannot spend more than is left")
	assert_eq(stamina.current, 70.0, "nothing spent on refusal")
	for i: int in range(CombatTuning.ticks(CombatTuning.STAMINA_REGEN_DELAY_MS)):
		stamina.tick()
	assert_eq(stamina.current, 70.0, "no refill during the delay")
	stamina.tick()
	assert_true(stamina.current > 70.0, "refills after the delay")


func test_poise_breaks_at_zero_and_refills() -> void:
	var poise: Poise = Poise.new(50.0)
	assert_false(poise.damage(30.0, false), "30 of 50 does not break")
	assert_true(poise.damage(30.0, false), "60 of 50 breaks")
	assert_eq(poise.current, 50.0, "refilled after breaking")


func test_hyper_armour_never_breaks_poise() -> void:
	var poise: Poise = Poise.new(50.0)
	assert_false(poise.damage(500.0, true), "hyper-armour holds")
	assert_eq(poise.current, 1.0, "poise floors at 1")


func test_player_moves_and_stops_at_walls() -> void:
	var sim: CombatSim = _field()
	_run(sim, 60, CombatInput.with_move(Vector2.RIGHT))
	assert_true(absf(sim.player.position.x - 180.0) < 0.5, "80 px in one second (got %s)" % sim.player.position.x)
	_run(sim, 600, CombatInput.with_move(Vector2.RIGHT))
	assert_eq(sim.player.position.x, 400.0 - CombatTuning.PLAYER_RADIUS, "stopped at the east wall")


func test_obstacles_block_movement() -> void:
	var sim: CombatSim = _field()
	sim.obstacles.append(Rect2(150, 130, 32, 40))
	_run(sim, 120, CombatInput.with_move(Vector2.RIGHT))
	assert_true(sim.player.position.x <= 150.0 - CombatTuning.PLAYER_RADIUS + 0.01,
		"stopped at the obstacle (x = %s)" % sim.player.position.x)


# --- Dodge ---------------------------------------------------------------------------

func test_dodge_costs_stamina_and_covers_two_tiles() -> void:
	var sim: CombatSim = _field()
	_press(sim, &"dodge")
	assert_eq(sim.player.state, Fighter.State.DODGE, "dodging")
	assert_eq(sim.player.stamina.current, CombatTuning.STAMINA_MAX - CombatTuning.DODGE_STAMINA, "stamina spent")
	_until_free(sim)
	assert_true(absf(sim.player.position.x - 132.0) < 0.5, "moved 32 px (x = %s)" % sim.player.position.x)


func test_dodge_needs_stamina() -> void:
	var sim: CombatSim = _field()
	sim.player.stamina.current = 5.0
	_press(sim, &"dodge")
	assert_eq(sim.player.state, Fighter.State.FREE, "no dodge without stamina")
	assert_eq(_events_of(sim, "no_stamina"), 1, "the refusal is reported")


func test_dodge_is_invulnerable_only_in_its_middle() -> void:
	var sim: CombatSim = _field()
	var iframe_start: int = CombatTuning.ticks(CombatTuning.DODGE_IFRAME_START_MS)
	var iframe_end: int = CombatTuning.ticks(CombatTuning.DODGE_IFRAME_END_MS)
	_press(sim, &"dodge")
	var invulnerable: Array[int] = []
	while sim.player.state == Fighter.State.DODGE:
		if sim.player.is_invulnerable():
			invulnerable.append(sim.player.state_tick)
		sim.step(CombatInput.new())
	assert_eq(invulnerable.size(), iframe_end - iframe_start, "200 ms of invulnerability")
	assert_eq(invulnerable[0], iframe_start, "starts after 100 ms")


func test_creature_attack_misses_a_dodging_player() -> void:
	var sim: CombatSim = _field([Vector2(125, 150)])
	var creature: Fighter = sim.creatures[0]
	creature.facing = Vector2.LEFT
	sim.start_attack(creature, sim._creature_lunge)
	# Dodge so the lunge's active frames land inside the invulnerable window.
	var windup: int = sim._creature_lunge.windup_ticks()
	_run(sim, windup - CombatTuning.ticks(CombatTuning.DODGE_IFRAME_START_MS) - 1)
	sim.step(CombatInput.press(&"dodge"))
	_run(sim, 30)
	assert_eq(sim.player.health, CombatTuning.PLAYER_HEALTH, "no damage through the dodge")


func test_creature_attack_hits_a_standing_player_after_its_telegraph() -> void:
	var sim: CombatSim = _field([Vector2(125, 150)])
	var creature: Fighter = sim.creatures[0]
	creature.facing = Vector2.LEFT
	sim.start_attack(creature, sim._creature_lunge)
	_run(sim, sim._creature_lunge.windup_ticks() - 1)
	assert_eq(sim.player.health, CombatTuning.PLAYER_HEALTH, "no damage during the telegraph")
	_run(sim, sim._creature_lunge.active_ticks() + 2)
	assert_eq(sim.player.health, CombatTuning.PLAYER_HEALTH - CombatTuning.CREATURE_DAMAGE, "hit after the windup")


# --- Greatsword chain ------------------------------------------------------------------

func test_heavy_alone_is_the_overhead_cleave() -> void:
	var sim: CombatSim = _field()
	_press(sim, &"heavy")
	assert_eq(_move_id(sim), &"cleave", "heavy from a standstill")


func test_finisher_depends_on_chain_position() -> void:
	var expected: Array[StringName] = [&"cleave", &"shove", &"spin", &"rising"]
	for lights: int in range(4):
		var sim: CombatSim = _field()
		for i: int in range(lights):
			_press(sim, &"light")
			_to_recovery(sim)
		_press(sim, &"heavy")
		assert_eq(_move_id(sim), expected[lights], "heavy after %d light swings" % lights)


func test_each_light_swing_starts_faster() -> void:
	assert_true(Greatsword.LIGHTS[1].windup_ms < Greatsword.LIGHTS[0].windup_ms, "second faster than first")
	assert_true(Greatsword.LIGHTS[2].windup_ms < Greatsword.LIGHTS[1].windup_ms, "third faster than second")


func test_fourth_light_starts_the_chain_again() -> void:
	var sim: CombatSim = _field()
	for i: int in range(4):
		_press(sim, &"light")
		if i < 3:
			_to_recovery(sim)
	assert_eq(_move_id(sim), &"light_1", "fourth light is the first swing again")


func test_chain_ends_if_the_attack_finishes_untouched() -> void:
	var sim: CombatSim = _field()
	_press(sim, &"light")
	_until_free(sim)
	_press(sim, &"heavy")
	assert_eq(_move_id(sim), &"cleave", "after waiting out the swing, heavy is a fresh cleave")


func test_input_pressed_just_before_recovery_is_buffered() -> void:
	var sim: CombatSim = _field()
	_press(sim, &"light")
	var to_recovery: int = Greatsword.LIGHTS[0].windup_ticks() + Greatsword.LIGHTS[0].active_ticks()
	_run(sim, to_recovery - 1 - CombatTuning.ticks(CombatTuning.INPUT_BUFFER_MS) + 1)
	_press(sim, &"light")  # within 100 ms of recovery starting
	_to_recovery(sim)
	sim.step(CombatInput.new())
	assert_eq(_move_id(sim), &"light_2", "buffered press became the second swing")


func test_input_pressed_too_early_is_dropped() -> void:
	var sim: CombatSim = _field()
	_press(sim, &"light")
	_press(sim, &"light")  # right at the start of a 300 ms windup
	_to_recovery(sim)
	sim.step(CombatInput.new())
	assert_eq(_move_id(sim), &"light_1", "too-early press did not chain")


func test_attacks_need_stamina() -> void:
	var sim: CombatSim = _field()
	sim.player.stamina.current = 3.0
	_press(sim, &"light")
	assert_eq(sim.player.state, Fighter.State.FREE, "no swing without stamina")


# --- Hits, poise and stagger ---------------------------------------------------------------

func test_light_hits_a_creature_in_front_once() -> void:
	var sim: CombatSim = _field([Vector2(125, 150)])
	_press(sim, &"light")
	_until_free(sim)
	assert_eq(sim.creatures[0].health, CombatTuning.CREATURE_HEALTH - Greatsword.LIGHTS[0].damage, "one hit")


func test_full_light_chain_lands_all_three_swings() -> void:
	# Found in the review render, 2026-10-10: each swing's push carried a
	# standing creature out of reach, so the third swing whiffed.
	var sim: CombatSim = _field([Vector2(124, 150)])
	var hits: int = 0
	for i: int in range(3):
		sim.step(CombatInput.press(&"light"))
		for t: int in range(200):
			hits += _events_of(sim, "hit")
			if sim.player.attack_phase() == &"recovery" and sim.hitstop == 0:
				break
			sim.step(CombatInput.new())
	assert_eq(hits, 3, "all three swings of the chain hit")


func test_light_misses_a_creature_behind() -> void:
	var sim: CombatSim = _field([Vector2(75, 150)])
	_press(sim, &"light")
	_until_free(sim)
	assert_eq(sim.creatures[0].health, CombatTuning.CREATURE_HEALTH, "behind the player: no hit")


func test_spin_sweep_hits_all_around() -> void:
	var sim: CombatSim = _field([Vector2(125, 150), Vector2(75, 150)])
	_press(sim, &"light")
	_to_recovery(sim)
	_press(sim, &"light")
	_to_recovery(sim)
	_press(sim, &"heavy")
	assert_eq(_move_id(sim), &"spin", "spin sweep")
	_until_free(sim)
	assert_true(sim.creatures[0].health < CombatTuning.CREATURE_HEALTH, "hit in front")
	assert_true(sim.creatures[1].health < CombatTuning.CREATURE_HEALTH, "hit behind")


func test_enough_poise_damage_staggers() -> void:
	var sim: CombatSim = _field([Vector2(125, 150)])
	var creature: Fighter = sim.creatures[0]
	# Wear poise down to 10 through damage, so it does not refill during the
	# 300 ms windup (a bare assignment would regenerate first).
	creature.poise.damage(CombatTuning.CREATURE_POISE - 10.0, false)
	_press(sim, &"light")
	_until_free(sim)
	assert_eq(creature.state, Fighter.State.STAGGERED, "15 poise damage breaks 10 poise")


func test_staggered_creatures_take_extra_damage() -> void:
	var sim: CombatSim = _field([Vector2(125, 150)])
	var creature: Fighter = sim.creatures[0]
	sim.stagger(creature)
	creature.state_length = 1000
	_press(sim, &"light")
	_until_free(sim)
	var expected: float = CombatTuning.CREATURE_HEALTH - Greatsword.LIGHTS[0].damage * CombatTuning.STAGGERED_DAMAGE_MULTIPLIER
	assert_eq(creature.health, expected, "1.5x damage while staggered")


func test_stagger_lasts_its_duration_then_ends() -> void:
	var sim: CombatSim = _field([Vector2(125, 150)])
	var creature: Fighter = sim.creatures[0]
	sim.stagger(creature)
	_run(sim, CombatTuning.ticks(CombatTuning.CREATURE_STAGGER_MS) - 1)
	assert_eq(creature.state, Fighter.State.STAGGERED, "still staggered just before 1.2 s")
	_run(sim, 2)
	assert_eq(creature.state, Fighter.State.FREE, "recovered after 1.2 s")
	sim.stagger(sim.player)
	_run(sim, CombatTuning.ticks(CombatTuning.PLAYER_STAGGER_MS) + 1)
	assert_eq(sim.player.state, Fighter.State.FREE, "the player recovers after 0.6 s")


func test_cleave_has_hyper_armour_in_its_windup() -> void:
	var sim: CombatSim = _field()
	_press(sim, &"heavy")
	assert_true(sim.player.has_hyper_armour(), "cleave windup has hyper-armour")
	var light: CombatSim = _field()
	_press(light, &"light")
	assert_false(light.player.has_hyper_armour(), "light swings do not")


func test_staggered_creature_stops_its_attack() -> void:
	var sim: CombatSim = _field([Vector2(125, 150)])
	var creature: Fighter = sim.creatures[0]
	creature.facing = Vector2.LEFT
	sim.start_attack(creature, sim._creature_lunge)
	sim.stagger(creature)
	_run(sim, sim._creature_lunge.windup_ticks() + sim._creature_lunge.active_ticks())
	assert_eq(sim.player.health, CombatTuning.PLAYER_HEALTH, "the interrupted lunge never lands")


func test_hit_stop_freezes_the_simulation() -> void:
	var sim: CombatSim = _field([Vector2(125, 150)])
	_press(sim, &"light")
	var hit_tick: int = -1
	for i: int in range(60):
		sim.step(CombatInput.new())
		if _events_of(sim, "hit") > 0:
			hit_tick = sim.tick_count
			break
	assert_true(hit_tick > 0, "the swing hit")
	var frozen_state_tick: int = sim.player.state_tick
	_run(sim, CombatTuning.ticks(Greatsword.LIGHTS[0].hitstop_ms))
	assert_eq(sim.tick_count, hit_tick, "no ticks advance during hit-stop")
	assert_eq(sim.player.state_tick, frozen_state_tick, "the swing is frozen too")


# --- Push and impacts ------------------------------------------------------------------------

## Light then heavy: the shove. At x = 150 the creature is beyond the light
## swing's reach, so only the shove's dash brings it into range.
func _shove(sim: CombatSim) -> void:
	_press(sim, &"light")
	_to_recovery(sim)
	_press(sim, &"heavy")
	_until_free(sim)


func test_shove_pushes_far_without_impact_in_the_open() -> void:
	var sim: CombatSim = _field([Vector2(150, 150)])
	_shove(sim)
	var creature: Fighter = sim.creatures[0]
	assert_true(creature.position.x > 190.0, "pushed far (x = %s)" % creature.position.x)
	assert_eq(creature.health, CombatTuning.CREATURE_HEALTH - Greatsword.FINISHERS[1].damage,
		"only the shove's damage, no impact")


func test_push_into_a_wall_is_an_impact() -> void:
	var sim: CombatSim = _field([Vector2(150, 150)])
	sim.obstacles.append(Rect2(175, 100, 20, 100))
	_shove(sim)
	var creature: Fighter = sim.creatures[0]
	var without_impact: float = CombatTuning.CREATURE_HEALTH - Greatsword.FINISHERS[1].damage
	assert_eq(creature.health, without_impact - CombatTuning.IMPACT_DAMAGE, "impact damage added")


func test_push_into_another_creature_hurts_both() -> void:
	var sim: CombatSim = _field([Vector2(150, 150), Vector2(178, 150)])
	_shove(sim)
	var second: Fighter = sim.creatures[1]
	assert_true(second.health <= CombatTuning.CREATURE_HEALTH - CombatTuning.IMPACT_DAMAGE,
		"the creature it was shoved into took impact damage (health %s)" % second.health)


# --- Follow-through and Brace ------------------------------------------------------------------

func test_skill_next_to_a_staggered_creature_is_follow_through() -> void:
	var sim: CombatSim = _field([Vector2(125, 150)])
	sim.stagger(sim.creatures[0])
	_press(sim, &"skill")
	assert_eq(_move_id(sim), &"follow_through", "Follow-through")


func test_skill_otherwise_is_brace() -> void:
	var sim: CombatSim = _field([Vector2(125, 150)])
	_press(sim, &"skill")
	assert_eq(sim.player.state, Fighter.State.BRACE, "Brace")
	assert_true(sim.player.has_hyper_armour(), "Brace has hyper-armour")


func test_far_staggered_creature_gives_brace_not_follow_through() -> void:
	var sim: CombatSim = _field([Vector2(200, 150)])
	sim.stagger(sim.creatures[0])
	_press(sim, &"skill")
	assert_eq(sim.player.state, Fighter.State.BRACE, "too far for Follow-through")


func test_hit_during_brace_makes_the_next_heavy_instant() -> void:
	var sim: CombatSim = _field([Vector2(122, 150)])
	var creature: Fighter = sim.creatures[0]
	creature.facing = Vector2.LEFT
	sim.start_attack(creature, sim._creature_lunge)
	_run(sim, sim._creature_lunge.windup_ticks() - 3)
	_press(sim, &"skill")
	_run(sim, sim._creature_lunge.active_ticks() + 2)
	assert_true(sim.player.brace_ready, "the absorbed hit readied the counter")
	assert_eq(sim.player.state, Fighter.State.BRACE, "not staggered while bracing")
	_until_free(sim)
	_press(sim, &"heavy")
	assert_eq(_move_id(sim), &"brace_counter", "instant counter")
	assert_eq(sim.player.attack_phase(), &"active", "no windup")


# --- Aim and lock-on --------------------------------------------------------------------------

func test_soft_aim_turns_towards_a_nearby_creature() -> void:
	var sim: CombatSim = _field([Vector2(125, 160)])  # about 22 degrees off
	_press(sim, &"light")
	var to_creature: Vector2 = (sim.creatures[0].position - sim.player.position).normalized()
	assert_true(sim.player.facing.is_equal_approx(to_creature), "facing turned to the creature")


func test_soft_aim_ignores_creatures_outside_the_cone() -> void:
	var sim: CombatSim = _field([Vector2(110, 175)])  # about 68 degrees off
	_press(sim, &"light")
	assert_true(sim.player.facing.is_equal_approx(Vector2.RIGHT), "facing unchanged")


func test_lock_on_picks_the_nearest_and_faces_it_while_moving() -> void:
	var sim: CombatSim = _field([Vector2(250, 150), Vector2(100, 200)])
	var input: CombatInput = CombatInput.with_move(Vector2.UP)
	input.lock_held = true
	sim.step(input)
	assert_eq(sim.lock_target, sim.creatures[1], "nearest creature")
	var to_target: Vector2 = (sim.creatures[1].position - sim.player.position).normalized()
	assert_true(sim.player.facing.is_equal_approx(to_target), "faces the target while moving away")


func test_lock_on_switches_target_and_releases() -> void:
	var sim: CombatSim = _field([Vector2(250, 150), Vector2(100, 200)])
	var hold: CombatInput = CombatInput.new()
	hold.lock_held = true
	sim.step(hold)
	var next: CombatInput = CombatInput.new()
	next.lock_held = true
	next.target_next_pressed = true
	sim.step(next)
	assert_eq(sim.lock_target, sim.creatures[0], "switched to the other creature")
	sim.step(CombatInput.new())
	assert_eq(sim.lock_target, null, "released")


func test_lock_on_ignores_creatures_out_of_range() -> void:
	var sim: CombatSim = CombatSim.new(Rect2(0, 0, 800, 300), Vector2(100, 150))
	sim.add_creature(Vector2(100 + CombatTuning.LOCK_ON_RANGE + 20.0, 150)).ai_enabled = false
	var hold: CombatInput = CombatInput.new()
	hold.lock_held = true
	sim.step(hold)
	assert_eq(sim.lock_target, null, "too far to lock on")


# --- Creature behaviour and respawn -------------------------------------------------------------

func test_creature_approaches_then_telegraphs() -> void:
	var sim: CombatSim = CombatSim.new(Rect2(0, 0, 400, 300), Vector2(100, 150))
	var creature: Fighter = sim.add_creature(Vector2(250, 150))
	_run(sim, 300)
	assert_true(creature.position.x < 150.0, "walked towards the player (x = %s)" % creature.position.x)
	var telegraphed: bool = false
	for i: int in range(120):
		sim.step(CombatInput.new())
		if creature.attack_phase() == &"windup":
			telegraphed = true
			break
	assert_true(telegraphed, "started a telegraphed attack in range")


func test_defeated_creature_fades_and_returns() -> void:
	var sim: CombatSim = _field([Vector2(125, 150)])
	var creature: Fighter = sim.creatures[0]
	creature.health = 1.0
	_press(sim, &"light")
	_until_free(sim)
	assert_eq(creature.state, Fighter.State.DOWN, "defeated")
	_run(sim, CombatTuning.ticks(CombatTuning.CREATURE_DOWN_MS) + CombatTuning.ticks(CombatTuning.CREATURE_RESPAWN_MS) + 2)
	assert_eq(creature.state, Fighter.State.FREE, "back")
	assert_eq(creature.health, CombatTuning.CREATURE_HEALTH, "at full health")
	assert_eq(creature.position, creature.spawn_position, "at its spawn point")


func test_defeated_creature_cannot_be_hit_or_locked() -> void:
	var sim: CombatSim = _field([Vector2(125, 150)])
	sim._defeat(sim.creatures[0])
	var hold: CombatInput = CombatInput.new()
	hold.lock_held = true
	sim.step(hold)
	assert_eq(sim.lock_target, null, "no lock on a defeated creature")


func test_player_recovers_after_being_downed() -> void:
	var sim: CombatSim = _field()
	sim._defeat(sim.player)
	_run(sim, CombatTuning.ticks(CombatTuning.PLAYER_DOWN_MS) + 1)
	assert_eq(sim.player.state, Fighter.State.FREE, "back on their feet")
	assert_eq(sim.player.health, CombatTuning.PLAYER_HEALTH, "full health")


func test_arena_layout_fits_the_view() -> void:
	var sim: CombatSim = CombatSim.make_arena()
	assert_true(Rect2(0, 0, 640, 360).encloses(sim.bounds), "arena inside 640x360")
	assert_eq(sim.creatures.size(), 3, "three training creatures")
	assert_eq(sim.creatures[2].armour, CombatTuning.ARMOURED_CREATURE_ARMOUR, "the third has a shell")
	for rect: Rect2 in sim.obstacles:
		assert_true(sim.bounds.encloses(rect), "obstacle inside the arena")
	for c: Fighter in sim.creatures:
		assert_eq(sim.resolve_position(c.position, c.radius), c.position, "creature starts on open ground")
