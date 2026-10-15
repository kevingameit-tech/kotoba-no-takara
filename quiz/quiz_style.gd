class_name QuizStyle
extends RefCounted
## Colours and small builders shared by the screens in quiz/ (the demo and the pre/post test).
## A temporary look until Mariana's Theme in ui/ exists (issue #37); then these screens use it.

const BACKGROUND: Color = Color("14213d")
const BUTTON: Color = Color("25324d")
const RIGHT: Color = Color("2e8f5a")
const WRONG: Color = Color("c2541f")
const TEXT: Color = Color("f4efe6")
const MUTED: Color = Color("a9b3c4")


static func background() -> ColorRect:
	var rect: ColorRect = ColorRect.new()
	rect.color = BACKGROUND
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return rect


static func label(node_name: String, text: String, font_size: int, color: Color = TEXT) -> Label:
	var node: Label = Label.new()
	node.name = node_name
	node.text = text
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	return node


static func button(text: String) -> Button:
	var node: Button = Button.new()
	node.text = text
	node.custom_minimum_size = Vector2(110, 40)
	node.add_theme_font_size_override("font_size", 20)
	for state in ["normal", "pressed", "disabled"]:
		node.add_theme_stylebox_override(state, box(BUTTON))
	node.add_theme_stylebox_override("hover", box(BUTTON.lightened(0.15)))
	node.add_theme_stylebox_override("focus", box(BUTTON.lightened(0.15), TEXT))
	node.add_theme_color_override("font_color", TEXT)
	node.add_theme_color_override("font_disabled_color", TEXT)
	return node


static func box(color: Color, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(6)
	if border.a > 0.0:
		style.border_color = border
		style.set_border_width_all(2)
	return style
