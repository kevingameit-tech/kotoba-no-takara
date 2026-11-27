extends GutTest
## GameState unit tests (Mariana).
## Conformează docs/contracts.md secțiunea 12 („Save schema”).
## Issue #44 / #53: Un singur GameState pentru salvare.

var game_state: Node


func before_each() -> void:
	game_state = autofree(load("res://autoload/game_state.gd").new())
	game_state.reset()


func test_initial_state_and_defaults() -> void:
	assert_eq(game_state.chapter, 1)
	assert_eq(game_state.map, "res://world/maps/tokyo_town.tscn")
	assert_eq(game_state.cell, Vector2i(0, 0))
	assert_eq(game_state.facing, Vector2i(0, 1))
	assert_eq(game_state.defeated, [])
	assert_eq(game_state.flags, {})
	assert_eq(game_state.hp, 20)
	assert_eq(game_state.max_hp, 20)
	assert_eq(game_state.quiz, {})
	assert_eq(game_state.pretest, {})


func test_to_dictionary_schema_v1() -> void:
	game_state.chapter = 2
	game_state.map = "res://world/maps/forest.tscn"
	game_state.cell = Vector2i(5, 10)
	game_state.facing = Vector2i(1, 0)
	game_state.defeated = ["c1_kappa_1", "c1_tengu"]
	game_state.flags = {"c1_intro_done": true}
	game_state.hp = 15
	game_state.max_hp = 25
	game_state.quiz = {"h_ka": {"box": 2, "seen": 4, "wrong": 1}}
	game_state.pretest = {"form": "A", "score": 8}

	var d: Dictionary = game_state.to_dictionary()
	
	assert_true(d.has("world"))
	assert_true(d.has("battle"))
	assert_true(d.has("quiz"))
	assert_true(d.has("pretest"))
	
	assert_eq(d["world"]["map"], "res://world/maps/forest.tscn")
	assert_eq(d["world"]["cell"], [5, 10])
	assert_eq(d["world"]["facing"], [1, 0])
	assert_eq(d["world"]["chapter"], 2)
	assert_eq(d["world"]["defeated"], ["c1_kappa_1", "c1_tengu"])
	assert_eq(d["world"]["flags"], {"c1_intro_done": true})
	
	assert_eq(d["battle"]["hp"], 15)
	assert_eq(d["battle"]["max_hp"], 25)
	
	assert_eq(d["quiz"], {"h_ka": {"box": 2, "seen": 4, "wrong": 1}})
	assert_eq(d["pretest"], {"form": "A", "score": 8})


func test_from_dictionary_normalizes_floats_and_vectors() -> void:
	# Simulează citirea din JSON (unde numerele vin ca float)
	var raw_data: Dictionary = {
		"world": {
			"map": "res://world/maps/tokyo_town.tscn",
			"cell": [12.0, 7.0],
			"facing": [0.0, 1.0],
			"chapter": 1.0,
			"defeated": ["c1_kappa_1"],
			"flags": {"c1_intro_done": true}
		},
		"battle": {
			"hp": 18.0,
			"max_hp": 20.0
		},
		"quiz": {
			"h_ka": {"box": 2.0, "seen": 4.0, "wrong": 1.0}
		},
		"pretest": {
			"form": "B",
			"score": 7.0
		}
	}
	
	game_state.from_dictionary(raw_data)
	
	assert_eq(game_state.cell, Vector2i(12, 7), "Array-ul [12.0, 7.0] trebuie convertit în Vector2i(12, 7).")
	assert_typeof(game_state.cell.x, TYPE_INT)
	assert_eq(game_state.facing, Vector2i(0, 1))
	assert_typeof(game_state.facing.y, TYPE_INT)
	assert_eq(game_state.chapter, 1)
	assert_typeof(game_state.chapter, TYPE_INT)
	assert_eq(game_state.defeated, ["c1_kappa_1"])
	assert_eq(game_state.hp, 18)
	assert_typeof(game_state.hp, TYPE_INT)
	assert_eq(game_state.max_hp, 20)
	assert_typeof(game_state.max_hp, TYPE_INT)
	assert_eq(game_state.pretest["score"], 7)
	assert_typeof(game_state.pretest["score"], TYPE_INT)


func test_reset_restores_defaults() -> void:
	game_state.chapter = 3
	game_state.hp = 5
	game_state.flags = {"test": true}
	
	game_state.reset()
	
	assert_eq(game_state.chapter, 1)
	assert_eq(game_state.hp, 20)
	assert_eq(game_state.flags, {})
