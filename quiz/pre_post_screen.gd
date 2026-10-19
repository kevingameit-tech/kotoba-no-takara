extends Control
## PrePostScreen: the pre-test before chapter 1 and the post-test after the Tengu (issue #46).
## The logic is PrePostTest (pre_post_test.gd). This screen shows an intro, the 10 questions
## without any feedback, and a thank-you, then emits finished.
## Contract: section 6 (texts are ui.csv keys; a Control translates its own text), section 12
## (GameState.pretest) and section 13 (events pretest and posttest).
##
## GameState and Telemetry do not exist yet. When they do, the screen writes GameState.pretest
## and calls Telemetry.log_event(); until then it only emits finished.
## Run it alone: open quiz/pre_post_screen.tscn and press F6 (kind = "pre").

signal finished(test_result: Dictionary)

const TITLE_KEYS: Dictionary = {"pre": "UI_PRETEST_TITLE", "post": "UI_POSTTEST_TITLE"}
const INTRO_KEYS: Dictionary = {"pre": "UI_PRETEST_INTRO", "post": "UI_POSTTEST_INTRO"}
const START_KEY: String = "UI_TEST_START"
const DONE_KEY: String = "UI_TEST_DONE"
const OK_KEY: String = "UI_OK"
const TOP_MARGIN: float = 34.0

## "pre" before chapter 1, "post" after the Tengu. Set it before add_child().
@export_enum("pre", "post") var kind: String = "pre"
## -1 means random; tests set a number to get the same form and order every time.
@export var rng_seed: int = -1
## Data source; null means the QuestionBank autoload. Set it before add_child().
var bank: Object = null
## The post-test needs GameState.pretest. Left empty, the screen reads it from GameState.
var pretest: Dictionary = {}

var _test: PrePostTest
var _question: Dictionary = {}
var _asked_at_ms: int = 0
var _asked: int = 0
var _result: Dictionary = {}

var _intro_box: VBoxContainer
var _question_box: VBoxContainer
var _done_box: VBoxContainer
var _progress: Label
var _kana: Label
var _choices: HBoxContainer


func _ready() -> void:
	_build_ui()
	if kind == PrePostTest.KIND_POST and pretest.is_empty():
		pretest = _read_pretest()
	var form: String = PrePostTest.pick_pre_form(rng_seed)
	if kind == PrePostTest.KIND_POST:
		form = PrePostTest.post_form_for(pretest, rng_seed)
	_test = PrePostTest.new(kind, form, bank, rng_seed)
	_show(_intro_box)
	(_intro_box.find_child("Start", false, false) as Button).grab_focus()


## The form of this test, "A" or "B".
func form() -> String:
	return _test.form


func _start() -> void:
	_show(_question_box)
	_show_question()


func _show_question() -> void:
	_question = _test.next_question()
	if _question.is_empty():
		return
	_asked += 1
	_progress.text = "%d / %d" % [_asked, PrePostTest.N_ITEMS]
	_kana.text = _question["prompt_text"]
	var choices: Array = _question["choices"]
	for i in _choices.get_child_count():
		(_choices.get_child(i) as Button).text = choices[i]
	(_choices.get_child(0) as Button).grab_focus()
	_asked_at_ms = Time.get_ticks_msec()


## No colours and no correct answer: the test only records what the player knows.
func _on_choice(choice: String) -> void:
	if _question.is_empty():
		return
	var qid: String = _question["qid"]
	_question = {}
	_test.submit(qid, choice, Time.get_ticks_msec() - _asked_at_ms)
	if _test.is_finished():
		_finish()
	else:
		_show_question()


func _finish() -> void:
	_result = _test.result()
	if kind == PrePostTest.KIND_PRE:
		_write_pretest(_result)
	_log_event(_test.event_name(), _test.telemetry_data(pretest))
	_show(_done_box)
	(_done_box.find_child("Ok", false, false) as Button).grab_focus()


func _read_pretest() -> Dictionary:
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state != null and "pretest" in game_state:
		return game_state.pretest
	return {}


func _write_pretest(value: Dictionary) -> void:
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state != null and "pretest" in game_state:
		game_state.pretest = value.duplicate()


func _log_event(event_name: String, data: Dictionary) -> void:
	var telemetry: Node = get_node_or_null("/root/Telemetry")
	if telemetry != null and telemetry.has_method("log_event"):
		telemetry.log_event(event_name, data)


func _show(box: VBoxContainer) -> void:
	for node in [_intro_box, _question_box, _done_box]:
		node.visible = node == box


func _build_ui() -> void:
	add_child(QuizStyle.background())

	_intro_box = _column("Intro", true)
	var title: Label = QuizStyle.label("Title", TITLE_KEYS[kind], 24)
	var intro: Label = _paragraph("IntroText", INTRO_KEYS[kind])
	var start: Button = _centered_button("Start", START_KEY)
	start.pressed.connect(_start)
	for node in [title, intro, start]:
		_intro_box.add_child(node)

	_question_box = _column("Questions", false)
	_progress = QuizStyle.label("Progress", "", 14, QuizStyle.MUTED)
	_kana = QuizStyle.label("Kana", "", 88)
	_choices = HBoxContainer.new()
	_choices.name = "Choices"
	_choices.alignment = BoxContainer.ALIGNMENT_CENTER
	_choices.add_theme_constant_override("separation", 10)
	# The same 4 buttons for every question: only their text changes.
	for i in QuizEngine.CHOICE_COUNT:
		var button: Button = QuizStyle.button("")
		button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		button.pressed.connect(func() -> void: _on_choice(button.text))
		_choices.add_child(button)
	for node in [_progress, _kana]:
		node.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	for node in [_progress, _kana, _choices]:
		_question_box.add_child(node)

	_done_box = _column("Done", true)
	var done: Label = _paragraph("DoneText", DONE_KEY)
	var ok: Button = _centered_button("Ok", OK_KEY)
	ok.pressed.connect(func() -> void: finished.emit(_result))
	for node in [done, ok]:
		_done_box.add_child(node)


## Intro and thank-you sit in the middle; the questions start from the top, so the buttons
## do not move between questions.
func _column(node_name: String, centered: bool) -> VBoxContainer:
	var column: VBoxContainer = VBoxContainer.new()
	column.name = node_name
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if centered:
		column.alignment = BoxContainer.ALIGNMENT_CENTER
	else:
		column.offset_top = TOP_MARGIN
	column.add_theme_constant_override("separation", 14)
	add_child(column)
	return column


func _paragraph(node_name: String, key: String) -> Label:
	var label: Label = QuizStyle.label(node_name, key, 16)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(520, 0)
	label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return label


func _centered_button(node_name: String, key: String) -> Button:
	var button: Button = QuizStyle.button(key)
	button.name = node_name
	button.custom_minimum_size = Vector2(160, 40)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return button
