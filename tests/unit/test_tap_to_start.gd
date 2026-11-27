extends GutTest
## TapToStart unit tests (Mariana).
## Issue #42: „Tap to start” deblochează sunetul.

var tap_screen: TapToStart


func before_each() -> void:
	tap_screen = load("res://ui/tap_to_start.tscn").instantiate()
	add_child_autofree(tap_screen)


func test_tap_screen_labels_use_i18n() -> void:
	assert_not_null(tap_screen.prompt_label, "Eticheta prompt trebuie să existe.")
	assert_eq(tap_screen.prompt_label.text, tr("MENU_TAP_TO_START"), "Prompt-ul trebuie să folosească cheia MENU_TAP_TO_START.")


func test_unlock_audio_and_emit_started() -> void:
	watch_signals(tap_screen)
	# Setăm audio mute pentru a verifica deblocarea
	AudioServer.set_bus_mute(0, true)
	assert_true(AudioServer.is_bus_mute(0), "Mute inițial activat pentru test.")
	
	tap_screen.unlock_and_start()
	
	assert_false(AudioServer.is_bus_mute(0), "unlock_and_start() trebuie să deblocheze sunetul (AudioServer mute=false).")
	assert_signal_emitted(tap_screen, "started", "Semnalul started trebuie să fie emis la apăsare.")
