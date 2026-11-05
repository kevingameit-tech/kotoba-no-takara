extends GutTest
## TouchControls and VirtualJoystick unit tests (Mariana).
## Contract: docs/contracts.md, section 5 (Input Map).
## Issue #42: TouchControls with joystick on move_* actions, deadzone 0.3-0.5, buttons A & B.

var controls: TouchControls


func before_each() -> void:
	controls = load("res://ui/touch_controls.tscn").instantiate()
	controls.auto_detect_mobile = false
	add_child_autofree(controls)


func after_each() -> void:
	if controls != null:
		controls.reset_all()


func test_controls_components_exist() -> void:
	assert_not_null(controls.joystick, "Joystick-ul virtual trebuie să existe.")
	assert_not_null(controls.button_a, "Butonul A (interact) trebuie să existe.")
	assert_not_null(controls.button_b, "Butonul B (cancel) trebuie să existe.")
	assert_not_null(controls.button_menu, "Butonul Menu trebuie să existe.")


func test_joystick_contract_mapping_and_deadzone() -> void:
	var joy: Control = controls.joystick
	assert_eq(joy.get("action_left"), "move_left", "Joystick stânga trebuie mapat pe move_left.")
	assert_eq(joy.get("action_right"), "move_right", "Joystick dreapta trebuie mapat pe move_right.")
	assert_eq(joy.get("action_up"), "move_up", "Joystick sus trebuie mapat pe move_up.")
	assert_eq(joy.get("action_down"), "move_down", "Joystick jos trebuie mapat pe move_down.")
	
	var deadzone: float = joy.get("deadzone_ratio")
	assert_true(deadzone >= 0.3 and deadzone <= 0.5, "Deadzone-ul trebuie să fie între 0.3 și 0.5 (contract secțiunea 5).")


func test_button_a_triggers_interact_action() -> void:
	var btn_a: TouchButton = controls.button_a
	assert_eq(btn_a.action, "interact", "Butonul A trebuie să fie legat la acțiunea 'interact'.")
	
	btn_a._press()
	assert_true(Input.is_action_pressed("interact"), "Apăsarea pe A trebuie să activeze acțiunea 'interact'.")
	
	btn_a._release()
	assert_false(Input.is_action_pressed("interact"), "Eliberarea butonului A trebuie să dezactiveze 'interact'.")


func test_button_b_triggers_cancel_action() -> void:
	var btn_b: TouchButton = controls.button_b
	assert_eq(btn_b.action, "cancel", "Butonul B trebuie să fie legat la acțiunea 'cancel'.")
	
	btn_b._press()
	assert_true(Input.is_action_pressed("cancel"), "Apăsarea pe B trebuie să activeze acțiunea 'cancel'.")
	
	btn_b._release()
	assert_false(Input.is_action_pressed("cancel"), "Eliberarea butonului B trebuie să dezactiveze 'cancel'.")


func test_button_menu_triggers_menu_action() -> void:
	var btn_m: TouchButton = controls.button_menu
	assert_eq(btn_m.action, "menu", "Butonul Menu trebuie să fie legat la acțiunea 'menu'.")
	
	btn_m._press()
	assert_true(Input.is_action_pressed("menu"), "Apăsarea pe Menu activează acțiunea 'menu'.")
	
	btn_m._release()
	assert_false(Input.is_action_pressed("menu"), "Eliberarea butonului Menu dezactivează 'menu'.")


func test_touch_targets_minimum_size() -> void:
	# Definition of Done: Țintele de atingere au cel puțin 48 CSS px.
	var btn_a: TouchButton = controls.button_a
	var btn_b: TouchButton = controls.button_b
	var joy: Control = controls.joystick
	
	assert_true(btn_a.radius * 2.0 >= 48.0, "Diametrul butonului A trebuie să fie de cel puțin 48px.")
	assert_true(btn_b.radius * 2.0 >= 48.0, "Diametrul butonului B trebuie să fie de cel puțin 48px.")
	var joy_size: Vector2 = joy.get("custom_minimum_size")
	assert_true(joy_size.x >= 48.0 and joy_size.y >= 48.0, "Dimensiunea joystick-ului trebuie să fie de cel puțin 48px.")


func test_reset_all_releases_all_actions() -> void:
	controls.button_a._press()
	controls.button_b._press()
	Input.action_press("move_up")
	
	controls.reset_all()
	
	assert_false(Input.is_action_pressed("interact"))
	assert_false(Input.is_action_pressed("cancel"))
	assert_false(Input.is_action_pressed("move_up"))
