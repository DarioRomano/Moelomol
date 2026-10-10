extends TestCase
## The game clock and the day-night light (docs/design/farming.md; Q21 and
## Q22, working assumption A).

const C: GDScript = preload("res://src/farm/game_clock.gd")


func test_a_day_starts_at_six_and_lasts_fifteen_real_minutes() -> void:
	var clock: GameClock = GameClock.new()
	assert_eq(clock.day, 1, "day 1")
	assert_eq(clock.time_text(), "06:00", "starts at 6:00")
	var real_seconds: float = (GameClock.DAY_END_MINUTE - GameClock.DAY_START_MINUTE) * GameClock.REAL_SECONDS_PER_GAME_MINUTE
	assert_eq(real_seconds, 15.0 * 60.0, "6:00 to 2:00 is 15 real minutes")
	assert_false(clock.advance(real_seconds - 1.0), "a second before the end, the day goes on")
	assert_true(clock.advance(1.0), "then it ends")
	assert_eq(clock.time_text(), "02:00", "at 2:00, wrapped past midnight")


func test_the_clock_stops_at_two_until_the_next_day() -> void:
	var clock: GameClock = GameClock.new()
	clock.advance(10000.0)
	assert_eq(clock.minute, float(GameClock.DAY_END_MINUTE), "held at 2:00")
	assert_true(clock.advance(1.0), "still the end")
	clock.next_day()
	assert_eq(clock.day, 2, "day 2")
	assert_eq(clock.time_text(), "06:00", "a new morning")


func test_phases_follow_the_time_of_day() -> void:
	var expected: Dictionary = {
		6 * 60: GameClock.DAWN, 6 * 60 + 59: GameClock.DAWN, 7 * 60: GameClock.DAY, 17 * 60 + 59: GameClock.DAY,
		18 * 60: GameClock.DUSK, 19 * 60 + 59: GameClock.DUSK, 20 * 60: GameClock.NIGHT, 25 * 60 + 59: GameClock.NIGHT,
	}
	for at: int in expected:
		assert_eq(GameClock.phase_at(at), expected[at], "%d:%02d" % [(at / 60) % 24, at % 60])


func test_the_light_is_full_by_day_amber_at_dusk_and_blue_at_night() -> void:
	assert_eq(GameClock.sky_tint_at(12 * 60), Color(1, 1, 1), "noon: untinted")
	var dusk: Color = GameClock.sky_tint_at(19 * 60)
	assert_true(dusk.r > dusk.b, "dusk is warm (more red than blue)")
	var night: Color = GameClock.sky_tint_at(23 * 60)
	assert_true(night.b > night.r and night.get_luminance() < 0.6, "night is dark (luminance %.2f) and blue" % night.get_luminance())
	var dawn: Color = GameClock.sky_tint_at(6 * 60)
	assert_true(dawn.b > dawn.r and dawn.v > night.v, "dawn is cool, lighter than night")


func test_the_light_changes_smoothly() -> void:
	var previous: Color = GameClock.sky_tint_at(GameClock.DAY_START_MINUTE)
	for at: int in range(GameClock.DAY_START_MINUTE + 1, GameClock.DAY_END_MINUTE + 1):
		var tint: Color = GameClock.sky_tint_at(at)
		var jump: float = absf(tint.r - previous.r) + absf(tint.g - previous.g) + absf(tint.b - previous.b)
		assert_true(jump < 0.03, "no jump at minute %d (%.3f)" % [at, jump])
		previous = tint


func test_the_base_lights_come_on_through_dusk() -> void:
	var clock: GameClock = GameClock.new()
	clock.minute = 12 * 60
	assert_eq(clock.lights(), 0.0, "off by day")
	clock.minute = 19 * 60
	assert_true(clock.lights() > 0.0 and clock.lights() < 1.0, "coming on at dusk")
	clock.minute = 21 * 60
	assert_eq(clock.lights(), 1.0, "on at night")
