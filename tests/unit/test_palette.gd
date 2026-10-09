extends TestCase
## The palette must match docs/design/art-direction.md: 27 distinct colours
## in 10 named groups.


func test_palette_has_27_colours() -> void:
	assert_eq(Palette.all_colours().size(), 27, "palette size")


func test_palette_colours_are_distinct() -> void:
	var seen: Dictionary = {}
	for colour: Color in Palette.all_colours():
		var key: String = colour.to_html(false)
		assert_false(seen.has(key), "colour #%s appears once" % key)
		seen[key] = true


func test_every_group_has_a_name() -> void:
	assert_eq(Palette.groups().size(), Palette.GROUP_NAMES.size(), "group count matches names")


func test_palette_is_opaque() -> void:
	for colour: Color in Palette.all_colours():
		assert_eq(colour.a, 1.0, "alpha of #%s" % colour.to_html(false))
