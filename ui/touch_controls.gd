class_name TouchControls
extends CanvasLayer
## TouchControls: on-screen controls overlay for mobile devices.
## Contract: docs/contracts.md, section 5 (Input Map).
## Issue #42: TouchControls with joystick on move_* actions, deadzone 0.3-0.5, buttons A & B.

@export var auto_detect_mobile: bool = true

var joystick: Control
var button_a: TouchButton
var button_b: TouchButton
var button_menu: TouchButton
var root_control: Control


func _ready() -> void:
	layer = 20
	_build_ui()
	_update_visibility()


func _update_visibility() -> void:
	if auto_detect_mobile:
		visible = DisplayServer.is_touchscreen_available()
	else:
		visible = true


func _build_ui() -> void:
	root_control = Control.new()
	root_control.name = "Root"
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)

	# Built-in VirtualJoystick configured per contract section 5:
	# "The built-in VirtualJoystick starts on the ui_* actions with deadzone 0:
	# set it to the move_* actions and a deadzone of 0.3 to 0.5."
	joystick = ClassDB.instantiate("VirtualJoystick")
	joystick.name = "Joystick"
	joystick.set("action_left", "move_left")
	joystick.set("action_right", "move_right")
	joystick.set("action_up", "move_up")
	joystick.set("action_down", "move_down")
	joystick.set("deadzone_ratio", 0.35)
	joystick.set("custom_minimum_size", Vector2(96, 96))
	joystick.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	joystick.offset_left = 24
	joystick.offset_top = -124
	joystick.offset_right = 120
	joystick.offset_bottom = -28
	root_control.add_child(joystick)

	# Action Buttons at bottom-right (anchored)
	button_a = TouchButton.new()
	button_a.name = "ButtonA"
	button_a.action = "interact"
	button_a.label_text = "A"
	button_a.radius = 26.0
	button_a.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	button_a.offset_left = -80
	button_a.offset_top = -100
	button_a.offset_right = -28
	button_a.offset_bottom = -48
	root_control.add_child(button_a)

	button_b = TouchButton.new()
	button_b.name = "ButtonB"
	button_b.action = "cancel"
	button_b.label_text = "B"
	button_b.radius = 26.0
	button_b.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	button_b.offset_left = -146
	button_b.offset_top = -74
	button_b.offset_right = -94
	button_b.offset_bottom = -22
	root_control.add_child(button_b)

	button_menu = TouchButton.new()
	button_menu.name = "ButtonMenu"
	button_menu.action = "menu"
	button_menu.label_text = "M"
	button_menu.radius = 24.0
	button_menu.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	button_menu.offset_left = -60
	button_menu.offset_top = 16
	button_menu.offset_right = -12
	button_menu.offset_bottom = 64
	root_control.add_child(button_menu)


func reset_all() -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("move_up")
	Input.action_release("move_down")
	if button_a != null:
		button_a.reset()
	if button_b != null:
		button_b.reset()
	if button_menu != null:
		button_menu.reset()
