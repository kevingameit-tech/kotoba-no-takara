class_name TestBattleModel
extends GutTest

func test_initial_state() -> void:
	var battle_model = load("res://battle/battle_model.gd").new()
	assert_not_null(battle_model, "BattleModel trebuie să fie instanțiat")
	assert_eq(battle_model.current_state, 0, "Starea inițială trebuie să fie START (0)")

func test_setup_transitions_to_choose_action() -> void:
	var battle_model = load("res://battle/battle_model.gd").new()
	battle_model.setup(null)
	assert_eq(battle_model.current_state, 1, "După setup starea trebuie să fie CHOOSE_ACTION (1)")
	assert_eq(battle_model.player_hp, 100, "Viața jucătorului trebuie resetată la 100")
	assert_eq(battle_model.enemy_hp, 50, "Viața inamicului trebuie resetată la 50")

func test_choose_attack_goes_to_question() -> void:
	var battle_model = load("res://battle/battle_model.gd").new()
	battle_model.setup(null)
	battle_model.choose_attack()
	assert_eq(battle_model.current_state, 2, "Alegerea atacului duce la starea de întrebare (2)")

func test_resolve_correct_answer_damages_enemy() -> void:
	var battle_model = load("res://battle/battle_model.gd").new()
	battle_model.setup(null)
	battle_model.choose_attack()
	battle_model.resolve_answer(true)
	assert_eq(battle_model.enemy_hp, 25, "Răspunsul corect scade viața inamicului la 25")
	assert_eq(battle_model.current_state, 1, "Se întoarce la alegerea acțiunii (CHOOSE_ACTION = 1)")

func test_resolve_winning_answer() -> void:
	var battle_model = load("res://battle/battle_model.gd").new()
	battle_model.setup(null)
	battle_model.choose_attack()
	battle_model.resolve_answer(true) 
	battle_model.choose_attack()
	battle_model.resolve_answer(true) 
	assert_eq(battle_model.current_state, 4, "Jucătorul câștigă lupta când viața inamicului ajunge la 0 (WIN = 4)")