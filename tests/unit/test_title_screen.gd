extends GutTest
## TitleScreen unit tests (Mariana).
## Conformează docs/contracts.md secțiunea 6 („Settings and UI text keys”) și Definition of Done.
## Issue #56: [ui] v0.1: notă de confidențialitate, versiunea pe titlu, accesibilitate.

var title_screen: TitleScreen
var settings_node: Node


func before_each() -> void:
	settings_node = get_node_or_null("/root/Settings")
	if settings_node != null:
		settings_node.set_language("ro")
		settings_node.set_text_size(0)

	title_screen = load("res://ui/title_screen.tscn").instantiate()
	title_screen.change_scene_on_play = false
	add_child_autofree(title_screen)


func test_components_exist() -> void:
	assert_not_null(title_screen.title_label, "Titlul ecranului trebuie să existe.")
	assert_not_null(title_screen.subtitle_label, "Subtitlul ecranului trebuie să existe.")
	assert_not_null(title_screen.version_label, "Eticheta de versiune trebuie să existe.")
	assert_not_null(title_screen.btn_new_game, "Butonul Joc Nou trebuie să existe.")
	assert_not_null(title_screen.btn_continue, "Butonul Continuă trebuie să existe.")
	assert_not_null(title_screen.btn_settings, "Butonul Setări trebuie să existe.")
	assert_not_null(title_screen.btn_privacy, "Butonul Confidențialitate trebuie să existe.")
	assert_not_null(title_screen.privacy_footer_label, "Subsolul cu nota de confidențialitate trebuie să existe.")
	assert_not_null(title_screen.privacy_dialog, "Dialogul modal de confidențialitate trebuie să existe.")
	assert_not_null(title_screen.settings_menu, "Meniul de setări integrat trebuie să existe.")


func test_version_label_reflects_project_setting() -> void:
	var expected_version: String = "v" + ProjectSettings.get_setting("application/config/version", "0.1.0")
	assert_eq(title_screen.version_label.text, expected_version, "Versiunea afișată trebuie să vină din application/config/version.")
	assert_eq(title_screen.version_label.text, "v0.1.0", "Versiunea curentă v0.1 trebuie să fie v0.1.0.")


func test_accessibility_touch_target_sizes() -> void:
	# Verifică constrângerea de accesibilitate mobilă (minimum 48px înălțime)
	assert_gte(title_screen.btn_new_game.custom_minimum_size.y, 48.0, "Butonul Joc Nou trebuie să aibă cel puțin 48px înălțime.")
	assert_gte(title_screen.btn_continue.custom_minimum_size.y, 48.0, "Butonul Continuă trebuie să aibă cel puțin 48px înălțime.")
	assert_gte(title_screen.btn_settings.custom_minimum_size.y, 48.0, "Butonul Setări trebuie să aibă cel puțin 48px înălțime.")
	assert_gte(title_screen.btn_privacy.custom_minimum_size.y, 48.0, "Butonul Confidențialitate trebuie să aibă cel puțin 48px înălțime.")


func test_language_switch_updates_title_screen_text() -> void:
	# Verificare text în limba română
	settings_node.set_language("ro")
	assert_eq(title_screen.btn_new_game.text, "Joc Nou")
	assert_eq(title_screen.btn_continue.text, "Continuă")
	assert_eq(title_screen.btn_settings.text, "Setări")
	assert_eq(title_screen.btn_privacy.text, "Confidențialitate")
	assert_eq(title_screen.subtitle_label.text, "Aventura Limbii Japoneze")

	# Comutare la limba engleză
	settings_node.set_language("en")
	assert_eq(title_screen.btn_new_game.text, "New Game")
	assert_eq(title_screen.btn_continue.text, "Continue")
	assert_eq(title_screen.btn_settings.text, "Settings")
	assert_eq(title_screen.btn_privacy.text, "Privacy")
	assert_eq(title_screen.subtitle_label.text, "Japanese Language Adventure")


func test_accessibility_large_text_mode() -> void:
	settings_node.set_text_size(0)
	var normal_title_size = title_screen.title_label.get_theme_font_size("font_size")
	var normal_btn_size = title_screen.btn_new_game.get_theme_font_size("font_size")

	settings_node.set_text_size(1)
	var large_title_size = title_screen.title_label.get_theme_font_size("font_size")
	var large_btn_size = title_screen.btn_new_game.get_theme_font_size("font_size")

	assert_gt(large_title_size, normal_title_size, "Titlul trebuie să crească la setarea text_size = 1.")
	assert_gt(large_btn_size, normal_btn_size, "Butoanele trebuie să crească la setarea text_size = 1.")


func test_privacy_notice_bilingual_content() -> void:
	var text: String = title_screen.privacy_dialog.dialog_text
	assert_true(text.contains("RO:"), "Dialogul trebuie să conțină secțiunea în limba română.")
	assert_true(text.contains("EN:"), "Dialogul trebuie să conțină secțiunea în limba engleză.")
	assert_true(text.contains("Nu stocăm date personale"), "Nota RO trebuie să confirme lipsa stocării datelor personale.")
	assert_true(text.contains("We do not store personal data"), "Nota EN trebuie să confirme lipsa stocării datelor personale.")
	assert_true(text.contains("16"), "Nota trebuie să conțină avertismentul pentru persoane sub 16 ani.")


func test_privacy_dialog_flow() -> void:
	watch_signals(title_screen)
	title_screen.btn_privacy.pressed.emit()
	assert_signal_emitted(title_screen, "privacy_opened")
	assert_true(title_screen.privacy_dialog.visible, "Dialogul de confidențialitate trebuie să devină vizibil la apăsarea butonului.")


func test_settings_flow() -> void:
	watch_signals(title_screen)
	assert_false(title_screen.settings_menu.visible)
	title_screen.btn_settings.pressed.emit()
	assert_signal_emitted(title_screen, "settings_opened")
	assert_true(title_screen.settings_menu.visible, "Meniul de setări trebuie să fie deschis.")


func test_play_pressed_signal() -> void:
	watch_signals(title_screen)
	title_screen.btn_new_game.pressed.emit()
	assert_signal_emitted(title_screen, "play_pressed")
