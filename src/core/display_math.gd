class_name DisplayMath
extends RefCounted
## What the ADR-0008 display settings (viewport stretch, integer scale,
## expand aspect) should produce for a given window size.
##
## Model, confirmed against renders in Godot 4.7.2 (see ADR-0008):
## 1. The visible area keeps the base size on the short side and grows on the
##    long side to match the window's aspect ratio (whole pixels, rounded down).
## 2. The scale is the largest whole number at which that area fits, never
##    below 1. Any leftover window space becomes black borders.
## tools/render_showcase.gd checks every render against this model.


static func base_size() -> Vector2i:
	return Vector2i(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height"))


## The visible game area in base pixels for a window size.
static func expected_view_size(window_size: Vector2i) -> Vector2i:
	var base: Vector2i = base_size()
	# Headless runs report a 0x0 window; there is nothing to scale.
	if window_size.x <= 0 or window_size.y <= 0:
		return base
	# Compare aspect ratios with integer cross-multiplication to avoid
	# floating-point ties.
	if window_size.x * base.y >= window_size.y * base.x:
		return Vector2i(window_size.x * base.y / window_size.y, base.y)
	return Vector2i(base.x, window_size.y * base.x / window_size.x)


## The whole-number scale for a window size.
static func expected_scale(window_size: Vector2i) -> int:
	var view: Vector2i = expected_view_size(window_size)
	return maxi(1, mini(window_size.x / view.x, window_size.y / view.y))
