extends TestCase
## The camera's rules (ADR-0015) in FollowCamera.

const BOUNDS: Rect2 = Rect2(0, 0, 1792, 1024)  # Millbrook
## Window sizes ADR-0008 names (and the render tool uses).
const WINDOWS: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(1366, 768),
	Vector2i(1280, 800), Vector2i(2560, 1080), Vector2i(3440, 1440), Vector2i(3840, 1080), Vector2i(5120, 1440), Vector2i(1024, 768)]


func _run(cam: FollowCamera, target: Vector2, view: Vector2, seconds: float, scale: float = 3.0) -> void:
	for i: int in range(roundi(seconds * 60.0)):
		cam.update(target, view, BOUNDS, scale, 1.0 / 60.0)


func test_small_moves_inside_the_dead_zone_do_not_move_the_camera() -> void:
	var cam: FollowCamera = FollowCamera.new()
	var view: Vector2 = Vector2(640, 360)
	cam.snap(Vector2(900, 500), view, BOUNDS, 3.0)
	var start: Vector2 = cam.position
	_run(cam, Vector2(900 + FollowCamera.DEAD_ZONE_HALF.x - 1.0, 500 - FollowCamera.DEAD_ZONE_HALF.y + 1.0), view, 1.0)
	assert_eq(cam.position, start, "a step or a dodge inside the box: no movement")


func test_the_camera_catches_up_in_about_a_sixth_of_a_second() -> void:
	var cam: FollowCamera = FollowCamera.new()
	var view: Vector2 = Vector2(640, 360)
	cam.snap(Vector2(900, 500), view, BOUNDS, 3.0)
	var target: Vector2 = Vector2(1000, 500)
	var wanted: float = 1000.0 - FollowCamera.DEAD_ZONE_HALF.x
	_run(cam, target, view, 0.15)
	var covered: float = (cam.position.x - 900.0) / (wanted - 900.0)
	assert_true(covered > 0.93 and covered <= 1.0, "95%% of the way in 0.15 s (%.2f)" % covered)


func test_the_view_never_shows_past_the_edges_on_any_screen() -> void:
	for window: Vector2i in WINDOWS:
		var view: Vector2 = Vector2(DisplayMath.expected_view_size(window))
		var scale: float = DisplayMath.expected_scale(window)
		for target: Vector2 in [Vector2(0, 0), Vector2(1792, 1024), Vector2(0, 1024), Vector2(1792, 0), Vector2(900, 512)]:
			var cam: FollowCamera = FollowCamera.new()
			cam.snap(Vector2(900, 512), view, BOUNDS, scale)
			_run(cam, target, view, 1.0, scale)
			var shown: Rect2 = Rect2(cam.position - view / 2.0, view)
			assert_true(BOUNDS.encloses(shown), "%s at %s shows %s" % [window, target, shown])


func test_away_from_the_edges_the_camera_sits_on_whole_screen_pixels() -> void:
	var cam: FollowCamera = FollowCamera.new()
	var view: Vector2 = Vector2(640, 360)
	cam.snap(Vector2(900, 500), view, BOUNDS, 3.0)
	for i: int in range(40):
		cam.update(Vector2(900 + i * 1.37, 500 + i * 0.71), view, BOUNDS, 3.0, 1.0 / 60.0)
		var px: Vector2 = cam.position * 3.0
		assert_true(px.is_equal_approx(px.round()), "tick %d at %s" % [i, cam.position])


func test_a_place_smaller_than_the_view_is_centred() -> void:
	var small: Rect2 = Rect2(0, 0, 400, 300)
	assert_eq(FollowCamera.clamp_to(Vector2(10, 10), Vector2(640, 360), small), Vector2(200, 150), "centred")
