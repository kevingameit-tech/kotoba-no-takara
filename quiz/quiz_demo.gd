extends Control
## QuizDemo: one battle question at a time, on the real data, for the prototype demo
## (lab of 2026-10-19). It shows what QuizEngine does (contract, section 8); the real
## battle screen is Ioana's, in battle/.
## Run it alone: open quiz/quiz_demo.tscn in Godot and press F6.
##
## No UI words are written here (section 6): the player sees the kana, the romaji choices,
## ✓ or ✗ with the expected answer, and the mnemonic from data/.

const POOL_ID: String = "c1_rows_a_k"
const LANG: String = "ro"  # becomes Settings.lang when the Settings autoload exists
const TOP_MARGIN: float = 34.0

## -1 means random; tests set a number to get the same questions every time.
@export var rng_seed: int = -1
## Data source for QuizEngine; null means the QuestionBank autoload. Set it before add_child().
var bank: Object = null

var _engine: QuizEngine
var _question: Dictionary = {}
var _asked_at_ms: int = 0
var _answered: bool = false
var _score: int = 0
var _total: int = 0

var _score_label: Label
var _kana: Label
var _choices: HBoxContainer
var _feedback: Label
var _explain: Label
var _next: Button


func _ready() -> void:
	_build_ui()
	_engine = QuizEngine.new(bank)
	_engine.start(POOL_ID, rng_seed)
	_show_next()


func _show_next() -> void:
	_question = _engine.next_question()
	if _question.is_empty():
		return
	_answered = false
	_kana.text = _question["prompt_text"]
	_feedback.text = ""
	_explain.text = ""
	_next.visible = false
	var choices: Array = _question["choices"]
	for i in _choices.get_child_count():
		var button: Button = _choices.get_child(i)
		button.text = choices[i]
		button.disabled = false
		button.add_theme_stylebox_override("disabled", QuizStyle.box(QuizStyle.BUTTON))
	(_choices.get_child(0) as Button).grab_focus()
	_asked_at_ms = Time.get_ticks_msec()


func _on_choice(choice: String) -> void:
	if _question.is_empty() or _answered:
		return
	_answered = true
	var elapsed_ms: int = Time.get_ticks_msec() - _asked_at_ms
	var result: Dictionary = _engine.submit(_question["qid"], choice, elapsed_ms)
	var expected: String = result.get("expected", "")
	var correct: bool = result.get("correct", false)
	_total += 1
	if correct:
		_score += 1
	for child in _choices.get_children():
		var button: Button = child
		button.disabled = true
		if button.text == expected:
			button.add_theme_stylebox_override("disabled", QuizStyle.box(QuizStyle.RIGHT))
		elif button.text == choice:
			button.add_theme_stylebox_override("disabled", QuizStyle.box(QuizStyle.WRONG))
	_feedback.text = ("✓  " if correct else "✗  ") + expected
	var feedback_color: Color = QuizStyle.RIGHT if correct else QuizStyle.WRONG
	_feedback.add_theme_color_override("font_color", feedback_color.lightened(0.3))
	_explain.text = result.get("explain", {}).get(LANG, "")
	_score_label.text = "%d / %d" % [_score, _total]
	_next.visible = true
	_next.grab_focus()


func _build_ui() -> void:
	add_child(QuizStyle.background())

	var column: VBoxContainer = VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Top-aligned, so the buttons stay in place when the answer appears below them.
	column.offset_top = TOP_MARGIN
	column.add_theme_constant_override("separation", 8)
	add_child(column)

	_score_label = QuizStyle.label("Score", "0 / 0", 14, QuizStyle.MUTED)
	_kana = QuizStyle.label("Kana", "", 88)
	_choices = HBoxContainer.new()
	_choices.name = "Choices"
	_choices.alignment = BoxContainer.ALIGNMENT_CENTER
	_choices.add_theme_constant_override("separation", 10)
	# The same 4 buttons for every question: only their text changes.
	for i in QuizEngine.CHOICE_COUNT:
		var button: Button = QuizStyle.button("")
		button.pressed.connect(func() -> void: _on_choice(button.text))
		_choices.add_child(button)
	_feedback = QuizStyle.label("Feedback", "", 20)
	_explain = QuizStyle.label("Explain", "", 14)
	_explain.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_explain.custom_minimum_size = Vector2(560, 0)
	_explain.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_next = QuizStyle.button("→")
	_next.name = "Next"
	_next.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_next.pressed.connect(_show_next)

	for node in [_score_label, _kana, _choices, _feedback, _explain, _next]:
		column.add_child(node)
