extends TestCase
## BuildInfo reads the stamp CI writes before export.

const TEMP_STAMP: String = "user://test_build_stamp.json"


func after_each() -> void:
	if FileAccess.file_exists(TEMP_STAMP):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_STAMP))


func _write(text: String) -> void:
	var file: FileAccess = FileAccess.open(TEMP_STAMP, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func test_missing_stamp_reports_dev() -> void:
	var info: Dictionary = BuildInfo.read("user://does_not_exist.json")
	assert_eq(info["build"], "dev", "build")
	assert_eq(info["commit"], "dev", "commit")
	assert_eq(info["version"], ProjectSettings.get_setting("application/config/version"), "version")


func test_stamp_values_are_read() -> void:
	_write('{"build": "42", "commit": "0123456789abcdef"}')
	var info: Dictionary = BuildInfo.read(TEMP_STAMP)
	assert_eq(info["build"], "42", "build")
	assert_eq(info["commit"], "0123456789abcdef", "commit")


func test_label_shortens_commit() -> void:
	_write('{"build": "7", "commit": "0123456789abcdef"}')
	var version: String = ProjectSettings.get_setting("application/config/version")
	assert_eq(BuildInfo.label(TEMP_STAMP), "v%s build 7 (0123456)" % version, "label")


func test_malformed_stamp_falls_back_to_dev() -> void:
	_write("[1, 2, 3]")
	var info: Dictionary = BuildInfo.read(TEMP_STAMP)
	assert_eq(info["build"], "dev", "build after malformed stamp")
