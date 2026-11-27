extends Node

signal language_changed(code: String)
signal volume_changed(bus_name: String, value: float)
signal text_size_changed(size: int)
signal telemetry_toggled(enabled: bool)

const SETTINGS_PATH := "user://settings.cfg"
const LANGS: Array[String] = ["ro", "en"]

var lang: String = "ro"
var music_volume: float = 1.0
var sfx_volume: float = 1.0
var text_size: int = 0
var telemetry_enabled: bool = true


func _ready() -> void:
	_load_translations()
	_load()
	TranslationServer.set_locale(lang)
	_apply_audio_volumes()


func _load_translations() -> void:
	if ResourceLoader.exists("res://i18n/ui.ro.translation"):
		var t_ro = load("res://i18n/ui.ro.translation")
		if t_ro != null:
			TranslationServer.add_translation(t_ro)
	if ResourceLoader.exists("res://i18n/ui.en.translation"):
		var t_en = load("res://i18n/ui.en.translation")
		if t_en != null:
			TranslationServer.add_translation(t_en)


func set_language(code: String) -> void:
	if code not in LANGS:
		return
	lang = code
	TranslationServer.set_locale(lang)
	save()
	language_changed.emit(lang)


func set_music_volume(vol: float) -> void:
	music_volume = clampf(vol, 0.0, 1.0)
	_apply_bus_volume("Music", music_volume)
	save()
	volume_changed.emit("Music", music_volume)


func set_sfx_volume(vol: float) -> void:
	sfx_volume = clampf(vol, 0.0, 1.0)
	_apply_bus_volume("SFX", sfx_volume)
	save()
	volume_changed.emit("SFX", sfx_volume)


func set_text_size(size: int) -> void:
	text_size = clampi(size, 0, 1)
	save()
	text_size_changed.emit(text_size)


func set_telemetry_enabled(enabled: bool) -> void:
	telemetry_enabled = enabled
	save()
	telemetry_toggled.emit(telemetry_enabled)


func _apply_audio_volumes() -> void:
	_apply_bus_volume("Music", music_volume)
	_apply_bus_volume("SFX", sfx_volume)


func _apply_bus_volume(bus_name: String, volume_linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(volume_linear, 0.0001, 1.0)))
		AudioServer.set_bus_mute(idx, volume_linear <= 0.0)


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
