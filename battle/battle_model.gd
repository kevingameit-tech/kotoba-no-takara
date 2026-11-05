class_name BattleModel
extends RefCounted

## Gestionează logica și stările mașinii de stări pentru sistemul de luptă.

enum State { START, CHOOSE_ACTION, QUESTION, ENEMY_TURN, WIN, LOSE, FLEE }

var current_state: State = State.START
var player_hp: int = 100
var enemy_hp: int = 50
var quiz_engine: QuizEngine = null

signal battle_finished(result: String)


## Inițializează lupta primind motorul de quiz și setările inițiale.
func setup(p_quiz_engine: QuizEngine = null) -> void:
	quiz_engine = p_quiz_engine
	player_hp = 100
	enemy_hp = 50
	current_state = State.CHOOSE_ACTION


## Jucătorul alege să atace (trece la starea de întrebare).
func choose_attack() -> void:
	if current_state != State.CHOOSE_ACTION:
		return
	current_state = State.QUESTION


## Jucătorul alege să fugă din luptă.
func choose_flee() -> void:
	if current_state != State.CHOOSE_ACTION:
		return
	current_state = State.FLEE
	emit_signal("battle_finished", "flee")


## Verifică răspunsul venit de la quiz și actualizează stările (HP).
func resolve_answer(is_correct: bool) -> void:
	if current_state != State.QUESTION:
		return
	
	if is_correct:
		enemy_hp -= 25
		if enemy_hp <= 0:
			current_state = State.WIN
			emit_signal("battle_finished", "win")
			return
	else:
		player_hp -= 20
		if player_hp <= 0:
			current_state = State.LOSE
			emit_signal("battle_finished", "lose")
			return
			
	current_state = State.CHOOSE_ACTION
