class_name FollowCamera
extends RefCounted
## The camera's rules (ADR-0015): it follows the player with a small dead
## zone, catches up smoothly, never shows past the edges of the place, and
## sits on whole screen pixels. Pure logic; the scene copies `position` to its
## Camera2D each frame.

## Half the dead zone in layout px: about 2 x 1.5 tiles in all.
const DEAD_ZONE_HALF: Vector2 = Vector2(16.0, 12.0)
## Catching up: the gap shrinks by e every this many seconds (95% in 0.15 s).
const CATCH_UP_TAU: float = 0.05

var position: Vector2 = Vector2.ZERO  # the view's centre, layout px
var _focus: Vector2 = Vector2.ZERO  # where the camera wants to be
var _smoothed: Vector2 = Vector2.ZERO  # the view's centre before rounding


## Places the camera on `target` at once (entering a place).
func snap(target: Vector2, view_size: Vector2, bounds: Rect2, scale: float) -> void:
	_focus = target
	_smoothed = clamp_to(target, view_size, bounds)
	position = clamp_to(round_to_screen(_smoothed, scale), view_size, bounds)


## Moves towards `target` for `delta` seconds of play.
func update(target: Vector2, view_size: Vector2, bounds: Rect2, scale: float, delta: float) -> void:
	# The dead zone: the focus moves only when the target leaves the box.
	var offset: Vector2 = target - _focus
	_focus.x += signf(offset.x) * maxf(0.0, absf(offset.x) - DEAD_ZONE_HALF.x)
	_focus.y += signf(offset.y) * maxf(0.0, absf(offset.y) - DEAD_ZONE_HALF.y)
	var wanted: Vector2 = clamp_to(_focus, view_size, bounds)
	var unrounded: Vector2 = _smoothed
	unrounded += (wanted - unrounded) * (1.0 - exp(-delta / CATCH_UP_TAU))
	_smoothed = unrounded
	# Rounded first, then clamped: the view never shows past the edge, and
	# away from the edges it sits on whole screen pixels (at an edge the
	# camera is still, so nothing shimmers).
	position = clamp_to(round_to_screen(unrounded, scale), view_size, bounds)


## A view centre that keeps the whole view inside `bounds`; centred on an
## axis where the place is smaller than the view.
static func clamp_to(centre: Vector2, view_size: Vector2, bounds: Rect2) -> Vector2:
	var half: Vector2 = view_size / 2.0
	var c: Vector2 = centre
	if bounds.size.x <= view_size.x:
		c.x = bounds.get_center().x
	else:
		c.x = clampf(c.x, bounds.position.x + half.x, bounds.end.x - half.x)
	if bounds.size.y <= view_size.y:
		c.y = bounds.get_center().y
	else:
		c.y = clampf(c.y, bounds.position.y + half.y, bounds.end.y - half.y)
	return c


## Rounds to whole screen pixels at `scale` screen pixels per layout pixel.
static func round_to_screen(at: Vector2, scale: float) -> Vector2:
	return (at * scale).round() / scale
