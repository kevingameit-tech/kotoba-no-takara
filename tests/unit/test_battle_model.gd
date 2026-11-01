class_name TestBattleModel
extends GutTest

const BattleModel = preload("res://battle/battle_model.gd")
const Battler = preload("res://battle/battler.gd")

func test_initial_state() -> void:
	var battle_model = BattleModel.new()
	assert_not_null(battle_model, "BattleModel trebuie să fie instanțiat")
	assert_eq(battle_model.current_state, 0, "Starea inițială trebuie să fie START (0)")

func test_setup_transitions_to_choose_action() -> void:
	var battle_model = BattleModel.new()
	battle_model.setup(null)
	assert_eq(battle_model.current_state, 1, "După setup starea trebuie să fie CHOOSE_ACTION (1)")
	assert_eq(battle_model.player_hp, 100, "Viața jucătorului trebuie resetată la 100")
	assert_eq(battle_model.enemy_hp, 50, "Viața inamicului trebuie resetată la 50")

func test_choose_attack_goes_to_question() -> void:
	var battle_model = BattleModel.new()
	battle_model.setup(null)
	battle_model.choose_attack()
	assert_eq(battle_model.current_state, 2, "Alegerea atacului duce la starea de întrebare (2)")

func test_choose_flee() -> void:
	var battle_model = BattleModel.new()
	battle_model.setup(null)
	battle_model.choose_flee()
	assert_eq(battle_model.current_state, 6, "Fugirea duce la starea FLEE (6)")

func test_resolve_correct_answer_damages_enemy() -> void:
	var battle_model = BattleModel.new()
	battle_model.setup(null)
	battle_model.choose_attack()
	battle_model.resolve_answer(true)
	assert_eq(battle_model.enemy_hp, 25, "Răspunsul corect scade viața inamicului la 25")
	assert_eq(battle_model.current_state, 1, "Se întoarce la alegerea acțiunii")

func test_resolve_wrong_answer_damages_player() -> void:
	var battle_model = BattleModel.new()
	battle_model.setup(null)
	battle_model.choose_attack()
	battle_model.resolve_answer(false)
	assert_eq(battle_model.player_hp, 80, "Răspunsul greșit scade viața jucătorului la 80")
	assert_eq(battle_model.current_state, 1, "Se întoarce la alegerea acțiunii")

func test_resolve_losing_battle() -> void:
	var battle_model = BattleModel.new()
	battle_model.setup(null)
	battle_model.player_hp = 10
	battle_model.choose_attack()
	battle_model.resolve_answer(false)
	assert_eq(battle_model.current_state, 5, "Jucătorul pierde lupta (LOSE = 5)")

func test_battler_does_not_modify_source_data() -> void:
	var mock_data = {
		"max_hp": 80
	}
	
	var battler = Battler.new()
	battler.initialize_from_data(mock_data)
	battler.take_damage(30)
	
	assert_eq(battler.current_hp, 50, "HP-ul curent al battler-ului a scăzut la 50")
	assert_eq(mock_data["max_hp"], 80, "Datele originale din sursă rămân absolut nemodificate")

# --- NOILE TESTE PENTRU SEED ȘI LIMITELE HP ---

func test_battler_deterministic_seed_damage() -> void:
	var battler1 = Battler.new()
	battler1.max_hp = 100
	battler1.current_hp = 100
	battler1.set_damage_seed(42)
	var dmg1 = battler1.calculate_and_take_damage(20)
	
	var battler2 = Battler.new()
	battler2.max_hp = 100
	battler2.current_hp = 100
	battler2.set_damage_seed(42)
	var dmg2 = battler2.calculate_and_take_damage(20)
	
	assert_eq(dmg1, dmg2, "Același seed trebuie să dea exact aceleași daune")
	assert_eq(battler1.current_hp, battler2.current_hp, "HP-ul rămas trebuie să fie identic")

func test_battler_hp_bounds() -> void:
	var battler = Battler.new()
	battler.max_hp = 50
	battler.current_hp = 10
	
	battler.take_damage(1000)
	assert_eq(battler.current_hp, 0, "HP-ul nu are voie să scadă sub 0 (lower bound)")
	
	battler.current_hp = 50
	battler.take_damage(-20)
	assert_eq(battler.current_hp, 50, "HP-ul respectă limitele stabilite")