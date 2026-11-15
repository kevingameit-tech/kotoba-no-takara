extends GutTest
## Telemetry unit tests (Mariana).
## Conformează docs/contracts.md secțiunea 13 și catalogului v1 de evenimente.
## Issue #50: [ui] telemetry.gd după catalogul de evenimente.

var telemetry: Node


func before_each() -> void:
	telemetry = autofree(load("res://autoload/telemetry.gd").new())
	add_child_autofree(telemetry)
	telemetry.endpoint_url = ""
	telemetry.clear_queue()
	telemetry.sent_batches.clear()
	telemetry.last_batch.clear()
	# Asigurăm telemetry_enabled = true la începutul fiecărui test
	var settings_node: Node = get_node_or_null("/root/Settings")
	if settings_node != null and "telemetry_enabled" in settings_node:
		settings_node.telemetry_enabled = true


func after_each() -> void:
	var settings_node: Node = get_node_or_null("/root/Settings")
	if settings_node != null and "telemetry_enabled" in settings_node:
		settings_node.telemetry_enabled = true


func test_sid_format_and_uniqueness() -> void:
	var sid: String = telemetry.get_sid()
	assert_eq(sid.length(), 32, "Session ID-ul trebuie să aibă exact 32 de caractere hexazecimale.")
	var re: RegEx = RegEx.create_from_string("^[0-9a-f]{32}$")
	assert_not_null(re.search(sid), "Session ID-ul trebuie să conțină doar caractere hexazecimale minuscule [0-9a-f].")
	
	# Verificăm că reset_session generează un alt ID unic
	telemetry.reset_session()
	var new_sid: String = telemetry.get_sid()
	assert_eq(new_sid.length(), 32)
	assert_ne(sid, new_sid, "Fiecare sesiune trebuie să aibă un sid unic aleator.")


func test_sid_kept_only_in_memory() -> void:
	# Verificăm că sid nu a fost scris în Settings sau pe disc
	var settings_node: Node = get_node_or_null("/root/Settings")
	if settings_node != null:
		var cfg := ConfigFile.new()
		if cfg.load(settings_node.SETTINGS_PATH) == OK:
			assert_false(cfg.has_section_key("general", "sid"), "sid-ul nu trebuie scris în ConfigFile.")
			assert_false(cfg.has_section_key("telemetry", "sid"), "sid-ul nu trebuie scris pe disc.")
		else:
			pass
	# Verificăm că telemetry nu are nicio cale sau metodă de salvare pe disc
	assert_false(telemetry.has_method("save"), "Telemetry nu trebuie să salveze date pe disc.")
	assert_false(FileAccess.file_exists("user://telemetry.json"), "telemetry.json nu trebuie să existe pe disc.")
	assert_false(FileAccess.file_exists("user://sid.txt"), "sid.txt nu trebuie să existe pe disc.")


func test_top_level_fields() -> void:
	telemetry.log_event("session_start")
	var queue: Array = telemetry.get_queue()
	assert_eq(queue.size(), 1, "Evenimentul session_start trebuie să fie adăugat în coadă.")
	
	var ev: Dictionary = queue[0]
	assert_eq(ev.get("v"), 1, "Schema version v trebuie să fie 1 (int).")
	assert_typeof(ev.get("v"), TYPE_INT)
	assert_eq(ev.get("build"), ProjectSettings.get_setting("application/config/version", "0.1.0"))
	assert_eq(ev.get("sid"), telemetry.get_sid())
	assert_typeof(ev.get("t_ms"), TYPE_INT)
	assert_gte(int(ev.get("t_ms")), 0, "t_ms trebuie să fie >= 0.")
	assert_eq(ev.get("event"), "session_start")
	assert_eq(ev.get("data"), {})
	assert_true(ev.get("platform") in ["web_desktop", "web_android", "web_ios", "desktop"])
	assert_true(ev.get("lang") in ["ro", "en"])


func test_drops_unknown_events() -> void:
	telemetry.log_event("unknown_custom_event", {"foo": "bar"})
	telemetry.log_event("free_chat", {"text": "salut"})
	assert_eq(telemetry.get_queue().size(), 0, "Doar evenimentele din catalogul v1 sunt acceptate; cele necunoscute sunt aruncate.")


func test_chapter_enter_validation() -> void:
	# Valid
	telemetry.log_event("chapter_enter", {"chapter": 1})
	assert_eq(telemetry.get_queue().size(), 1)
	assert_eq(telemetry.get_queue()[0]["data"], {"chapter": 1})
	telemetry.clear_queue()
	
	# Extra câmpuri necunoscute sunt aruncate
	telemetry.log_event("chapter_enter", {"chapter": 2, "extra_text": "ignora_ma"})
	assert_eq(telemetry.get_queue().size(), 1)
	assert_eq(telemetry.get_queue()[0]["data"], {"chapter": 2}, "Câmpurile suplimentare trebuie să fie eliminate.")
	telemetry.clear_queue()
	
	# Invalid: chapter <= 0 sau > 99
	telemetry.log_event("chapter_enter", {"chapter": 0})
	telemetry.log_event("chapter_enter", {"chapter": 100})
	telemetry.log_event("chapter_enter", {})
	assert_eq(telemetry.get_queue().size(), 0, "Valorile invalide pentru chapter trebuie aruncate.")


func test_answer_validation_choice_mode() -> void:
	# Valid choice
	telemetry.log_event("answer", {
		"encounter_id": "c1_kappa_1",
		"qid": "q_0001",
		"item_id": "h_ki",
		"mode": "choice",
		"correct": true,
		"elapsed_ms": 3200,
		"chosen": "sa"
	})
	assert_eq(telemetry.get_queue().size(), 1)
	var d: Dictionary = telemetry.get_queue()[0]["data"]
	assert_eq(d["encounter_id"], "c1_kappa_1")
	assert_eq(d["qid"], "q_0001")
	assert_eq(d["item_id"], "h_ki")
	assert_eq(d["mode"], "choice")
	assert_eq(d["correct"], true)
	assert_eq(d["elapsed_ms"], 3200)
	assert_eq(d["chosen"], "sa")
	telemetry.clear_queue()
	
	# Invalid: encounter_id format greșit
	telemetry.log_event("answer", {
		"encounter_id": "bad_encounter",
		"qid": "q_0001",
		"item_id": "h_ki",
		"mode": "choice",
		"correct": true,
		"elapsed_ms": 3200,
		"chosen": "sa"
	})
	assert_eq(telemetry.get_queue().size(), 0, "encounter_id greșit trebuie respins.")
	
	# Invalid: qid format greșit
	telemetry.log_event("answer", {
		"encounter_id": "c1_kappa_1",
		"qid": "wrong_qid",
		"item_id": "h_ki",
		"mode": "choice",
		"correct": true,
		"elapsed_ms": 3200,
		"chosen": "sa"
	})
	assert_eq(telemetry.get_queue().size(), 0, "qid greșit trebuie respins.")


func test_answer_validation_type_mode_no_free_text() -> void:
	# Valid type mode cu chosen gol ("")
	telemetry.log_event("answer", {
		"encounter_id": "c1_kappa_1",
		"qid": "q_0002",
		"item_id": "h_ki",
		"mode": "type",
		"correct": true,
		"elapsed_ms": 2500,
		"chosen": ""
	})
	assert_eq(telemetry.get_queue().size(), 1)
	assert_eq(telemetry.get_queue()[0]["data"]["chosen"], "")
	telemetry.clear_queue()
	
	# In modul type, chosen NU are voie să conțină text scris de jucător (garanție confidențialitate)
	telemetry.log_event("answer", {
		"encounter_id": "c1_kappa_1",
		"qid": "q_0002",
		"item_id": "h_ki",
		"mode": "type",
		"correct": true,
		"elapsed_ms": 2500,
		"chosen": "text_introdus_de_jucator"
	})
	assert_eq(telemetry.get_queue().size(), 0, "În modul type, dacă chosen nu este gol, evenimentul trebuie respins pentru confidențialitate.")


func test_battle_end_validation() -> void:
	# Valid
	telemetry.log_event("battle_end", {
		"encounter_id": "c1_kappa_1",
		"outcome": "win",
		"correct": 5,
		"wrong": 1
	})
	assert_eq(telemetry.get_queue().size(), 1)
	var d: Dictionary = telemetry.get_queue()[0]["data"]
	assert_eq(d["outcome"], "win")
	assert_eq(d["correct"], 5)
	assert_eq(d["wrong"], 1)
	telemetry.clear_queue()
	
	# Invalid outcome
	telemetry.log_event("battle_end", {
		"encounter_id": "c1_kappa_1",
		"outcome": "draw",
		"correct": 5,
		"wrong": 1
	})
	assert_eq(telemetry.get_queue().size(), 0, "Outcome în afara (win, lose, flee) trebuie respins.")


func test_pretest_and_posttest_validation() -> void:
	# Pretest valid
	telemetry.log_event("pretest", {"form": "A", "score": 8, "n_items": 10})
	assert_eq(telemetry.get_queue().size(), 1)
	assert_eq(telemetry.get_queue()[0]["data"], {"form": "A", "score": 8, "n_items": 10})
	telemetry.clear_queue()
	
	# Pretest invalid: score > n_items
	telemetry.log_event("pretest", {"form": "A", "score": 11, "n_items": 10})
	assert_eq(telemetry.get_queue().size(), 0, "Scorul nu poate depăși n_items.")
	
	# Posttest valid cu pretest
	telemetry.log_event("posttest", {"form": "B", "score": 9, "n_items": 10, "pre_form": "A", "pre_score": 8})
	assert_eq(telemetry.get_queue().size(), 1)
	assert_eq(telemetry.get_queue()[0]["data"]["pre_form"], "A")
	assert_eq(telemetry.get_queue()[0]["data"]["pre_score"], 8)
	telemetry.clear_queue()
	
	# Posttest valid fără pretest salvat
	telemetry.log_event("posttest", {"form": "B", "score": 9, "n_items": 10, "pre_form": "", "pre_score": -1})
	assert_eq(telemetry.get_queue().size(), 1)
	telemetry.clear_queue()
	
	# Posttest invalid: pre_form gol dar pre_score != -1
	telemetry.log_event("posttest", {"form": "B", "score": 9, "n_items": 10, "pre_form": "", "pre_score": 5})
	assert_eq(telemetry.get_queue().size(), 0, "Când pre_form este gol, pre_score trebuie să fie -1.")


func test_quit_validation() -> void:
	# Valid
	telemetry.log_event("quit", {"scene": "tokyo_town"})
	assert_eq(telemetry.get_queue().size(), 1)
	assert_eq(telemetry.get_queue()[0]["data"]["scene"], "tokyo_town")
	telemetry.clear_queue()
	
	# Invalid caractere nepermise în scene
	telemetry.log_event("quit", {"scene": "../../etc/passwd"})
	assert_eq(telemetry.get_queue().size(), 0, "Nume de scene cu caractere invalide trebuie respinse.")


func test_opt_out_respects_settings() -> void:
	var settings_node: Node = get_node_or_null("/root/Settings")
	if settings_node != null and "telemetry_enabled" in settings_node:
		settings_node.telemetry_enabled = false
	
	# Încercăm să înregistrăm evenimente
	telemetry.log_event("session_start")
	telemetry.log_event("chapter_enter", {"chapter": 1})
	assert_eq(telemetry.get_queue().size(), 0, "Când telemetria este oprită, log_event nu trebuie să adauge nimic în coadă.")
	
	telemetry.flush()
	assert_eq(telemetry.sent_batches.size(), 0, "Când telemetria este oprită, flush nu trebuie să trimită nimic.")
	
	if settings_node != null and "telemetry_enabled" in settings_node:
		settings_node.telemetry_enabled = true


func test_batch_flush_on_threshold() -> void:
	# Adăugăm 9 evenimente -> nu a atins încă BATCH_SIZE (10)
	for i in range(9):
		telemetry.log_event("chapter_enter", {"chapter": 1})
	assert_eq(telemetry.get_queue().size(), 9)
	assert_eq(telemetry.sent_batches.size(), 0)
	
	# Al 10-lea eveniment declanșează automat flush()
	telemetry.log_event("chapter_enter", {"chapter": 1})
	assert_eq(telemetry.get_queue().size(), 0, "Coadă trebuie să se golească după atingerea mărimii lotului.")
	assert_eq(telemetry.sent_batches.size(), 1, "Un lot trebuie să fi fost trimis.")
	assert_eq(telemetry.last_batch.size(), 10, "Lotul trebuie să conțină 10 evenimente.")


func test_wire_format_and_json_serialization() -> void:
	telemetry.log_event("session_start")
	telemetry.flush()
	
	assert_eq(telemetry.sent_batches.size(), 1)
	var batch: Array = telemetry.last_batch
	var json_str: String = JSON.stringify(batch)
	var parsed: Variant = JSON.parse_string(json_str)
	
	assert_true(parsed is Array, "Formatul wire trebuie să fie un JSON array de obiecte.")
	assert_eq(parsed.size(), 1)
	var ev: Dictionary = parsed[0]
	assert_eq(int(ev["v"]), 1)
	assert_true(ev.has("sid"))
	assert_true(ev.has("t_ms"))
	assert_true(ev.has("platform"))
	assert_true(ev.has("lang"))
	assert_eq(ev["event"], "session_start")
	assert_eq(ev["data"], {})


func test_platform_override() -> void:
	telemetry.platform_override = "web_android"
	telemetry.log_event("session_start")
	assert_eq(telemetry.get_queue()[0]["platform"], "web_android")
	telemetry.clear_queue()
	
	telemetry.platform_override = "web_ios"
	telemetry.log_event("session_start")
	assert_eq(telemetry.get_queue()[0]["platform"], "web_ios")
	telemetry.clear_queue()


func test_focus_out_triggers_flush() -> void:
	telemetry.log_event("session_start")
	assert_eq(telemetry.get_queue().size(), 1)
	assert_eq(telemetry.sent_batches.size(), 0)
	
	# Simulăm pierderea focusului aplicației
	telemetry.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_eq(telemetry.get_queue().size(), 0)
	assert_eq(telemetry.sent_batches.size(), 1)
