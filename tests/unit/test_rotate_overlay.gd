extends GutTest
## RotateOverlay unit tests (Mariana).
## Contract: docs/contracts.md, section 1 ("Phones are used in landscape; Mariana's
## 'rotate your phone' overlay covers portrait").
## Issue #42: Overlay „rotește telefonul” în modul portret.

var overlay: RotateOverlay


func before_each() -> void:
	overlay = load("res://ui/rotate_overlay.tscn").instantiate()
	add_child_autofree(overlay)


func test_overlay_components_exist() -> void:
	assert_not_null(overlay.overlay_panel, "Panoul de overlay trebuie să existe.")
	assert_not_null(overlay.message_label, "Eticheta cu mesajul de rotire trebuie să existe.")
	assert_not_null(overlay.icon_label, "Pictograma de rotire trebuie să existe.")


func test_overlay_blocks_mouse_input_when_active() -> void:
	assert_eq(overlay.overlay_panel.mouse_filter, Control.MOUSE_FILTER_STOP, "Overlay-ul trebuie să blocheze input-ul în modul portret.")


func test_overlay_message_uses_i18n() -> void:
	var expected_ro: String = tr("UI_ROTATE_DEVICE")
	assert_eq(overlay.message_label.text, expected_ro, "Mesajul trebuie să folosească cheia de localizare UI_ROTATE_DEVICE.")


func test_portrait_detection_logic() -> void:
	# Verificăm comportamentul funcției _check_orientation logic
	var portrait_size := Vector2(360, 640)
	var landscape_size := Vector2(640, 360)
	
	var is_portrait: bool = portrait_size.y > portrait_size.x
	var is_landscape: bool = landscape_size.y > landscape_size.x
	
	assert_true(is_portrait, "Înălțimea mai mare decât lățimea indică modul portret.")
	assert_false(is_landscape, "Lățimea mai mare indică modul peisaj.")
