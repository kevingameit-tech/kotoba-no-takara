class_name RotateOverlay
extends CanvasLayer
## RotateOverlay: displays a rotation prompt when the phone is held in portrait mode.
## Contract: docs/contracts.md, section 1 ("Phones are used in landscape; Mariana's
## 'rotate your phone' overlay covers portrait").
## Issue #42: Overlay „rotește telefonul” în modul portret.

var overlay_panel: ColorRect
var message_label: Label
var icon_label: Label


func _ready() -> void:
	layer = 100
	_build_ui()
	get_viewport().size_changed.connect(_check_orientation)
	_check_orientation()


func _build_ui() -> void:
	overlay_panel = ColorRect.new()
	overlay_panel.name = "Background"
	overlay_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay_panel.color = Color(0.08, 0.13, 0.24, 0.96)
	overlay_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay_panel)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay_panel.add_child(center)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(column)

	icon_label = Label.new()
	icon_label.name = "Icon"
	icon_label.text = "📱 ⟳"
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.add_theme_font_size_override("font_size", 48)
	column.add_child(icon_label)

	message_label = Label.new()
	message_label.name = "Message"
	message_label.text = tr("UI_ROTATE_DEVICE")
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.custom_minimum_size = Vector2(280, 0)
	message_label.add_theme_font_size_override("font_size", 16)
	message_label.add_theme_color_override("font_color", Color(0.96, 0.94, 0.90, 1.0))
	column.add_child(message_label)


func _check_orientation() -> void:
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var is_portrait: bool = vp_size.y > vp_size.x
	visible = is_portrait
