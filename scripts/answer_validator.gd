class_name AnswerValidator
extends Node

# Verifică dacă răspunsul introdus de jucător se potrivește cu un răspuns corect
# (folosește TextFormatter pentru a ignora spațiile și literele mari/mici)
static func is_answer_correct(player_input: String, correct_answer: String) -> bool:
	var clean_input = TextFormatter.sanitize_input(player_input)
	var clean_correct = TextFormatter.sanitize_input(correct_answer)
	return clean_input == clean_correct

# Verifică dacă răspunsul se află într-o listă de răspunsuri acceptate
static func is_answer_in_list(player_input: String, valid_answers: Array) -> bool:
	var clean_input = TextFormatter.sanitize_input(player_input)
	for answer in valid_answers:
		if TextFormatter.sanitize_input(answer) == clean_input:
			return true
	return false
