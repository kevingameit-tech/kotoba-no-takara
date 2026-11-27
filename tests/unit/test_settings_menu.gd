extends GutTest
## SettingsMenu unit tests (Mariana).
## Conformează docs/contracts.md secțiunea 6 („Settings and UI text keys”).
## Issue #52: [ui] Pauză și Setări: limbă, volum, mărimea textului, opt-out.

var settings_menu: SettingsMenu
var settings_node: Node


func before_each() -> void:
	settings_node = get_node_or_null("/root/Settings")
	if settings_node != null:
		settings_node.set_language("ro")
		settings_node.music_volume = 1.0
		settings_node.sfx_volume = 1.0
		settings_node.text_size = 0
		settings_node.telemetry_enabled = true
	
	settings_menu = load("res://ui/settings_menu.tscn").instantiate()
	add_child_autofree(settings_menu)


func test_components_exist() -> void:
	assert_not_null(settings_menu.title_label, "Titlul setărilor trebuie să existe.")
	assert_not_null(settings_menu.btn_lang_ro, "Butonul de limbă RO trebuie să existe.")
	assert_not_null(settings_menu.btn_lang_en, "Butonul de limbă EN trebuie să existe.")
	assert_not_null(settings_menu.slider_music, "Slider-ul pentru volum muzică trebuie să existe.")
	assert_not_null(settings_menu.slider_sfx, "Slider-ul pentru volum SFX trebuie să existe.")
	assert_not_null(settings_menu.btn_size_normal, "Opțiunea de text normal trebuie să existe.")
	assert_not_null(settings_menu.btn_size_large, "Opțiunea de text mare trebuie să existe.")
	assert_not_null(settings_menu.check_telemetry, "Comutatorul pentru telemetrie trebuie să existe.")
	assert_not_null(settings_menu.btn_back, "Butonul Înapoi trebuie să existe.")


func test_accessibility_touch_target_sizes() -> void:
	# Verifică constrângerea de accesibilitate mobilă (minimum 48px înălțime)
	assert_gte(settings_menu.btn_lang_ro.custom_minimum_size.y, 48.0)
	assert_gte(settings_menu.btn_lang_en.custom_minimum_size.y, 48.0)
	assert_gte(settings_menu.btn_size_normal.custom_minimum_size.y, 48.0)
	assert_gte(settings_menu.btn_size_large.custom_minimum_size.y, 48.0)
	assert_gte(settings_menu.check_telemetry.custom_minimum_size.y, 48.0)
	assert_gte(settings_menu.btn_back.custom_minimum_size.y, 48.0)


func test_language_switch_updates_all_ui_text_dynamically() -> void:
	# Criteriu: RO <-> EN schimbă tot textul, inclusiv cel pus din cod
	settings_node.set_language("ro")
	assert_eq(settings_menu.title_label.text, "Setări")
	assert_eq(settings_menu.lang_title_label.text, "Limbă")
	assert_eq(settings_menu.music_title_label.text, "Volum Muzică")
	assert_eq(settings_menu.sfx_title_label.text, "Volum Efecte")
	assert_eq(settings_menu.text_size_title_label.text, "Mărimea Textului")
	assert_eq(settings_menu.check_telemetry.text, "Statistici de joc")
	assert_eq(settings_menu.btn_back.text, "Înapoi")
	
	# Comutăm la EN
	settings_menu._on_lang_en_pressed()
	assert_eq(settings_node.lang, "en")
	assert_eq(settings_menu.title_label.text, "Settings")
	assert_eq(settings_menu.lang_title_label.text, "Language")
	assert_eq(settings_menu.music_title_label.text, "Music Volume")
	assert_eq(settings_menu.sfx_title_label.text, "SFX Volume")
	assert_eq(settings_menu.text_size_title_label.text, "Text Size")
	assert_eq(settings_menu.check_telemetry.text, "Game Statistics")
	assert_eq(settings_menu.btn_back.text, "Back")
	
	# Comutăm înapoi la RO
	settings_menu._on_lang_ro_pressed()
	assert_eq(settings_node.lang, "ro")
	assert_eq(settings_menu.title_label.text, "Setări")
	assert_eq(settings_menu.btn_back.text, "Înapoi")


func test_volume_sliders() -> void:
	settings_menu.slider_music.value = 0.7
	assert_almost_eq(settings_node.music_volume, 0.7, 0.01)
	assert_eq(settings_menu.music_val_label.text, "70%")
	
	settings_menu.slider_sfx.value = 0.4
	assert_almost_eq(settings_node.sfx_volume, 0.4, 0.01)
	assert_eq(settings_menu.sfx_val_label.text, "40%")


func test_text_size_buttons() -> void:
	settings_menu._on_size_large_pressed()
	assert_eq(settings_node.text_size, 1)
	assert_true(settings_menu.btn_size_large.button_pressed)
	
	settings_menu._on_size_normal_pressed()
	assert_eq(settings_node.text_size, 0)
	assert_true(settings_menu.btn_size_normal.button_pressed)


func test_telemetry_opt_out_stops_sending() -> void:
	# Criteriu: Opt-out oprește trimiterea
	var telemetry_node: Node = get_node_or_null("/root/Telemetry")
	if telemetry_node != null:
		telemetry_node.clear_queue()
	
	# Dezactivăm telemetria prin CheckButton
	settings_menu.check_telemetry.button_pressed = false
	assert_false(settings_node.telemetry_enabled, "Telemetria trebuie să fie dezactivată în Settings.")
	
	if telemetry_node != null:
		assert_false(telemetry_node.is_telemetry_enabled(), "Telemetry.is_telemetry_enabled() trebuie să returneze false.")
		telemetry_node.log_event("session_start")
		telemetry_node.log_event("chapter_enter", {"chapter": 1})
		assert_eq(telemetry_node.get_queue().size(), 0, "Niciun eveniment nu trebuie să fie adăugat când telemetria e oprită.")
	
	# Reactivăm telemetria
	settings_menu.check_telemetry.button_pressed = true
	assert_true(settings_node.telemetry_enabled)
	if telemetry_node != null:
		assert_true(telemetry_node.is_telemetry_enabled())
		telemetry_node.log_event("session_start")
		assert_eq(telemetry_node.get_queue().size(), 1, "Evenimentele se înregistrează din nou când telemetria e activată.")
		telemetry_node.clear_queue()


func test_back_button_emits_signal_and_hides() -> void:
	watch_signals(settings_menu)
	settings_menu.show()
	assert_true(settings_menu.visible)
	
	settings_menu.btn_back.pressed.emit()
	assert_signal_emitted(settings_menu, "back_pressed")
	assert_false(settings_menu.visible)
