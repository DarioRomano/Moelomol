class_name Projectile
extends RefCounted
## An arrow in flight. Moves in a straight line each tick; hits the first
## creature on its path (or every creature, if it pierces) with `move`, and
## stops at walls, obstacles or the end of its range.

var owner: Fighter
var move: CombatMove  # what a hit does (damage, poise, push, hit-stop)
var position: Vector2
var previous_position: Vector2
var velocity: Vector2  # layout px per tick
var range_left: float  # layout px it may still fly
var pierce: bool = false
var marker: bool = false  # the Volley marker: marks where it stops
var hit: Array[Fighter] = []


static func make(p_owner: Fighter, p_move: CombatMove, from: Vector2, direction: Vector2,
		speed_per_tick: float, max_range: float) -> Projectile:
	var p: Projectile = Projectile.new()
	p.owner = p_owner
	p.move = p_move
	p.position = from
	p.previous_position = from
	p.velocity = direction.normalized() * speed_per_tick
	p.range_left = max_range
	return p
