class_name FakeQuizEngine
extends QuizEngine

## Simulator (fake / test double) pentru QuizEngine.
## Permite testelor unitare (de exemplu pentru luptă / BattleModel) să ruleze
## complet izolat, fără să depindă de fișiere JSON externe sau autoload-uri.
## Contract: docs/contracts.md, secțiunea 8.

var pool_id: String = ""
var last_rng_seed: int = -1
var is_started: bool = false
var questions_queue: Array[Dictionary] = []
var expected_answers: Dictionary = {}
var custom_answers: Dictionary = {}
var default_expected: String = "a"
var auto_generate_fallback: bool = true
var question_counter: int = 1
var fake_state: Dictionary = {}


func _init(bank: Object = null) -> void:
	super._init(bank)


## Inițializează sesiunea simulată de quiz.
func start(p_pool_id: String, rng_seed: int = -1) -> void:
	pool_id = p_pool_id
	last_rng_seed = rng_seed
	is_started = true
	question_counter = 1


## Adaugă o întrebare scriptată în coadă, ce va fi returnată de next_question().
func queue_question(question_data: Dictionary, expected_answer: String = "") -> void:
	questions_queue.append(question_data)
	var qid: String = str(question_data.get("qid", ""))
	if qid != "":
		expected_answers[qid] = expected_answer


## Programează dinainte rezultatul exact pentru o verificare submit().
func script_submit_result(qid: String, correct: bool, expected: String, explain: Dictionary = {}) -> void:
	custom_answers[qid] = {
		"correct": correct,
		"expected": expected,
		"explain": explain if not explain.is_empty() else {"ro": "", "en": ""}
	}


## Returnează următoarea întrebare scriptată sau o întrebare mock implicită.
func next_question() -> Dictionary:
	if not questions_queue.is_empty():
		return questions_queue.pop_front()
	
	if not auto_generate_fallback:
		return {}

	# Întrebare mock implicită, conformă cu secțiunea 8 din contracts.md
	var qid: String = "fake_q_%04d" % question_counter
	question_counter += 1
	var q: Dictionary = {
		"qid": qid,
		"item_id": "h_a",
		"mode": MODE_CHOICE,
		"prompt_text": "あ",
		"prompt_audio": "",
		"choices": ["a", "i", "u", "e"],
	}
	expected_answers[qid] = default_expected
	return q


## Trimite un răspuns, emite semnalul answered și returnează dicționarul cerut de contract.
func submit(qid: String, answer: String, elapsed_ms: int) -> Dictionary:
	var result: Dictionary
	if custom_answers.has(qid):
		result = custom_answers[qid]
	else:
		var expected: String = expected_answers.get(qid, default_expected)
		var is_correct: bool = (answer == expected)
		result = {
			"correct": is_correct,
			"expected": expected,
			"explain": {"ro": "", "en": ""}
		}
	
	var item_id: String = "h_a"
	answered.emit(qid, item_id, result.get("correct", false), elapsed_ms)
	return result


## Returnează starea internă pentru testarea salvărilor.
func get_state() -> Dictionary:
	return fake_state.duplicate(true)


## Încarcă starea internă simulată.
func set_state(state: Dictionary) -> void:
	fake_state = state.duplicate(true)
