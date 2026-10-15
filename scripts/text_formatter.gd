class_name TextFormatter
extends Node

#eliniman spatiile si facem literele mici
static func sanitize_input(input_text: String) -> String:
	return input_text.strip_edges().to_lower()

#Formatare scor
static func format_score(score:int) -> String:
	return "Scor: %05d" % score
