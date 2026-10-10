extends TestCase
## Guards project-wide rules from the ADRs: renderer, typing, export presets.

const EXPORT_PRESETS_PATH: String = "res://export_presets.cfg"
## CI (tools/export.sh) exports these presets by exact name.
const REQUIRED_PRESETS: Dictionary = {
	"Windows Desktop": "Windows Desktop",
	"macOS": "macOS",
	"Linux": "Linux",
	"Web": "Web",
	"Linux ARM64": "Linux",
}


func test_renderer_is_compatibility_everywhere() -> void:
	# Working assumption for open question Q5.
	assert_eq(ProjectSettings.get_setting("rendering/renderer/rendering_method"), "gl_compatibility",
		"desktop rendering method")


func test_untyped_declarations_are_errors() -> void:
	# ADR-0003: 2 = Error.
	assert_eq(ProjectSettings.get_setting("debug/gdscript/warnings/untyped_declaration"), 2,
		"untyped_declaration warning level")


func test_main_scene_exists() -> void:
	var main_scene: String = ProjectSettings.get_setting("application/run/main_scene")
	assert_true(ResourceLoader.exists(main_scene), "main scene %s exists" % main_scene)


func test_export_presets_match_ci() -> void:
	var config: ConfigFile = ConfigFile.new()
	var error: Error = config.load(EXPORT_PRESETS_PATH)
	assert_eq(error, OK, "load %s" % EXPORT_PRESETS_PATH)
	var found: Dictionary = {}
	for section: String in config.get_sections():
		if section.count(".") != 1:
			continue
		var preset_name: String = config.get_value(section, "name", "")
		var platform: String = config.get_value(section, "platform", "")
		found[preset_name] = platform
		var filter: String = config.get_value(section, "include_filter", "")
		assert_true(filter.contains("build_stamp.json"),
			"preset '%s' includes build_stamp.json (include_filter is '%s')" % [preset_name, filter])
	for preset_name: String in REQUIRED_PRESETS:
		assert_true(found.has(preset_name), "export preset '%s' exists" % preset_name)
		if found.has(preset_name):
			assert_eq(found[preset_name], REQUIRED_PRESETS[preset_name], "platform of preset '%s'" % preset_name)
