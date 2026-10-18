class_name Battler
extends RefCounted

var max_hp: int = 100
var current_hp: int = 100
var attack_power: int = 10
var defense: int = 5
var source_data = null

func initialize_from_data(p_data) -> void:
	source_data = p_data
	if p_data != null:
		if "max_hp" in p_data:
			max_hp = p_data.max_hp
		elif "hp" in p_data:
			max_hp = p_data.hp
		
		current_hp = max_hp
		
		if "attack" in p_data:
			attack_power = p_data.attack
		if "defense" in p_data:
			defense = p_data.defense

func take_damage(amount: int) -> void:
	current_hp = maxi(0, current_hp - amount)

func is_alive() -> bool:
	return current_hp > 0