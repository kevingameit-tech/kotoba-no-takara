class_name TestBattleScene
extends GutTest

const BattleSceneScript = preload("res://battle/battle_scene.gd")
const FakeQuizEngineScript = preload("res://tests/fakes/fake_quiz_engine.gd")

var _scene: BattleScene = null


func before_each() -> void:
	_scene = BattleSceneScript.new()
	add_child_autofree(_scene)


func test_initial_setup_regular_enemy() -> void:
	var encounter = {
		"id": "c1_kappa_1",
		"chapter": 1,
		"pool_id": "c1_rows_a_k",
		"is_boss": false,
		"enemy": "res://battle/data/enemies/placeholder.tres"
	}
	_scene.setup(encounter)

	assert_eq(_scene.player_battler.current_hp, 100, "Jucătorul începe cu 100 HP")
	assert_eq(_scene.enemy_battler.current_hp, 50, "Inamicul obișnuit are 50 HP")
	assert_false(_scene.encounter_data["is_boss"], "Nu este boss")


func test_setup_tengu_boss_has_higher_hp() -> void:
	var encounter = {
		"id": "c1_boss_tengu",
		"chapter": 1,
		"pool_id": "c1_boss_tengu",
		"is_boss": true,
		"enemy": "res://battle/data/enemies/tengu.tres"
	}
	_scene.setup(encounter)

	assert_true(_scene.encounter_data["is_boss"], "Tengu este marcat ca boss")
	assert_eq(_scene.enemy_battler.max_hp, 120, "Tengu are HP ridicat (120 HP) conform cerinței")
	assert_eq(_scene.encounter_data["pool_id"], "c1_boss_tengu", "Folosește pool-ul greu c1_boss_tengu")


func test_correct_answer_damages_enemy_and_shows_feedback() -> void:
	var fake_engine = FakeQuizEngineScript.new()
	fake_engine.queue_question({
		"qid": "test_q1",
		"item_id": "h_a",
		"mode": "choice",
		"prompt_text": "あ",
		"choices": ["a", "i", "u", "e"]
	}, "a")

	_scene.engine = fake_engine
	_scene.setup({
		"id": "c1_kappa_1",
		"pool_id": "c1_rows_a_k",
		"is_boss": false
	})

	watch_signals(_scene)
	# Simulăm alegerea răspunsului corect
	_scene._on_choice_selected("a")

	assert_eq(_scene.correct_count, 1, "Contorul de răspunsuri corecte este incrementat")
	assert_lt(_scene.enemy_battler.current_hp, 50, "Inamicul primește daune la răspuns corect")
	assert_true("Corect: a" in _scene._feedback_label.text, "Răspunsul corect este afișat explicit în UI")


func test_wrong_answer_damages_player_and_shows_expected() -> void:
	var fake_engine = FakeQuizEngineScript.new()
	fake_engine.queue_question({
		"qid": "test_q2",
		"item_id": "h_a",
		"mode": "choice",
		"prompt_text": "あ",
		"choices": ["a", "i", "u", "e"]
	}, "a")

	_scene.engine = fake_engine
	_scene.setup({
		"id": "c1_kappa_1",
		"pool_id": "c1_rows_a_k",
		"is_boss": false
	})

	# Simulăm alegerea unui răspuns greșit
	_scene._on_choice_selected("i")

	assert_eq(_scene.wrong_count, 1, "Contorul de răspunsuri greșite este incrementat")
	assert_lt(_scene.player_battler.current_hp, 100, "Jucătorul primește daune la răspuns greșit")
	assert_true("Răspuns corect: a" in _scene._feedback_label.text, "Răspunsul corect așteptat este afișat la greșeală")


func test_battle_win_signal_emission() -> void:
	_scene.setup({
		"id": "c1_kappa_1",
		"pool_id": "c1_rows_a_k",
		"is_boss": false
	})

	watch_signals(_scene)
	_scene.enemy_battler.take_damage(100) # Învingem inamicul direct
	_scene._finish_battle("win")

	assert_signal_emitted(_scene, "battle_finished")
	var signal_args = get_signal_parameters(_scene, "battle_finished")
	assert_not_null(signal_args, "Semnalul trebuie să aibă parametri")
	assert_eq(signal_args[0]["outcome"], "win", "Rezultatul luptei este win")
	assert_eq(signal_args[0]["encounter_id"], "c1_kappa_1", "ID-ul întâlnirii este transmis corect")


func test_battle_flee_signal_emission() -> void:
	_scene.setup({
		"id": "c1_kappa_1",
		"pool_id": "c1_rows_a_k",
		"is_boss": false
	})

	watch_signals(_scene)
	_scene._on_flee_pressed()

	assert_signal_emitted(_scene, "battle_finished")
	var signal_args = get_signal_parameters(_scene, "battle_finished")
	assert_eq(signal_args[0]["outcome"], "flee", "Rezultatul luptei este flee")


func test_buttons_meet_48px_accessibility_constraint() -> void:
	_scene.setup({
		"id": "c1_kappa_1",
		"pool_id": "c1_rows_a_k",
		"is_boss": false
	})

	var buttons = _scene.find_children("*", "Button", true, false)
	assert_gt(buttons.size(), 0, "Trebuie să existe butoane în scenă")
	for btn in buttons:
		var button: Button = btn
		assert_true(button.custom_minimum_size.x >= 48.0, "Lățimea butonului '%s' e >= 48px" % button.text)
		assert_true(button.custom_minimum_size.y >= 48.0, "Înălțimea butonului '%s' e >= 48px" % button.text)
