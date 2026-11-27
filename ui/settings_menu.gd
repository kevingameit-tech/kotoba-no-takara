class_name SettingsMenu
extends CanvasLayer
## SettingsMenu: Ecranul de setări pentru limbă, volum, mărimea textului și opt-out telemetrie.
## Conformează docs/contracts.md secțiunea 6 („Settings and UI text keys”).
## Issue #52: [ui] Pauză și Setări: limbă, volum, mărimea textului, opt-out.

signal back_pressed

var background: ColorRect
var panel_container: PanelContainer
var title_label: Label
var lang_title_label: Label
var btn_lang_ro: Button
var btn_lang_en: Button
var music_title_label: Label
var slider_music: HSlider
var music_val_label: Label
var sfx_title_label: Label
var slider_sfx: HSlider
var sfx_val_label: Label
var iphone_audio_hint_label: Label
var text_size_title_label: Label
var btn_size_normal: Button
var btn_size_large: Button
var check_telemetry: CheckButton
var telemetry_desc_label: Label
var btn_back: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 60
	_build_ui()
	_load_current_values()
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
	if event.is_action_pressed("cancel") or event.is_action_pressed("menu"):
		get_viewport().set_input_as_handled()
		_on_back_pressed()


func _build_ui() -> void:
	background = ColorRect.new()
	background.name = "Background"
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.06, 0.09, 0.16, 0.92)
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(background)

	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.add_child(center)

	panel_container = PanelContainer.new()
	panel_container.name = "SettingsPanel"
	panel_container.custom_minimum_size = Vector2(380, 0)
	center.add_child(panel_container)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel_container.add_child(margin)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 12)
	margin.add_child(main_vbox)

	# Titlu
	title_label = Label.new()
	title_label.name = "Title"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 22)
	main_vbox.add_child(title_label)

	# 1. Secțiunea Limbă
	var lang_box := VBoxContainer.new()
	lang_box.add_theme_constant_override("separation", 4)
	main_vbox.add_child(lang_box)

	lang_title_label = Label.new()
	lang_title_label.name = "LangTitle"
	lang_title_label.add_theme_font_size_override("font_size", 14)
	lang_box.add_child(lang_title_label)

	var lang_btn_box := HBoxContainer.new()
	lang_btn_box.add_theme_constant_override("separation", 12)
	lang_box.add_child(lang_btn_box)

	btn_lang_ro = Button.new()
	btn_lang_ro.name = "BtnLangRO"
	btn_lang_ro.toggle_mode = true
	btn_lang_ro.custom_minimum_size = Vector2(80, 48)
	btn_lang_ro.pressed.connect(_on_lang_ro_pressed)
	lang_btn_box.add_child(btn_lang_ro)

	btn_lang_en = Button.new()
	btn_lang_en.name = "BtnLangEN"
	btn_lang_en.toggle_mode = true
	btn_lang_en.custom_minimum_size = Vector2(80, 48)
	btn_lang_en.pressed.connect(_on_lang_en_pressed)
	lang_btn_box.add_child(btn_lang_en)

	# 2. Secțiunea Volum Muzică
	var music_box := VBoxContainer.new()
	music_box.add_theme_constant_override("separation", 4)
	main_vbox.add_child(music_box)

	var music_header := HBoxContainer.new()
	music_box.add_child(music_header)

	music_title_label = Label.new()
	music_title_label.name = "MusicTitle"
	music_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	music_header.add_child(music_title_label)

	music_val_label = Label.new()
	music_val_label.name = "MusicValue"
	music_val_label.custom_minimum_size = Vector2(48, 0)
	music_val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	music_header.add_child(music_val_label)

	slider_music = HSlider.new()
	slider_music.name = "SliderMusic"
	slider_music.min_value = 0.0
	slider_music.max_value = 1.0
	slider_music.step = 0.05
	slider_music.custom_minimum_size = Vector2(0, 32)
	slider_music.value_changed.connect(_on_music_slider_changed)
	music_box.add_child(slider_music)

	# 3. Secțiunea Volum SFX
	var sfx_box := VBoxContainer.new()
	sfx_box.add_theme_constant_override("separation", 4)
	main_vbox.add_child(sfx_box)

	var sfx_header := HBoxContainer.new()
	sfx_box.add_child(sfx_header)

	sfx_title_label = Label.new()
	sfx_title_label.name = "SfxTitle"
	sfx_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sfx_header.add_child(sfx_title_label)

	sfx_val_label = Label.new()
	sfx_val_label.name = "SfxValue"
	sfx_val_label.custom_minimum_size = Vector2(48, 0)
	sfx_val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	sfx_header.add_child(sfx_val_label)

	slider_sfx = HSlider.new()
	slider_sfx.name = "SliderSfx"
	slider_sfx.min_value = 0.0
	slider_sfx.max_value = 1.0
	slider_sfx.step = 0.05
	slider_sfx.custom_minimum_size = Vector2(0, 32)
	slider_sfx.value_changed.connect(_on_sfx_slider_changed)
	sfx_box.add_child(slider_sfx)

	iphone_audio_hint_label = Label.new()
	iphone_audio_hint_label.name = "IPhoneAudioHint"
	iphone_audio_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	iphone_audio_hint_label.add_theme_font_size_override("font_size", 10)
	iphone_audio_hint_label.add_theme_color_override("font_color", Color(0.70, 0.72, 0.80, 0.75))
	sfx_box.add_child(iphone_audio_hint_label)

	# 4. Secțiunea Mărimea Textului
	var size_box := VBoxContainer.new()
	size_box.add_theme_constant_override("separation", 4)
	main_vbox.add_child(size_box)

	text_size_title_label = Label.new()
	text_size_title_label.name = "TextSizeTitle"
	text_size_title_label.add_theme_font_size_override("font_size", 14)
	size_box.add_child(text_size_title_label)

	var size_btn_box := HBoxContainer.new()
	size_btn_box.add_theme_constant_override("separation", 12)
	size_box.add_child(size_btn_box)

	btn_size_normal = Button.new()
	btn_size_normal.name = "BtnSizeNormal"
	btn_size_normal.toggle_mode = true
	btn_size_normal.custom_minimum_size = Vector2(90, 48)
	btn_size_normal.pressed.connect(_on_size_normal_pressed)
	size_btn_box.add_child(btn_size_normal)

	btn_size_large = Button.new()
	btn_size_large.name = "BtnSizeLarge"
	btn_size_large.toggle_mode = true
	btn_size_large.custom_minimum_size = Vector2(90, 48)
	btn_size_large.pressed.connect(_on_size_large_pressed)
	size_btn_box.add_child(btn_size_large)

	# 5. Secțiunea Telemetrie (Opt-out)
	var telemetry_box := VBoxContainer.new()
	telemetry_box.add_theme_constant_override("separation", 2)
	main_vbox.add_child(telemetry_box)

	check_telemetry = CheckButton.new()
	check_telemetry.name = "CheckTelemetry"
	check_telemetry.custom_minimum_size = Vector2(0, 48)
	check_telemetry.toggled.connect(_on_telemetry_toggled)
	telemetry_box.add_child(check_telemetry)

	telemetry_desc_label = Label.new()
	telemetry_desc_label.name = "TelemetryDesc"
	telemetry_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	telemetry_desc_label.add_theme_font_size_override("font_size", 11)
	telemetry_desc_label.add_theme_color_override("font_color", Color(0.65, 0.70, 0.80, 0.85))
	telemetry_box.add_child(telemetry_desc_label)

	# 6. Buton Înapoi
	btn_back = Button.new()
	btn_back.name = "BtnBack"
	btn_back.custom_minimum_size = Vector2(120, 48)
	btn_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_back.pressed.connect(_on_back_pressed)
	main_vbox.add_child(btn_back)


func _load_current_values() -> void:
	var settings_node: Node = get_node_or_null("/root/Settings")
	if settings_node != null:
		slider_music.value = float(settings_node.music_volume)
		slider_sfx.value = float(settings_node.sfx_volume)
		check_telemetry.button_pressed = bool(settings_node.telemetry_enabled)
		_update_lang_buttons_state(str(settings_node.lang))
		_update_text_size_buttons_state(int(settings_node.text_size))
	else:
		slider_music.value = 1.0
		slider_sfx.value = 1.0
		check_telemetry.button_pressed = true
		_update_lang_buttons_state("ro")
		_update_text_size_buttons_state(0)
	
	music_val_label.text = "%d%%" % int(slider_music.value * 100)
	sfx_val_label.text = "%d%%" % int(slider_sfx.value * 100)


## Actualizează dinamic toate textele din interfață la comutarea limbii (RO <-> EN)
func _update_text() -> void:
	title_label.text = tr("MENU_SETTINGS")
	lang_title_label.text = tr("MENU_LANGUAGE")
	btn_lang_ro.text = tr("MENU_LANG_RO")
	btn_lang_en.text = tr("MENU_LANG_EN")
	music_title_label.text = tr("MENU_MUSIC_VOLUME")
	sfx_title_label.text = tr("MENU_SFX_VOLUME")
	text_size_title_label.text = tr("MENU_TEXT_SIZE")
	btn_size_normal.text = tr("MENU_TEXT_SIZE_NORMAL")
	btn_size_large.text = tr("MENU_TEXT_SIZE_LARGE")
	check_telemetry.text = tr("MENU_TELEMETRY")
	telemetry_desc_label.text = tr("MENU_TELEMETRY_DESC")
	btn_back.text = tr("UI_BACK")
	if iphone_audio_hint_label != null:
		iphone_audio_hint_label.text = tr("UI_IPHONE_SILENT_HINT")


func _update_lang_buttons_state(current_lang: String) -> void:
	btn_lang_ro.button_pressed = (current_lang == "ro")
	btn_lang_en.button_pressed = (current_lang == "en")
	if current_lang == "ro":
		btn_lang_ro.add_theme_color_override("font_color", Color(0.95, 0.75, 0.30, 1.0))
		btn_lang_en.remove_theme_color_override("font_color")
	else:
		btn_lang_en.add_theme_color_override("font_color", Color(0.95, 0.75, 0.30, 1.0))
		btn_lang_ro.remove_theme_color_override("font_color")


func _update_text_size_buttons_state(current_size: int) -> void:
	btn_size_normal.button_pressed = (current_size == 0)
	btn_size_large.button_pressed = (current_size == 1)
	if current_size == 0:
		btn_size_normal.add_theme_color_override("font_color", Color(0.95, 0.75, 0.30, 1.0))
		btn_size_large.remove_theme_color_override("font_color")
	else:
		btn_size_large.add_theme_color_override("font_color", Color(0.95, 0.75, 0.30, 1.0))
		btn_size_normal.remove_theme_color_override("font_color")


func _on_language_changed(code: String) -> void:
	_update_text()
	_update_lang_buttons_state(code)


func _on_lang_ro_pressed() -> void:
	var settings_node: Node = get_node_or_null("/root/Settings")
	if settings_node != null:
		settings_node.set_language("ro")
	else:
		_on_language_changed("ro")


func _on_lang_en_pressed() -> void:
	var settings_node: Node = get_node_or_null("/root/Settings")
	if settings_node != null:
		settings_node.set_language("en")
	else:
		_on_language_changed("en")


func _on_music_slider_changed(val: float) -> void:
	music_val_label.text = "%d%%" % int(val * 100)
	var settings_node: Node = get_node_or_null("/root/Settings")
	if settings_node != null:
		settings_node.set_music_volume(val)


func _on_sfx_slider_changed(val: float) -> void:
	sfx_val_label.text = "%d%%" % int(val * 100)
	var settings_node: Node = get_node_or_null("/root/Settings")
	if settings_node != null:
		settings_node.set_sfx_volume(val)


func _on_size_normal_pressed() -> void:
	var settings_node: Node = get_node_or_null("/root/Settings")
	if settings_node != null:
		settings_node.set_text_size(0)
	_update_text_size_buttons_state(0)


func _on_size_large_pressed() -> void:
	var settings_node: Node = get_node_or_null("/root/Settings")
	if settings_node != null:
		settings_node.set_text_size(1)
	_update_text_size_buttons_state(1)


func _on_telemetry_toggled(enabled: bool) -> void:
	var settings_node: Node = get_node_or_null("/root/Settings")
	if settings_node != null:
		settings_node.set_telemetry_enabled(enabled)


func _on_back_pressed() -> void:
	back_pressed.emit()
	hide()
