extends TestCase
## The game clock and the day-night light (docs/design/farming.md; Q21 and
## Q22, decided 2026-10-10: a 20-minute day that fully cycles).


func test_a_full_day_lasts_twenty_real_minutes() -> void:
	var clock: GameClock = GameClock.new()
	assert_eq(clock.day(), 1, "day 1")
	assert_eq(clock.time_text(), "06:00", "starts at 6:00")
	assert_eq(clock.advance(20.0 * 60.0 - 1.0), 0, "a second short of 20 minutes, still day 1")
	assert_eq(clock.advance(1.0), 1, "then day 2 starts")
	assert_eq(clock.day(), 2, "day 2")
	assert_eq(clock.time_text(), "06:00", "at 6:00 again")


func test_an_hour_is_fifty_real_seconds() -> void:
	var clock: GameClock = GameClock.new()
	clock.advance(50.0)
	assert_eq(clock.time_text(), "07:00", "50 s: an hour")


func test_the_day_cycles_through_midnight_without_sleep() -> void:
	var clock: GameClock = GameClock.new()
	clock.advance(50.0 * 18)  # to midnight
	assert_eq(clock.time_text(), "00:00", "midnight")
	assert_eq(clock.day(), 1, "still day 1 until 6:00")
	clock.advance(50.0 * 5)
	assert_eq(clock.time_text(), "05:00", "past 2:00 and on")
	assert_eq(clock.phase(), GameClock.NIGHT, "still night")
	assert_eq(clock.advance(50.0), 1, "6:00 starts the new day, awake")


func test_sleep_skips_to_the_next_morning() -> void:
	var clock: GameClock = GameClock.new()
	clock.advance(50.0 * 8)  # 14:00, day 1
	assert_eq(clock.sleep_until_morning(), 1, "one new day")
	assert_eq(clock.day(), 2, "day 2")
	assert_eq(clock.time_text(), "06:00", "6:00")
	clock.advance(50.0 * 21)  # 3:00 in the night of day 2
	assert_eq(clock.day(), 2, "3:00 still belongs to day 2")
	clock.sleep_until_morning()
	assert_eq(clock.day(), 3, "sleeping at 3:00 wakes on day 3")
	assert_eq(clock.time_text(), "06:00", "at 6:00, three hours later")


func test_phases_follow_the_time_of_day() -> void:
	var expected: Dictionary = {
		6 * 60: GameClock.DAWN, 6 * 60 + 59: GameClock.DAWN, 7 * 60: GameClock.DAY, 17 * 60 + 59: GameClock.DAY,
		18 * 60: GameClock.DUSK, 19 * 60 + 59: GameClock.DUSK, 20 * 60: GameClock.NIGHT, 23 * 60 + 59: GameClock.NIGHT,
		0: GameClock.NIGHT, 5 * 60 + 59: GameClock.NIGHT,
	}
	for at: int in expected:
		assert_eq(GameClock.phase_at(at), expected[at], "%d:%02d" % [at / 60, at % 60])


func test_the_light_is_full_by_day_amber_at_dusk_and_blue_at_night() -> void:
	assert_eq(GameClock.sky_tint_at(12 * 60), Color(1, 1, 1), "noon: untinted")
	var dusk: Color = GameClock.sky_tint_at(19 * 60)
	assert_true(dusk.r > dusk.b, "dusk is warm (more red than blue)")
	for at: int in [23 * 60, 2 * 60, 5 * 60]:
		var night: Color = GameClock.sky_tint_at(at)
		assert_true(night.b > night.r and night.get_luminance() < 0.6,
			"night at %d:00 is dark (luminance %.2f) and blue" % [at / 60, night.get_luminance()])
	var dawn: Color = GameClock.sky_tint_at(6 * 60)
	assert_true(dawn.b > dawn.r and dawn.v > GameClock.sky_tint_at(23 * 60).v, "dawn is cool, lighter than night")


func test_the_light_changes_smoothly_all_round_the_clock() -> void:
	var previous: Color = GameClock.sky_tint_at(0)
	for at: int in range(1, GameClock.MINUTES_PER_DAY + 1):
		var tint: Color = GameClock.sky_tint_at(at)
		var jump: float = absf(tint.r - previous.r) + absf(tint.g - previous.g) + absf(tint.b - previous.b)
		assert_true(jump < 0.03, "no jump at minute %d (%.3f)" % [at, jump])
		previous = tint


func test_the_base_lights_come_on_at_dusk_and_go_out_at_dawn() -> void:
	assert_eq(GameClock.lights_at(12 * 60), 0.0, "off by day")
	var dusk: float = GameClock.lights_at(19 * 60)
	assert_true(dusk > 0.0 and dusk < 1.0, "coming on at dusk")
	assert_eq(GameClock.lights_at(21 * 60), 1.0, "on at night")
	assert_eq(GameClock.lights_at(3 * 60), 1.0, "still on after midnight")
	var dawn: float = GameClock.lights_at(6 * 60 + 30)
	assert_true(dawn > 0.0 and dawn < 1.0, "going out at dawn")
	assert_eq(GameClock.lights_at(7 * 60), 0.0, "off by 7:00")
