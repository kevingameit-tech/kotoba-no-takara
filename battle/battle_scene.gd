class_name BattleScene
extends Control

@export var battle_model: BattleModel

func _ready() -> void:
    # Asigurarea dimensiunii minime a butoanelor la 48px pentru accesibilitate
    setup_accessible_buttons()

func setup_accessible_buttons() -> void:
    # Parcurge butoanele din interfață și setează custom_minimum_size
    for child in get_children():
        if child is Button:
            child.custom_minimum_size = Vector2(48, 48)