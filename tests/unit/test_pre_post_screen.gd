extends GutTest
## Tests for quiz/pre_post_screen.gd. The screen gets its own QuestionBank, loaded from data/.
## Telemetry and GameState are not written yet, so these tests put small fakes under /root
## with the same names, and remove them afterwards.

const SEED: int = 11


class FakeTelemetry:
	extends Node
	var events: Array = []

	func log_event(event: String, data: Dictionary = {}) -> void:
		events.append({"event": event, "data": data})


class FakeGameState:
	extends Node
	var pretest: Dictionary = {}


var bank: Node
var telemetry: FakeTelemetry
var game_state: FakeGameState


func before_each() -> void:
	bank = autofree(load("res://autoload/question_bank.gd").new())
	assert_eq(bank.load_all(), OK)
	telemetry = _add_fake(FakeTelemetry.new(), "Telemetry")
	game_state = _add_fake(FakeGameState.new(), "GameState")


func after_each() -> void:
	for fake in [telemetry, game_state]:
		if is_instance_valid(fake):
			fake.get_parent().remove_child(fake)
			fake.free()


func _add_fake(node: Node, node_name: String) -> Node:
	if get_tree().root.has_node(node_name):
		node.free()
		return null
	node.name = node_name
	get_tree().root.add_child(node)
	return node


func _screen(kind: String, pretest: Dictionary = {}) -> Control:
	var screen: Control = load("res://quiz/pre_post_screen.tscn").instantiate()
	screen.kind = kind
	screen.rng_seed = SEED
	screen.bank = bank
	screen.pretest = pretest
	add_child_autofree(screen)
	return screen


func _node(screen: Control, node_name: String) -> Node:
	return screen.find_child(node_name, true, false)


func _expected(screen: Control) -> String:
	return bank.get_item(screen._question["item_id"]).get("romaji", "")


func _answer_all(screen: Control, right: int) -> void:
	_node(screen, "Start").pressed.emit()
	for i in PrePostTest.N_ITEMS:
		var expected: String = _expected(screen)
		var pick: String = expected
		if i >= right:
			for choice in screen._question["choices"]:
				if choice != expected:
					pick = choice
					break
		screen._on_choice(pick)


func test_starts_on_the_intro_with_text_keys() -> void:
	var screen: Control = _screen("pre")
	assert_true(_node(screen, "Intro").visible)
	assert_false(_node(screen, "Questions").visible)
	assert_eq(_node(screen, "Title").text, "UI_PRETEST_TITLE")
	assert_eq(_node(screen, "IntroText").text, "UI_PRETEST_INTRO")
	assert_eq(_node(screen, "Start").text, "UI_TEST_START")


func test_start_shows_the_first_of_ten_questions() -> void:
	var screen: Control = _screen("pre")
	_node(screen, "Start").pressed.emit()
	assert_true(_node(screen, "Questions").visible)
	assert_eq(_node(screen, "Progress").text, "1 / 10")
	assert_eq(_node(screen, "Choices").get_child_count(), 4)


func test_an_answer_shows_no_feedback_and_moves_on() -> void:
	var screen: Control = _screen("pre")
	_node(screen, "Start").pressed.emit()
	screen._on_choice(_expected(screen))
	assert_eq(_node(screen, "Progress").text, "2 / 10")
	for child in _node(screen, "Choices").get_children():
		assert_false(child.disabled, "no button is coloured or locked")


func test_a_second_press_on_the_same_question_counts_once() -> void:
	var screen: Control = _screen("pre")
	_node(screen, "Start").pressed.emit()
	var choice: String = _expected(screen)
	screen._on_choice(choice)
	screen._on_choice(choice)
	assert_eq(_node(screen, "Progress").text, "3 / 10", "the second press answers question 2, once")


func test_pretest_end_writes_game_state_logs_and_emits() -> void:
	var screen: Control = _screen("pre")
	watch_signals(screen)
	_answer_all(screen, 7)
	assert_true(_node(screen, "Done").visible)
	assert_eq(_node(screen, "DoneText").text, "UI_TEST_DONE")
	assert_eq(game_state.pretest, {"form": screen.form(), "score": 7})
	assert_eq(telemetry.events.size(), 1)
	assert_eq(telemetry.events[0]["event"], "pretest")
	assert_eq(telemetry.events[0]["data"], {"form": screen.form(), "score": 7, "n_items": 10})
	_node(screen, "Ok").pressed.emit()
	assert_signal_emitted_with_parameters(screen, "finished", [{"form": screen.form(), "score": 7}])


func test_posttest_uses_the_other_form_and_repeats_the_pretest() -> void:
	game_state.pretest = {"form": "A", "score": 4.0}  # a JSON save gives floats
	var screen: Control = _screen("post")
	assert_eq(screen.form(), "B")
	assert_eq(_node(screen, "Title").text, "UI_POSTTEST_TITLE")
	_answer_all(screen, 9)
	assert_eq(telemetry.events[0]["event"], "posttest")
	assert_eq(telemetry.events[0]["data"], {"form": "B", "score": 9, "n_items": 10, "pre_form": "A", "pre_score": 4})
	assert_eq(game_state.pretest, {"form": "A", "score": 4.0}, "the post-test never overwrites the pre-test")


func test_posttest_without_a_pretest_still_runs() -> void:
	var screen: Control = _screen("post")
	_answer_all(screen, 0)
	var data: Dictionary = telemetry.events[0]["data"]
	assert_eq(data["pre_form"], "")
	assert_eq(data["pre_score"], -1)
	assert_eq(data["score"], 0)


func test_every_text_key_is_in_ui_csv_with_ro_and_en() -> void:
	var file: FileAccess = FileAccess.open("res://i18n/ui.csv", FileAccess.READ)
	var rows: Dictionary = {}
	while not file.eof_reached():
		var line: PackedStringArray = file.get_csv_line()
		if line.size() >= 3:
			rows[line[0]] = line
	var screen_script: GDScript = load("res://quiz/pre_post_screen.gd")
	var keys: Array = screen_script.TITLE_KEYS.values() + screen_script.INTRO_KEYS.values()
	keys += [screen_script.START_KEY, screen_script.DONE_KEY, screen_script.OK_KEY]
	for key in keys:
		assert_true(rows.has(key), "%s is in ui.csv" % key)
		if rows.has(key):
			assert_ne(rows[key][1].strip_edges(), "", "%s has EN" % key)
			assert_ne(rows[key][2].strip_edges(), "", "%s has RO" % key)
