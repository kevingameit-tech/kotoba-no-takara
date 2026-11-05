class_name Battler
extends RefCounted

## Gestionează statisticile temporare ale unui combatant (jucător sau inamic)
## cu suport pentru daune deterministe (bazate pe seed) și limite stricte de HP (bounds).

var max_hp: int = 100
var current_hp: int = 100
var attack_power: int = 10
var defense: int = 5
var source_data = null

# Generator de numere aleatoare dedicat pentru daune deterministe
var rng: RandomNumberGenerator = RandomNumberGenerator.new()


## Inițializează statisticile copiind datele dintr-o resursă sau un dicționar
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


## Setează un seed fix pentru a asigura daune deterministe
func set_damage_seed(p_seed: int) -> void:
	rng.seed = p_seed


## Calculează daunele folosind RNG-ul cu seed și aplică limitele de HP (bounds)
func calculate_and_take_damage(attacker_attack: int) -> int:
	# Calculăm o bază de daune (cel puțin 1)
	var base_damage = maxi(1, attacker_attack - defense)
	
	# Generăm o variație folosind seed-ul fixat
	var variance = rng.randi_range(-2, 2)
	var final_damage = maxi(1, base_damage + variance)
	
	# Aplicăm daunele folosind clampi pentru a nu ieși niciodată din intervalul [0, max_hp]
	current_hp = clampi(current_hp - final_damage, 0, max_hp)
	return final_damage


## Aplică daune directe respectând limitele de HP
func take_damage(amount: int) -> void:
	current_hp = clampi(current_hp - amount, 0, max_hp)


## Verifică dacă combatantul este în viață
func is_alive() -> bool:
	return current_hp > 0