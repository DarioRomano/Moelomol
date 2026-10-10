class_name CombatDrawer
extends RefCounted
## Draws a CombatSim onto any CanvasItem with placeholder shapes in the
## palette (top-down 3/4 view, ADR-0014). Placeholder art until the
## AI-generated art (combat-art-prompts.md) arrives; listed in the asset
## register.
##
## `alpha` blends each fighter between its previous and current tick position
## (render interpolation, Q20); 1.0 draws the current tick exactly.

const WALL: float = 16.0
const TILE: float = 16.0


static func draw(canvas: CanvasItem, sim: CombatSim, alpha: float, effects: Array[Dictionary]) -> void:
	_draw_arena(canvas, sim)
	var order: Array[Fighter] = sim.fighters()
	order.sort_custom(func(a: Fighter, b: Fighter) -> bool: return a.position.y < b.position.y)
	for f: Fighter in order:
		_draw_shadow(canvas, f, _at(f, alpha))
	for f: Fighter in order:
		if f.kind == Fighter.Kind.PLAYER:
			_draw_player(canvas, f, _at(f, alpha))
		else:
			_draw_creature(canvas, f, _at(f, alpha))
	if sim.lock_target != null:
		_draw_lock(canvas, _at(sim.lock_target, alpha))
	for effect: Dictionary in effects:
		_draw_effect(canvas, effect)


static func _at(f: Fighter, alpha: float) -> Vector2:
	return f.previous_position.lerp(f.position, clampf(alpha, 0.0, 1.0))


static func _draw_arena(canvas: CanvasItem, sim: CombatSim) -> void:
	var b: Rect2 = sim.bounds
	canvas.draw_rect(b.grow(WALL), Palette.STONE[0])
	canvas.draw_rect(Rect2(b.position.x - WALL, b.position.y - WALL, b.size.x + WALL * 2, WALL - 4), Palette.STONE[1])
	canvas.draw_rect(b, Palette.WILD[1])
	var y: float = b.position.y
	var row: int = 0
	while y < b.end.y:
		var x: float = b.position.x + (TILE if row % 2 == 1 else 0.0)
		while x < b.end.x:
			canvas.draw_rect(Rect2(x, y, minf(TILE, b.end.x - x), minf(TILE, b.end.y - y)), Palette.WILD[0])
			x += TILE * 2
		y += TILE
		row += 1
	for rect: Rect2 in sim.obstacles:
		# 3/4 view: a lighter top face and a darker front face.
		canvas.draw_rect(rect, Palette.STONE[0])
		canvas.draw_rect(Rect2(rect.position.x, rect.position.y - 8, rect.size.x, rect.size.y), Palette.STONE[2])
		canvas.draw_rect(Rect2(rect.position.x, rect.end.y - 8, rect.size.x, 8), Palette.STONE[1])


static func _draw_shadow(canvas: CanvasItem, f: Fighter, at: Vector2) -> void:
	if f.state == Fighter.State.GONE:
		return
	canvas.draw_rect(Rect2(at.x - f.radius, at.y - 2, f.radius * 2, 4), Color(Palette.SHADOW[0], 0.6))


static func _sector(canvas: CanvasItem, at: Vector2, facing: Vector2, radius: float, arc_deg: float, colour: Color) -> void:
	if arc_deg >= 360.0:
		# A fan capped below 360 degrees leaves a thin gap behind the
		# attacker (seen in the spin-sweep render).
		canvas.draw_circle(at, radius, colour)
		return
	var points: PackedVector2Array = PackedVector2Array([at])
	var half: float = deg_to_rad(arc_deg / 2.0)
	var steps: int = maxi(4, int(arc_deg / 12.0))
	for i: int in range(steps + 1):
		var angle: float = facing.angle() - half + (half * 2.0) * i / steps
		points.append(at + Vector2.from_angle(angle) * radius)
	canvas.draw_colored_polygon(points, colour)


static func _draw_player(canvas: CanvasItem, f: Fighter, at: Vector2) -> void:
	var fade: float = 1.0
	if f.state == Fighter.State.DODGE:
		fade = 0.45 if f.is_invulnerable() else 0.8
	if f.state == Fighter.State.DOWN:
		canvas.draw_rect(Rect2(at.x - 10, at.y - 6, 20, 6), Color(Palette.WARMTH[0], 0.7))
		return
	_draw_blade(canvas, f, at)
	var top: Vector2 = at + Vector2(-8, -24)
	var tint: Color = Palette.STONE[2] if f.is_staggered() else Color.WHITE
	canvas.draw_rect(Rect2(top + Vector2(4, 0), Vector2(8, 8)), Palette.WARMTH[2] * tint * Color(1, 1, 1, fade))
	canvas.draw_rect(Rect2(top + Vector2(3, 8), Vector2(10, 10)), Palette.WARMTH[1] * tint * Color(1, 1, 1, fade))
	canvas.draw_rect(Rect2(top + Vector2(4, 18), Vector2(3, 6)), Palette.WARMTH[0] * Color(1, 1, 1, fade))
	canvas.draw_rect(Rect2(top + Vector2(9, 18), Vector2(3, 6)), Palette.WARMTH[0] * Color(1, 1, 1, fade))
	# Eyes show the facing: none when facing away.
	if f.facing.y > -0.5:
		var shift: float = roundf(f.facing.x * 2.0)
		canvas.draw_rect(Rect2(top + Vector2(6 + shift, 3), Vector2(1, 1)), Palette.SHADOW[0])
		canvas.draw_rect(Rect2(top + Vector2(9 + shift, 3), Vector2(1, 1)), Palette.SHADOW[0])
	if f.has_hyper_armour():
		canvas.draw_rect(Rect2(top - Vector2(2, 2), Vector2(20, 28)), Palette.PAPER[1], false, 1.0)
	if f.is_staggered():
		_draw_dizzy(canvas, top + Vector2(8, -4), f.state_tick)


static func _draw_blade(canvas: CanvasItem, f: Fighter, at: Vector2) -> void:
	var hand: Vector2 = at + Vector2(0, -12)
	var length: float = 26.0
	match f.state:
		Fighter.State.BRACE:
			canvas.draw_line(hand + f.facing * 6, hand + f.facing * 6 + Vector2(0, 14), Palette.STONE[2], 3.0)
			canvas.draw_arc(at, 14, 0, TAU, 24, Palette.STONE[2], 1.0)
			return
		Fighter.State.ATTACK:
			var move: CombatMove = f.move
			var reach: float = f.radius + move.reach
			match f.attack_phase():
				&"windup":
					# Blade drawn back over the shoulder, opposite the facing.
					var back: Vector2 = (-f.facing).rotated(0.6)
					canvas.draw_line(hand, hand + back * length, Palette.STONE[2], 3.0)
					canvas.draw_line(hand, hand + back * length, Palette.PAPER[1], 1.0)
				&"active":
					_sector(canvas, at, f.facing, reach, move.arc_deg, Color(Palette.PAPER[1], 0.55))
					canvas.draw_line(hand, hand + f.facing * length, Palette.PAPER[1], 3.0)
				&"recovery":
					_sector(canvas, at, f.facing, reach, move.arc_deg, Color(Palette.PAPER[0], 0.15))
					canvas.draw_line(hand, hand + f.facing.rotated(0.9) * length, Palette.STONE[2], 3.0)
			return
	# Carried on the back while free or dodging.
	canvas.draw_line(hand + Vector2(-6, 6), hand + Vector2(6, -14), Palette.STONE[1], 3.0)


static func _draw_creature(canvas: CanvasItem, f: Fighter, at: Vector2) -> void:
	if f.state == Fighter.State.GONE:
		return
	var fade: float = 1.0
	if f.state == Fighter.State.DOWN:
		fade = 1.0 - float(f.state_tick) / maxf(1.0, f.state_length)
		# Returning to the land: a patch of moss grows where it stood.
		canvas.draw_rect(Rect2(at.x - 6, at.y - 2, 12, 4), Color(Palette.WILD[2], 1.0 - fade))
	var body: Color = Palette.CHANGED[1]
	var phase: StringName = f.attack_phase()
	if f.is_staggered():
		body = Palette.STONE[1]
	elif phase == &"windup" and (f.state_tick / 4) % 2 == 0:
		body = Palette.DANGER[1]  # the telegraph flash
	if phase == &"windup":
		_sector(canvas, at, f.facing, f.radius + f.move.reach, f.move.arc_deg, Color(Palette.DANGER[0], 0.25))
	elif phase == &"active":
		_sector(canvas, at, f.facing, f.radius + f.move.reach, f.move.arc_deg, Color(Palette.DANGER[1], 0.6))
	body.a = fade
	canvas.draw_rect(Rect2(at.x - 7, at.y - 12, 14, 11), body)
	canvas.draw_rect(Rect2(at.x - 5, at.y - 15, 10, 4), Color(Palette.CHANGED[0], fade))
	if f.facing.y > -0.5:
		var shift: float = roundf(f.facing.x * 2.0)
		canvas.draw_rect(Rect2(at.x - 3 + shift, at.y - 9, 2, 2), Color(Palette.PAPER[1], fade))
		canvas.draw_rect(Rect2(at.x + 1 + shift, at.y - 9, 2, 2), Color(Palette.PAPER[1], fade))
	if f.state == Fighter.State.DOWN:
		return
	# Health and poise above the creature.
	canvas.draw_rect(Rect2(at.x - 8, at.y - 21, 16, 2), Palette.SHADOW[0])
	canvas.draw_rect(Rect2(at.x - 8, at.y - 21, 16 * f.health / f.max_health, 2), Palette.DANGER[1])
	canvas.draw_rect(Rect2(at.x - 8, at.y - 18, 16, 1), Palette.SHADOW[0])
	canvas.draw_rect(Rect2(at.x - 8, at.y - 18, 16 * f.poise.ratio(), 1), Palette.PAPER[0])
	if f.is_staggered():
		_draw_dizzy(canvas, at + Vector2(0, -26), f.state_tick)


static func _draw_dizzy(canvas: CanvasItem, centre: Vector2, tick: int) -> void:
	for i: int in range(3):
		var angle: float = tick * 0.15 + i * TAU / 3.0
		canvas.draw_rect(Rect2(centre + Vector2(cos(angle) * 6, sin(angle) * 2) - Vector2(1, 1), Vector2(2, 2)), Palette.WARMTH[3])


static func _draw_lock(canvas: CanvasItem, at: Vector2) -> void:
	var centre: Vector2 = at + Vector2(0, -8)
	var colour: Color = Palette.PAPER[1]
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var tip: Vector2 = centre + corner * 12
		canvas.draw_line(tip, tip - Vector2(corner.x * 4, 0), colour, 1.0)
		canvas.draw_line(tip, tip - Vector2(0, corner.y * 4), colour, 1.0)


static func _draw_effect(canvas: CanvasItem, effect: Dictionary) -> void:
	var at: Vector2 = effect["position"]
	var age: int = effect["age"]
	match effect["kind"]:
		"impact":
			var r: float = 4.0 + age * 1.5
			canvas.draw_arc(at + Vector2(0, -6), r, 0, TAU, 20, Color(Palette.CHANGED[2], 1.0 - age / 12.0), 2.0)
		"hit":
			var size: float = 3.0 + age
			var c: Color = Color(Palette.PAPER[1], 1.0 - age / 6.0)
			canvas.draw_line(at + Vector2(-size, -8), at + Vector2(size, -8), c, 1.0)
			canvas.draw_line(at + Vector2(0, -8 - size), at + Vector2(0, -8 + size), c, 1.0)
