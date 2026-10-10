class_name CombatHud
extends Control
## Arena HUD: health and stamina bars (art-direction: calm, sparse, at the
## edge), the current move, and the controls. Lives in a UiFrame, so it
## follows the UI width setting (ADR-0008).

var _health: float = 1.0
var _stamina: float = 1.0
var _label: Label
var _help: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = _make_label()
	_label.position = Vector2(8, 22)
	_help = _make_label()
	_help.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 4)
	_help.grow_vertical = Control.GROW_DIRECTION_BEGIN
	# Two lines: one did not fit a 4:3 screen (seen in the review render).
	_help.text = "Move WASD / stick   Light J / X   Heavy (hold) K / RT   Skill L / Y   Dodge Space / A   Swap Tab / RB\n" \
		+ "Lock Shift / LT   Switch Q E / right stick   F5 interpolation   F6 creatures passive   F7 other weapon"


func _make_label() -> Label:
	var label: Label = Label.new()
	label.add_theme_font_size_override("font_size", 7)
	label.add_theme_color_override("font_color", Palette.PAPER[1])
	label.add_theme_color_override("font_shadow_color", Palette.SHADOW[0])
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(label)
	return label


func show_state(sim: CombatSim, interpolation: bool) -> void:
	var p: Fighter = sim.player
	_health = p.health / p.max_health
	_stamina = p.stamina.current / p.stamina.maximum
	var doing: String = _describe(p)
	var passive: bool = not sim.creatures.is_empty() and not sim.creatures[0].ai_enabled
	var weapon: Weapon = p.weapon()
	var swap: String = "   swap in %.1f s" % (p.swap_cooldown / float(CombatTuning.TICK_RATE)) if p.swap_cooldown > 0 else ""
	_label.text = "%s: %s   %s%s%s   interpolation %s%s" % [
		weapon.display_name, doing, weapon.status_text(p), swap,
		"   locked" if sim.lock_target != null else "",
		"on" if interpolation else "off", "   creatures passive" if passive else ""]
	queue_redraw()


static func _describe(p: Fighter) -> String:
	match p.state:
		Fighter.State.ATTACK:
			return "%s (%s)" % [p.move.display_name, p.attack_phase()]
		Fighter.State.DODGE:
			return "Dodge" + (" (invulnerable)" if p.is_invulnerable() else "")
		Fighter.State.BRACE:
			return "Brace"
		Fighter.State.CHARGE:
			return "Charging"
		Fighter.State.STAGGERED:
			return "Staggered"
		Fighter.State.DOWN:
			return "Down"
	return "Ready"


func _draw() -> void:
	draw_rect(Rect2(8, 8, 96, 4), Palette.SHADOW[0])
	draw_rect(Rect2(8, 8, 96 * _health, 4), Palette.DANGER[1])
	draw_rect(Rect2(8, 14, 96, 3), Palette.SHADOW[0])
	draw_rect(Rect2(8, 14, 96 * _stamina, 3), Palette.WARMTH[3])
