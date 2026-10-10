class_name Fighter
extends RefCounted
## One combatant in a CombatSim: the player or a creature. Plain data; the
## rules live in CombatSim.

enum Kind { PLAYER, CREATURE }
enum State {
	FREE,        # moving or standing
	ATTACK,      # performing `move`: windup (the telegraph), active, recovery
	DODGE,       # player roll
	BRACE,       # player Brace stance
	CHARGE,      # player holding a charge (hammer); state_tick = ticks held
	STAGGERED,
	DOWN,        # defeated: fading (creature) or knocked out (player)
	GONE,        # creature waiting to respawn
}

var kind: Kind
var position: Vector2
var previous_position: Vector2  # for drawing between ticks
var spawn_position: Vector2
var radius: float
var facing: Vector2 = Vector2.DOWN
var max_health: float
var health: float
var poise: Poise
var stamina: Stamina = null  # player only
var armour: float = 0.0  # damage the shell still absorbs; 0 = none or broken
var armour_max: float = 0.0

## Player loadout (Q19): two weapons, one in hand.
var weapons: Array[Weapon] = []
var weapon_index: int = 0
var swap_cooldown: int = 0  # ticks until the next swap is allowed

var state: State = State.FREE
var state_tick: int = 0  # ticks spent in the current state
var state_length: int = 0  # ticks the current state lasts (0 = open-ended)

var move: CombatMove = null
var hit_this_move: Array[Fighter] = []
## Where the current attack's hit zone starts: follows the fighter during the
## windup, then stays put while the attack (and any lunge) plays out.
var attack_origin: Vector2 = Vector2.ZERO
var chain: int = 0  # greatsword light swings done in the current chain
var brace_ready: bool = false  # a hit landed during Brace: next heavy is instant

var push_velocity: Vector2 = Vector2.ZERO  # px per tick while being shoved
var push_ticks: int = 0
var dodge_direction: Vector2 = Vector2.ZERO
## Ticks of the dodge that are invulnerable: [first, first after]. The roll
## sets the shared window; Wardstep is invulnerable throughout.
var iframes: Vector2i = Vector2i(CombatTuning.ticks(CombatTuning.DODGE_IFRAME_START_MS),
	CombatTuning.ticks(CombatTuning.DODGE_IFRAME_END_MS))
var effects: StatusEffects = StatusEffects.new()
var resists: Array[StringName] = []  # effects this creature ignores
var tempo: float = 0.0  # Chill: time owed before the next slowed tick
var cooldown: int = 0  # creature: ticks until it may attack again
var ai_enabled: bool = true  # creature: false = a passive training dummy


static func make_player(at: Vector2) -> Fighter:
	var f: Fighter = Fighter.new()
	f.kind = Kind.PLAYER
	f.position = at
	f.previous_position = at
	f.spawn_position = at
	f.radius = CombatTuning.PLAYER_RADIUS
	f.max_health = CombatTuning.PLAYER_HEALTH
	f.health = f.max_health
	f.poise = Poise.new(CombatTuning.PLAYER_POISE)
	f.stamina = Stamina.new()
	f.weapons = [Greatsword.new(), Hammer.new()]
	return f


static func make_creature(at: Vector2) -> Fighter:
	var f: Fighter = Fighter.new()
	f.kind = Kind.CREATURE
	f.position = at
	f.previous_position = at
	f.spawn_position = at
	f.radius = CombatTuning.CREATURE_RADIUS
	f.max_health = CombatTuning.CREATURE_HEALTH
	f.health = f.max_health
	f.poise = Poise.new(CombatTuning.CREATURE_POISE)
	return f


## Gives a creature a shell that absorbs `amount` damage.
func give_armour(amount: float) -> void:
	armour_max = amount
	armour = amount


## The weapon in hand, or null (creatures).
func weapon() -> Weapon:
	return weapons[weapon_index] if weapon_index < weapons.size() else null


func enter(new_state: State, length: int = 0) -> void:
	state = new_state
	state_tick = 0
	state_length = length


func is_alive() -> bool:
	return state != State.DOWN and state != State.GONE


func is_staggered() -> bool:
	return state == State.STAGGERED


## Which part of the current attack we are in: &"windup", &"active",
## &"recovery", or &"" when not attacking.
func attack_phase() -> StringName:
	if state != State.ATTACK or move == null:
		return &""
	if state_tick < move.windup_ticks():
		return &"windup"
	if state_tick < move.windup_ticks() + move.active_ticks():
		return &"active"
	return &"recovery"


## True while the player cannot be hurt: the middle of a dodge.
func is_invulnerable() -> bool:
	return state == State.DODGE and state_tick >= iframes.x and state_tick < iframes.y


## True while hits cannot stagger this fighter.
func has_hyper_armour() -> bool:
	if state == State.BRACE:
		return true
	var phase: StringName = attack_phase()
	return move != null and move.hyper_armour and (phase == &"windup" or phase == &"active")
