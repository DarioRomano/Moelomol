class_name GameClock
extends RefCounted
## The game's clock (docs/design/farming.md, "The day–night cycle"; Q21 and
## Q22, working assumption A). A day runs from 6:00 to 2:00 the next night;
## at 0.75 real seconds per game minute that is 15 real minutes. Time is kept
## in game minutes since the midnight that starts the day, so 2:00 at the end
## of a day is minute 1560.
##
## Starting values; tuning needs the lead's approval.

const DAY_START_MINUTE: int = 6 * 60  # 6:00
const DAY_END_MINUTE: int = 26 * 60  # 2:00 the next night: the player falls asleep
const REAL_SECONDS_PER_GAME_MINUTE: float = 0.75

const DAWN: StringName = &"dawn"  # 6:00-7:00
const DAY: StringName = &"day"  # 7:00-18:00
const DUSK: StringName = &"dusk"  # 18:00-20:00
const NIGHT: StringName = &"night"  # 20:00-2:00
const PHASE_STARTS: Dictionary = {DAWN: 6 * 60, DAY: 7 * 60, DUSK: 18 * 60, NIGHT: 20 * 60}

## The world's tint through the day: [game minute, colour multiplied over the
## world], blended linearly between neighbours. The HUD is never tinted.
const SKY: Array[Array] = [
	[6 * 60, Color(0.72, 0.76, 0.92)],  # dawn: pale and cool
	[7 * 60, Color(1.0, 1.0, 1.0)],
	[18 * 60, Color(1.0, 1.0, 1.0)],
	[19 * 60, Color(1.0, 0.82, 0.64)],  # dusk: amber
	[20 * 60, Color(0.54, 0.6, 0.82)],  # then blue
	# Night: dark and blue, but soil and crops must still read (the first
	# render at 0.32 made dry and watered soil look the same).
	[22 * 60, Color(0.44, 0.5, 0.74)],
	[26 * 60, Color(0.44, 0.5, 0.74)],
]
## The base's warm lights (windows, lanterns) come on through dusk.
const LIGHTS_ON_START: int = 18 * 60 + 30
const LIGHTS_ON_FULL: int = 19 * 60 + 30

var day: int = 1
var minute: float = DAY_START_MINUTE


## Advances by `real_seconds` of play. Returns true if this reached 2:00, the
## end of the day; the clock then stays at 2:00 until next_day().
func advance(real_seconds: float) -> bool:
	if minute >= DAY_END_MINUTE:
		return true
	minute = minf(minute + real_seconds / REAL_SECONDS_PER_GAME_MINUTE, DAY_END_MINUTE)
	return minute >= DAY_END_MINUTE


## Starts the next day at 6:00 (after sleeping or falling asleep).
func next_day() -> void:
	day += 1
	minute = DAY_START_MINUTE


func phase() -> StringName:
	return phase_at(minute)


static func phase_at(at: float) -> StringName:
	if at >= PHASE_STARTS[NIGHT]:
		return NIGHT
	if at >= PHASE_STARTS[DUSK]:
		return DUSK
	if at >= PHASE_STARTS[DAY]:
		return DAY
	return DAWN


## "18:40", wrapping after midnight ("01:15").
func time_text() -> String:
	var whole: int = floori(minute)
	return "%02d:%02d" % [(whole / 60) % 24, whole % 60]


func sky_tint() -> Color:
	return sky_tint_at(minute)


static func sky_tint_at(at: float) -> Color:
	for i: int in range(1, SKY.size()):
		var to: Array = SKY[i]
		if at <= float(to[0]):
			var from: Array = SKY[i - 1]
			var t: float = clampf((at - float(from[0])) / (float(to[0]) - float(from[0])), 0.0, 1.0)
			return (from[1] as Color).lerp(to[1] as Color, t)
	return SKY[SKY.size() - 1][1]


## 0 (off) to 1 (fully on) for the base's warm lights.
func lights() -> float:
	return clampf((minute - LIGHTS_ON_START) / float(LIGHTS_ON_FULL - LIGHTS_ON_START), 0.0, 1.0)
