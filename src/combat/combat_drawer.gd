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
	"wardstep": 12, "beam": 12, "seed_jump": 14, "seed_latch": 10, "perfect_brace": 16, "brace_absorb": 10}
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


## `arena`: draw the test arena's floor and walls (false in an area, which
## draws its own map underneath).
static func draw(canvas: CanvasItem, sim: CombatSim, alpha: float, effects: Array[Dictionary], arena: bool = true) -> void:
	if arena:
		_draw_arena(canvas, sim)
	_draw_props(canvas, sim)
	for light: Vector2 in sim.lights:
		_draw_light(canvas, light, sim.tick_count)
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
	for weapon: Weapon in sim.player.weapons:
		var magic: Magic = weapon as Magic
		if magic != null and magic.seed_host != null:
			_draw_seed_growth(canvas, magic, _at(magic.seed_host, alpha))
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
	if radius <= 0.0:
		return
	if zone.get("shape", &"sector") == &"lane":
		canvas.draw_colored_polygon(_lane_points(zone["origin"], zone["facing"], radius, zone["width"]), colour)
	else:
		_sector(canvas, zone["origin"], zone["facing"], radius, zone["arc"], colour)


## The four corners of a lane: `length` along `facing` from `origin`,
## `width` across.
static func _lane_points(origin: Vector2, facing: Vector2, length: float, width: float) -> PackedVector2Array:
	var across: Vector2 = facing.orthogonal() * width / 2.0
	return PackedVector2Array([origin + across, origin + facing * length + across,
		origin + facing * length - across, origin - across])


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
	if zone.get("shape", &"sector") == &"lane":
		var corners: PackedVector2Array = _lane_points(origin, facing, radius, zone["width"])
		corners.append(corners[0])
		canvas.draw_polyline(corners, colour, 1.0)
		return
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


## The Rot seed on its host: a growth on the creature's shoulder with
## tendrils that lengthen as the seed ages; it fades in its last second.
static func _draw_seed_growth(canvas: CanvasItem, magic: Magic, at: Vector2) -> void:
	var colour: Color = EFFECT_COLOURS[StatusEffects.ROT]
	var total: int = CombatTuning.ticks(Magic.SEED_DURATION_MS)
	var grown: float = clampf(1.0 - float(magic.seed_ticks_left) / total, 0.0, 1.0)
	var fade: float = minf(1.0, magic.seed_ticks_left / float(CombatTuning.TICK_RATE))
	var root: Vector2 = at + Vector2(4, -12)
	for i: int in range(3):
		var direction: Vector2 = Vector2.from_angle(-PI / 2 + (i - 1) * 0.9)
		canvas.draw_line(root, root + direction * (3.0 + grown * 5.0), Color(colour.lightened(0.2), fade), 1.0)
	canvas.draw_circle(root, 2.5 + grown, Color(colour.darkened(0.2), fade))
	canvas.draw_circle(root + Vector2(-0.8, -0.8), 1.0, Color(colour.lightened(0.45), fade))


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
	if arrow.move == Magic.ROT_SEED.arrow:
		# The Rot seed: a dark husk with a violet glow, tumbling slowly.
		var colour: Color = EFFECT_COLOURS[StatusEffects.ROT]
		canvas.draw_line(tip - direction * 5, tip, Color(colour, 0.4), 1.0)
		canvas.draw_circle(tip, 3.0, Color(colour, 0.35))
		canvas.draw_circle(tip, 1.8, (colour as Color).darkened(0.3))
		canvas.draw_rect(Rect2(tip + direction.rotated(arrow.range_left * 0.2) * 1.5 - Vector2(0.5, 0.5), Vector2(1, 1)), colour.lightened(0.4))
		return
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
	if arrow.roller:
		# A rolling millstone: a stone wheel seen on edge-ish, its spokes turning.
		var centre: Vector2 = at + Vector2(0, -arrow.radius * 0.6)
		canvas.draw_circle(centre, arrow.radius, Palette.STONE[1])
		canvas.draw_arc(centre, arrow.radius, 0, TAU, 24, Palette.STONE[0], 1.0)
		var turn: float = -arrow.range_left / arrow.radius
		for i: int in range(3):
			var spoke: Vector2 = Vector2.from_angle(turn + i * TAU / 3.0) * (arrow.radius - 2.0)
			canvas.draw_line(centre - spoke, centre + spoke, Palette.STONE[2], 1.0)
		canvas.draw_circle(centre, 2.0, Palette.SHADOW[0])
		return
	var length: float = 8.0 if arrow.pierce else 6.0
	var width: float = 2.0 if arrow.pierce else 1.0
	var colour: Color = Palette.WARMTH[3] if arrow.pierce else Palette.PAPER[1]
	canvas.draw_line(tip - direction * length, tip, colour, width)
	if arrow.marker:
		canvas.draw_line(tip - direction * length, tip - direction * (length + 3) + direction.orthogonal() * 2,
			Palette.DANGER[1], 1.0)


static func _draw_zone(canvas: CanvasItem, zone: Zone) -> void:
	if zone.kind == &"glob":
		# A toad's glob in flight: the marked circle where it will land,
		# filling as it comes down.
		var t: float = clampf(float(zone.age) / maxf(1.0, zone.delay), 0.0, 1.0)
		canvas.draw_circle(zone.position, zone.radius * t, Color(Palette.DANGER[0], 0.3))
		canvas.draw_arc(zone.position, zone.radius, 0, TAU, 24, Color(Palette.DANGER[1], 0.85), 1.0)
		var arc_top: Vector2 = zone.position + Vector2(0, -28.0 * sin(PI * t))
		canvas.draw_circle(arc_top, 2.5, Palette.CHANGED[1].lightened(0.2))
		return
	if zone.kind == &"slick":
		if zone.age < zone.delay:
			return
		var left: float = 1.0 - float(zone.age - zone.delay) / maxf(1.0, zone.period)
		canvas.draw_circle(zone.position, zone.radius, Color(Palette.CHANGED[0], 0.35 + 0.25 * left))
		canvas.draw_arc(zone.position, zone.radius, 0, TAU, 24, Color(Palette.CHANGED[1], 0.6 * left), 1.0)
		return
	if zone.kind == &"chill_pool":
		var colour: Color = EFFECT_COLOURS[StatusEffects.CHILL]
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
		canvas.draw_rect(Rect2(at.x - f.radius, at.y - 2, f.radius * 2, 4), Color(Palette.WILD[2], 1.0 - fade))
	if f.disguised:
		_draw_sheaf(canvas, at, 1.0)  # a stook: a sheaf like any other
		return
	var phase: StringName = f.attack_phase()
	var flash: bool = phase == &"windup" and (f.state_tick / 4) % 2 == 0
	# The telegraph is the attack's whole hit zone, lunge included
	# (CombatSim.attack_zone); during the attack it fills as the lunge travels.
	if phase == &"windup" or phase == &"active":
		_zone(canvas, f, true, Color(Palette.DANGER[0], 0.25))
		_zone_outline(canvas, f, Color(Palette.DANGER[1], 0.8))
	if phase == &"active":
		_zone(canvas, f, false, Color(Palette.DANGER[1], 0.6))
	var lift: float = 10.0 if f.airborne else 0.0
	var body_at: Vector2 = at + Vector2(0, -lift)
	match f.creature_kind.id:
		&"field_mouse":
			_draw_mouse(canvas, f, body_at, flash, fade)
		&"rook":
			_draw_rook(canvas, f, body_at, flash, fade)
		&"hedgehog":
			_draw_hedgehog(canvas, f, body_at, flash, fade)
		&"flood_toad":
			_draw_toad(canvas, f, body_at, flash, fade)
		&"stook":
			_draw_stook(canvas, f, body_at, flash, fade)
		&"moth":
			_draw_moth(canvas, f, body_at, flash, fade)
		&"grist":
			_draw_grist(canvas, f, body_at, flash, fade)
		_:
			_draw_training(canvas, f, body_at, flash, fade)
	if f.state == Fighter.State.DOWN or f.ai_state == &"asleep":
		if f.ai_state == &"asleep":
			_draw_sleep(canvas, body_at + Vector2(f.radius, -f.radius * 1.6), f.ai_timer + int(at.x))
		return
	if f.creature_kind.id != &"moth":
		_draw_bars(canvas, f, body_at)  # (a moth dies to any hit: no bars)
	_draw_effect_pips(canvas, f, body_at + Vector2(0, 14.0 - f.radius * 2.0))
	if f.is_staggered():
		_draw_dizzy(canvas, body_at + Vector2(0, -f.radius * 2.0 - 12.0), f.state_tick)


## The body colour a creature shows: grey when staggered, pale blue when
## Frozen, the danger red on a telegraph's flash.
static func _body_colour(f: Fighter, base: Color, flash: bool) -> Color:
	if f.is_staggered():
		if f.effects.count(StatusEffects.CHILL) >= StatusEffects.MAX_STACKS:
			return Palette.WATER[1].lightened(0.3)  # Frozen
		return Palette.STONE[1]
	if flash:
		return Palette.DANGER[1]
	return base


## Health (red) and poise (pale) over a creature, as wide as it is; armour
## (grey) above them while it lasts.
static func _draw_bars(canvas: CanvasItem, f: Fighter, at: Vector2) -> void:
	var half: float = maxf(8.0, f.radius * 1.2)
	var top: float = at.y - f.radius * 2.0 - 7.0
	canvas.draw_rect(Rect2(at.x - half, top, half * 2, 2), Palette.SHADOW[0])
	canvas.draw_rect(Rect2(at.x - half, top, half * 2 * f.health / f.max_health, 2), Palette.DANGER[1])
	canvas.draw_rect(Rect2(at.x - half, top + 3, half * 2, 1), Palette.SHADOW[0])
	canvas.draw_rect(Rect2(at.x - half, top + 3, half * 2 * f.poise.ratio(), 1), Palette.PAPER[0])
	if f.armour > 0.0:
		canvas.draw_rect(Rect2(at.x - half, top - 3, half * 2 * f.armour / f.armour_max, 2), Palette.STONE[2])


static func _eyes(canvas: CanvasItem, f: Fighter, centre: Vector2, gap: float, colour: Color, fade: float) -> void:
	if f.facing.y < -0.5:
		return  # facing away: no eyes
	var shift: float = roundf(f.facing.x * 2.0)
	canvas.draw_rect(Rect2(centre + Vector2(-gap - 1 + shift, 0), Vector2(2, 2)), Color(colour, fade))
	canvas.draw_rect(Rect2(centre + Vector2(gap - 1 + shift, 0), Vector2(2, 2)), Color(colour, fade))


## The arena's training creature (and anything without its own drawing).
static func _draw_training(canvas: CanvasItem, f: Fighter, at: Vector2, flash: bool, fade: float) -> void:
	var body: Color = _body_colour(f, Palette.CHANGED[1], flash)
	canvas.draw_rect(Rect2(at.x - 7, at.y - 12, 14, 11), Color(body, fade))
	canvas.draw_rect(Rect2(at.x - 5, at.y - 15, 10, 4), Color(Palette.CHANGED[0], fade))
	if f.armour > 0.0:
		# A stone shell over the back, cracking as it is chipped.
		canvas.draw_rect(Rect2(at.x - 8, at.y - 14, 16, 6), Color(Palette.STONE[1], fade))
		canvas.draw_rect(Rect2(at.x - 8, at.y - 14, 16, 2), Color(Palette.STONE[2], fade))
		if f.armour < f.armour_max * 0.5:
			canvas.draw_line(Vector2(at.x - 3, at.y - 14), Vector2(at.x, at.y - 9), Palette.SHADOW[0], 1.0)
	_eyes(canvas, f, at + Vector2(-1, -9), 2.0, Palette.PAPER[1], fade)


## A field mouse: a small grey body with a long tail, too many teeth.
static func _draw_mouse(canvas: CanvasItem, f: Fighter, at: Vector2, flash: bool, fade: float) -> void:
	var body: Color = _body_colour(f, Palette.STONE[1], flash)
	var back: Vector2 = -f.facing
	canvas.draw_line(at + Vector2(0, -3) + back * 4, at + Vector2(0, -2) + back * 9 + back.orthogonal() * 2, Color(Palette.STONE[2], fade), 1.0)
	canvas.draw_rect(Rect2(at.x - 4, at.y - 6, 8, 5), Color(body, fade))
	canvas.draw_rect(Rect2(at.x - 3, at.y - 8, 2, 2), Color(Palette.STONE[2], fade))
	canvas.draw_rect(Rect2(at.x + 1, at.y - 8, 2, 2), Color(Palette.STONE[2], fade))
	_eyes(canvas, f, at + Vector2(-1, -5), 2.0, Palette.DANGER[1], fade)


## A rook: black, wings out while aloft (its shadow on the ground below).
static func _draw_rook(canvas: CanvasItem, f: Fighter, at: Vector2, flash: bool, fade: float) -> void:
	var body: Color = _body_colour(f, Palette.SHADOW[1], flash)
	if f.airborne:
		canvas.draw_circle(at + Vector2(0, 10), 4.0, Color(Palette.SHADOW[0], 0.35 * fade))
		var flap: float = sin(f.ai_timer * 0.4) * 3.0
		canvas.draw_line(at + Vector2(-1, -6), at + Vector2(-9, -8 - flap), Color(body, fade), 2.0)
		canvas.draw_line(at + Vector2(1, -6), at + Vector2(9, -8 - flap), Color(body, fade), 2.0)
	canvas.draw_rect(Rect2(at.x - 4, at.y - 9, 8, 7), Color(body, fade))
	canvas.draw_rect(Rect2(at.x - 1 + f.facing.x * 4, at.y - 7 + f.facing.y * 2, 3, 2), Color(Palette.PAPER[0], fade))
	_eyes(canvas, f, at + Vector2(-1, -8), 2.0, Palette.PAPER[1], fade)


## A hedgehog: a brown body under a coat of spines; curled, a spiked ball.
static func _draw_hedgehog(canvas: CanvasItem, f: Fighter, at: Vector2, flash: bool, fade: float) -> void:
	var body: Color = _body_colour(f, Palette.CHANGED[0], flash)
	var spines: Color = Color(Palette.STONE[2], fade)
	if f.curled:
		var centre: Vector2 = at + Vector2(0, -6)
		canvas.draw_circle(centre, 6.0, Color(body, fade))
		for i: int in range(10):
			var d: Vector2 = Vector2.from_angle(i * TAU / 10.0 + f.state_tick * 0.05)
			canvas.draw_line(centre + d * 5.0, centre + d * 9.0, spines, 1.0)
		return
	canvas.draw_rect(Rect2(at.x - 6, at.y - 7, 12, 6), Color(body, fade))
	for i: int in range(6):
		canvas.draw_line(Vector2(at.x - 5 + i * 2, at.y - 7), Vector2(at.x - 6 + i * 2, at.y - 11), spines, 1.0)
	_eyes(canvas, f, at + Vector2(-1 + f.facing.x * 3, -5), 1.5, Palette.SHADOW[0], fade)


## A flood toad: squat and brown; its throat sac glows as it fills to lob.
static func _draw_toad(canvas: CanvasItem, f: Fighter, at: Vector2, flash: bool, fade: float) -> void:
	var body: Color = _body_colour(f, Palette.WILD[1].darkened(0.1), flash)
	canvas.draw_rect(Rect2(at.x - 7, at.y - 7, 14, 6), Color(body, fade))
	canvas.draw_rect(Rect2(at.x - 5, at.y - 9, 10, 2), Color(body, fade))
	for i: int in range(3):
		canvas.draw_rect(Rect2(at.x - 4 + i * 3, at.y - 6, 1, 1), Color(Palette.CHANGED[1], fade))
	if f.attack_phase() == &"windup":
		var fill: float = float(f.state_tick) / maxf(1.0, f.move.windup_ticks())
		canvas.draw_circle(at + Vector2(0, -3), 2.0 + fill * 3.0, Color(Palette.CHANGED[2].lightened(0.3), 0.8 * fade))
	_eyes(canvas, f, at + Vector2(-1, -10), 3.0, Palette.CHANGED[2], fade)


## A sheaf of wheat stood upright (scenery, or a stook in disguise).
static func _draw_sheaf(canvas: CanvasItem, at: Vector2, fade: float) -> void:
	var straw: Color = Color(Palette.CHANGED[2], fade)
	for i: int in range(5):
		var x: float = at.x - 4 + i * 2
		canvas.draw_line(Vector2(x, at.y - 1), Vector2(at.x - 2 + i, at.y - 14), straw, 1.0)
	canvas.draw_rect(Rect2(at.x - 3, at.y - 8, 6, 2), Color(Palette.CHANGED[0], fade))
	canvas.draw_rect(Rect2(at.x - 3, at.y - 17, 6, 4), straw)


## A stook risen: the sheaf straightened, straw arms unbound.
static func _draw_stook(canvas: CanvasItem, f: Fighter, at: Vector2, flash: bool, fade: float) -> void:
	var rising: float = 1.0
	if f.ai_state == &"rising":
		rising = 1.0 - float(f.ai_timer) / maxf(1.0, CombatTuning.ticks(CreatureBrain.STOOK_RISE_MS))
	var straw: Color = _body_colour(f, Palette.CHANGED[2], flash)
	var top: float = at.y - 14.0 - 6.0 * rising
	for i: int in range(5):
		canvas.draw_line(Vector2(at.x - 4 + i * 2, at.y - 1), Vector2(at.x - 2 + i, top), Color(straw, fade), 1.0)
	canvas.draw_rect(Rect2(at.x - 3, top - 3, 6, 4), Color(straw, fade))
	var reach: float = 4.0 + 7.0 * rising
	canvas.draw_line(Vector2(at.x - 2, top + 6), Vector2(at.x - 2 - reach, top + 2), Color(straw, fade), 1.0)
	canvas.draw_line(Vector2(at.x + 2, top + 6), Vector2(at.x + 2 + reach, top + 2), Color(straw, fade), 1.0)
	_eyes(canvas, f, Vector2(at.x - 1, top - 2), 1.5, Palette.CHANGED[2], fade)


## A moth: pale, dusty wings with an eye pattern, fluttering.
static func _draw_moth(canvas: CanvasItem, f: Fighter, at: Vector2, flash: bool, fade: float) -> void:
	var wing: Color = _body_colour(f, Palette.PAPER[0], flash)
	var flutter: float = absf(sin(f.ai_timer * 0.6)) * 3.0 + 1.0
	var centre: Vector2 = at + Vector2(0, -10)
	canvas.draw_rect(Rect2(centre + Vector2(-1 - flutter - 2, -2), Vector2(flutter + 2, 4)), Color(wing, fade))
	canvas.draw_rect(Rect2(centre + Vector2(1, -2), Vector2(flutter + 2, 4)), Color(wing, fade))
	canvas.draw_rect(Rect2(centre + Vector2(-1, -2), Vector2(2, 5)), Color(Palette.STONE[1], fade))
	canvas.draw_rect(Rect2(centre + Vector2(-flutter - 1, -1), Vector2(1, 1)), Color(Palette.CHANGED[0], fade))
	canvas.draw_rect(Rect2(centre + Vector2(flutter + 1, -1), Vector2(1, 1)), Color(Palette.CHANGED[0], fade))


## Grist: a huge dark boar with pale tusks; caked in mud while armoured.
static func _draw_grist(canvas: CanvasItem, f: Fighter, at: Vector2, flash: bool, fade: float) -> void:
	var body: Color = _body_colour(f, Palette.SHADOW[2].darkened(0.1), flash)
	var r: float = f.radius
	if f.ai_state == &"wallowing":
		canvas.draw_circle(at + Vector2(0, -4), r + 6.0, Color(Palette.CHANGED[2].darkened(0.45), 0.6 * fade))
	canvas.draw_rect(Rect2(at.x - r, at.y - r * 1.4, r * 2, r * 1.3), Color(body, fade))
	canvas.draw_rect(Rect2(at.x - r * 0.7, at.y - r * 1.7, r * 1.4, r * 0.4), Color(body.darkened(0.2), fade))  # the bristled back
	if f.armour > 0.0:
		var mud: Color = Color(Palette.CHANGED[2].darkened(0.45), fade)
		canvas.draw_rect(Rect2(at.x - r, at.y - r * 1.4, r * 2, r * 0.7), mud)
		for i: int in range(5):
			canvas.draw_rect(Rect2(at.x - r + i * r * 0.45, at.y - r * 0.6, 3, 3), mud)
	var snout: Vector2 = at + Vector2(f.facing.x * r * 0.9, -r * 0.7 + f.facing.y * 3.0)
	canvas.draw_rect(Rect2(snout - Vector2(4, 3), Vector2(8, 6)), Color(body.lightened(0.15), fade))
	if f.facing.y > -0.5:
		var tusk: Color = Color(Palette.PAPER[1], fade)
		canvas.draw_line(snout + Vector2(-4, 2), snout + Vector2(-6, -4), tusk, 2.0)
		canvas.draw_line(snout + Vector2(4, 2), snout + Vector2(6, -4), tusk, 2.0)
	_eyes(canvas, f, at + Vector2(-1 + f.facing.x * r * 0.5, -r * 1.1), 4.0, Palette.DANGER[1] if f.phase == 2 else Palette.PAPER[0], fade)


## "z"s drifting up from a sleeper.
static func _draw_sleep(canvas: CanvasItem, at: Vector2, tick: int) -> void:
	for i: int in range(2):
		var rise: float = fmod(tick * 0.3 + i * 10.0, 20.0)
		var spot: Vector2 = at + Vector2(i * 4, -rise)
		var c: Color = Color(Palette.PAPER[1], 1.0 - rise / 20.0)
		canvas.draw_line(spot, spot + Vector2(3, 0), c, 1.0)
		canvas.draw_line(spot + Vector2(3, 0), spot + Vector2(0, 3), c, 1.0)
		canvas.draw_line(spot + Vector2(0, 3), spot + Vector2(3, 3), c, 1.0)


## The arena's props: Grist's yard and the field's sheaves.
static func _draw_props(canvas: CanvasItem, sim: CombatSim) -> void:
	for prop: Dictionary in sim.props:
		var rect: Rect2 = prop["rect"]
		match prop["kind"]:
			&"wallow":
				canvas.draw_rect(rect, Palette.CHANGED[2].darkened(0.55))
				canvas.draw_rect(rect.grow(-3), Palette.CHANGED[2].darkened(0.4))
			&"trough":
				canvas.draw_rect(rect, Palette.STONE[1])
				canvas.draw_rect(rect.grow(-2), Palette.WATER[0])
			&"sacks":
				for i: int in range(3):
					var sack: Rect2 = Rect2(rect.position + Vector2(i * rect.size.x / 3.0, 0), Vector2(rect.size.x / 3.0 - 1, rect.size.y))
					canvas.draw_rect(sack, Palette.PAPER[0].darkened(0.15))
					canvas.draw_rect(Rect2(sack.position + Vector2(1, 2), Vector2(sack.size.x - 2, 2)), Palette.STONE[0])
			&"millstone_leaning":
				var centre: Vector2 = rect.get_center()
				canvas.draw_rect(Rect2(centre.x - rect.size.x / 2, rect.position.y - 8, rect.size.x, rect.size.y + 8), Palette.STONE[1])
				canvas.draw_rect(Rect2(centre.x - rect.size.x / 2, rect.position.y - 8, rect.size.x, 2), Palette.STONE[2])
				canvas.draw_circle(Vector2(centre.x, rect.position.y), 2.0, Palette.SHADOW[0])
			&"millstone_flat":
				var c: Vector2 = rect.get_center()
				canvas.draw_circle(c, rect.size.x / 2.0, Palette.STONE[1])
				canvas.draw_arc(c, rect.size.x / 2.0, 0, TAU, 24, Palette.STONE[2], 1.0)
				canvas.draw_circle(c, 2.0, Palette.SHADOW[0])
			&"sheaf":
				_draw_sheaf(canvas, rect.get_center() + Vector2(0, 6), 1.0)
			_:
				canvas.draw_rect(rect, Palette.STONE[1])


## A light source: a pool of glow (glowing fungus).
static func _draw_light(canvas: CanvasItem, at: Vector2, tick: int) -> void:
	var pulse: float = 0.5 + 0.5 * sin(tick * 0.05)
	canvas.draw_circle(at, 18.0, Color(Palette.CHANGED[2], 0.08 + 0.04 * pulse))
	canvas.draw_circle(at, 6.0, Color(Palette.CROPS[1], 0.25))
	for i: int in range(3):
		canvas.draw_rect(Rect2(at + Vector2(-4 + i * 3, -2 - i % 2), Vector2(2, 3)), Palette.CROPS[1].lightened(0.3))


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
		"seed_jump":
			# An arc from the old host to the new one, the seed riding it.
			var t: float = age / float(EFFECT_TICKS["seed_jump"])
			var from: Vector2 = effect.get("from", at) + Vector2(4, -12)
			var to: Vector2 = at + Vector2(4, -12)
			var points: PackedVector2Array = []
			for i: int in range(9):
				var k: float = i / 8.0
				points.append(from.lerp(to, k) + Vector2(0, -12.0 * sin(PI * k)))
			canvas.draw_polyline(points, Color(EFFECT_COLOURS[StatusEffects.ROT], 0.8 * (1.0 - t)), 1.0)
			var u: float = minf(1.0, t * 2.0)
			canvas.draw_circle(from.lerp(to, u) + Vector2(0, -12.0 * sin(PI * u)), 2.0, Color(EFFECT_COLOURS[StatusEffects.ROT], 1.0 - t))
		"seed_latch":
			var t: float = age / float(EFFECT_TICKS["seed_latch"])
			canvas.draw_arc(at + Vector2(4, -12), 3.0 + t * 6.0, 0, TAU, 16, Color(EFFECT_COLOURS[StatusEffects.ROT].lightened(0.3), 1.0 - t), 1.0)
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
