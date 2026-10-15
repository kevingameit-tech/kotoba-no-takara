extends GutTest

func test_save_and_load_data():
	var test_data = {
		"high_score": 1500,
		"player_name": "KotobaPlayer",
		"completed_levels": 3
	}
	
	# Salvăm datele
	var save_result = SaveManager.save_game_data(test_data)
	assert_eq(save_result, OK, "Salvarea datelor ar trebui să reușească fără erori.")
	
	# Încărcăm datele înapoi
	var loaded_data = SaveManager.load_game_data()
	assert_eq(loaded_data.get("high_score"), 1500, "Scorul maxim încărcat ar trebui să fie 1500.")
	assert_eq(loaded_data.get("player_name"), "KotobaPlayer", "Numele jucătorului ar trebui să coincidă.")
	assert_eq(loaded_data.get("completed_levels"), 3, "Numărul de niveluri completate ar trebui să fie 3.")
