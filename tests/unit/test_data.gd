extends GutTest
## Checks that data/hiragana.json loads in Godot and has the expected shape.
## The Python validator (tools/validate_data.py) checks every field; this test
## proves that Godot itself can read the file with FileAccess and JSON.

const HIRAGANA_PATH: String = "res://data/hiragana.json"
const EXPECTED_COUNT: int = 46
const ID_PREFIX: String = "h_"

var _parse_error: String = ""
var _items: Array = []


func before_all() -> void:
	_items = _load_items(HIRAGANA_PATH)


func test_file_parses() -> void:
	assert_eq(_parse_error, "", "hiragana.json should load: %s" % _parse_error)


func test_has_46_items() -> void:
	assert_eq(_items.size(), EXPECTED_COUNT, "hiragana.json should have 46 items")


func test_ids_are_unique() -> void:
	var seen: Dictionary = {}
	for item in _items:
		var id: String = _id_of(item)
		assert_false(seen.has(id), "duplicate id: %s" % id)
		seen[id] = true
	assert_eq(seen.size(), EXPECTED_COUNT, "there should be 46 different ids")


func test_ids_start_with_h() -> void:
	assert_gt(_items.size(), 0, "no items were loaded")
	for item in _items:
		var id: String = _id_of(item)
		assert_true(id.begins_with(ID_PREFIX), "id should start with h_: \"%s\"" % id)


## Returns the "items" array of a data file, or [] and sets _parse_error.
func _load_items(path: String) -> Array:
	if not FileAccess.file_exists(path):
		_parse_error = "file not found: %s" % path
		return []
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		_parse_error = "cannot open %s (error %d)" % [path, FileAccess.get_open_error()]
		return []
	var json: JSON = JSON.new()
	var error: Error = json.parse(file.get_as_text())
	if error != OK:
		_parse_error = "line %d: %s" % [json.get_error_line(), json.get_error_message()]
		return []
	var data: Variant = json.data
	if not (data is Dictionary):
		_parse_error = "the top level is not a JSON object"
		return []
	var items: Variant = (data as Dictionary).get("items")
	if not (items is Array):
		_parse_error = "\"items\" is missing or is not an array"
		return []
	return items as Array


## The id of one item, or "" when the item is not a Dictionary or has no id.
func _id_of(item: Variant) -> String:
	if not (item is Dictionary):
		return ""
	return str((item as Dictionary).get("id", ""))
