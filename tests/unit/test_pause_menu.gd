extends GutTest
## PauseMenu unit tests (Mariana).
## Conformează docs/contracts.md secțiunile 5 („Input Map”) și 6 („Settings and UI text keys”).
## Issue #52: [ui] Pauză și Setări: limbă, volum, mărimea textului, opt-out.

var pause_menu: PauseMenu
var settings_node: Node


func before_each() -> void:
	settings_node = get_node_or_null("/root/Settings")
	if settings_node != null:
		settings_node.set_language("ro")
	
	pause_menu = load("res://ui/pause_menu.tscn").instantiate()
	pause_menu.pause_tree_on_open = false # Dezactivăm pauza arborelui în teste pentru a nu bloca runner-ul GUT
	add_child_autofree(pause_menu)


func test_components_exist() -> void:
	assert_not_null(pause_menu.title_label, "Titlul meniului de pauză trebuie să existe.")
	assert_not_null(pause_menu.btn_resume, "Butonul Continuă trebuie să existe.")
	assert_not_null(pause_menu.btn_settings, "Butonul Setări trebuie să existe.")
	assert_not_null(pause_menu.btn_quit, "Butonul Ieșire trebuie să existe.")
	assert_not_null(pause_menu.settings_menu, "Ecranul de setări integrat trebuie să existe.")


func test_accessibility_touch_target_sizes() -> void:
	# Verifică constrângerea de accesibilitate mobilă (minimum 48px înălțime)
	assert_gte(pause_menu.btn_resume.custom_minimum_size.y, 48.0)
	assert_gte(pause_menu.btn_settings.custom_minimum_size.y, 48.0)
	assert_gte(pause_menu.btn_quit.custom_minimum_size.y, 48.0)


func test_language_switch_updates_pause_menu_text() -> void:
	# Verificare text în limba română
	settings_node.set_language("ro")
	assert_eq(pause_menu.title_label.text, "Pauză")
	assert_eq(pause_menu.btn_resume.text, "Continuă")
	assert_eq(pause_menu.btn_settings.text, "Setări")
	assert_eq(pause_menu.btn_quit.text, "Ieșire")
	
	# Comutare la limba engleză
	settings_node.set_language("en")
	assert_eq(pause_menu.title_label.text, "Pause")
	assert_eq(pause_menu.btn_resume.text, "Continue")
	assert_eq(pause_menu.btn_settings.text, "Settings")
	assert_eq(pause_menu.btn_quit.text, "Quit")


func test_open_and_resume_flow() -> void:
	watch_signals(pause_menu)
	pause_menu.hide()
	assert_false(pause_menu.visible)
	
	pause_menu.open()
	assert_true(pause_menu.visible)
	
	pause_menu.btn_resume.pressed.emit()
	assert_signal_emitted(pause_menu, "resumed")
	assert_false(pause_menu.visible)


func test_settings_subscreen_navigation() -> void:
	watch_signals(pause_menu)
	pause_menu.open()
	assert_false(pause_menu.settings_menu.visible)
	
	# Deschidem ecranul de setări din meniul de pauză
	pause_menu.btn_settings.pressed.emit()
	assert_signal_emitted(pause_menu, "settings_opened")
	assert_true(pause_menu.settings_menu.visible)
	
	# Apăsăm Înapoi în setări
	pause_menu.settings_menu.btn_back.pressed.emit()
	assert_false(pause_menu.settings_menu.visible)
	assert_true(pause_menu.visible, "Meniul de pauză rămâne vizibil după închiderea setărilor.")


func test_quit_signal() -> void:
	watch_signals(pause_menu)
	pause_menu.open()
	pause_menu.btn_quit.pressed.emit()
	assert_signal_emitted(pause_menu, "quit_pressed")
