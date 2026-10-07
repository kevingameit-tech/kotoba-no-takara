extends GutTest
## Tests for autoload/question_bank.gd with the real files in data/.
## The bank is created with new() (not as an autoload), so every test starts empty.

const QuestionBankScript: GDScript = preload("res://autoload/question_bank.gd")
const TEMP_FILE: String = "user://test_question_bank.json"

var _bank: Node = null


func before_each() -> void:
	_bank = autofree(QuestionBankScript.new())


func after_each() -> void:
	if FileAccess.file_exists(TEMP_FILE):
		DirAccess.remove_absolute(TEMP_FILE)


func test_load_all_returns_ok() -> void:
	assert_eq(_bank.load_all(), OK, "every file in data/ should load")


func test_get_item_returns_a_kana_item() -> void:
	_bank.load_all()
	var item: Dictionary = _bank.get_item("h_ka")
	assert_eq(item.get("kana"), "か")
	assert_eq(item.get("romaji"), "ka")
	assert_eq(item.get("row"), "k")
	assert_typeof(item.get("chapter"), TYPE_INT, "chapter is cast to int")


func test_unknown_ids_return_empty_values() -> void:
	_bank.load_all()
	assert_true(_bank.get_item("h_nope").is_empty(), "unknown item")
	assert_true(_bank.get_pool("nope").is_empty(), "unknown pool")
	assert_true(_bank.get_encounter("nope").is_empty(), "unknown encounter")
	assert_true(_bank.get_dialogue("nope").is_empty(), "unknown dialogue")


func test_get_pool_returns_the_ids_in_order() -> void:
	_bank.load_all()
	var ids: Array[String] = _bank.get_pool("c1_row_a")
	assert_eq(ids, ["h_a", "h_i", "h_u", "h_e", "h_o"] as Array[String])


func test_every_pool_item_exists() -> void:
	_bank.load_all()
	for pool_id in ["c1_row_a", "c1_row_k", "c1_row_w", "c1_boss_tengu", "c2_katakana_all"]:
		var ids: Array[String] = _bank.get_pool(pool_id)
		assert_gt(ids.size(), 0, "%s should not be empty" % pool_id)
		for item_id in ids:
			assert_false(_bank.get_item(item_id).is_empty(), "%s: unknown %s" % [pool_id, item_id])


func test_items_for_filters_by_chapter_and_row() -> void:
	_bank.load_all()
	var rows: Array[String] = ["a", "k"]
	var items: Array[Dictionary] = _bank.items_for(1, rows)
	assert_eq(items.size(), 10, "rows a and k of chapter 1 have 10 hiragana")
	for item in items:
		assert_eq(item.get("script"), "hira")
	assert_eq(_bank.items_for(2, rows).size(), 10, "chapter 2 has the same rows in katakana")


func test_get_encounter_has_its_id_and_an_int_chapter() -> void:
	_bank.load_all()
	var encounter: Dictionary = _bank.get_encounter("c1_boss_tengu")
	assert_eq(encounter.get("id"), "c1_boss_tengu")
	assert_eq(encounter.get("pool_id"), "c1_boss_tengu")
	assert_true(encounter.get("is_boss"), "the tengu is a boss")
	assert_typeof(encounter.get("chapter"), TYPE_INT, "chapter is cast to int")


func test_get_dialogue_returns_the_lines() -> void:
	_bank.load_all()
	var lines: Array[Dictionary] = _bank.get_dialogue("c1_intro_kenji")
	assert_eq(lines.size(), 6)
	assert_eq(lines[0].get("speaker"), "kenji")
	assert_true((lines[0].get("text") as Dictionary).has("ro"), "text has ro")
	assert_eq(lines[5].get("set_flag"), "c1_intro_done")


func test_getters_return_copies() -> void:
	_bank.load_all()
	var item: Dictionary = _bank.get_item("h_a")
	item["kana"] = "x"
	var ids: Array[String] = _bank.get_pool("c1_row_a")
	ids.clear()
	assert_eq(_bank.get_item("h_a").get("kana"), "あ", "the bank keeps its own item")
	assert_eq(_bank.get_pool("c1_row_a").size(), 5, "the bank keeps its own pool")


func test_broken_json_reports_the_file_and_the_line() -> void:
	_write_temp("{\n  \"schema_version\": 1,\n  \"items\": [\n}\n")
	assert_null(_bank._read_json(TEMP_FILE, "items"), "a broken file gives null")
	assert_push_error("test_question_bank.json, line")


func test_other_schema_version_is_rejected() -> void:
	_write_temp("{ \"schema_version\": 2, \"items\": [] }")
	assert_null(_bank._read_json(TEMP_FILE, "items"), "version 2 is not supported yet")
	assert_push_error("schema_version is 2")


func _write_temp(text: String) -> void:
	var file: FileAccess = FileAccess.open(TEMP_FILE, FileAccess.WRITE)
	file.store_string(text)
	file.close()
