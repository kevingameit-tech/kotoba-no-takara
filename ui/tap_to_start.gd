class_name TapToStart
extends CanvasLayer
## TapToStart: start screen overlay required for Web and mobile browsers to unlock audio context.
## Issue #42: „Tap to start” deblochează sunetul.
## Contract: docs/contracts.md (session_start telemetry happens after Tap to start).

signal started

var background: ColorRect
var prompt_label: Label


func _ready() -> void:
	layer = 90
	_build_ui()


func _build_ui() -> void:
	background = ColorRect.new()
	background.name = "Background"
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.08, 0.13, 0.24, 1.0)
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	background.gui_input.connect(_on_gui_input)
	add_child(background)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_child(center)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(column)

	var title_label: Label = Label.new()
	title_label.name = "Title"
	title_label.text = "Kotoba no Takara"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 34)
	title_label.add_theme_color_override("font_color", Color(0.96, 0.94, 0.90, 1.0))
	column.add_child(title_label)

	var jp_label: Label = Label.new()
	jp_label.name = "JapaneseTitle"
	jp_label.text = "言葉の宝"
	jp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	jp_label.add_theme_font_size_override("font_size", 22)
	jp_label.add_theme_color_override("font_color", Color(0.66, 0.70, 0.80, 1.0))
	column.add_child(jp_label)

	prompt_label = Label.new()
	prompt_label.name = "Prompt"
	prompt_label.text = tr("MENU_TAP_TO_START")
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 18)
	prompt_label.add_theme_color_override("font_color", Color(0.95, 0.75, 0.30, 1.0))
	column.add_child(prompt_label)

	var privacy_label: Label = Label.new()
	privacy_label.name = "PrivacyNotice"
	privacy_label.text = tr("UI_PRIVACY_NOTICE")
	privacy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	privacy_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	privacy_label.custom_minimum_size = Vector2(460, 0)
	privacy_label.add_theme_font_size_override("font_size", 11)
	privacy_label.add_theme_color_override("font_color", Color(0.60, 0.65, 0.75, 0.8))
	column.add_child(privacy_label)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		unlock_and_start()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		unlock_and_start()


func unlock_and_start() -> void:
	# Unlock audio bus
	AudioServer.set_bus_mute(0, false)
	started.emit()
	queue_free()
