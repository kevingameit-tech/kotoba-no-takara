extends GutTest

func test_ui_csv_format():
	var file_path = "res://i18n/ui.csv"
	assert_true(FileAccess.file_exists(file_path), "Fișierul i18n/ui.csv ar trebui să existe.")
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	assert_not_null(file, "Fișierul ui.csv ar trebui să poată fi deschis.")
	
	# Verificăm antetul
	var header = file.get_csv_line()
	assert_eq(header, PackedStringArray(["keys", "en", "ro"]), "Antetul CSV trebuie să fie keys,en,ro.")
	
	var valid_prefixes = ["MENU_", "UI_", "WORLD_", "BATTLE_"]
	
	while not file.eof_reached():
		var line = file.get_csv_line()
		if line.size() < 3 or line[0].strip_edges().is_empty():
			continue # Sărim peste liniile goale
			
		var key = line[0]
		var en_text = line[1]
		var ro_text = line[2]
		
		# Verificăm că nicio celulă nu e goală
		assert_false(en_text.strip_edges().is_empty(), "Traducerea EN nu trebuie să fie goală pentru cheia: " + key)
		assert_false(ro_text.strip_edges().is_empty(), "Traducerea RO nu trebuie să fie goală pentru cheia: " + key)
		
		# Verificăm prefixul cheii
		var has_valid_prefix = false
		for prefix in valid_prefixes:
			if key.begins_with(prefix):
				has_valid_prefix = true
				break
		assert_true(has_valid_prefix, "Cheia '" + key + "' trebuie să înceapă cu unul dintre prefixele permise.")
		
		# Verificăm să nu fie folosită sedila în loc de virgulă dedesubt (U+015F sau U+0163)
		for text in [en_text, ro_text]:
			assert_false(text.contains(char(0x015F)), "Se interzice folosirea lui ș cu sedilă în: " + key)
			assert_false(text.contains(char(0x0163)), "Se interzice folosirea lui ț cu sedilă în: " + key)

	file.close()
