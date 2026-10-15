extends Node
## SaveManager (autoload): writes and reads user://save.json (IndexedDB in the web build).
## Contract: docs/contracts.md, section 12. Based on Mariana's first version.
##
## GameState (section 4) does not exist yet, so save_game() stores only "version" and
## "build" for now. When GameState lands, its fields are added in _collect().

const SAVE_PATH: String = "user://save.json"
const SAVE_VERSION: int = 1

## Tests point this at another file, so they never touch the player's real save.
var save_path: String = SAVE_PATH


## Writes the current game. Returns OK or the file error.
func save_game() -> Error:
	var file: FileAccess = FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		var error: Error = FileAccess.get_open_error()
		push_warning("SaveManager: cannot write %s (%s)" % [save_path, error_string(error)])
		return error
	file.store_string(JSON.stringify(_collect(), "\t"))
	return OK


## Returns the saved game, or {} when there is no save, the file is corrupted
## or its version is unknown. It never crashes: the caller shows a message and starts a new game.
func load_game() -> Dictionary:
	if not has_save():
		return {}
	var text: String = FileAccess.get_file_as_string(save_path)
	var json: JSON = JSON.new()
	if json.parse(text) != OK:
		push_warning("SaveManager: %s is corrupted (line %d: %s)" % [save_path, json.get_error_line(), json.get_error_message()])
		return {}
	var data: Variant = json.data
	if not data is Dictionary:
		push_warning("SaveManager: %s does not hold an object" % save_path)
		return {}
	# JSON gives numbers back as float.
	var version: int = int(data.get("version", -1))
	if version != SAVE_VERSION:
		push_warning("SaveManager: unknown save version %d" % version)
		return {}
	data["version"] = version
	return data


func has_save() -> bool:
	return FileAccess.file_exists(save_path)


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(save_path)


func _collect() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"build": str(ProjectSettings.get_setting("application/config/version", "")),
	}
