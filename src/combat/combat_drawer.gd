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
## How long each effect plays, in ticks.
const EFFECT_TICKS: Dictionary = {"impact": 12, "hit": 6, "shockwave": 18, "armour_break": 16,
	"release": 14, "shatter": 16, "blight_bloom": 18, "brittle": 14, "frozen": 14, "spread": 12,
	"wardstep": 12, "beam": 12, "perfect_brace": 16, "brace_absorb": 10}
## Effect colours (docs/design/combat.md, "The three effects").
const EFFECT_COLOURS: Dictionary = {
	StatusEffects.SMOULDER: Color("#e0a95b"),
	StatusEffects.CHILL: Color("#4f8296"),
	StatusEffects.ROT: Color("#6e5b73"),
}


## The effect a combat event leaves behind, or an empty dictionary.
static func effect_for_event(event: Dictionary) -> Dictionary:
	var kind: String = event["type"]
	if not EFFECT_TICKS.has(kind):
		return {}
	var effect: Dictionary = {"kind": kind, "position": event["position"], "age": 0}
	if event.has("radius"):
		effect["radius"] = event["radius"]
	for key: String in ["from", "facing", "arc"]:
		if event.has(key):
			effect[key] = event[key]
	return effect


## Collects the effects of `events` and ages the old ones by a tick.
static func update_effects(effects: Array[Dictionary], events: Array[Dictionary]) -> void:
	for event: Dictionary in events:
		var effect: Dictionary = effect_for_event(event)
		if not effect.is_empty():
			effects.append(effect)
	for effect: Dictionary in effects:
		effect["age"] = int(effect["age"]) + 1
	var alive: Array[Dictionary] = effects.filter(func(e: Dictionary) -> bool:
		return int(e["age"]) < int(EFFECT_TICKS[e["kind"]]))
	effects.assign(alive)


static func draw(canvas: CanvasItem, sim: CombatSim, alpha: float, effects: Array[Dictionary]) -> void:
	_draw_arena(canvas, sim)
	for zone: Zone in sim.zones:
		_draw_zone(canvas, zone)
	var order: Array[Fighter] = sim.fighters()
	order.sort_custom(func(a: Fighter, b: Fighter) -> bool: return a.position.y < b.position.y)
	for f: Fighter in order:
		_draw_shadow(canvas, f, _at(f, alpha))
	for f: Fighter in order:
		if f.kind == Fighter.Kind.PLAYER:
			_draw_player(canvas, f, _at(f, alpha))
		else:
			_draw_creature(canvas, f, _at(f, alpha))
	for arrow: Projectile in sim.projectiles:
		_draw_arrow(canvas, arrow, arrow.previous_position.lerp(arrow.position, clampf(alpha, 0.0, 1.0)))
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


## The sector of f's attack zone: the whole projection (full) or how far
## it reaches right now.
static func _zone(canvas: CanvasItem, f: Fighter, full: bool, colour: Color) -> void:
	var zone: Dictionary = CombatSim.attack_zone(f)
	if zone.is_empty():
		return
	var radius: float = zone["full_reach"] if full else zone["reach"]
	if radius > 0.0:
		_sector(canvas, zone["origin"], zone["facing"], radius, zone["arc"], colour)


## The far edge of the zone: an arc at the full reach and its sides, so the
## end of a lunge's reach is a clear line.
static func _zone_outline(canvas: CanvasItem, f: Fighter, colour: Color) -> void:
	var zone: Dictionary = CombatSim.attack_zone(f)
	if zone.is_empty():
		return
	var facing: Vector2 = zone["facing"]
	var half: float = deg_to_rad(float(zone["arc"]) / 2.0)
	var radius: float = zone["full_reach"]
	var origin: Vector2 = zone["origin"]
	canvas.draw_arc(origin, radius, facing.angle() - half, facing.angle() + half, 16, colour, 1.0)
	if float(zone["arc"]) < 360.0:
		canvas.draw_line(origin, origin + Vector2.from_angle(facing.angle() - half) * radius, colour, 1.0)
		canvas.draw_line(origin, origin + Vector2.from_angle(facing.angle() + half) * radius, colour, 1.0)


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
	if f.weapon() is Hammer:
		_draw_hammer(canvas, f, at, f.weapon() as Hammer)
		return
	if f.weapon() is Bow:
		_draw_bow(canvas, f, at, f.weapon() as Bow)
		return
	if f.weapon() is Magic:
		_draw_lantern(canvas, f, at)
		return
	var hand: Vector2 = at + Vector2(0, -12)
	var length: float = 32.0  # longer with the 40% reach (2026-10-10)
	match f.state:
		Fighter.State.BRACE:
			# The guard: the blade held flat across the body, facing the
			# threat, behind a half-ring; white and bright in the perfect
			# window, stone grey after it.
			var across: Vector2 = f.facing.orthogonal()
			var guard_at: Vector2 = hand + f.facing * 7
			var perfect: bool = Greatsword.in_perfect_window(f)
			var colour: Color = Palette.PAPER[1] if perfect else Palette.STONE[2]
			canvas.draw_line(guard_at - across * 10, guard_at + across * 10, Palette.STONE[2], 3.0)
			canvas.draw_line(guard_at - across * 10, guard_at + across * 10, Palette.PAPER[1], 1.0)
			canvas.draw_arc(at, 16, f.facing.angle() - 1.2, f.facing.angle() + 1.2, 16, colour, 2.0 if perfect else 1.0)
			return
		Fighter.State.ATTACK:
			match f.attack_phase():
				&"windup":
					# Blade drawn back over the shoulder, opposite the facing.
					var back: Vector2 = (-f.facing).rotated(0.6)
					canvas.draw_line(hand, hand + back * length, Palette.STONE[2], 3.0)
					canvas.draw_line(hand, hand + back * length, Palette.PAPER[1], 1.0)
				&"active":
					_zone(canvas, f, false, Color(Palette.PAPER[1], 0.55))
					canvas.draw_line(hand, hand + f.facing * length, Palette.PAPER[1], 3.0)
				&"recovery":
					_zone(canvas, f, true, Color(Palette.PAPER[0], 0.15))
					canvas.draw_line(hand, hand + f.facing.rotated(0.9) * length, Palette.STONE[2], 3.0)
			return
	# Carried on the back while free or dodging.
	canvas.draw_line(hand + Vector2(-6, 6), hand + Vector2(6, -14), Palette.STONE[1], 3.0)


## The maul: a shaft and an iron-banded head.
static func _hammer_shape(canvas: CanvasItem, hand: Vector2, direction: Vector2, head_colour: Color) -> void:
	var tip: Vector2 = hand + direction * 22.0
	canvas.draw_line(hand, tip, Palette.WARMTH[0], 2.0)
	var across: Vector2 = direction.orthogonal()
	var head: PackedVector2Array = PackedVector2Array([
		tip + across * 5 - direction, tip - across * 5 - direction,
		tip - across * 5 + direction * 5, tip + across * 5 + direction * 5])
	canvas.draw_colored_polygon(head, head_colour)


static func _draw_hammer(canvas: CanvasItem, f: Fighter, at: Vector2, hammer: Hammer) -> void:
	var hand: Vector2 = at + Vector2(0, -12)
	match f.state:
		Fighter.State.CHARGE:
			# Raised overhead; the head flashes in the sweet spot.
			var window: Vector2i = hammer.sweet_spot_ticks()
			var held: int = f.state_tick
			var head: Color = Palette.STONE[2]
			if held >= window.x and held < window.y:
				head = Palette.PAPER[1]
			elif held >= window.y:
				head = Palette.DANGER[1]
			_hammer_shape(canvas, hand + Vector2(0, -4), Vector2.UP.rotated(-0.25 * signf(f.facing.x)), head)
			_draw_charge_meter(canvas, at + Vector2(0, -44), held, hammer)
			return
		Fighter.State.ATTACK:
			var move: CombatMove = f.move
			var phase: StringName = f.attack_phase()
			if move.arc_deg >= 360.0:  # Ground stamp: the hammer straight down
				if phase != &"windup":
					_zone(canvas, f, phase != &"active", Color(Palette.PAPER[1], 0.45 if phase == &"active" else 0.15))
				_hammer_shape(canvas, hand + Vector2(4, -6), Vector2.DOWN, Palette.STONE[2])
				return
			match phase:
				&"windup":
					var swing: Vector2 = Vector2.UP.lerp(f.facing, 0.5).normalized()
					if move.id == &"hammer_jab":
						swing = -f.facing
					_hammer_shape(canvas, hand, swing, Palette.STONE[2])
				&"active":
					_zone(canvas, f, false, Color(Palette.PAPER[1], 0.55))
					_hammer_shape(canvas, hand, f.facing, Palette.PAPER[1] if move.breaks_armour else Palette.STONE[2])
				&"recovery":
					_zone(canvas, f, true, Color(Palette.PAPER[0], 0.15))
					_hammer_shape(canvas, hand + Vector2(0, 6), f.facing, Palette.STONE[1])
			return
	# Carried on the back.
	_hammer_shape(canvas, hand + Vector2(-6, 6), Vector2(0.5, -1).normalized(), Palette.STONE[1])


## The recurve: an arc across `direction`, its string pulled back by `pull`.
static func _bow_shape(canvas: CanvasItem, grip: Vector2, direction: Vector2, pull: float) -> void:
	var across: Vector2 = direction.orthogonal()
	var top: Vector2 = grip + across * 8 - direction * 3
	var bottom: Vector2 = grip - across * 8 - direction * 3
	var points: PackedVector2Array = PackedVector2Array([top, grip + across * 4, grip, grip - across * 4, bottom])
	canvas.draw_polyline(points, Palette.WARMTH[1], 2.0)
	var nock: Vector2 = grip - direction * (3.0 + pull)
	canvas.draw_line(top, nock, Palette.PAPER[0], 1.0)
	canvas.draw_line(nock, bottom, Palette.PAPER[0], 1.0)
	if pull > 0.0:
		canvas.draw_line(nock, grip + direction * 4, Palette.PAPER[1], 1.0)  # the nocked arrow


static func _draw_bow(canvas: CanvasItem, f: Fighter, at: Vector2, bow: Bow) -> void:
	var hand: Vector2 = at + Vector2(0, -12)
	match f.state:
		Fighter.State.CHARGE:
			var stage: int = bow.stage_for(f.state_tick)
			_bow_shape(canvas, hand + f.facing * 7, f.facing, 2.0 + stage * 2.0)
			_draw_stage_pips(canvas, at + Vector2(0, -36), stage, bow.is_clean(f.state_tick))
			return
		Fighter.State.ATTACK:
			_bow_shape(canvas, hand + f.facing * 7, f.facing, 0.0)
			return
	# Carried across the back.
	canvas.draw_arc(hand + Vector2(-2, 0), 9, -PI * 0.75, PI * 0.25, 8, Palette.WARMTH[1], 2.0)


## The lantern: held at the hip, raised to cast, glowing in the changed
## land's violet.
static func _draw_lantern(canvas: CanvasItem, f: Fighter, at: Vector2) -> void:
	var hand: Vector2 = at + Vector2(0, -12)
	var lantern: Vector2 = hand + Vector2(6 * signf(f.facing.x + 0.01), 4)
	var glow: float = 4.0
	match f.state:
		Fighter.State.CHARGE:
			lantern = hand + f.facing * 8
			var magic: Magic = f.weapon() as Magic
			if magic != null and magic.is_siphoning(f):
				glow = 5.0 + minf(6.0, magic.drained_total() * 0.6)
				_draw_siphon(canvas, f, magic, at, lantern)
			else:
				# Filling towards the Siphon: a ring closes round the lantern.
				var progress: float = minf(1.0, f.state_tick / float(CombatTuning.ticks(Magic.SIPHON_HOLD_MS)))
				glow = 5.0 + progress * 2.0
				canvas.draw_arc(lantern, 7.0, -PI / 2, -PI / 2 + TAU * progress, 16, Color(Palette.CHANGED[2], 0.9), 1.0)
		Fighter.State.ATTACK:
			lantern = hand + f.facing * 8
			var phase: StringName = f.attack_phase()
			glow = 6.0 if phase == &"windup" else 4.0
	canvas.draw_circle(lantern, glow, Color(Palette.CHANGED[1], 0.35))
	canvas.draw_rect(Rect2(lantern - Vector2(2, 3), Vector2(4, 6)), Palette.CHANGED[0])
	canvas.draw_rect(Rect2(lantern - Vector2(1, 2), Vector2(2, 3)), Palette.CHANGED[2])


## The Siphon: where the beam will go (faint), the tether to the creature
## being drained, and beads of what has been drained in the lantern's glow.
static func _draw_siphon(canvas: CanvasItem, f: Fighter, magic: Magic, at: Vector2, lantern: Vector2) -> void:
	var aim_end: Vector2 = at + f.facing * Magic.BEAM_LENGTH
	canvas.draw_line(lantern, aim_end + Vector2(0, -8), Color(Palette.CHANGED[1], 0.18), 1.0)
	var target: Fighter = magic.siphon_target
	if target != null:
		var to: Vector2 = target.position + Vector2(0, -10)
		canvas.draw_line(to, lantern, Color(Palette.CHANGED[1], 0.8), 1.0)
		# Motes travelling down the tether towards the lantern.
		for i: int in range(3):
			var t: float = fmod(magic.siphon_ticks / 12.0 + i / 3.0, 1.0)
			canvas.draw_circle(to.lerp(lantern, t), 1.5, Palette.CHANGED[2])
	var bead: int = 0
	for kind: StringName in StatusEffects.KINDS:
		for i: int in range(int(magic.drained.get(kind, 0))):
			var angle: float = bead * TAU / 10.0 + magic.siphon_ticks * 0.08
			canvas.draw_circle(lantern + Vector2.from_angle(angle) * 8.0, 1.5, (EFFECT_COLOURS[kind] as Color).lightened(0.25))
			bead += 1


## Up to five pips per effect above a creature, one row per effect present.
static func _draw_effect_pips(canvas: CanvasItem, f: Fighter, at: Vector2) -> void:
	var row: int = 0
	for kind: StringName in StatusEffects.KINDS:
		var n: int = f.effects.count(kind)
		if n == 0:
			continue
		# A dark strip behind the pips: violet Rot vanished into the grass in
		# the first render.
		var top_left: Vector2 = at + Vector2(-9, -29 - row * 4)
		canvas.draw_rect(Rect2(top_left, Vector2(18, 4)), Palette.SHADOW[0])
		for i: int in range(n):
			canvas.draw_rect(Rect2(top_left + Vector2(1 + i * 3.5, 1), Vector2(2.5, 2)), (EFFECT_COLOURS[kind] as Color).lightened(0.2))
		row += 1


## Three pips above the player for the draw stages; white in a clean-release
## moment.
static func _draw_stage_pips(canvas: CanvasItem, centre: Vector2, stage: int, clean: bool) -> void:
	for i: int in range(3):
		var colour: Color = Palette.SHADOW[0]
		if i < stage:
			colour = Palette.PAPER[1] if clean and i == stage - 1 else Palette.WARMTH[3]
		canvas.draw_rect(Rect2(centre + Vector2(-9 + i * 7, 0), Vector2(4, 3)), colour)


static func _draw_arrow(canvas: CanvasItem, arrow: Projectile, at: Vector2) -> void:
	var direction: Vector2 = arrow.velocity.normalized()
	var tip: Vector2 = at + Vector2(0, -8)  # flies at chest height
	if arrow.move.effect != &"":
		# A spell: an ember (round) or a frost shard (a diamond), with a trail.
		var colour: Color = EFFECT_COLOURS[arrow.move.effect]
		canvas.draw_line(tip - direction * 6, tip, Color(colour, 0.5), 1.0)
		if arrow.move.effect == StatusEffects.CHILL:
			var across: Vector2 = direction.orthogonal() * 2
			canvas.draw_colored_polygon(PackedVector2Array([tip + direction * 3, tip + across, tip - direction * 2, tip - across]), colour)
		else:
			canvas.draw_circle(tip, 2.0, colour)
		return
	var length: float = 8.0 if arrow.pierce else 6.0
	var width: float = 2.0 if arrow.pierce else 1.0
	var colour: Color = Palette.WARMTH[3] if arrow.pierce else Palette.PAPER[1]
	canvas.draw_line(tip - direction * length, tip, colour, width)
	if arrow.marker:
		canvas.draw_line(tip - direction * length, tip - direction * (length + 3) + direction.orthogonal() * 2,
			Palette.DANGER[1], 1.0)


static func _draw_zone(canvas: CanvasItem, zone: Zone) -> void:
	if zone.kind in [&"rot_pool", &"chill_pool"]:
		var colour: Color = EFFECT_COLOURS[StatusEffects.ROT if zone.kind == &"rot_pool" else StatusEffects.CHILL]
		var left: float = 1.0 - float(zone.age) / (zone.period * zone.waves)
		canvas.draw_circle(zone.position, zone.radius, Color(colour, 0.15 + 0.15 * left))
		canvas.draw_arc(zone.position, zone.radius, 0, TAU, 32, Color(colour, 0.8), 1.0)
		return
	var waiting: bool = zone.age < zone.delay
	canvas.draw_circle(zone.position, zone.radius, Color(Palette.WARMTH[3], 0.08 if waiting else 0.16))
	canvas.draw_arc(zone.position, zone.radius, 0, TAU, 32, Color(Palette.WARMTH[3], 0.7), 1.0)
	if waiting:
		return
	# Falling arrows for a few ticks after each wave.
	var since_wave: int = (zone.age - zone.delay) % zone.period
	if since_wave > 5:
		return
	for i: int in range(7):
		var angle: float = i * 2.39996  # golden angle: spread evenly
		var spot: Vector2 = zone.position + Vector2.from_angle(angle) * zone.radius * sqrt((i + 0.5) / 7.0)
		var fall: float = (5 - since_wave) * 3.0
		canvas.draw_line(spot + Vector2(0, -fall - 6), spot + Vector2(0, -fall), Palette.PAPER[1], 1.0)


## The charge meter above the player: three level pips over a bar. The bar
## fills through levels 1 and 2 to the marked sweet spot (level 3) and turns
## red when overcharged.
static func _draw_charge_meter(canvas: CanvasItem, centre: Vector2, held: int, hammer: Hammer) -> void:
	var window: Vector2i = hammer.sweet_spot_ticks()
	var levels: Array[int] = hammer.level_ticks()
	var full: float = window.y + 18.0
	var width: float = 30.0
	var left: Vector2 = centre - Vector2(width / 2.0, 0)
	canvas.draw_rect(Rect2(left - Vector2(1, 1), Vector2(width + 2, 5)), Palette.SHADOW[0])
	var zone_start: float = width * window.x / full
	var zone_width: float = width * (window.y - window.x) / full
	canvas.draw_rect(Rect2(left + Vector2(zone_start, 0), Vector2(zone_width, 3)), Palette.WARMTH[3] * Color(1, 1, 1, 0.6))
	var level: int = hammer.level_for(held)
	var overcharged: bool = held >= window.y
	var fills: Array[Color] = [Palette.STONE[1], Palette.PAPER[0], Palette.WARMTH[2], Palette.PAPER[1]]
	var fill: Color = Palette.DANGER[1] if overcharged else fills[level]
	canvas.draw_rect(Rect2(left, Vector2(width * minf(held / full, 1.0), 3)), fill)
	# Notches at levels 1 and 2, and both edges of the sweet spot, above and
	# below the bar so the fill cannot hide them (the first hammer render
	# showed the zone vanishing under it).
	for i: int in range(2):
		var x: float = width * levels[i] / full
		canvas.draw_rect(Rect2(left + Vector2(x - 0.5, 4), Vector2(1, 2)), Palette.PAPER[0])
	for x: float in [zone_start, zone_start + zone_width]:
		canvas.draw_rect(Rect2(left + Vector2(x - 0.5, -3), Vector2(1, 2)), Palette.WARMTH[3])
		canvas.draw_rect(Rect2(left + Vector2(x - 0.5, 4), Vector2(1, 2)), Palette.WARMTH[3])
	# Level pips: lit as each level is reached; red when overcharged.
	for i: int in range(3):
		var colour: Color = Palette.SHADOW[0]
		if i < level:
			colour = Palette.DANGER[1] if overcharged else (Palette.PAPER[1] if i == 2 else Palette.WARMTH[3])
		canvas.draw_rect(Rect2(centre + Vector2(-9 + i * 7, -8), Vector2(4, 3)), colour)


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
		if f.effects.count(StatusEffects.CHILL) >= StatusEffects.MAX_STACKS:
			body = Palette.WATER[1].lightened(0.3)  # Frozen
	elif phase == &"windup" and (f.state_tick / 4) % 2 == 0:
		body = Palette.DANGER[1]  # the telegraph flash
	# The telegraph is the attack's whole hit zone, lunge included
	# (CombatSim.attack_zone); during the attack it fills as the lunge travels.
	if phase == &"windup" or phase == &"active":
		_zone(canvas, f, true, Color(Palette.DANGER[0], 0.25))
		_zone_outline(canvas, f, Color(Palette.DANGER[1], 0.8))
	if phase == &"active":
		_zone(canvas, f, false, Color(Palette.DANGER[1], 0.6))
	body.a = fade
	canvas.draw_rect(Rect2(at.x - 7, at.y - 12, 14, 11), body)
	canvas.draw_rect(Rect2(at.x - 5, at.y - 15, 10, 4), Color(Palette.CHANGED[0], fade))
	if f.armour > 0.0:
		# A stone shell over the back, cracking as it is chipped.
		canvas.draw_rect(Rect2(at.x - 8, at.y - 14, 16, 6), Color(Palette.STONE[1], fade))
		canvas.draw_rect(Rect2(at.x - 8, at.y - 14, 16, 2), Color(Palette.STONE[2], fade))
		if f.armour < f.armour_max * 0.5:
			canvas.draw_line(Vector2(at.x - 3, at.y - 14), Vector2(at.x, at.y - 9), Palette.SHADOW[0], 1.0)
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
	if f.armour > 0.0:
		canvas.draw_rect(Rect2(at.x - 8, at.y - 24, 16 * f.armour / f.armour_max, 2), Palette.STONE[2])
	_draw_effect_pips(canvas, f, at)
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
		"shockwave":
			# A cone rolling forward from the player (Hammer.SHOCKWAVE_ARC_DEG):
			# its wavefront travels out to the reach, the cone faintly filled.
			var radius: float = effect["radius"]
			var t: float = age / float(EFFECT_TICKS["shockwave"])
			var facing: Vector2 = effect.get("facing", Vector2.RIGHT)
			var half: float = deg_to_rad(float(effect.get("arc", 360.0)) / 2.0)
			_sector(canvas, at, facing, radius, rad_to_deg(half * 2.0), Color(Palette.PAPER[1], 0.12 * (1.0 - t)))
			for i: int in range(2):
				var front: float = radius * minf(1.0, 0.25 + t * 1.3 - i * 0.2)
				if front > 0.0:
					canvas.draw_arc(at, front, facing.angle() - half, facing.angle() + half, 24,
						Color(Palette.PAPER[1] if i == 0 else Palette.WARMTH[3], (1.0 - t) * (1.0 - i * 0.3)), 2.0 - i)
		"armour_break":
			var t: float = age / float(EFFECT_TICKS["armour_break"])
			for i: int in range(6):
				var direction: Vector2 = Vector2.from_angle(i * TAU / 6.0 + 0.4)
				var shard: Vector2 = at + Vector2(0, -12) + direction * (4.0 + t * 14.0) + Vector2(0, t * t * 8.0)
				canvas.draw_rect(Rect2(shard - Vector2(1.5, 1.5), Vector2(3, 3)), Color(Palette.STONE[2], 1.0 - t))
		"release", "blight_bloom", "shatter", "spread":
			var t: float = age / float(EFFECT_TICKS[effect["kind"]])
			var colours: Dictionary = {"release": Palette.CHANGED[1], "blight_bloom": EFFECT_COLOURS[StatusEffects.ROT],
				"shatter": Palette.PAPER[1], "spread": EFFECT_COLOURS[StatusEffects.SMOULDER]}
			var radius: float = effect.get("radius", 16.0)
			canvas.draw_arc(at + Vector2(0, -6), radius * (0.2 + 0.8 * t), 0, TAU, 32, Color(colours[effect["kind"]], 1.0 - t), 2.0)
		"brittle", "frozen":
			var t: float = age / float(EFFECT_TICKS[effect["kind"]])
			var colour: Color = Palette.PAPER[1] if effect["kind"] == "brittle" else Palette.WATER[1].lightened(0.4)
			for i: int in range(5):
				var direction: Vector2 = Vector2.from_angle(i * TAU / 5.0 - PI / 2)
				canvas.draw_line(at + Vector2(0, -8) + direction * 3, at + Vector2(0, -8) + direction * (6 + t * 6), Color(colour, 1.0 - t), 1.0)
		"perfect_brace":
			# A white flash and sparks thrown forward from the guard.
			var t: float = age / float(EFFECT_TICKS["perfect_brace"])
			canvas.draw_arc(at + Vector2(0, -10), 10.0 + t * 14.0, 0, TAU, 24, Color(Palette.PAPER[1], 1.0 - t), 3.0 * (1.0 - t) + 1.0)
			for i: int in range(8):
				var direction: Vector2 = Vector2.from_angle(i * TAU / 8.0)
				canvas.draw_line(at + Vector2(0, -10) + direction * (8 + t * 10), at + Vector2(0, -10) + direction * (12 + t * 16),
					Color(Palette.WARMTH[3], 1.0 - t), 1.0)
		"brace_absorb":
			var t: float = age / float(EFFECT_TICKS["brace_absorb"])
			canvas.draw_arc(at + Vector2(0, -10), 14.0, 0, TAU, 20, Color(Palette.STONE[2], 1.0 - t), 2.0)
		"beam":
			var t: float = age / float(EFFECT_TICKS["beam"])
			var from: Vector2 = effect.get("from", at) + Vector2(0, -10)
			var to: Vector2 = at + Vector2(0, -10)
			canvas.draw_line(from, to, Color(Palette.CHANGED[1], 0.6 * (1.0 - t)), 5.0 * (1.0 - t) + 1.0)
			canvas.draw_line(from, to, Color(Palette.PAPER[1], 1.0 - t), 1.0)
		"wardstep":
			var t: float = age / float(EFFECT_TICKS["wardstep"])
			var from: Vector2 = effect.get("from", at)
			canvas.draw_rect(Rect2(from + Vector2(-5, -22), Vector2(10, 20)), Color(Palette.CHANGED[2], 0.5 * (1.0 - t)))
			canvas.draw_line(from + Vector2(0, -12), at + Vector2(0, -12), Color(Palette.CHANGED[1], 0.6 * (1.0 - t)), 1.0)
		"hit":
			var size: float = 3.0 + age
			var c: Color = Color(Palette.PAPER[1], 1.0 - age / 6.0)
			canvas.draw_line(at + Vector2(-size, -8), at + Vector2(size, -8), c, 1.0)
			canvas.draw_line(at + Vector2(0, -8 - size), at + Vector2(0, -8 + size), c, 1.0)
