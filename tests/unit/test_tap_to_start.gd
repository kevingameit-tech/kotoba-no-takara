extends GutTest
## TapToStart unit tests (Mariana).
## Issue #42: „Tap to start” deblochează sunetul.
## Issue #58: [ui] iPhone: indiciu pentru modul silențios și test de 30 min (navigator.audioSession).

var tap_screen: TapToStart
var settings_node: Node


func before_each() -> void:
	settings_node = get_node_or_null("/root/Settings")
	if settings_node != null:
		settings_node.set_language("ro")

	tap_screen = load("res://ui/tap_to_start.tscn").instantiate()
	add_child_autofree(tap_screen)


func test_tap_screen_labels_use_i18n() -> void:
	assert_not_null(tap_screen.prompt_label, "Eticheta prompt trebuie să existe.")
	assert_eq(tap_screen.prompt_label.text, tr("MENU_TAP_TO_START"), "Prompt-ul trebuie să folosească cheia MENU_TAP_TO_START.")
	assert_not_null(tap_screen.iphone_hint_label, "Indiciul pentru modul silențios pe iPhone trebuie să existe.")
	assert_eq(tap_screen.iphone_hint_label.text, tr("UI_IPHONE_SILENT_HINT"), "Indiciul de mod silențios trebuie să folosească cheia UI_IPHONE_SILENT_HINT.")


func test_iphone_silent_hint_language_switching() -> void:
	settings_node.set_language("ro")
	assert_true(tap_screen.iphone_hint_label.text.contains("modul silențios"), "Mesajul RO trebuie să menționeze modul silențios.")
	
	settings_node.set_language("en")
	assert_true(tap_screen.iphone_hint_label.text.contains("Silent Mode"), "Mesajul EN trebuie să menționeze Silent Mode.")


func test_unlock_audio_and_emit_started() -> void:
	watch_signals(tap_screen)
	# Setăm audio mute pentru a verifica deblocarea
	AudioServer.set_bus_mute(0, true)
	assert_true(AudioServer.is_bus_mute(0), "Mute inițial activat pentru test.")
	
	tap_screen.unlock_and_start()
	
	assert_false(AudioServer.is_bus_mute(0), "unlock_and_start() trebuie să deblocheze sunetul (AudioServer mute=false).")
	assert_signal_emitted(tap_screen, "started", "Semnalul started trebuie să fie emis la apăsare.")


func test_web_playback_type_configured_to_stream() -> void:
	# Verifică conformitatea cerinței din Issue #58: audio/general/default_playback_type.web = 0 (Stream)
	var playback_type = ProjectSettings.get_setting("audio/general/default_playback_type.web", -1)
	assert_eq(playback_type, 0, "audio/general/default_playback_type.web trebuie să fie 0 (Stream) pentru a preveni blocarea în Safari.")
