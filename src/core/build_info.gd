class_name BuildInfo
extends RefCounted
## Identifies which build is running, so playtest reports can name it.
##
## CI writes res://build_stamp.json before exporting. Local runs from the
## editor have no stamp and report "dev".

const STAMP_PATH: String = "res://build_stamp.json"


## Returns {"version", "build", "commit"}; missing fields fall back to "dev".
static func read(path: String = STAMP_PATH) -> Dictionary:
	var info: Dictionary = {
		"version": str(ProjectSettings.get_setting("application/config/version", "0.0.0")),
		"build": "dev",
		"commit": "dev",
	}
	if not FileAccess.file_exists(path):
		return info
	var text: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		push_warning("BuildInfo: %s is not a JSON object" % path)
		return info
	var stamp: Dictionary = parsed
	for key: String in ["build", "commit"]:
		if stamp.has(key):
			info[key] = str(stamp[key])
	return info


## One-line label, e.g. "v0.1.0 build 12 (a1b2c3d)".
static func label(path: String = STAMP_PATH) -> String:
	var info: Dictionary = read(path)
	var commit: String = str(info["commit"])
	if commit.length() > 7:
		commit = commit.substr(0, 7)
	return "v%s build %s (%s)" % [info["version"], info["build"], commit]
