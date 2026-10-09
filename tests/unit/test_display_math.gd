extends TestCase
## DisplayMath must predict what ADR-0008's settings produce. The same model
## is checked against real renders by tools/render_showcase.gd; these tests
## pin the arithmetic for the screen sizes the lead named.


func _check(window: Vector2i, view: Vector2i, scale: int) -> void:
	var label: String = "%dx%d" % [window.x, window.y]
	assert_eq(DisplayMath.expected_view_size(window), view, label + " view")
	assert_eq(DisplayMath.expected_scale(window), scale, label + " scale")


func test_16_9_screens_fill_exactly() -> void:
	_check(Vector2i(1280, 720), Vector2i(640, 360), 2)
	_check(Vector2i(1920, 1080), Vector2i(640, 360), 3)
	_check(Vector2i(2560, 1440), Vector2i(640, 360), 4)
	_check(Vector2i(3840, 2160), Vector2i(640, 360), 6)


func test_ultrawide_21_9() -> void:
	# Lead, 2026-10-09: support 21:9 at 1080p and 1440p.
	_check(Vector2i(2560, 1080), Vector2i(853, 360), 3)
	_check(Vector2i(3440, 1440), Vector2i(860, 360), 4)


func test_super_ultrawide_32_9() -> void:
	# Lead, 2026-10-09: support 32:9 at 1080p and 1440p. Twice the 16:9 width.
	_check(Vector2i(3840, 1080), Vector2i(1280, 360), 3)
	_check(Vector2i(5120, 1440), Vector2i(1280, 360), 4)


func test_16_10_shows_more_height() -> void:
	_check(Vector2i(1280, 800), Vector2i(640, 400), 2)
	_check(Vector2i(2560, 1600), Vector2i(640, 400), 4)


func test_non_multiples_round_down_and_leave_borders() -> void:
	# Seen in the first renders: 1366x768 keeps a 640x360 view at 2x.
	_check(Vector2i(1366, 768), Vector2i(640, 360), 2)
	_check(Vector2i(1024, 768), Vector2i(640, 480), 1)


func test_scale_never_drops_below_one() -> void:
	assert_eq(DisplayMath.expected_scale(Vector2i(320, 200)), 1, "smaller than the base")


func test_no_window_does_not_divide_by_zero() -> void:
	# Found 2026-10-09: headless runs report a 0x0 window and the test card
	# divided by zero. The runner turns that error into a failure.
	_check(Vector2i(0, 0), Vector2i(640, 360), 1)
