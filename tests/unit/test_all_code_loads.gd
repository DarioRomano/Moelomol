extends TestCase
## Every script parses and every scene loads and instantiates without errors.
## This is what catches untyped declarations (ADR-0003), because the project
## turns that warning into a parse error.

const SKIP_DIRS: Array[String] = ["res://.godot", "res://build", "res://renders"]


func test_every_script_compiles() -> void:
	var scripts: Array[String] = _find_files("res://", ".gd")
	assert_true(scripts.size() > 0, "found scripts to check")
	for path: String in scripts:
		var script: GDScript = load(path) as GDScript
		assert_true(script != null, "%s loads" % path)
		if script != null:
			assert_true(script.can_instantiate() or script.is_abstract(), "%s compiles" % path)


func test_every_scene_instantiates() -> void:
	var scenes: Array[String] = _find_files("res://", ".tscn")
	assert_true(scenes.size() > 0, "found scenes to check")
	for path: String in scenes:
		var packed: PackedScene = load(path) as PackedScene
		assert_true(packed != null, "%s loads" % path)
		if packed == null:
			continue
		var node: Node = packed.instantiate()
		assert_true(node != null, "%s instantiates" % path)
		if node != null:
			# Enter the tree briefly so _ready() runs and its errors are caught.
			(Engine.get_main_loop() as SceneTree).root.add_child(node)
			await (Engine.get_main_loop() as SceneTree).process_frame
			node.queue_free()
			await (Engine.get_main_loop() as SceneTree).process_frame


func _find_files(dir_path: String, extension: String) -> Array[String]:
	var result: Array[String] = []
	if dir_path in SKIP_DIRS:
		return result
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return result
	for sub: String in dir.get_directories():
		result.append_array(_find_files(dir_path.path_join(sub), extension))
	for file: String in dir.get_files():
		if file.ends_with(extension):
			result.append(dir_path.path_join(file))
	return result
