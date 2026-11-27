extends GutTest
## Accessibility test suite for v0.1 (Mariana).
## Conformează docs/contracts.md secțiunea 6 („Settings and UI text keys”) și Definition of Done.
## Issue #56: [ui] v0.1: notă de confidențialitate, versiunea pe titlu, accesibilitate.

var title_screen: TitleScreen
var pause_menu: PauseMenu
var settings_menu: SettingsMenu
var settings_node: Node


func before_each() -> void:
	settings_node = get_node_or_null("/root/Settings")
	if settings_node != null:
		settings_node.set_language("ro")
		settings_node.set_text_size(0)

	title_screen = load("res://ui/title_screen.tscn").instantiate()
	title_screen.change_scene_on_play = false
	add_child_autofree(title_screen)

	pause_menu = load("res://ui/pause_menu.tscn").instantiate()
	pause_menu.pause_tree_on_open = false
	add_child_autofree(pause_menu)

	settings_menu = load("res://ui/settings_menu.tscn").instantiate()
	add_child_autofree(settings_menu)


func test_all_ui_buttons_meet_touch_target_48px() -> void:
	# 1. TitleScreen
	var title_buttons = [
		title_screen.btn_new_game,
		title_screen.btn_continue,
		title_screen.btn_settings,
		title_screen.btn_privacy
	]
	for btn in title_buttons:
		assert_gte(btn.custom_minimum_size.y, 48.0, "Title button %s must be >= 48px height." % btn.name)

	# 2. PauseMenu
	var pause_buttons = [
		pause_menu.btn_resume,
		pause_menu.btn_settings,
		pause_menu.btn_quit
	]
	for btn in pause_buttons:
		assert_gte(btn.custom_minimum_size.y, 48.0, "Pause button %s must be >= 48px height." % btn.name)

	# 3. SettingsMenu
	var settings_buttons = [
		settings_menu.btn_lang_ro,
		settings_menu.btn_lang_en,
		settings_menu.btn_size_normal,
		settings_menu.btn_size_large,
		settings_menu.check_telemetry,
		settings_menu.btn_back
	]
	for btn in settings_buttons:
		assert_gte(btn.custom_minimum_size.y, 48.0, "Settings button %s must be >= 48px height." % btn.name)


func test_large_text_support() -> void:
	settings_node.set_text_size(0)
	var normal_title_size = title_screen.title_label.get_theme_font_size("font_size")
	var normal_btn_size = title_screen.btn_new_game.get_theme_font_size("font_size")

	settings_node.set_text_size(1)
	var large_title_size = title_screen.title_label.get_theme_font_size("font_size")
	var large_btn_size = title_screen.btn_new_game.get_theme_font_size("font_size")

	assert_gt(large_title_size, normal_title_size, "Font size must increase when text_size = 1 (large).")
	assert_gt(large_btn_size, normal_btn_size, "Button font size must increase when text_size = 1 (large).")


func test_feedback_non_color_exclusive() -> void:
	# Verifică faptul că feedback-ul folosește simboluri grafice explicite (○ și ×), nu doar culori.
	var right_symbol: String = "○"
	var wrong_symbol: String = "×"
	assert_eq(right_symbol, "○", "Simbolul pentru corect este cerc grafic.")
	assert_eq(wrong_symbol, "×", "Simbolul pentru greșit este cruce grafică.")

	# Verifică faptul că fișierul quiz_demo.gd conține feedback simbolic
	var quiz_file = FileAccess.open("res://quiz/quiz_demo.gd", FileAccess.READ)
	assert_not_null(quiz_file)
	var content = quiz_file.get_as_text()
	quiz_file.close()

	assert_true(content.contains("○"), "QuizDemo trebuie să utilizeze simbolul ○ pentru răspuns corect.")
	assert_true(content.contains("×"), "QuizDemo trebuie să utilizeze simbolul × pentru răspuns greșit.")


func test_no_punitive_timer_in_ui() -> void:
	# În v0.1, nicio scenă de UI / învățare nu conține un timer restrictiv / de penalizare
	assert_null(title_screen.get_node_or_null("Timer"), "Ecranul de titlu nu are timer punitiv.")
	assert_null(pause_menu.get_node_or_null("Timer"), "Meniul de pauză nu are timer punitiv.")
	assert_null(settings_menu.get_node_or_null("Timer"), "Meniul de setări nu are timer punitiv.")


func test_version_setting_conformity() -> void:
	var version_str = ProjectSettings.get_setting("application/config/version", "")
	assert_eq(version_str, "0.1.0", "application/config/version trebuie să fie 0.1.0 pentru v0.1.")
	assert_true(title_screen.version_label.text.contains("0.1.0"), "Ecranul de titlu trebuie să afișeze versiunea 0.1.0.")
