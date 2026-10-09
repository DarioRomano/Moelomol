extends TestCase
## The test card's scale readout must match the scale ADR-0008 settings give,
## so the lead can trust it on a real screen.

const TestCard: GDScript = preload("res://scenes/showcase/test_card.gd")


func test_scale_at_exact_multiples() -> void:
	assert_eq(TestCard.expected_scale(Vector2i(1280, 720)), 2, "1280x720")
	assert_eq(TestCard.expected_scale(Vector2i(1920, 1080)), 3, "1920x1080")
	assert_eq(TestCard.expected_scale(Vector2i(2560, 1440)), 4, "2560x1440")
	assert_eq(TestCard.expected_scale(Vector2i(3840, 2160)), 6, "3840x2160")


func test_scale_rounds_down_between_multiples() -> void:
	# Seen in the 2026-10-09 renders: 1366x768 shows 2x with thin borders.
	assert_eq(TestCard.expected_scale(Vector2i(1366, 768)), 2, "1366x768")
	assert_eq(TestCard.expected_scale(Vector2i(2560, 1080)), 3, "2560x1080 (limited by height)")


func test_scale_never_drops_below_one() -> void:
	assert_eq(TestCard.expected_scale(Vector2i(1024, 768)), 1, "1024x768")
	assert_eq(TestCard.expected_scale(Vector2i(320, 200)), 1, "smaller than the base")
