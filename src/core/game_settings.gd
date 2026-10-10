class_name GameSettings
extends RefCounted
## Player settings, saved to user://settings.cfg.
##
## The UI width (Q15, lead 2026-10-09): on screens wider than the chosen
## shape, HUD and menus stay inside a centred frame while the world still
## fills the screen. Accessibility: a wider hammer sweet spot
## (docs/design/combat.md, "Hammer"). The options menu that changes these
## comes with the first menu; until then only the review renders and the
## settings file set them.
##
## Use GameSettings.shared() in the game; tests make their own instances.

signal changed

enum UiWidth { FULL, WIDE_21_9, WIDE_16_9 }

const PATH: String = "user://settings.cfg"
const SECTION: String = "display"
const KEY_UI_WIDTH: String = "ui_width"
const ACCESSIBILITY: String = "accessibility"
const KEY_HAMMER_WIDE_SWEET_SPOT: String = "hammer_wide_sweet_spot"
## How each UiWidth is written in the settings file and on the command line.
const UI_WIDTH_NAMES: Dictionary = {
	UiWidth.FULL: "full",
	UiWidth.WIDE_21_9: "21:9",
	UiWidth.WIDE_16_9: "16:9",
}

static var _shared: GameSettings = null

var ui_width: UiWidth = UiWidth.FULL
var hammer_wide_sweet_spot: bool = false


## The game-wide settings, loaded from PATH on first use.
static func shared() -> GameSettings:
	if _shared == null:
		_shared = GameSettings.new()
		_shared.load_from(PATH)
	return _shared


## Parses "full", "21:9" or "16:9"; returns -1 for anything else.
static func parse_ui_width(text: String) -> int:
	for value: int in UI_WIDTH_NAMES:
		if UI_WIDTH_NAMES[value] == text:
			return value
	return -1


func set_ui_width(value: UiWidth) -> void:
	if value == ui_width:
		return
	ui_width = value
	changed.emit()


## Loads settings; a missing file keeps the defaults, an unknown value is
## reported and replaced by the default.
func load_from(path: String) -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(path) != OK:
		return
	var text: String = str(config.get_value(SECTION, KEY_UI_WIDTH, UI_WIDTH_NAMES[UiWidth.FULL]))
	var value: int = parse_ui_width(text)
	if value < 0:
		push_warning("GameSettings: unknown ui_width '%s' in %s; using full" % [text, path])
		value = UiWidth.FULL
	set_ui_width(value as UiWidth)
	var wide: Variant = config.get_value(ACCESSIBILITY, KEY_HAMMER_WIDE_SWEET_SPOT, false)
	if wide is bool:
		hammer_wide_sweet_spot = wide
	else:
		push_warning("GameSettings: %s must be true or false in %s" % [KEY_HAMMER_WIDE_SWEET_SPOT, path])


func save_to(path: String) -> Error:
	var config: ConfigFile = ConfigFile.new()
	config.load(path)  # keep any other sections already there
	config.set_value(SECTION, KEY_UI_WIDTH, UI_WIDTH_NAMES[ui_width])
	config.set_value(ACCESSIBILITY, KEY_HAMMER_WIDE_SWEET_SPOT, hammer_wide_sweet_spot)
	return config.save(path)
