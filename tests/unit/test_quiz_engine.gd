extends GutTest
## Tests for quiz/quiz_engine.gd. A small fake bank replaces QuestionBank, so these tests
## do not depend on data/. It has rows a and k, and さ (row s), which the player has not met
## in these pools: さ must never be a choice.

const SEED: int = 42
const ROW_A: Array[String] = ["a", "i", "u", "e", "o"]
const ROWS_A_K: Array[String] = ["a", "i", "u", "e", "o", "ka", "ki", "ku", "ke", "ko"]


class FakeBank:
	extends RefCounted
	var _items: Dictionary = {}
	var _pools: Dictionary = {}

	func _init() -> void:
		_add("h_a", "あ", "a", "a", ["h_o"])
		_add("h_i", "い", "i", "a", [])
		_add("h_u", "う", "u", "a", [])
		_add("h_e", "え", "e", "a", [])
		_add("h_o", "お", "o", "a", ["h_a"])
		_add("h_ka", "か", "ka", "k", [])
		_add("h_ki", "き", "ki", "k", ["h_sa"])
		_add("h_ku", "く", "ku", "k", [])
		_add("h_ke", "け", "ke", "k", [])
		_add("h_ko", "こ", "ko", "k", [])
		_add("h_sa", "さ", "sa", "s", ["h_ki"])
		_pools["c1_row_a"] = ["h_a", "h_i", "h_u", "h_e", "h_o"]
		_pools["c1_row_k"] = ["h_ka", "h_ki", "h_ku", "h_ke", "h_ko"]
		_pools["only_a"] = ["h_a"]

	func get_item(item_id: String) -> Dictionary:
		var item: Dictionary = _items.get(item_id, {})
		return item.duplicate(true)

	func get_pool(pool_id: String) -> Array[String]:
		var ids: Array[String] = []
		ids.assign(_pools.get(pool_id, []))
		return ids

	func items_for(chapter: int, rows: Array[String]) -> Array[Dictionary]:
		var result: Array[Dictionary] = []
		for item in _items.values():
			if item["chapter"] == chapter and rows.has(item["row"]):
				result.append(item.duplicate(true))
		return result

	func _add(id: String, kana: String, romaji: String, row: String, confusable: Array) -> void:
		_items[id] = {
			"id": id, "kana": kana, "romaji": romaji, "row": row, "chapter": 1,
			"confusable_ids": confusable, "mnemonic": {"ro": "ro_" + id, "en": "en_" + id},
		}


var _bank: FakeBank = null


func before_each() -> void:
	_bank = FakeBank.new()


func test_question_has_the_contract_keys() -> void:
	var question: Dictionary = _engine("c1_row_a").next_question()
	for key in ["qid", "item_id", "mode", "prompt_text", "prompt_audio", "choices"]:
		assert_has(question, key, "missing key %s" % key)
	assert_eq(question["mode"], "choice")
	assert_eq(question["prompt_audio"], "")
	assert_eq(question["prompt_text"], _bank.get_item(question["item_id"])["kana"])
	assert_eq((question["choices"] as Array).size(), 4)


func test_expected_answer_appears_once_and_choices_are_different() -> void:
	var engine: QuizEngine = _engine("c1_row_k")
	for i in 20:
		var question: Dictionary = engine.next_question()
		var choices: Array = question["choices"]
		assert_eq(choices.count(_expected(question)), 1, "the expected reading exactly once")
		for choice in choices:
			assert_eq(choices.count(choice), 1, "duplicate choice %s" % choice)


func test_row_a_pool_uses_only_row_a() -> void:
	var engine: QuizEngine = _engine("c1_row_a")
	for i in 15:
		for choice in engine.next_question()["choices"]:
			assert_has(ROW_A, choice, "a reading from a row that was not met")


func test_row_k_pool_uses_rows_a_and_k_but_never_sa() -> void:
	var engine: QuizEngine = _engine("c1_row_k")
	for i in 25:
		for choice in engine.next_question()["choices"]:
			assert_has(ROWS_A_K, choice, "a reading from a row that was not met")


func test_confusable_kana_is_always_a_choice() -> void:
	var engine: QuizEngine = _engine("only_a")
	for i in 10:
		assert_has(engine.next_question()["choices"], "o", "お is confusable with あ")


func test_same_seed_gives_the_same_questions() -> void:
	var first: QuizEngine = _engine("c1_row_k", 7)
	var second: QuizEngine = _engine("c1_row_k", 7)
	for i in 12:
		var a: Dictionary = first.next_question()
		var b: Dictionary = second.next_question()
		assert_eq(a["item_id"], b["item_id"])
		assert_eq(a["choices"], b["choices"])


func test_pool_is_reshuffled_when_it_runs_out() -> void:
	var engine: QuizEngine = _engine("c1_row_a")
	var counts: Dictionary = {}
	for i in 15:
		var question: Dictionary = engine.next_question()
		assert_false(question.is_empty(), "question %d is empty" % i)
		counts[question["item_id"]] = counts.get(question["item_id"], 0) + 1
	for item_id in ["h_a", "h_i", "h_u", "h_e", "h_o"]:
		assert_eq(counts.get(item_id, 0), 3, "%s should come once per round" % item_id)


func test_no_item_twice_in_a_row() -> void:
	for rng_seed in range(1, 21):
		var engine: QuizEngine = _engine("c1_row_a", rng_seed)
		var previous: String = ""
		for i in 15:
			var item_id: String = engine.next_question()["item_id"]
			assert_ne(item_id, previous, "seed %d: the same item twice in a row" % rng_seed)
			previous = item_id


func test_qids_are_unique() -> void:
	var engine: QuizEngine = _engine("c1_row_a")
	var seen: Dictionary = {}
	for i in 12:
		var qid: String = engine.next_question()["qid"]
		assert_false(seen.has(qid), "duplicate qid %s" % qid)
		seen[qid] = true


func test_correct_answer() -> void:
	var engine: QuizEngine = _engine("c1_row_a")
	var question: Dictionary = engine.next_question()
	var result: Dictionary = engine.submit(question["qid"], _expected(question), 1200)
	assert_true(result["correct"], "the expected reading is correct")
	assert_eq(result["expected"], _expected(question))
	var item_id: String = question["item_id"]
	assert_eq(result["explain"], {"ro": "ro_" + item_id, "en": "en_" + item_id})


func test_wrong_answer_still_gives_the_expected_one() -> void:
	var engine: QuizEngine = _engine("c1_row_a")
	var question: Dictionary = engine.next_question()
	var result: Dictionary = engine.submit(question["qid"], "zzz", 900)
	assert_false(result["correct"], "zzz is wrong")
	assert_eq(result["expected"], _expected(question))


func test_answered_is_emitted_once_with_its_parameters() -> void:
	var engine: QuizEngine = _engine("c1_row_a")
	watch_signals(engine)
	var question: Dictionary = engine.next_question()
	engine.submit(question["qid"], _expected(question), 1500)
	assert_signal_emit_count(engine, "answered", 1)
	var parameters: Array = [question["qid"], question["item_id"], true, 1500]
	assert_signal_emitted_with_parameters(engine, "answered", parameters)


func test_the_same_qid_cannot_be_answered_twice() -> void:
	var engine: QuizEngine = _engine("c1_row_a")
	watch_signals(engine)
	var question: Dictionary = engine.next_question()
	engine.submit(question["qid"], _expected(question), 100)
	assert_true(engine.submit(question["qid"], "a", 100).is_empty(), "second submit gives {}")
	assert_push_error("already answered")
	assert_signal_emit_count(engine, "answered", 1)


func test_unknown_qid_is_rejected() -> void:
	var engine: QuizEngine = _engine("c1_row_a")
	assert_true(engine.submit("q_9999", "a", 100).is_empty(), "unknown qid gives {}")
	assert_push_error("q_9999")


func test_unknown_pool_reports_errors() -> void:
	var engine: QuizEngine = QuizEngine.new(_bank)
	engine.start("no_such_pool", SEED)
	assert_push_error("no_such_pool")
	assert_true(engine.next_question().is_empty(), "no question without a pool")
	assert_push_error("start()")


func test_boxes_move_up_and_back_to_one() -> void:
	var engine: QuizEngine = _engine("only_a")
	_answer(engine, true)
	_answer(engine, true)
	_answer(engine, true)
	assert_eq(engine.get_state()["h_a"], {"box": 3, "seen": 3, "wrong": 0}, "box 3 is the top")
	_answer(engine, false)
	assert_eq(engine.get_state()["h_a"], {"box": 1, "seen": 4, "wrong": 1}, "wrong: back to 1")


func test_set_state_cleans_a_state_loaded_from_json() -> void:
	var engine: QuizEngine = QuizEngine.new(_bank)
	var saved: Dictionary = {"h_a": {"box": 2.0, "seen": 5.0, "wrong": 1.0}, "h_i": {"box": 9}}
	saved["h_u"] = "broken"
	engine.set_state(saved)
	var state: Dictionary = engine.get_state()
	assert_eq(state["h_a"], {"box": 2, "seen": 5, "wrong": 1})
	assert_typeof(state["h_a"]["box"], TYPE_INT, "floats from JSON become int")
	assert_eq(state["h_i"]["box"], 3, "box stays between 1 and 3")
	assert_false(state.has("h_u"), "an entry that is not a dictionary is skipped")


func test_get_state_returns_a_copy() -> void:
	var engine: QuizEngine = _engine("only_a")
	_answer(engine, true)
	var state: Dictionary = engine.get_state()
	state["h_a"]["box"] = 99
	assert_eq(engine.get_state()["h_a"]["box"], 2, "the engine keeps its own state")


func _engine(pool_id: String, rng_seed: int = SEED) -> QuizEngine:
	var engine: QuizEngine = QuizEngine.new(_bank)
	engine.start(pool_id, rng_seed)
	return engine


func _expected(question: Dictionary) -> String:
	return _bank.get_item(question["item_id"])["romaji"]


func _answer(engine: QuizEngine, correct: bool) -> void:
	var question: Dictionary = engine.next_question()
	engine.submit(question["qid"], _expected(question) if correct else "zzz", 1000)
