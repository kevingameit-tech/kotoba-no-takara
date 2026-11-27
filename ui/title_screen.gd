class_name TitleScreen
extends Control
## TitleScreen: Ecranul de titlu pentru Kotoba no Takara.
## Conformează docs/contracts.md secțiunea 6 („Settings and UI text keys”) și Definition of Done.
## Issue #56: [ui] v0.1: notă de confidențialitate, versiunea pe titlu, accesibilitate.

signal play_pressed
signal continue_pressed
signal settings_opened
signal privacy_opened

@export var change_scene_on_play: bool = true

const PRIVACY_NOTICE_RO := "Nu stocăm date personale. Jocul trimite doar statistici de joc fără nume pentru îmbunătățirea jocului. Statisticile se pot opri oricând din Setări. Ai sub 16 ani? Întreabă un părinte."
const PRIVACY_NOTICE_EN := "We do not store personal data. The game only sends gameplay statistics without names to improve the game. You can turn them off at any time in Settings. Under 16? Ask a parent."

var background: ColorRect
var main_container: CenterContainer
var panel_container: PanelContainer
var title_label: Label
var subtitle_label: Label
var version_label: Label
var btn_new_game: Button
var btn_continue: Button
var btn_settings: Button
var btn_privacy: Button
var privacy_footer_label: Label
var privacy_dialog: AcceptDialog
var settings_menu: SettingsMenu


func _ready() -> void:
	_build_ui()
	_connect_settings_signals()
	_update_text()
	_apply_text_size()
	_check_save_state()
	
	if btn_new_game != null:
		btn_new_game.grab_focus()


func _connect_settings_signals() -> void:
	var settings_node: Node = get_node_or_null("/root/Settings")
	if settings_node != null:
		if settings_node.has_signal("language_changed") and not settings_node.language_changed.is_connected(_on_language_changed):
			settings_node.language_changed.connect(_on_language_changed)
		if settings_node.has_signal("text_size_changed") and not settings_node.text_size_changed.is_connected(_on_text_size_changed):
			settings_node.text_size_changed.connect(_on_text_size_changed)


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	background = ColorRect.new()
	background.name = "Background"
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.06, 0.08, 0.16, 1.0)
	add_child(background)

	main_container = CenterContainer.new()
	main_container.name = "CenterContainer"
	main_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.add_child(main_container)

	panel_container = PanelContainer.new()
	panel_container.name = "MenuPanel"
	panel_container.custom_minimum_size = Vector2(300, 0)
	main_container.add_child(panel_container)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel_container.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 12)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)

	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "Kotoba no Takara"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_color_override("font_color", Color(0.98, 0.88, 0.42, 1.0))
	vbox.add_child(title_label)

	subtitle_label = Label.new()
	subtitle_label.name = "SubtitleLabel"
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95, 0.9))
	vbox.add_child(subtitle_label)

	version_label = Label.new()
	version_label.name = "VersionLabel"
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version_label.add_theme_color_override("font_color", Color(0.65, 0.70, 0.80, 0.8))
	vbox.add_child(version_label)

	# Buton Joc Nou
	btn_new_game = Button.new()
	btn_new_game.name = "BtnNewGame"
	btn_new_game.custom_minimum_size = Vector2(220, 48)
	btn_new_game.pressed.connect(_on_new_game_pressed)
	vbox.add_child(btn_new_game)

	# Buton Continuă
	btn_continue = Button.new()
	btn_continue.name = "BtnContinue"
	btn_continue.custom_minimum_size = Vector2(220, 48)
	btn_continue.pressed.connect(_on_continue_pressed)
	vbox.add_child(btn_continue)

	# Buton Setări
	btn_settings = Button.new()
	btn_settings.name = "BtnSettings"
	btn_settings.custom_minimum_size = Vector2(220, 48)
	btn_settings.pressed.connect(_on_settings_pressed)
	vbox.add_child(btn_settings)

	# Buton Confidențialitate
	btn_privacy = Button.new()
	btn_privacy.name = "BtnPrivacy"
	btn_privacy.custom_minimum_size = Vector2(220, 48)
	btn_privacy.pressed.connect(_on_privacy_pressed)
	vbox.add_child(btn_privacy)

	# Text notă scurtă confidențialitate în subsol
	privacy_footer_label = Label.new()
	privacy_footer_label.name = "PrivacyFooterLabel"
	privacy_footer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	privacy_footer_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	privacy_footer_label.custom_minimum_size = Vector2(260, 0)
	privacy_footer_label.add_theme_color_override("font_color", Color(0.60, 0.65, 0.75, 0.7))
	vbox.add_child(privacy_footer_label)

	# Dialog modal confidențialitate RO/EN
	privacy_dialog = AcceptDialog.new()
	privacy_dialog.name = "PrivacyDialog"
	privacy_dialog.exclusive = true
	privacy_dialog.ok_button_text = tr("UI_OK")
	add_child(privacy_dialog)

	# Subecran Setări
	settings_menu = load("res://ui/settings_menu.tscn").instantiate()
	settings_menu.hide()
	add_child(settings_menu)
	if settings_menu.has_signal("back_pressed"):
		settings_menu.back_pressed.connect(_on_settings_back)


func _update_text() -> void:
	var raw_version: String = ProjectSettings.get_setting("application/config/version", "0.1.0")
	if version_label != null:
		version_label.text = "v" + raw_version

	if subtitle_label != null:
		subtitle_label.text = tr("MENU_TITLE_SUBTITLE")

	if btn_new_game != null:
		btn_new_game.text = tr("MENU_NEW_GAME")

	if btn_continue != null:
		btn_continue.text = tr("MENU_CONTINUE")

	if btn_settings != null:
		btn_settings.text = tr("MENU_SETTINGS")

	if btn_privacy != null:
		btn_privacy.text = tr("MENU_PRIVACY")

	if privacy_footer_label != null:
		privacy_footer_label.text = tr("UI_PRIVACY_NOTICE")

	if privacy_dialog != null:
		privacy_dialog.title = tr("UI_PRIVACY_TITLE")
		privacy_dialog.ok_button_text = tr("UI_OK")
		privacy_dialog.dialog_text = "Notă de confidențialitate / Privacy Notice:\n\n" + \
			"RO: " + PRIVACY_NOTICE_RO + "\n\n" + \
			"EN: " + PRIVACY_NOTICE_EN


func _apply_text_size() -> void:
	var current_text_size: int = 0
	var settings_node: Node = get_node_or_null("/root/Settings")
	if settings_node != null and "text_size" in settings_node:
		current_text_size = settings_node.text_size

	var is_large := current_text_size == 1

	var title_size := 40 if is_large else 32
	var subtitle_size := 18 if is_large else 14
	var version_size := 15 if is_large else 12
	var button_size := 20 if is_large else 16
	var footer_size := 14 if is_large else 11

	if title_label != null:
		title_label.add_theme_font_size_override("font_size", title_size)

	if subtitle_label != null:
		subtitle_label.add_theme_font_size_override("font_size", subtitle_size)

	if version_label != null:
		version_label.add_theme_font_size_override("font_size", version_size)

	for btn in [btn_new_game, btn_continue, btn_settings, btn_privacy]:
		if btn != null:
			btn.add_theme_font_size_override("font_size", button_size)

	if privacy_footer_label != null:
		privacy_footer_label.add_theme_font_size_override("font_size", footer_size)


func _check_save_state() -> void:
	var save_manager_node: Node = get_node_or_null("/root/SaveManager")
	var has_save: bool = false
	if save_manager_node != null and save_manager_node.has_method("has_save"):
		has_save = save_manager_node.has_save()

	if btn_continue != null:
		btn_continue.disabled = not has_save


func _on_language_changed(_code: String) -> void:
	_update_text()


func _on_text_size_changed(_size: int) -> void:
	_apply_text_size()


func _on_new_game_pressed() -> void:
	play_pressed.emit()
	if change_scene_on_play and is_inside_tree() and ResourceLoader.exists("res://quiz/quiz_demo.tscn"):
		get_tree().change_scene_to_file("res://quiz/quiz_demo.tscn")


func _on_continue_pressed() -> void:
	continue_pressed.emit()
	var save_manager_node: Node = get_node_or_null("/root/SaveManager")
	if save_manager_node != null and save_manager_node.has_method("load_game"):
		save_manager_node.load_game()
	if change_scene_on_play and is_inside_tree() and ResourceLoader.exists("res://quiz/quiz_demo.tscn"):
		get_tree().change_scene_to_file("res://quiz/quiz_demo.tscn")


func _on_settings_pressed() -> void:
	settings_opened.emit()
	if settings_menu != null:
		if settings_menu.has_method("open"):
			settings_menu.open()
		else:
			settings_menu.show()


func _on_settings_back() -> void:
	if btn_settings != null:
		btn_settings.grab_focus()


func _on_privacy_pressed() -> void:
	privacy_opened.emit()
	if privacy_dialog != null:
		privacy_dialog.popup_centered(Vector2i(460, 240))
