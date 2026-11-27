extends GutTest
## Settings autoload unit tests (Mariana).
## Conformează docs/contracts.md secțiunea 6.

var settings: Node


func before_each() -> void:
	settings = autofree(load("res://autoload/settings.gd").new())
	add_child_autofree(settings)


func test_initial_values() -> void:
	assert_true(settings.lang in ["ro", "en"], "Limba implicită trebuie să fie ro sau en.")
	assert_true(settings.telemetry_enabled, "Telemetria este activată implicit.")
	assert_gte(settings.music_volume, 0.0)
	assert_lte(settings.music_volume, 1.0)
	assert_gte(settings.sfx_volume, 0.0)
	assert_lte(settings.sfx_volume, 1.0)


func test_set_language() -> void:
	watch_signals(settings)
	settings.lang = "ro"
	settings.set_language("en")
	assert_eq(settings.lang, "en")
	assert_signal_emitted_with_parameters(settings, "language_changed", ["en"])
	
	# Limbă necunoscută este ignorată
	settings.set_language("fr")
	assert_eq(settings.lang, "en")


func test_telemetry_toggle() -> void:
	settings.telemetry_enabled = false
	assert_false(settings.telemetry_enabled)
	settings.telemetry_enabled = true
	assert_true(settings.telemetry_enabled)
