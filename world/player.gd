extends CharacterBody2D
class_name Player

@export var pfoa: Sprite2D

# Viteza de deplasare a caracterului
@export var SPEED = 150.0
@export var SPRINT_SPEED = 150.0
var actionabil :bool = false

func _ready() -> void:
	pfoa.visible = false
	actionabil = false
func _physics_process(_delta):
	var current_speed = SPEED
	# Input.get_vector preia automat tastele (Săgeți sau WASD dacă sunt mapate așa în Project Settings)
	# Ordinea este: stânga, dreapta, sus, jos
	var direction = Input.get_vector("LEFT", "RIGHT", "UP", "DOWN")
	if Input.is_action_pressed("SPRINT"):
		#print("viteza")
		current_speed = SPRINT_SPEED
		
	if direction:
		# Dacă jucătorul apasă o direcție, înmulțim vectorul direcției cu viteza
		velocity = direction * current_speed
	else:
		# Dacă nu apasă nimic, oprim caracterul
		velocity = Vector2.ZERO
	#print (actionabil)
	# move_and_slide() aplică viteza calculată și gestionează automat coliziunile (alunecarea pe lângă pereți)
	move_and_slide()

func intentie() -> void:
	pfoa.visible = actionabil
	
