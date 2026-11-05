extends Node

signal language_changed(code: String)

const SETTINGS_PATH := "user://settings.cfg"
const LANGS: Array[String] = ["ro", "en"]

var lang: String = "ro"
var music_volume: float = 1.0
var sfx_volume: float = 1.0
var text_size: int = 0
var telemetry_enabled: bool = true


func _ready() -> void:
	_load()
	TranslationServer.set_locale(lang)


func set_language(code: String) -> void:
	if code not in LANGS or code == lang:
		return
	lang = code
	TranslationServer.set_locale(lang)
	save()
	language_changed.emit(lang)


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("general", "lang", lang)
	cfg.set_value("general", "text_size", text_size)
	cfg.set_value("general", "telemetry_enabled", telemetry_enabled)
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.save(SETTINGS_PATH)


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	var saved_lang: String = cfg.get_value("general", "lang", lang)
	if saved_lang in LANGS:
		lang = saved_lang
	text_size = int(cfg.get_value("general", "text_size", text_size))
	telemetry_enabled = bool(cfg.get_value("general", "telemetry_enabled", telemetry_enabled))
	music_volume = clampf(float(cfg.get_value("audio", "music_volume", music_volume)), 0.0, 1.0)
	sfx_volume = clampf(float(cfg.get_value("audio", "sfx_volume", sfx_volume)), 0.0, 1.0)
