class_name GameClock
extends RefCounted
## The game's clock (docs/design/farming.md, "The day–night cycle"; Q21 and
## Q22, decided by the lead 2026-10-10). A full day of 24 game hours lasts
## 20 real minutes and cycles on its own: sleep is never required. The new
## day starts at 6:00, asleep or awake; that is when crops grow.
##
## Time is kept as game minutes since midnight before day 1; the game starts
## at 6:00 on day 1 (minute 360).

const MINUTES_PER_DAY: int = 24 * 60
const DAY_START_MINUTE: int = 6 * 60  # 6:00: the day turns over here
const REAL_SECONDS_PER_DAY: float = 20.0 * 60.0
const REAL_SECONDS_PER_GAME_MINUTE: float = REAL_SECONDS_PER_DAY / MINUTES_PER_DAY

const DAWN: StringName = &"dawn"  # 6:00-7:00
const DAY: StringName = &"day"  # 7:00-18:00
const DUSK: StringName = &"dusk"  # 18:00-20:00
const NIGHT: StringName = &"night"  # 20:00-6:00
const DAWN_START: int = 6 * 60
const DAY_START: int = 7 * 60
const DUSK_START: int = 18 * 60
const NIGHT_START: int = 20 * 60

## The world's tint through a day, by minute of the day (0 = midnight):
## [minute, colour multiplied over the world], blended linearly. The HUD is
## never tinted.
const SKY: Array[Array] = [
	[0, Color(0.44, 0.5, 0.74)],  # night
	[5 * 60 + 30, Color(0.44, 0.5, 0.74)],
	[6 * 60, Color(0.72, 0.76, 0.92)],  # dawn: pale and cool
	[7 * 60, Color(1.0, 1.0, 1.0)],
	[18 * 60, Color(1.0, 1.0, 1.0)],
	[19 * 60, Color(1.0, 0.82, 0.64)],  # dusk: amber
	[20 * 60, Color(0.54, 0.6, 0.82)],  # then blue
	# Night: dark and blue, but soil and crops must still read (a first
	# render at 0.32 made dry and watered soil look the same).
	[22 * 60, Color(0.44, 0.5, 0.74)],
	[24 * 60, Color(0.44, 0.5, 0.74)],
]
## The base's warm lights come on through dusk and go out through dawn.
const LIGHTS_ON_START: int = 18 * 60 + 30
const LIGHTS_ON_FULL: int = 19 * 60 + 30
const LIGHTS_OFF_START: int = 6 * 60
const LIGHTS_OFF_FULL: int = 7 * 60

var total_minutes: float = DAY_START_MINUTE


## Day number, counted from 6:00 to 6:00 (day 1 is the first).
func day() -> int:
	return day_of(total_minutes)


static func day_of(total: float) -> int:
	return 1 + floori((total - DAY_START_MINUTE) / MINUTES_PER_DAY)


## Minute of the day, 0 (midnight) to 1439.
func minute() -> float:
	return fposmod(total_minutes, MINUTES_PER_DAY)


## Advances by `real_seconds` of play. Returns how many new days started
## (0 on almost every tick, 1 as 6:00 passes).
func advance(real_seconds: float) -> int:
	var before: int = day()
	total_minutes += real_seconds / REAL_SECONDS_PER_GAME_MINUTE
	return day() - before


## Sleeping: skips to the next 6:00. Returns the new days started (always 1).
func sleep_until_morning() -> int:
	var before: int = day()
	total_minutes = DAY_START_MINUTE + before * MINUTES_PER_DAY
	return day() - before


func phase() -> StringName:
	return phase_at(minute())


static func phase_at(at: float) -> StringName:
	if at >= NIGHT_START or at < DAWN_START:
		return NIGHT
	if at >= DUSK_START:
		return DUSK
	if at >= DAY_START:
		return DAY
	return DAWN


## "18:40". Many small tick-sized steps sum to a hair under a whole minute
## (60 game minutes showed as "06:59"), so round that hair away first.
func time_text() -> String:
	var whole: int = floori(minute() + 0.001) % MINUTES_PER_DAY
	return "%02d:%02d" % [whole / 60, whole % 60]


func sky_tint() -> Color:
	return sky_tint_at(minute())


static func sky_tint_at(at: float) -> Color:
	var m: float = fposmod(at, MINUTES_PER_DAY)
	for i: int in range(1, SKY.size()):
		var to: Array = SKY[i]
		if m <= float(to[0]):
			var from: Array = SKY[i - 1]
			var t: float = clampf((m - float(from[0])) / (float(to[0]) - float(from[0])), 0.0, 1.0)
			return (from[1] as Color).lerp(to[1] as Color, t)
	return SKY[SKY.size() - 1][1]


## 0 (off) to 1 (fully on) for the base's warm lights.
func lights() -> float:
	return lights_at(minute())


static func lights_at(at: float) -> float:
	if at >= LIGHTS_ON_START:
		return clampf((at - LIGHTS_ON_START) / float(LIGHTS_ON_FULL - LIGHTS_ON_START), 0.0, 1.0)
	if at < LIGHTS_OFF_START:
		return 1.0
	return clampf(1.0 - (at - LIGHTS_OFF_START) / float(LIGHTS_OFF_FULL - LIGHTS_OFF_START), 0.0, 1.0)
