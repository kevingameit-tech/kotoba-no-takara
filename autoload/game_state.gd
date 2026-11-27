extends Node
## GameState (autoload): ține starea jocului care este salvată în user://save.json.
## Conformează docs/contracts.md secțiunea 12 („Save schema”) și Issue #44 / #53.
## Proprietar: Mariana.

signal state_loaded
signal state_reset

const DEFAULT_MAP: String = "res://world/maps/tokyo_town.tscn"
const DEFAULT_HP: int = 20
const DEFAULT_MAX_HP: int = 20

# World fields (David)
var map: String = DEFAULT_MAP
var cell: Vector2i = Vector2i(0, 0)
var facing: Vector2i = Vector2i(0, 1)
var chapter: int = 1
var defeated: Array = []
var flags: Dictionary = {}

# Battle fields (Ioana)
var hp: int = DEFAULT_HP
var max_hp: int = DEFAULT_MAX_HP

# Quiz fields (Kevin)
var quiz: Dictionary = {}

# Pretest fields (Kevin)
var pretest: Dictionary = {}


func _ready() -> void:
	pass


## Resetează starea la valorile inițiale pentru un joc nou.
func reset() -> void:
	map = DEFAULT_MAP
	cell = Vector2i(0, 0)
	facing = Vector2i(0, 1)
	chapter = 1
	defeated.clear()
	flags.clear()
	hp = DEFAULT_HP
	max_hp = DEFAULT_MAX_HP
	quiz.clear()
	pretest.clear()
	state_reset.emit()


## Returnează starea curentă conform schemei de salvare v1.
func to_dictionary() -> Dictionary:
	var def_copy: Array[String] = []
	for d in defeated:
		def_copy.append(str(d))
	
	var data: Dictionary = {
		"world": {
			"map": map,
			"cell": [cell.x, cell.y],
			"facing": [facing.x, facing.y],
			"chapter": chapter,
			"defeated": def_copy,
			"flags": flags.duplicate(true),
		},
		"battle": {
			"hp": hp,
			"max_hp": max_hp,
		},
		"quiz": quiz.duplicate(true),
	}
	
	if not pretest.is_empty():
		data["pretest"] = pretest.duplicate(true)
	
	return data


## Încarcă și normalizează starea dintr-un dicționar de salvare.
## Toate numerele din JSON (care vin ca float) sunt convertite explicit cu int().
func from_dictionary(data: Dictionary) -> void:
	if data.has("world") and data["world"] is Dictionary:
		var w: Dictionary = data["world"]
		map = str(w.get("map", DEFAULT_MAP))
		
		var raw_cell: Variant = w.get("cell")
		if raw_cell is Array and raw_cell.size() >= 2:
			cell = Vector2i(int(raw_cell[0]), int(raw_cell[1]))
		else:
			cell = Vector2i(0, 0)
		
		var raw_facing: Variant = w.get("facing")
		if raw_facing is Array and raw_facing.size() >= 2:
			facing = Vector2i(int(raw_facing[0]), int(raw_facing[1]))
		else:
			facing = Vector2i(0, 1)
		
		chapter = int(w.get("chapter", 1))
		
		defeated.clear()
		var raw_def: Variant = w.get("defeated")
		if raw_def is Array:
			for item in raw_def:
				defeated.append(str(item))
		
		var raw_flags: Variant = w.get("flags")
		flags = raw_flags.duplicate(true) if raw_flags is Dictionary else {}
	
	if data.has("battle") and data["battle"] is Dictionary:
		var b: Dictionary = data["battle"]
		hp = int(b.get("hp", DEFAULT_HP))
		max_hp = int(b.get("max_hp", DEFAULT_MAX_HP))
	
	if data.has("quiz") and data["quiz"] is Dictionary:
		quiz = data["quiz"].duplicate(true)
	else:
		quiz.clear()
	
	if data.has("pretest") and data["pretest"] is Dictionary:
		pretest = data["pretest"].duplicate(true)
		if pretest.has("score"):
			pretest["score"] = int(pretest["score"])
	else:
		pretest.clear()
	
	state_loaded.emit()
