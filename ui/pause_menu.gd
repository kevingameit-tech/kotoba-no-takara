class_name PauseMenu
extends CanvasLayer
## PauseMenu: Meniul de pauză activat pe tasta Escape / butonul Menu de pe telefon.
## Conformează docs/contracts.md secțiunile 5 („Input Map”) și 6 („Settings and UI text keys”).
## Issue #52: [ui] Pauză și Setări: limbă, volum, mărimea textului, opt-out.

signal resumed
signal settings_opened
signal quit_pressed

@export var pause_tree_on_open: bool = true

var background: ColorRect
var panel_container: PanelContainer
var title_label: Label
var btn_resume: Button
var btn_settings: Button
var btn_quit: Button
var settings_menu: SettingsMenu


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 50
	_build_ui()
	_update_text()
	_connect_settings_signals()


func _connect_settings_signals() -> void:
	var settings_node: Node = get_node_or_null("/root/Settings")
	if settings_node != null and settings_node.has_signal("language_changed"):
		if not settings_node.language_changed.is_connected(_on_language_changed):
			settings_node.language_changed.connect(_on_language_changed)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("menu") or event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		if settings_menu != null and settings_menu.visible:
			settings_menu.hide()
		else:
			resume()


func _build_ui() -> void:
	background = ColorRect.new()
	background.name = "Background"
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.04, 0.06, 0.12, 0.85)
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(background)

	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.add_child(center)

	panel_container = PanelContainer.new()
	panel_container.name = "PausePanel"
	panel_container.custom_minimum_size = Vector2(260, 0)
	center.add_child(panel_container)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel_container.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)

	title_label = Label.new()
	title_label.name = "Title"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color(0.96, 0.94, 0.90, 1.0))
	vbox.add_child(title_label)

	# Buton Continuă
	btn_resume = Button.new()
	btn_resume.name = "BtnResume"
	btn_resume.custom_minimum_size = Vector2(180, 48)
	btn_resume.pressed.connect(resume)
	vbox.add_child(btn_resume)

	# Buton Setări
	btn_settings = Button.new()
	btn_settings.name = "BtnSettings"
	btn_settings.custom_minimum_size = Vector2(180, 48)
	btn_settings.pressed.connect(_on_settings_pressed)
	vbox.add_child(btn_settings)

	# Buton Ieșire
	btn_quit = Button.new()
	btn_quit.name = "BtnQuit"
	btn_quit.custom_minimum_size = Vector2(180, 48)
	btn_quit.pressed.connect(_on_quit_pressed)
	vbox.add_child(btn_quit)

	# Ecranul de Setări integrat
	settings_menu = SettingsMenu.new()
	settings_menu.name = "SettingsMenu"
	settings_menu.hide()
	settings_menu.back_pressed.connect(_on_settings_back)
	add_child(settings_menu)


func _update_text() -> void:
	title_label.text = tr("MENU_PAUSE")
	btn_resume.text = tr("MENU_CONTINUE")
	btn_settings.text = tr("MENU_SETTINGS")
	btn_quit.text = tr("MENU_QUIT")


func _on_language_changed(_code: String) -> void:
	_update_text()


func open() -> void:
	show()
	if pause_tree_on_open:
		get_tree().paused = true
	btn_resume.grab_focus()


func resume() -> void:
	if pause_tree_on_open:
		get_tree().paused = false
	resumed.emit()
	hide()


func _on_settings_pressed() -> void:
	settings_opened.emit()
	if settings_menu != null:
		settings_menu.show()


func _on_settings_back() -> void:
	if settings_menu != null:
		settings_menu.hide()
	btn_settings.grab_focus()


func _on_quit_pressed() -> void:
	if pause_tree_on_open:
		get_tree().paused = false
	quit_pressed.emit()
