class_name PlayerStatsTracker
extends Node

var total_answers: int = 0
var correct_answers: int = 0
var current_streak: int = 0
var best_streak: int = 0

# Înregistrează un răspuns (corect sau greșit) și actualizează statisticile
func record_answer(is_correct: bool) -> void:
	total_answers += 1
	if is_correct:
		correct_answers += 1
		current_streak += 1
		if current_streak > best_streak:
			best_streak = current_streak
	else:
		current_streak = 0

# Calculează procentul de acuratețe (între 0.0 și 100.0)
func get_accuracy_percentage() -> float:
	if total_answers == 0:
		return 0.0
	return (float(correct_answers) / float(total_answers))  * 100.0

# Resetează statisticile
func reset_stats() -> void:
	total_answers = 0
	correct_answers = 0
	current_streak = 0
	best_streak = 0
