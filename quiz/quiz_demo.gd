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
const COLOR_BACKGROUND: Color = Color("14213d")
const COLOR_BUTTON: Color = Color("25324d")
const COLOR_RIGHT: Color = Color("2e8f5a")
const COLOR_WRONG: Color = Color("c2541f")
const COLOR_TEXT: Color = Color("f4efe6")
const COLOR_MUTED: Color = Color("a9b3c4")
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
	for child in _choices.get_children():
		_choices.remove_child(child)
		child.queue_free()
	for choice in _question["choices"]:
		var button: Button = _make_button(choice)
		button.pressed.connect(_on_choice.bind(choice))
		_choices.add_child(button)
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
			_paint(button, COLOR_RIGHT)
		elif button.text == choice:
			_paint(button, COLOR_WRONG)
	_feedback.text = ("✓  " if correct else "✗  ") + expected
	_feedback.add_theme_color_override("font_color", COLOR_RIGHT.lightened(0.3) if correct else COLOR_WRONG.lightened(0.3))
	_explain.text = result.get("explain", {}).get(LANG, "")
	_score_label.text = "%d / %d" % [_score, _total]
	_next.visible = true
	_next.grab_focus()


func _build_ui() -> void:
	var background: ColorRect = ColorRect.new()
	background.color = COLOR_BACKGROUND
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var column: VBoxContainer = VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Top-aligned, so the buttons stay in place when the answer appears below them.
	column.offset_top = TOP_MARGIN
	column.add_theme_constant_override("separation", 8)
	add_child(column)

	_score_label = _make_label("Score", "0 / 0", 14, COLOR_MUTED)
	_kana = _make_label("Kana", "", 88, COLOR_TEXT)
	_choices = HBoxContainer.new()
	_choices.name = "Choices"
	_choices.alignment = BoxContainer.ALIGNMENT_CENTER
	_choices.add_theme_constant_override("separation", 10)
	_feedback = _make_label("Feedback", "", 20, COLOR_TEXT)
	_explain = _make_label("Explain", "", 14, COLOR_TEXT)
	_explain.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_explain.custom_minimum_size = Vector2(560, 0)
	_explain.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_next = _make_button("→")
	_next.name = "Next"
	_next.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_next.pressed.connect(_show_next)

	for node in [_score_label, _kana, _choices, _feedback, _explain, _next]:
		column.add_child(node)


func _make_label(node_name: String, text: String, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.name = node_name
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _make_button(text: String) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(110, 40)
	button.add_theme_font_size_override("font_size", 20)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(state, _box(COLOR_BUTTON))
	button.add_theme_stylebox_override("hover", _box(COLOR_BUTTON.lightened(0.15)))
	button.add_theme_stylebox_override("focus", _box(COLOR_BUTTON.lightened(0.15), COLOR_TEXT))
	button.add_theme_color_override("font_color", COLOR_TEXT)
	button.add_theme_color_override("font_disabled_color", COLOR_TEXT)
	return button


func _paint(button: Button, color: Color) -> void:
	button.add_theme_stylebox_override("disabled", _box(color))


func _box(color: Color, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(6)
	if border.a > 0.0:
		box.border_color = border
		box.set_border_width_all(2)
	return box
