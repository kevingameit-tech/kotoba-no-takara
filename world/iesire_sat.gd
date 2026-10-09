extends Area2D

# Poți alege calea scenei direct din Inspector prin export:
@export_file("*.tscn") var next_scene_path: String
@export var player: Player


var change_lvl : bool = false


func _on_body_entered(body: Node2D) -> void:
	# Verifică dacă corpul care a intrat este chiar jucătorul
	# (poți folosi un grup, de ex. adaugi nodul jucătorului în grupul "player")
	print("Un corp a intrat în zonă: ", body.name)
	
	if body is Player:
		#print("da")
		
		body.actionabil = true
		body.intentie()
		change_lvl = true


func change_level() -> void:
	print("ar trebui sa schimb scena")
	# Schimbă scena curentă cu următoarea
	if next_scene_path != "":
		get_tree().change_scene_to_file(next_scene_path)
	else:
		print("Eroare: Nu ai setat calea către următoarea scenă în Inspector!")


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		print ("corpul a iesit")
		body.actionabil = false
		body.intentie()
		change_lvl = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ACTION") && change_lvl:
		change_level()
