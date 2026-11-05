class_name BattleScene
extends Control

## Scena principală de luptă (BattleScene).
## Gestionează interfața vizuală, butoanele accesibile (min. 48px), integrarea cu
## QuizEngine real (sau test double), datele din encounters.json și semnalul de final.
## Contract: docs/contracts.md, secțiunea 9 și 10.

signal battle_finished(result: Dictionary)

const KANA_FONT: String = "res://fonts/dotgothic16_kana.ttf"
const COLOR_BG: Color = Color("14213d")
const COLOR_BUTTON: Color = Color("25324d")
const COLOR_RIGHT: Color = Color("2e8f5a")
const COLOR_WRONG: Color = Color("c2541f")
const COLOR_TEXT: Color = Color("f4efe6")
const COLOR_MUTED: Color = Color("a9b3c4")

## Seed opțional pentru determinism în teste (-1 = aleatoriu).
@export var rng_seed: int = -1

## Sursa de date pentru întrebări (null = QuestionBank autoload).
var bank: Object = null

## Motorul de quiz (dacă e null, setup() creează o instanță reală de QuizEngine).
var engine: QuizEngine = null

## Combatantul jucătorului și al inamicului.
var player_battler: Battler = null
var enemy_battler: Battler = null

## Datele întâlnirii curente (din encounters.json).
var encounter_data: Dictionary = {}

## Contoare pentru statistici.
var correct_count: int = 0
var wrong_count: int = 0

## Stare internă.
var _is_setup: bool = false
var _current_question: Dictionary = {}
var _asked_at_ms: int = 0
var _answered: bool = false

# Noduri UI create dinamic pentru independență totală și robustețe.
var _enemy_info_label: Label
var _enemy_hp_bar: ProgressBar
var _player_hp_bar: ProgressBar
var _player_info_label: Label
var _kana_label: Label
var _feedback_label: Label
var _explain_label: Label
var _choices_container: HBoxContainer
var _actions_container: HBoxContainer
var _next_button: Button
var _flee_button: Button


func _ready() -> void:
	_build_ui()
	setup_accessible_buttons()
	# Dacă scena este rulată independent (F6) și setup() nu a fost apelat din exterior,
	# pornim o luptă demonstrativă implicită (conform contractului, secțiunea 9).
	if not _is_setup:
		setup({
			"id": "c1_kappa_1",
			"chapter": 1,
			"pool_id": "c1_rows_a_k",
			"is_boss": false,
			"enemy": "res://battle/data/enemies/placeholder.tres"
		})


## Inițializează lupta pe baza dicționarului de întâlnire (din encounters.json).
func setup(encounter: Dictionary) -> void:
	encounter_data = encounter.duplicate(true)
	_is_setup = true
	correct_count = 0
	wrong_count = 0
	_answered = false

	var enc_id: String = str(encounter.get("id", "c1_kappa_1"))
	var pool_id: String = str(encounter.get("pool_id", "c1_rows_a_k"))
	var is_boss: bool = bool(encounter.get("is_boss", false))
	var enemy_path: String = str(encounter.get("enemy", "res://battle/data/enemies/placeholder.tres"))

	# 1. Încărcăm resursa de inamic (EnemyData sau BossData).
	var enemy_resource: Resource = null
	if ResourceLoader.exists(enemy_path):
		enemy_resource = load(enemy_path)
	elif is_boss and ResourceLoader.exists("res://battle/data/enemies/tengu.tres"):
		enemy_resource = load("res://battle/data/enemies/tengu.tres")
	elif ResourceLoader.exists("res://battle/data/enemies/placeholder.tres"):
		enemy_resource = load("res://battle/data/enemies/placeholder.tres")

	# 2. Inițializăm Battler-ul jucătorului și al inamicului.
	player_battler = Battler.new()
	player_battler.max_hp = 100
	player_battler.current_hp = 100
	player_battler.attack_power = 25
	player_battler.defense = 5

	enemy_battler = Battler.new()
	if enemy_resource != null:
		enemy_battler.initialize_from_data(enemy_resource)
	else:
		# Fallback dacă resursa nu există: boss-ul Tengu are 120 HP, inamicul de rând 50 HP.
		enemy_battler.max_hp = 120 if is_boss else 50
		enemy_battler.current_hp = enemy_battler.max_hp
		enemy_battler.attack_power = 15 if is_boss else 10
		enemy_battler.defense = 4 if is_boss else 2

	# 3. În joc, folosim QuizEngine real (testele pot injecta un FakeQuizEngine înainte de setup).
	if engine == null:
		engine = QuizEngine.new(bank)
	engine.start(pool_id, rng_seed)

	# 4. Actualizăm interfața cu noile date.
	_update_ui_state()
	_show_next_question()


## Asigură că toate butoanele respectă dimensiunea minimă accesibilă de 48px.
func setup_accessible_buttons() -> void:
	for node in find_children("*", "Button", true, false):
		if node is Button:
			node.custom_minimum_size.x = maxf(node.custom_minimum_size.x, 48.0)
			node.custom_minimum_size.y = maxf(node.custom_minimum_size.y, 48.0)


## Încarcă următoarea întrebare din QuizEngine.
func _show_next_question() -> void:
	if engine == null:
		return

	_current_question = engine.next_question()
	if _current_question.is_empty():
		return

	_answered = false
	_kana_label.text = str(_current_question.get("prompt_text", ""))
	_feedback_label.text = ""
	_explain_label.text = ""
	_next_button.visible = false

	# Curățăm butoanele anterioare de opțiuni
	for child in _choices_container.get_children():
		_choices_container.remove_child(child)
		child.free()

	# Creăm cele 4 butoane de opțiuni (romaji)
	var choices: Array = _current_question.get("choices", [])
	for choice in choices:
		var btn: Button = _create_styled_button(str(choice))
		btn.pressed.connect(_on_choice_selected.bind(str(choice)))
		_choices_container.add_child(btn)

	if _choices_container.get_child_count() > 0:
		(_choices_container.get_child(0) as Button).grab_focus()

	_asked_at_ms = Time.get_ticks_msec()
	setup_accessible_buttons()


## Tratează selectarea unei variante de răspuns de către jucător.
func _on_choice_selected(chosen: String) -> void:
	if _current_question.is_empty() or _answered:
		return

	_answered = true
	var elapsed_ms: int = Time.get_ticks_msec() - _asked_at_ms
	var qid: String = str(_current_question.get("qid", ""))

	# Trimitem răspunsul la QuizEngine
	var result: Dictionary = engine.submit(qid, chosen, elapsed_ms)
	var expected: String = str(result.get("expected", ""))
	var is_correct: bool = bool(result.get("correct", false))

	# Actualizăm butoanele vizual (dezactivare + culori)
	for child in _choices_container.get_children():
		if child is Button:
			child.disabled = true
			if child.text == expected:
				_paint_button(child, COLOR_RIGHT)
			elif child.text == chosen:
				_paint_button(child, COLOR_WRONG)

	# Regula Definition of Done: Răspunsul corect e afișat clar, nu doar o culoare!
	if is_correct:
		correct_count += 1
		_feedback_label.text = "○  Corect: " + expected
		_feedback_label.add_theme_color_override("font_color", COLOR_RIGHT.lightened(0.3))
		# Jucătorul lovește inamicul
		enemy_battler.take_damage(player_battler.attack_power)
	else:
		wrong_count += 1
		_feedback_label.text = "×  Ai ales: " + chosen + "  |  Răspuns corect: " + expected
		_feedback_label.add_theme_color_override("font_color", COLOR_WRONG.lightened(0.3))
		# Inamicul lovește jucătorul
		player_battler.take_damage(enemy_battler.attack_power)

	var explain_data: Dictionary = result.get("explain", {})
	_explain_label.text = str(explain_data.get("ro", explain_data.get("en", "")))

	_update_ui_state()

	# Verificăm condițiile de sfârșit de luptă
	if not enemy_battler.is_alive():
		_feedback_label.text += "  ★ Victorie!"
		_finish_battle("win")
	elif not player_battler.is_alive():
		_feedback_label.text += "  💀 Înfrângere!"
		_finish_battle("lose")
	else:
		_next_button.visible = true
		_next_button.grab_focus()


## Jucătorul alege să fugă din luptă.
func _on_flee_pressed() -> void:
	if _answered:
		return
	_finish_battle("flee")


## Emite semnalul de final conform contractului din secțiunea 9.
func _finish_battle(outcome: String) -> void:
	var enc_id: String = str(encounter_data.get("id", "c1_kappa_1"))
	var final_result: Dictionary = {
		"encounter_id": enc_id,
		"outcome": outcome,
		"correct": correct_count,
		"wrong": wrong_count,
	}
	emit_signal("battle_finished", final_result)


## Actualizează etichetele și barele de viață.
func _update_ui_state() -> void:
	if enemy_battler != null:
		var boss_tag: String = " [BOSS]" if encounter_data.get("is_boss", false) else ""
		var enemy_name: String = str(encounter_data.get("id", "Inamic")) + boss_tag
		_enemy_info_label.text = "%s: %d / %d HP" % [enemy_name, enemy_battler.current_hp, enemy_battler.max_hp]
		_enemy_hp_bar.max_value = enemy_battler.max_hp
		_enemy_hp_bar.value = enemy_battler.current_hp

	if player_battler != null:
		_player_info_label.text = "Player: %d / %d HP" % [player_battler.current_hp, player_battler.max_hp]
		_player_hp_bar.max_value = player_battler.max_hp
		_player_hp_bar.value = player_battler.current_hp


## Construiește structura vizuală a scenei în mod programatic pentru fiabilitate totală.
func _build_ui() -> void:
	if ResourceLoader.exists(KANA_FONT):
		var font_var: FontVariation = FontVariation.new()
		font_var.base_font = ThemeDB.fallback_font
		font_var.fallbacks = [load(KANA_FONT)]
		var battle_theme: Theme = Theme.new()
		battle_theme.default_font = font_var
		theme = battle_theme

	var bg: ColorRect = ColorRect.new()
	bg.color = COLOR_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var main_vbox: VBoxContainer = VBoxContainer.new()
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_vbox.offset_top = 20
	main_vbox.offset_bottom = -20
	main_vbox.offset_left = 30
	main_vbox.offset_right = -30
	main_vbox.add_theme_constant_override("separation", 10)
	add_child(main_vbox)

	# Zona Inamic (Sus)
	_enemy_info_label = _create_label("EnemyInfo", "Inamic: 50 / 50 HP", 16, COLOR_TEXT)
	main_vbox.add_child(_enemy_info_label)

	_enemy_hp_bar = ProgressBar.new()
	_enemy_hp_bar.custom_minimum_size = Vector2(0, 16)
	_enemy_hp_bar.show_percentage = false
	main_vbox.add_child(_enemy_hp_bar)

	# Zona Întrebare Kana (Mijloc)
	_kana_label = _create_label("KanaPrompt", "あ", 72, COLOR_TEXT)
	main_vbox.add_child(_kana_label)

	_feedback_label = _create_label("Feedback", "", 18, COLOR_TEXT)
	main_vbox.add_child(_feedback_label)

	_explain_label = _create_label("Explain", "", 14, COLOR_MUTED)
	_explain_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main_vbox.add_child(_explain_label)

	# Opțiunile de răspuns (4 butoane romaji)
	_choices_container = HBoxContainer.new()
	_choices_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_choices_container.add_theme_constant_override("separation", 12)
	main_vbox.add_child(_choices_container)

	# Buton de continuare (Next)
	_next_button = _create_styled_button("Următoarea întrebare →")
	_next_button.visible = false
	_next_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_next_button.pressed.connect(_show_next_question)
	main_vbox.add_child(_next_button)

	# Zona Jucător (Jos)
	_player_info_label = _create_label("PlayerInfo", "Player: 100 / 100 HP", 16, COLOR_TEXT)
	main_vbox.add_child(_player_info_label)

	_player_hp_bar = ProgressBar.new()
	_player_hp_bar.custom_minimum_size = Vector2(0, 16)
	_player_hp_bar.show_percentage = false
	main_vbox.add_child(_player_hp_bar)

	# Butoane de acțiune secundare (ex: Fugi)
	_actions_container = HBoxContainer.new()
	_actions_container.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(_actions_container)

	_flee_button = _create_styled_button("Fugi din luptă")
	_flee_button.pressed.connect(_on_flee_pressed)
	_actions_container.add_child(_flee_button)


func _create_label(p_name: String, p_text: String, p_size: int, p_color: Color) -> Label:
	var lbl: Label = Label.new()
	lbl.name = p_name
	lbl.text = p_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", p_size)
	lbl.add_theme_color_override("font_color", p_color)
	return lbl


func _create_styled_button(p_text: String) -> Button:
	var btn: Button = Button.new()
	btn.text = p_text
	btn.custom_minimum_size = Vector2(110, 48) # Minim 48px pentru accesibilitate
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", COLOR_TEXT)
	btn.add_theme_color_override("font_disabled_color", COLOR_TEXT)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		btn.add_theme_stylebox_override(state, _make_flat_box(COLOR_BUTTON))
	btn.add_theme_stylebox_override("hover", _make_flat_box(COLOR_BUTTON.lightened(0.15)))
	return btn


func _paint_button(btn: Button, color: Color) -> void:
	btn.add_theme_stylebox_override("disabled", _make_flat_box(color))


func _make_flat_box(bg_color: Color) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = bg_color
	box.set_corner_radius_all(6)
	return box
