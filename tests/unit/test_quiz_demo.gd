extends GutTest
## Tests for quiz/quiz_demo.gd. The demo gets its own QuestionBank, loaded from data/,
## so the tests do not depend on the autoload.

const SEED: int = 7

var bank: Node
var demo: Control


func before_each() -> void:
	bank = autofree(load("res://autoload/question_bank.gd").new())
	assert_eq(bank.load_all(), OK)
	demo = load("res://quiz/quiz_demo.tscn").instantiate()
	demo.bank = bank
	demo.rng_seed = SEED
	add_child_autofree(demo)


func _expected() -> String:
	return bank.get_item(demo._question["item_id"]).get("romaji", "")


func _button(text: String) -> Button:
	for child in demo.find_child("Choices", true, false).get_children():
		if child.text == text:
			return child
	return null


func _wrong_choice() -> String:
	for choice in demo._question["choices"]:
		if choice != _expected():
			return choice
	return ""


func test_first_question_shows_a_kana_and_four_choices() -> void:
	assert_ne(demo.find_child("Kana", true, false).text, "")
	assert_eq(demo.find_child("Choices", true, false).get_child_count(), 4)
	assert_false(demo.find_child("Next", true, false).visible)


func test_right_answer_shows_a_check_the_mnemonic_and_the_score() -> void:
	_button(_expected()).pressed.emit()
	assert_string_starts_with(demo.find_child("Feedback", true, false).text, "✓")
	assert_ne(demo.find_child("Explain", true, false).text, "", "the mnemonic from data/ is shown")
	assert_eq(demo.find_child("Score", true, false).text, "1 / 1")
	assert_true(demo.find_child("Next", true, false).visible)


func test_wrong_answer_shows_the_expected_reading() -> void:
	var expected: String = _expected()
	_button(_wrong_choice()).pressed.emit()
	var feedback: String = demo.find_child("Feedback", true, false).text
	assert_string_starts_with(feedback, "✗")
	assert_string_contains(feedback, expected)
	assert_eq(demo.find_child("Score", true, false).text, "0 / 1")


func test_a_second_press_on_the_same_question_counts_once() -> void:
	_button(_expected()).pressed.emit()
	demo._on_choice(_expected())
	assert_eq(demo.find_child("Score", true, false).text, "1 / 1")


func test_next_shows_a_new_question_with_fresh_buttons() -> void:
	var first_qid: String = demo._question["qid"]
	_button(_expected()).pressed.emit()
	demo.find_child("Next", true, false).pressed.emit()
	assert_ne(demo._question["qid"], first_qid)
	for child in demo.find_child("Choices", true, false).get_children():
		if not child.is_queued_for_deletion():
			assert_false(child.disabled)
