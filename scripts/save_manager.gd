class_name SaveManager
extends Node

const SAVE_FILE_PATH = "user://save_game.json"

# Salvează un dicționar de date pe disc în format JSON
static func save_game_data(data: Dictionary) -> Error:
	var json_string = JSON.stringify(data)
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(json_string)
	return OK

# Încarcă datele salvate de pe disc
static func load_game_data() -> Dictionary:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		return {}
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file == null:
		return {}
		
	var content = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(content)
	if error != OK:
		push_error("SaveManager: Failed to parse JSON save file.")
		return {}
		
	var data = json.get_data()
	if data is Dictionary:
		return data
		
	return {}
