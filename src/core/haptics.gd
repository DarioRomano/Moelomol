class_name Haptics
extends RefCounted
## Controller rumble by named effect (ADR-0013: gameplay asks for effects,
## this decides what each controller does). Rumble only for now; DualSense
## adaptive triggers are a later prototype. Values follow the haptics table in
## docs/design/combat.md; how they feel can only be judged on a real
## controller (playtest checklist).

## effect name -> [weak motor 0..1, strong motor 0..1, seconds]
const EFFECTS: Dictionary = {
	&"greatsword_hit": [0.2, 0.6, 0.08],
	&"greatsword_heavy_hit": [0.3, 0.9, 0.14],
	&"impact": [0.4, 1.0, 0.16],
	&"player_hit": [0.5, 0.5, 0.12],
	&"stagger": [0.2, 0.7, 0.2],
	&"hammer_jab": [0.2, 0.4, 0.06],
	&"hammer_charge": [0.15, 0.0, 0.9],  # weak motor while the charge rises
	&"hammer_sweet_spot": [0.0, 0.8, 0.03],  # a sharp click
	&"hammer_hit": [0.3, 0.8, 0.12],
	&"hammer_perfect": [0.6, 1.0, 0.25],  # the heaviest pulse in the game
	&"bow_stage": [0.0, 0.45, 0.03],  # a tick at each draw stage
	&"bow_release": [0.25, 0.15, 0.05],  # the string's snap
	&"bow_hit": [0.15, 0.3, 0.05],
	&"bow_heavy_hit": [0.3, 0.7, 0.1],
	&"spell_cast": [0.1, 0.0, 0.05],  # a faint buzz
	&"spell_hit": [0.1, 0.2, 0.04],
	&"release": [0.3, 0.6, 0.1],  # up to 5 stacks consumed
	&"release_big": [0.5, 0.95, 0.2],  # more than 5
	&"wardstep": [0.15, 0.1, 0.06],
}

const HEAVY_GREATSWORD_MOVES: Array[StringName] = [&"cleave", &"spin", &"rising", &"follow_through", &"brace_counter"]

## 0 = off, 1 = full. The options menu will set this (ADR-0013: vibration
## intensity including off).
var intensity: float = 1.0
## Replaced in tests; in the game this is Input.start_joy_vibration.
var rumble: Callable = func(device: int, weak: float, strong: float, seconds: float) -> void:
	Input.start_joy_vibration(device, weak, strong, seconds)
## Replaced in tests; in the game, the connected controllers.
var devices: Callable = func() -> Array[int]:
	return Input.get_connected_joypads()


## Plays a named effect on every connected controller. Unknown names are a
## programming error.
func play(effect: StringName) -> void:
	if not EFFECTS.has(effect):
		push_error("Haptics: unknown effect %s" % effect)
		return
	if intensity <= 0.0:
		return
	var values: Array = EFFECTS[effect]
	for device: int in devices.call():
		rumble.call(device, float(values[0]) * intensity, float(values[1]) * intensity, float(values[2]))


## The effect for a combat event from CombatSim, or &"" for none.
static func effect_for_event(event: Dictionary) -> StringName:
	match event["type"]:
		"hit":
			var target: Fighter = event["target"]
			if target.kind == Fighter.Kind.PLAYER:
				return &"player_hit"
			var move: StringName = event["move"]
			match move:
				Hammer.STRIKE_PERFECT:
					return &""  # the shockwave plays the perfect-strike pulse
				Hammer.STRIKE_EARLY, Hammer.STRIKE_LATE:
					return &"hammer_hit"
				&"hammer_jab", &"ground_stamp":
					return &"hammer_jab"
				&"arrow_heavy":
					return &"bow_heavy_hit"
				&"arrow_quick", &"arrow_strong", &"arrow_piercing", &"arrow_marker":
					return &"bow_hit"
				&"volley_rain":
					return &""  # many small hits at once: rumble would only blur
				&"ember", &"frost":
					return &"spell_hit"
				&"release", &"shatter":
					return &""  # the release event plays the pulse
			return &"greatsword_heavy_hit" if move in HEAVY_GREATSWORD_MOVES else &"greatsword_hit"
		"impact":
			return &"impact"
		"charge_start":
			return &"hammer_charge"
		"sweet_spot":
			return &"hammer_sweet_spot"
		"shockwave":
			return &"hammer_perfect"
		"draw_stage":
			return &"bow_stage"
		"cast":
			return &"spell_cast"
		"wardstep":
			return &"wardstep"
		"frozen":
			return &"stagger"
		"release":
			var consumed: Dictionary = event["consumed"]
			var stacks: int = 0
			for kind: StringName in consumed:
				stacks += int(consumed[kind])
			return &"release_big" if stacks > StatusEffects.MAX_STACKS else &"release"
		"arrow":
			var shooter: Fighter = event["fighter"]
			return &"bow_release" if shooter.kind == Fighter.Kind.PLAYER else &""
		"stagger":
			var fighter: Fighter = event["fighter"]
			return &"stagger" if fighter.kind == Fighter.Kind.CREATURE else &""
	return &""
