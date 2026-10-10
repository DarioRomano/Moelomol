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
}

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
			var heavy: bool = event["move"] in [&"cleave", &"spin", &"rising", &"follow_through", &"brace_counter"]
			return &"greatsword_heavy_hit" if heavy else &"greatsword_hit"
		"impact":
			return &"impact"
		"stagger":
			var fighter: Fighter = event["fighter"]
			return &"stagger" if fighter.kind == Fighter.Kind.CREATURE else &""
	return &""
