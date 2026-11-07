class_name CreatureKind
extends RefCounted
## What a kind of creature is (docs/design/enemies.md): its values, its
## behaviour (an archetype, run by CreatureBrain) and its moves. Plain data;
## one instance per creature, so a brain may change its moves (Grist's charge
## length) without touching the others.
##
## Starting values; balance needs the lead's approval.

## Behaviours (enemies.md, "Archetypes").
const CHASER: StringName = &"chaser"
const SWARMER: StringName = &"swarmer"
const FLYER: StringName = &"flyer"
const CURLER: StringName = &"curler"
const ARTILLERY: StringName = &"artillery"
const AMBUSHER: StringName = &"ambusher"
const LIGHT_SEEKER: StringName = &"light_seeker"
const BRUTE_BOSS: StringName = &"brute_boss"
## Kettlebridge's river pike: artillery from water (area-kettlebridge.md).
const WATER_ARTILLERY: StringName = &"water_artillery"

var id: StringName
var display_name: String
var behaviour: StringName
var health: float
var poise: float
var radius: float
var speed: float  # layout px/s
var stagger_ms: int = CombatTuning.CREATURE_STAGGER_MS
var attack_range: float = CombatTuning.CREATURE_ATTACK_RANGE  # gap at which it attacks
var cooldown_ms: int = CombatTuning.CREATURE_COOLDOWN_MS  # after each attack
## How far from its home the player can be before it gives up and goes back
## (creatures hold their ground; combat.md).
var leash: float = 220.0
var resists: Array[StringName] = []
var armour: float = 0.0
var boss: bool = false
var respawns: bool = true
## Smoulder spreads from it at this many stacks (dry straw burns sooner).
var smoulder_spread_at: int = StatusEffects.MAX_STACKS
var drops: Array[StringName] = []
## A swarmer that splits: hit hard, it becomes two of this kind (market rats).
var splits_into: StringName = &""
## A flyer that carries: it drops one of this kind beside the player
## (jackdaws carry rat runts).
var carries: StringName = &""
## Its moves by name; which names a brain uses depends on its behaviour.
var moves: Dictionary = {}


## The arena's training creature: the plain Chaser.
static func training() -> CreatureKind:
	var k: CreatureKind = _make(&"training", "Training creature", CHASER,
		CombatTuning.CREATURE_HEALTH, CombatTuning.CREATURE_POISE, CombatTuning.CREATURE_RADIUS, CombatTuning.CREATURE_SPEED)
	k.leash = 10000.0  # the arena is its ground
	return k


## Field mice (Swarmer): packs that zigzag in, nip, scatter when hurt.
static func field_mouse() -> CreatureKind:
	var k: CreatureKind = _make(&"field_mouse", "Field mouse", SWARMER, 18.0, 10.0, 4.0, 70.0)
	k.stagger_ms = 600
	k.attack_range = 14.0
	k.cooldown_ms = 700
	var nip: CombatMove = CombatMove.make(&"mouse_nip", "Nip", Vector3i(350, 100, 400), 4.0, 8.0, 2.0, 8.0, 70.0, 0.0)
	nip.dash = 10.0
	nip.hitstop_ms = 0
	k.moves[&"attack"] = nip
	k.drops = [&"grey_pelt"]
	return k


## Rooks (Flyer): circle out of melee reach, dive along a line, land.
static func rook() -> CreatureKind:
	var k: CreatureKind = _make(&"rook", "Rook", FLYER, 24.0, 12.0, 5.0, 90.0)
	k.stagger_ms = 800
	var dive: CombatMove = CombatMove.make(&"rook_dive", "Dive", Vector3i(500, 250, 1000), 8.0, 20.0, 6.0, 4.0, 0.0, 0.0)
	dive.shape = &"lane"
	dive.lane_width = 8.0
	dive.dash = 96.0
	k.moves[&"attack"] = dive
	k.drops = [&"rook_feather"]
	return k


## Hedgehogs (Curler): curl when the player is near, roll along a line.
static func hedgehog() -> CreatureKind:
	var k: CreatureKind = _make(&"hedgehog", "Hedgehog", CURLER, 40.0, 30.0, 6.0, 25.0)
	k.attack_range = 32.0  # it curls at this gap
	k.cooldown_ms = 1000
	var roll: CombatMove = CombatMove.make(&"hedgehog_roll", "Roll", Vector3i(600, 400, 800), 10.0, 30.0, 8.0, 0.0, 0.0, 0.0)
	roll.shape = &"lane"
	roll.lane_width = 12.0
	roll.dash = 80.0
	roll.stops_at_walls = true
	k.moves[&"attack"] = roll
	k.drops = [&"quills"]
	return k


## Flood toads (Artillery): keep their distance, lob at a marked spot.
static func flood_toad() -> CreatureKind:
	var k: CreatureKind = _make(&"flood_toad", "Flood toad", ARTILLERY, 30.0, 20.0, 6.0, 60.0)
	k.cooldown_ms = 1200
	k.resists = [StatusEffects.SMOULDER]
	var lob: CombatMove = CombatMove.make(&"toad_lob", "Lob", Vector3i(600, 17, 600), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
	lob.melee = false
	k.moves[&"attack"] = lob
	var glob: CombatMove = CombatMove.make(&"toad_glob", "Glob", Vector3i.ZERO, 8.0, 15.0, 0.0, 0.0, 0.0, 0.0)
	glob.hitstop_ms = 0
	k.moves[&"glob"] = glob
	k.drops = [&"toad_slime"]
	return k


## Stooks (Ambusher): a sheaf of wheat until the player is close.
static func stook() -> CreatureKind:
	var k: CreatureKind = _make(&"stook", "Stook", AMBUSHER, 50.0, 40.0, 7.0, 30.0)
	k.leash = 64.0  # it holds its patch of field
	k.cooldown_ms = 1200
	k.smoulder_spread_at = 3
	var lash: CombatMove = CombatMove.make(&"stook_lash", "Lash", Vector3i(500, 100, 600), 12.0, 30.0, 8.0, 19.0, 360.0, 0.0)
	k.moves[&"attack"] = lash
	k.drops = [&"straw", &"wheat_seed"]
	return k


## Moths (Light-seeker): swirl around lights at night, dart in groups.
static func moth() -> CreatureKind:
	var k: CreatureKind = _make(&"moth", "Moth", LIGHT_SEEKER, 6.0, 1.0, 3.0, 70.0)
	k.cooldown_ms = 900
	var dart: CombatMove = CombatMove.make(&"moth_dart", "Dart", Vector3i(300, 200, 300), 3.0, 0.0, 0.0, 2.0, 0.0, 0.0)
	dart.shape = &"lane"
	dart.lane_width = 4.0
	dart.dash = 48.0
	dart.hitstop_ms = 0
	k.moves[&"attack"] = dart
	k.drops = [&"wing_dust"]
	return k


## Grist, the miller's boar: Millbrook's boss (enemies.md).
static func grist() -> CreatureKind:
	var k: CreatureKind = _make(&"grist", "Grist", BRUTE_BOSS, 600.0, 150.0, 14.0, 50.0)
	k.stagger_ms = 1500
	k.attack_range = 30.0  # gores at this gap
	k.cooldown_ms = 700
	k.boss = true
	k.respawns = false
	k.leash = 10000.0  # it never leaves the yard, and the yard is fenced
	var gore: CombatMove = CombatMove.make(&"grist_gore", "Gore", Vector3i(450, 120, 500), 14.0, 40.0, 10.0, 26.0, 120.0, 0.0)
	gore.hyper_armour = true
	k.moves[&"gore"] = gore
	# The charge's length is set before each charge (CreatureBrain).
	var charge: CombatMove = CombatMove.make(&"grist_charge", "Charge", Vector3i(800, 500, 400), 20.0, 50.0, 40.0, 0.0, 0.0, 0.0)
	charge.shape = &"lane"
	charge.lane_width = 28.0
	charge.hyper_armour = true
	charge.stops_at_walls = true
	charge.hitstop_ms = CombatTuning.HITSTOP_HEAVY_MS
	k.moves[&"charge"] = charge
	var heave: CombatMove = CombatMove.make(&"grist_heave", "Millstone", Vector3i(1000, 17, 600), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
	heave.shape = &"lane"
	heave.lane_width = 20.0
	heave.melee = false
	heave.hyper_armour = true
	k.moves[&"heave"] = heave
	var millstone: CombatMove = CombatMove.make(&"millstone", "Millstone", Vector3i.ZERO, 25.0, 60.0, 30.0, 0.0, 0.0, 0.0)
	millstone.hitstop_ms = CombatTuning.HITSTOP_HEAVY_MS
	k.moves[&"millstone"] = millstone
	k.drops = [&"grist_heart", &"tusk"]
	return k


## Market rats (Swarmer that splits; area-kettlebridge.md): big, greyed and
## slow for a swarmer; a heavy hit splits one into two runts.
static func market_rat() -> CreatureKind:
	var k: CreatureKind = _make(&"market_rat", "Market rat", SWARMER, 36.0, 14.0, 6.0, 60.0)
	k.stagger_ms = 600
	k.attack_range = 14.0
	k.cooldown_ms = 800
	var bite: CombatMove = CombatMove.make(&"rat_bite", "Bite", Vector3i(400, 100, 450), 6.0, 10.0, 3.0, 9.0, 70.0, 0.0)
	bite.dash = 10.0
	bite.hitstop_ms = 0
	k.moves[&"attack"] = bite
	k.splits_into = &"rat_runt"
	k.drops = [&"grey_pelt"]
	return k


## A rat runt: what a market rat splits into, or a jackdaw drops. Quick and
## weak; it does not come back.
static func rat_runt() -> CreatureKind:
	var k: CreatureKind = _make(&"rat_runt", "Rat runt", SWARMER, 12.0, 6.0, 4.0, 80.0)
	k.stagger_ms = 500
	k.attack_range = 12.0
	k.cooldown_ms = 700
	k.respawns = false
	k.leash = 10000.0  # loose in the town: it follows
	var nip: CombatMove = CombatMove.make(&"runt_nip", "Nip", Vector3i(300, 100, 400), 3.0, 6.0, 2.0, 8.0, 70.0, 0.0)
	nip.dash = 8.0
	nip.hitstop_ms = 0
	k.moves[&"attack"] = nip
	return k


## Jackdaws (Flyer that drops creatures): circle like rooks, but each comes
## carrying a rat runt and drops it beside the player before its first dive.
static func jackdaw() -> CreatureKind:
	var k: CreatureKind = _make(&"jackdaw", "Jackdaw", FLYER, 20.0, 10.0, 5.0, 100.0)
	k.stagger_ms = 800
	var dive: CombatMove = CombatMove.make(&"jackdaw_dive", "Dive", Vector3i(450, 250, 1000), 6.0, 15.0, 5.0, 4.0, 0.0, 0.0)
	dive.shape = &"lane"
	dive.lane_width = 8.0
	dive.dash = 90.0
	k.moves[&"attack"] = dive
	k.carries = &"rat_runt"
	k.drops = [&"jackdaw_feather"]
	return k


## River pike (Artillery from water): under the river, out of reach; it
## surfaces to spit at a marked spot, then lies at the surface a while,
## where arrows (and a blade from the bank's edge) can reach it.
static func river_pike() -> CreatureKind:
	var k: CreatureKind = _make(&"river_pike", "River pike", WATER_ARTILLERY, 40.0, 25.0, 8.0, 0.0)
	k.cooldown_ms = 2400
	k.leash = 10000.0  # it never leaves its stretch of river
	k.resists = [StatusEffects.SMOULDER]
	var spit: CombatMove = CombatMove.make(&"pike_spit", "Spit", Vector3i(700, 17, 300), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
	spit.melee = false
	k.moves[&"attack"] = spit
	var jet: CombatMove = CombatMove.make(&"pike_jet", "Jet", Vector3i.ZERO, 10.0, 20.0, 0.0, 0.0, 0.0, 0.0)
	jet.hitstop_ms = 0
	k.moves[&"jet"] = jet
	k.drops = [&"pike_scale"]
	return k


## Lichen-backs (Ambusher among gravestones): a mossed gravestone until the
## player is close; then it heaves up and slams.
static func lichen_back() -> CreatureKind:
	var k: CreatureKind = _make(&"lichen_back", "Lichen-back", AMBUSHER, 60.0, 40.0, 7.0, 28.0)
	k.leash = 64.0  # it holds its plot
	k.cooldown_ms = 1300
	var slam: CombatMove = CombatMove.make(&"lichen_slam", "Slam", Vector3i(550, 100, 650), 14.0, 35.0, 10.0, 18.0, 120.0, 0.0)
	k.moves[&"attack"] = slam
	k.drops = [&"lichen"]
	return k


## Every kind, by id (the arena's creature sets, tests).
static func by_id(kind_id: StringName) -> CreatureKind:
	match kind_id:
		&"field_mouse":
			return field_mouse()
		&"rook":
			return rook()
		&"hedgehog":
			return hedgehog()
		&"flood_toad":
			return flood_toad()
		&"stook":
			return stook()
		&"moth":
			return moth()
		&"grist":
			return grist()
		&"market_rat":
			return market_rat()
		&"rat_runt":
			return rat_runt()
		&"jackdaw":
			return jackdaw()
		&"river_pike":
			return river_pike()
		&"lichen_back":
			return lichen_back()
	return training()


static func _make(p_id: StringName, p_name: String, p_behaviour: StringName, p_health: float, p_poise: float,
		p_radius: float, p_speed: float) -> CreatureKind:
	var k: CreatureKind = CreatureKind.new()
	k.id = p_id
	k.display_name = p_name
	k.behaviour = p_behaviour
	k.health = p_health
	k.poise = p_poise
	k.radius = p_radius
	k.speed = p_speed
	return k
