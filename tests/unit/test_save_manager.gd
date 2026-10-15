extends GutTest
## SaveManager: contract section 12. Every test uses its own file, never user://save.json.

const TEST_PATH: String = "user://test_save.json"

var manager: Node


func before_each() -> void:
	manager = autofree(load("res://autoload/save_manager.gd").new())
	manager.save_path = TEST_PATH
	manager.delete_save()


func after_each() -> void:
	manager.delete_save()


func _write_raw(text: String) -> void:
	var file: FileAccess = FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func test_no_save_at_start() -> void:
	assert_false(manager.has_save())
	assert_eq(manager.load_game(), {})


func test_save_then_load_gives_version_and_build() -> void:
	assert_eq(manager.save_game(), OK)
	assert_true(manager.has_save())
	var data: Dictionary = manager.load_game()
	assert_eq(data.get("version"), 1)
	assert_typeof(data.get("version"), TYPE_INT, "the version comes back as int, not float")
	assert_eq(data.get("build"), ProjectSettings.get_setting("application/config/version"))


func test_delete_save_removes_the_file() -> void:
	manager.save_game()
	manager.delete_save()
	assert_false(manager.has_save())


func test_corrupted_file_gives_empty_dictionary() -> void:
	_write_raw("{ not json")
	assert_eq(manager.load_game(), {})


func test_json_that_is_not_an_object_gives_empty_dictionary() -> void:
	_write_raw("[1, 2, 3]")
	assert_eq(manager.load_game(), {})


func test_unknown_version_gives_empty_dictionary() -> void:
	_write_raw('{"version": 99, "build": "9.9.9"}')
	assert_eq(manager.load_game(), {})


func test_default_path_is_the_contract_path() -> void:
	var fresh: Node = autofree(load("res://autoload/save_manager.gd").new())
	assert_eq(fresh.save_path, "user://save.json")
