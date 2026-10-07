extends GutTest
## Tests for quiz/pre_post_test.gd. A small fake bank holds the two test forms, so these
## tests do not depend on data/. Form A and form B have one kana from each row and no kana
## in common, like c1_test_a and c1_test_b in data/pools.json.

const SEED: int = 42
const FORM_A: Array[String] = ["h_a", "h_ki", "h_shi", "h_tsu", "h_nu", "h_hi", "h_me", "h_yu", "h_ru", "h_wa"]
const FORM_B: Array[String] = ["h_o", "h_ko", "h_sa", "h_chi", "h_ne", "h_ho", "h_mu", "h_yo", "h_re", "h_n"]


class FakeBank:
	extends RefCounted
	var _items: Dictionary = {}
	var _pools: Dictionary = {}

	func _init() -> void:
		var table: Array = [
			["h_a", "あ", "a", "a"], ["h_o", "お", "o", "a"], ["h_ki", "き", "ki", "k"],
			["h_ko", "こ", "ko", "k"], ["h_shi", "し", "shi", "s"], ["h_sa", "さ", "sa", "s"],
			["h_tsu", "つ", "tsu", "t"], ["h_chi", "ち", "chi", "t"], ["h_nu", "ぬ", "nu", "n"],
			["h_ne", "ね", "ne", "n"], ["h_hi", "ひ", "hi", "h"], ["h_ho", "ほ", "ho", "h"],
			["h_me", "め", "me", "m"], ["h_mu", "む", "mu", "m"], ["h_yu", "ゆ", "yu", "y"],
			["h_yo", "よ", "yo", "y"], ["h_ru", "る", "ru", "r"], ["h_re", "れ", "re", "r"],
			["h_wa", "わ", "wa", "w"], ["h_n", "ん", "n", "n_final"],
		]
		for row in table:
			_items[row[0]] = {
				"id": row[0], "kana": row[1], "romaji": row[2], "row": row[3], "chapter": 1,
				"confusable_ids": [], "mnemonic": {"ro": "ro_" + row[0], "en": "en_" + row[0]},
			}
		_pools["c1_test_a"] = FORM_A
		_pools["c1_test_b"] = FORM_B

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


var _bank: FakeBank = null


func before_each() -> void:
	_bank = FakeBank.new()


func test_pre_form_is_a_or_b_and_a_seed_repeats_it() -> void:
	var seen: Dictionary = {}
	for rng_seed in range(20):
		var form: String = PrePostTest.pick_pre_form(rng_seed)
		assert_has(["A", "B"], form)
		assert_eq(PrePostTest.pick_pre_form(rng_seed), form, "seed %d gives the same form" % rng_seed)
		seen[form] = true
	assert_eq(seen.size(), 2, "both forms come up")


func test_post_form_is_the_other_one() -> void:
	assert_eq(PrePostTest.post_form_for({"form": "A", "score": 4}), "B")
	assert_eq(PrePostTest.post_form_for({"form": "B", "score": 7}), "A")
	assert_has(["A", "B"], PrePostTest.post_form_for({}, SEED), "no pre-test: a random form")


func test_asks_every_kana_of_the_form_exactly_once() -> void:
	var test: PrePostTest = PrePostTest.new("pre", "A", _bank, SEED)
	var asked: Array[String] = []
	for i in PrePostTest.N_ITEMS:
		var question: Dictionary = test.next_question()
		asked.append(question["item_id"])
		test.submit(question["qid"], _expected(question), 1000)
	asked.sort()
	var form_a: Array[String] = FORM_A.duplicate()
	form_a.sort()
	assert_eq(asked, form_a, "the 10 kana of form A, each once")
	assert_true(test.is_finished())
	assert_true(test.next_question().is_empty(), "no 11th question")


func test_score_counts_only_the_right_answers() -> void:
	var test: PrePostTest = _answered_test("pre", "A", 6)
	assert_eq(test.score(), 6)
	assert_eq(test.result(), {"form": "A", "score": 6}, "what goes into GameState.pretest")


func test_a_wrong_answer_is_recorded_without_telling_the_player() -> void:
	var test: PrePostTest = PrePostTest.new("pre", "B", _bank, SEED)
	var question: Dictionary = test.next_question()
	assert_false(question.has("expected"), "the question does not carry the answer")
	assert_true(test.submit(question["qid"], "zzz", 800), "a wrong answer is recorded too")
	assert_eq(test.score(), 0)


func test_pretest_event_data() -> void:
	var test: PrePostTest = _answered_test("pre", "A", 6)
	assert_eq(test.event_name(), "pretest")
	assert_eq(test.telemetry_data(), {"form": "A", "score": 6, "n_items": 10})


func test_posttest_event_repeats_the_pretest_score() -> void:
	var test: PrePostTest = _answered_test("post", "B", 10)
	assert_eq(test.event_name(), "posttest")
	var data: Dictionary = test.telemetry_data({"form": "A", "score": 4.0})
	assert_eq(data, {"form": "B", "score": 10, "n_items": 10, "pre_form": "A", "pre_score": 4})
	assert_typeof(data["pre_score"], TYPE_INT, "a float from the save file becomes int")


func test_posttest_without_a_valid_pretest_sends_unknown() -> void:
	var test: PrePostTest = _answered_test("post", "A", 3)
	var unknown: Dictionary = {"pre_form": "", "pre_score": -1}
	for pretest in [{}, {"form": "C", "score": 3}, {"form": "B", "score": 99}, {"form": "B", "score": "6"}, {"form": "B"}]:
		var data: Dictionary = test.telemetry_data(pretest)
		assert_eq({"pre_form": data["pre_form"], "pre_score": data["pre_score"]}, unknown, str(pretest))


func test_one_question_at_a_time() -> void:
	var test: PrePostTest = PrePostTest.new("pre", "A", _bank, SEED)
	var question: Dictionary = test.next_question()
	assert_true(test.next_question().is_empty(), "the open question must be answered first")
	assert_push_error("before asking the next one")
	assert_true(test.submit(question["qid"], _expected(question), 500))
	assert_false(test.next_question().is_empty(), "after the answer the next question comes")


func test_unknown_or_repeated_qid_is_not_counted() -> void:
	var test: PrePostTest = PrePostTest.new("pre", "A", _bank, SEED)
	var question: Dictionary = test.next_question()
	assert_false(test.submit("q_9999", "a", 100), "unknown qid")
	assert_push_error("q_9999")
	assert_true(test.submit(question["qid"], _expected(question), 100))
	assert_false(test.submit(question["qid"], _expected(question), 100), "the same qid twice")
	assert_push_error("is not the open question")
	assert_eq(test.score(), 1)


func test_wrong_kind_or_form_reports_an_error() -> void:
	var wrong_kind: PrePostTest = PrePostTest.new("middle", "A", _bank, SEED)
	assert_push_error("kind")
	assert_true(wrong_kind.next_question().is_empty())
	var wrong_form: PrePostTest = PrePostTest.new("pre", "C", _bank, SEED)
	assert_push_error("form")
	assert_true(wrong_form.next_question().is_empty())


func _expected(question: Dictionary) -> String:
	return _bank.get_item(question["item_id"])["romaji"]


## A finished test where the first [param right] answers are correct and the rest wrong.
func _answered_test(kind: String, form: String, right: int) -> PrePostTest:
	var test: PrePostTest = PrePostTest.new(kind, form, _bank, SEED)
	for i in PrePostTest.N_ITEMS:
		var question: Dictionary = test.next_question()
		test.submit(question["qid"], _expected(question) if i < right else "zzz", 1000)
	return test
