class_name TouchButton
extends Control
## TouchButton: on-screen touch action button (e.g. A, B, Menu) for mobile play.
## Contract: docs/contracts.md, section 5 (Input Map).
## Issue #42: TouchControls with buttons A (interact) and B (cancel).
## Target size has at least 48 CSS px (DEFINITION_OF_DONE).

@export var action: String = "interact"
@export var label_text: String = "A"
@export var radius: float = 26.0

var _touch_id: int = -1
var _is_pressed: bool = false


func _ready() -> void:
	custom_minimum_size = Vector2(radius * 2, radius * 2)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if _touch_id == -1:
				_touch_id = event.index
				_press()
				accept_event()
		elif event.index == _touch_id:
			_release()
			accept_event()
	elif event is InputEventMouseButton and not event.is_echo():
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if _touch_id == -1:
					_touch_id = 999
					_press()
					accept_event()
			elif _touch_id == 999:
				_release()
				accept_event()


func _press() -> void:
	_is_pressed = true
	Input.action_press(action)
	queue_redraw()


func _release() -> void:
	_is_pressed = false
	_touch_id = -1
	Input.action_release(action)
	queue_redraw()


func reset() -> void:
	if _is_pressed:
		_release()


func _draw() -> void:
	var center: Vector2 = size * 0.5
	var bg_color: Color = Color(0.20, 0.55, 0.40, 0.85) if _is_pressed else Color(0.15, 0.20, 0.30, 0.70)
	var border_color: Color = Color(1.0, 1.0, 1.0, 0.9) if _is_pressed else Color(0.95, 0.93, 0.90, 0.6)
	
	draw_circle(center, radius, bg_color)
	draw_arc(center, radius, 0, TAU, 32, border_color, 2.0)
	
	var font: Font = ThemeDB.fallback_font
	var default_theme: Theme = get_theme()
	if default_theme != null and default_theme.default_font != null:
		font = default_theme.default_font
		
	var font_size: int = 18
	var text_size: Vector2 = font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var text_pos: Vector2 = Vector2(center.x - text_size.x * 0.5, center.y + text_size.y * 0.35)
	draw_string(font, text_pos, label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(0.96, 0.94, 0.90, 1.0))
