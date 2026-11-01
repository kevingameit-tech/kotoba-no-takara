extends Node

signal language_changed(new_lang: String)

var lang: String = "en" :
	set(value):
		if lang != value:
			lang = value
			emit_signal("language_changed", lang)

func set_language(new_lang: String) -> void:
	if new_lang == "en" or new_lang == "ro":
		lang = new_lang
