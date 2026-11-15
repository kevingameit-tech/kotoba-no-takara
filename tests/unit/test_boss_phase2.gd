class_name TestBossPhase2
extends GutTest

## Teste unitare pentru tranziția de fază a boss-ului Tengu (Faza 2 cu pool mai greu).
## Verifică pragul de 50% HP (phase2_hp_ratio), comutarea QuizEngine pe phase2_pool_id,
## emiterea semnalului phase_changed și actualizarea corespunzătoare a interfeței.
## Contract: docs/contracts.md, secțiunile 9 și 10.

const BattleSceneScript = preload("res://battle/battle_scene.gd")
const FakeQuizEngineScript = preload("res://tests/fakes/fake_quiz_engine.gd")
const BossDataScript = preload("res://battle/data/boss_data.gd")

var _scene: BattleScene = null


func before_each() -> void:
	_scene = BattleSceneScript.new()
	add_child_autofree(_scene)


func test_boss_starts_in_phase_1() -> void:
	var encounter = {
		"id": "c1_boss_tengu",
		"chapter": 1,
		"pool_id": "c1_boss_tengu",
		"phase2_pool_id": "c1_boss_tengu_phase2",
		"is_boss": true,
		"enemy": "res://battle/data/enemies/tengu.tres"
	}
	_scene.setup(encounter)

	assert_eq(_scene.current_phase, 1, "Boss-ul începe în Faza 1")
	assert_eq(_scene.phase2_pool_id, "c1_boss_tengu_phase2", "Pool-ul pentru faza 2 este extras corect")
	assert_eq(_scene.phase2_hp_ratio, 0.5, "Pragul pentru faza 2 este de 50% din max_hp")
	assert_true("[BOSS]" in _scene._enemy_info_label.text, "Eticheta UI indică marcajul [BOSS] în Faza 1")


func test_boss_transitions_to_phase_2_at_threshold() -> void:
	var fake_engine = FakeQuizEngineScript.new()
	_scene.engine = fake_engine
	var encounter = {
		"id": "c1_boss_tengu",
		"chapter": 1,
		"pool_id": "c1_boss_tengu",
		"phase2_pool_id": "c1_boss_tengu_phase2",
		"is_boss": true,
		"enemy": "res://battle/data/enemies/tengu.tres"
	}
	_scene.setup(encounter)

	watch_signals(_scene)

	# Tengu are 120 HP. Pragul de 50% este 60 HP.
	# Setăm HP-ul boss-ului exact la prag (60 HP)
	_scene.enemy_battler.current_hp = 60
	var transitioned: bool = _scene.check_boss_phase_transition()

	assert_true(transitioned, "Tranziția la Faza 2 returnează true")
	assert_eq(_scene.current_phase, 2, "Boss-ul a trecut în Faza 2")
	assert_signal_emitted(_scene, "phase_changed", "Semnalul phase_changed a fost emis")
	var signal_args = get_signal_parameters(_scene, "phase_changed")
	assert_not_null(signal_args, "Parametrii semnalului nu sunt null")
	assert_eq(signal_args[0], 2, "Semnalul transmite noua fază (2)")
	assert_true("[FAZA 2]" in _scene._enemy_info_label.text, "Eticheta UI se actualizează cu [FAZA 2]")


func test_phase_2_switches_quiz_engine_to_harder_pool() -> void:
	var fake_engine = FakeQuizEngineScript.new()
	_scene.engine = fake_engine
	var encounter = {
		"id": "c1_boss_tengu",
		"chapter": 1,
		"pool_id": "c1_boss_tengu",
		"phase2_pool_id": "c1_boss_tengu_phase2",
		"is_boss": true,
		"enemy": "res://battle/data/enemies/tengu.tres"
	}
	_scene.setup(encounter)

	assert_eq(fake_engine.pool_id, "c1_boss_tengu", "La început motorul folosește pool-ul standard de boss")

	# Simulăm scăderea HP-ului sub 50% (ex: la 50 HP)
	_scene.enemy_battler.current_hp = 50
	_scene.check_boss_phase_transition()

	assert_eq(fake_engine.pool_id, "c1_boss_tengu_phase2", "QuizEngine a fost repornit cu pool-ul mai greu de faza 2")


func test_regular_enemy_never_triggers_phase_2() -> void:
	var encounter = {
		"id": "c1_kappa_1",
		"chapter": 1,
		"pool_id": "c1_rows_a_k",
		"is_boss": false,
		"enemy": "res://battle/data/enemies/placeholder.tres"
	}
	_scene.setup(encounter)

	watch_signals(_scene)

	# Scădem HP-ul inamicului obișnuit sub 50%
	_scene.enemy_battler.current_hp = 10
	var transitioned: bool = _scene.check_boss_phase_transition()

	assert_false(transitioned, "Inamicul obișnuit nu declanșează Faza 2")
	assert_eq(_scene.current_phase, 1, "Faza rămâne 1")
	assert_signal_not_emitted(_scene, "phase_changed", "Nu se emite semnalul phase_changed pentru inamici normali")


func test_phase_2_triggers_only_once_on_subsequent_damage() -> void:
	var fake_engine = FakeQuizEngineScript.new()
	_scene.engine = fake_engine
	var encounter = {
		"id": "c1_boss_tengu",
		"chapter": 1,
		"pool_id": "c1_boss_tengu",
		"phase2_pool_id": "c1_boss_tengu_phase2",
		"is_boss": true,
		"enemy": "res://battle/data/enemies/tengu.tres"
	}
	_scene.setup(encounter)

	watch_signals(_scene)

	# Prima lovitură duce viața sub 50% (la 55 HP)
	_scene.enemy_battler.current_hp = 55
	var first_transition: bool = _scene.check_boss_phase_transition()
	assert_true(first_transition, "Prima trecere în faza 2 reușește")

	# Lovitură ulterioară duce viața la 30 HP
	_scene.enemy_battler.current_hp = 30
	var second_transition: bool = _scene.check_boss_phase_transition()
	assert_false(second_transition, "A doua verificare returnează false deoarece boss-ul e deja în Faza 2")
	assert_eq(get_signal_emit_count(_scene, "phase_changed"), 1, "Semnalul phase_changed a fost emis exact o singură dată")


func test_choice_selection_triggers_phase_2_when_crossing_threshold() -> void:
	var fake_engine = FakeQuizEngineScript.new()
	fake_engine.queue_question({
		"qid": "q_boss_hit",
		"item_id": "h_a",
		"mode": "choice",
		"prompt_text": "あ",
		"choices": ["a", "i", "u", "e"]
	}, "a")

	_scene.engine = fake_engine
	var encounter = {
		"id": "c1_boss_tengu",
		"chapter": 1,
		"pool_id": "c1_boss_tengu",
		"phase2_pool_id": "c1_boss_tengu_phase2",
		"is_boss": true,
		"enemy": "res://battle/data/enemies/tengu.tres"
	}
	_scene.setup(encounter)

	watch_signals(_scene)

	# Tengu are 120 HP. Setăm HP-ul la 70 HP.
	# Jucătorul răspunde corect ("a") și lovește cu 25 atac -> Tengu ajunge la 45 HP (<= 60 HP).
	_scene.enemy_battler.current_hp = 70
	_scene._on_choice_selected("a")

	assert_eq(_scene.current_phase, 2, "Răspunsul corect a scăzut viața sub 50% și a activat Faza 2")
	assert_signal_emitted(_scene, "phase_changed")
	assert_eq(fake_engine.pool_id, "c1_boss_tengu_phase2", "Pool-ul este comutat la c1_boss_tengu_phase2 direct din fluxul de luptă")
	assert_true("FAZA 2" in _scene._feedback_label.text, "Feedback-ul vizual anunță intrarea în FAZA 2!")
