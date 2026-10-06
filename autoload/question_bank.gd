extends Node
## QuestionBank (autoload): the only code that reads the JSON files in data/.
## Other modules ask it for items, pools, encounters and dialogue lines.
## Contract: docs/contracts.md, sections 7, 8, 10 and 11.
##
## Every getter returns a copy, so a caller cannot change the loaded data by accident.

const SCHEMA_VERSION: int = 1
const KANA_FILES: Array[String] = [
	"res://data/hiragana.json",
	"res://data/katakana.json",
]
const POOLS_FILE: String = "res://data/pools.json"
const ENCOUNTERS_FILE: String = "res://data/encounters.json"
## One file per chapter. Add a line here when a chapter gets its own dialogue file.
const DIALOGUE_FILES: Array[String] = [
	"res://data/dialogue/ch1.json",
]

var _items: Dictionary = {}          # item id -> item (section 7)
var _item_ids: Array[String] = []    # item ids in file order, used by items_for()
var _pools: Dictionary = {}          # pool id -> Array[String] of item ids
var _encounters: Dictionary = {}     # encounter id -> encounter (section 10)
var _dialogues: Dictionary = {}      # dialogue id -> Array of lines (section 11)
var _last_error: Error = OK


func _ready() -> void:
	var error: Error = load_all()
	if error != OK:
		push_error("QuestionBank: data/ did not load (%s)" % error_string(error))


## Reads every file in data/. Returns OK, or the error of the first file that failed.
## A failing file is reported with push_error(): its path and, for a JSON error, the line.
func load_all() -> Error:
	_clear()
	for path in KANA_FILES:
		var items: Variant = _read_json(path, "items")
		if items == null:
			return _last_error
		for item in items:
			_add_item(item)
	var pools: Variant = _read_json(POOLS_FILE, "pools")
	if pools == null:
		return _last_error
	for pool_id in pools:
		var ids: Array[String] = []
		ids.assign(pools[pool_id].get("items", []))
		_pools[pool_id] = ids
	var encounters: Variant = _read_json(ENCOUNTERS_FILE, "encounters")
	if encounters == null:
		return _last_error
	for encounter_id in encounters:
		var encounter: Dictionary = (encounters[encounter_id] as Dictionary).duplicate(true)
		encounter["id"] = encounter_id
		encounter["chapter"] = int(encounter.get("chapter", 0))
		_encounters[encounter_id] = encounter
	for path in DIALOGUE_FILES:
		var dialogues: Variant = _read_json(path, "dialogues")
		if dialogues == null:
			return _last_error
		for dialogue_id in dialogues:
			_dialogues[dialogue_id] = dialogues[dialogue_id]
	return OK


## One kana item ({} if the id is unknown).
func get_item(item_id: String) -> Dictionary:
	if not _items.has(item_id):
		return {}
	return (_items[item_id] as Dictionary).duplicate(true)


## The items of [param chapter] whose row is in [param rows], in file order.
func items_for(chapter: int, rows: Array[String]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item_id in _item_ids:
		var item: Dictionary = _items[item_id]
		if item["chapter"] == chapter and rows.has(item["row"]):
			result.append(item.duplicate(true))
	return result


## The item ids of a pool ([] if the pool is unknown).
func get_pool(pool_id: String) -> Array[String]:
	var ids: Array[String] = []
	if _pools.has(pool_id):
		ids.assign(_pools[pool_id])
	return ids


## One encounter with its own "id" and an int "chapter" ({} if the id is unknown).
func get_encounter(encounter_id: String) -> Dictionary:
	if not _encounters.has(encounter_id):
		return {}
	return (_encounters[encounter_id] as Dictionary).duplicate(true)


## The lines of one dialogue ([] if the id is unknown).
func get_dialogue(dialogue_id: String) -> Array[Dictionary]:
	var lines: Array[Dictionary] = []
	if _dialogues.has(dialogue_id):
		lines.assign((_dialogues[dialogue_id] as Array).duplicate(true))
	return lines


func _clear() -> void:
	_items.clear()
	_item_ids.clear()
	_pools.clear()
	_encounters.clear()
	_dialogues.clear()
	_last_error = OK


func _add_item(raw: Variant) -> void:
	if not (raw is Dictionary) or not (raw as Dictionary).has("id"):
		push_error("QuestionBank: an item without an id was skipped")
		return
	var item: Dictionary = (raw as Dictionary).duplicate(true)
	item["chapter"] = int(item.get("chapter", 0))
	var item_id: String = str(item["id"])
	_items[item_id] = item
	_item_ids.append(item_id)


## Opens one data file and returns the value under [param key], or null after push_error().
func _read_json(path: String, key: String) -> Variant:
	if not FileAccess.file_exists(path):
		return _fail(ERR_FILE_NOT_FOUND, "%s: file not found" % path)
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _fail(FileAccess.get_open_error(), "%s: cannot open the file" % path)
	var json: JSON = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		var where: String = "%s, line %d" % [path, json.get_error_line()]
		return _fail(ERR_PARSE_ERROR, "%s: %s" % [where, json.get_error_message()])
	var data: Variant = json.data
	if not (data is Dictionary):
		return _fail(ERR_INVALID_DATA, "%s: the top level must be a JSON object" % path)
	var version: int = int((data as Dictionary).get("schema_version", 0))
	if version != SCHEMA_VERSION:
		var problem: String = "schema_version is %d, expected %d" % [version, SCHEMA_VERSION]
		return _fail(ERR_INVALID_DATA, "%s: %s" % [path, problem])
	if not (data as Dictionary).has(key):
		return _fail(ERR_INVALID_DATA, "%s: the key \"%s\" is missing" % [path, key])
	return (data as Dictionary)[key]


func _fail(error: Error, message: String) -> Variant:
	_last_error = error
	push_error("QuestionBank: " + message)
	return null
