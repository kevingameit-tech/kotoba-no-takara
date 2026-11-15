extends Node
## Telemetry: client de telemetrie pentru colectarea evenimentelor de joc (fără date personale).
## Conformează catalogului de evenimente v1 definit de Kevin (docs/contracts.md, secțiunea 13).
## Backend compatibil: tools/log_backend/ (Google Apps Script / Sheets) cu POST text/plain.
## Responsabil: Mariana (Issue #50).
## ATENȚIE: Autoload-ul se numește Telemetry (NICIODATĂ Logger, care este clasă internă Godot).

signal event_logged(event_name: String, data: Dictionary)
signal flushed(batch_size: int)

const SCHEMA_VERSION: int = 1
const BATCH_SIZE: int = 10
const MAX_BATCH_SIZE: int = 200
const FLUSH_INTERVAL_SEC: float = 15.0

# Tipare regex conform tools/log_backend/Code.gs
const REGEX_SNAKE_ID: String = "^[a-z][a-z0-9_]{0,47}$"
const REGEX_QID: String = "^q_[0-9]{1,8}$"
const REGEX_ENCOUNTER_ID: String = "^c[1-9]_[a-z0-9_]{1,45}$"
const REGEX_READING: String = "^([a-z]{1,24})?$"
const REGEX_SCENE: String = "^([a-z][a-z0-9_]{0,47})?$"
const REGEX_BUILD: String = "^([A-Za-z0-9][A-Za-z0-9_.+-]{0,31})?$"
const REGEX_SID: String = "^[0-9a-f]{32}$"

const FORMS: Array[String] = ["A", "B"]
const MODES: Array[String] = ["choice", "type"]
const OUTCOMES: Array[String] = ["win", "lose", "flee"]
const PLATFORMS: Array[String] = ["web_desktop", "web_android", "web_ios", "desktop"]
const LANGS: Array[String] = ["ro", "en"]

var endpoint_url: String = ""
var platform_override: String = ""
var current_scene_name: String = ""

# sid (session id): ținut DOAR în memorie! Niciodată salvat pe disc.
var _sid: String = ""
var _start_ticks_msec: int = 0
var _queue: Array[Dictionary] = []
var _flush_timer: Timer

# Regex-uri pre-compilate
var _re_snake_id: RegEx
var _re_qid: RegEx
var _re_encounter_id: RegEx
var _re_reading: RegEx
var _re_scene: RegEx
var _re_build: RegEx
var _re_sid: RegEx

# Istoric pentru teste și inspecție
var sent_batches: Array[Array] = []
var last_batch: Array = []


func _ready() -> void:
	_init_regexes()
	_init_session()
	_setup_timer()
	if OS.has_feature("web"):
		_setup_web_lifecycle_hooks()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		flush()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		if is_telemetry_enabled() and not _has_quit_event():
			log_event("quit", {"scene": get_current_scene_name()})
		flush()


func _init_session() -> void:
	var crypto := Crypto.new()
	_sid = crypto.generate_random_bytes(16).hex_encode()
	_start_ticks_msec = Time.get_ticks_msec()


func _init_regexes() -> void:
	_re_snake_id = RegEx.create_from_string(REGEX_SNAKE_ID)
	_re_qid = RegEx.create_from_string(REGEX_QID)
	_re_encounter_id = RegEx.create_from_string(REGEX_ENCOUNTER_ID)
	_re_reading = RegEx.create_from_string(REGEX_READING)
	_re_scene = RegEx.create_from_string(REGEX_SCENE)
	_re_build = RegEx.create_from_string(REGEX_BUILD)
	_re_sid = RegEx.create_from_string(REGEX_SID)


func _setup_timer() -> void:
	_flush_timer = Timer.new()
	_flush_timer.name = "FlushTimer"
	_flush_timer.wait_time = FLUSH_INTERVAL_SEC
	_flush_timer.autostart = true
	_flush_timer.one_shot = false
	_flush_timer.timeout.connect(flush)
	add_child(_flush_timer)


func _setup_web_lifecycle_hooks() -> void:
	# JavaScriptBridge este garantat doar pe Web; apelurile sunt protejate cu OS.has_feature("web")
	if not OS.has_feature("web"):
		return
	var window = JavaScriptBridge.get_interface("window")
	if window != null:
		var hide_callback = JavaScriptBridge.create_callback(_on_web_page_hide)
		window.addEventListener("pagehide", hide_callback)
		window.addEventListener("visibilitychange", hide_callback)


func _on_web_page_hide(_args: Array) -> void:
	if not is_telemetry_enabled():
		_queue.clear()
		return
	if not _has_quit_event():
		log_event("quit", {"scene": get_current_scene_name()})
	flush_keepalive()


## Returnează true dacă utilizatorul nu a oprit statisticile în Setări.
func is_telemetry_enabled() -> bool:
	var settings_node: Node = get_node_or_null("/root/Settings")
	if settings_node != null and "telemetry_enabled" in settings_node:
		return bool(settings_node.telemetry_enabled)
	return true


func get_sid() -> String:
	return _sid


func get_build() -> String:
	var b: String = ProjectSettings.get_setting("application/config/version", "0.1.0")
	if _re_build != null and _re_build.search(b):
		return b
	return "0.1.0"


func get_t_ms() -> int:
	var elapsed: int = Time.get_ticks_msec() - _start_ticks_msec
	return clampi(elapsed, 0, 2147483647)


func get_platform() -> String:
	if platform_override != "":
		return platform_override
	if OS.has_feature("web"):
		var ua: String = ""
		var js_window = JavaScriptBridge.get_interface("window")
		if js_window != null and js_window.navigator != null:
			ua = str(js_window.navigator.userAgent).to_lower()
		if "android" in ua:
			return "web_android"
		elif "iphone" in ua or "ipad" in ua or "ipod" in ua:
			return "web_ios"
		return "web_desktop"
	return "desktop"


func get_lang() -> String:
	var settings_node: Node = get_node_or_null("/root/Settings")
	if settings_node != null and "lang" in settings_node:
		var l: String = str(settings_node.lang).to_lower()
		if l in LANGS:
			return l
	var locale: String = TranslationServer.get_locale().substr(0, 2).to_lower()
	return "en" if locale == "en" else "ro"


func get_current_scene_name() -> String:
	if current_scene_name != "":
		return current_scene_name
	if get_tree() != null and get_tree().current_scene != null:
		var path: String = get_tree().current_scene.scene_file_path
		if path != "":
			return path.get_file().get_basename().to_snake_case()
	return ""


## Înregistrează un eveniment din catalogul v1.
## Câmpurile necunoscute sunt aruncate; dacă lipsesc câmpuri obligatorii sau au valori invalide,
## evenimentul este ignorat.
func log_event(event: String, data: Dictionary = {}) -> void:
	if not is_telemetry_enabled():
		return
	
	if _re_snake_id == null:
		_init_regexes()
	if _sid == "":
		_init_session()
	
	var clean_data: Variant = _clean_and_validate_data(event, data)
	if clean_data == null:
		# Eveniment sau date invalide, drop conform regulilor
		return
	
	var event_obj: Dictionary = {
		"v": SCHEMA_VERSION,
		"build": get_build(),
		"sid": get_sid(),
		"t_ms": get_t_ms(),
		"platform": get_platform(),
		"lang": get_lang(),
		"event": event,
		"data": clean_data,
	}
	
	_queue.append(event_obj)
	event_logged.emit(event, clean_data)
	
	if _queue.size() >= BATCH_SIZE:
		flush()


## Trimite lotul curent de evenimente.
func flush() -> void:
	if _queue.is_empty():
		return
	if not is_telemetry_enabled():
		_queue.clear()
		return
	
	var count: int = mini(_queue.size(), MAX_BATCH_SIZE)
	var batch: Array = _queue.slice(0, count)
	_queue = _queue.slice(count)
	
	last_batch = batch
	sent_batches.append(batch)
	flushed.emit(batch.size())
	
	if endpoint_url == "":
		return
	
	_send_http_batch(batch)


func _send_http_batch(batch: Array) -> void:
	if not is_inside_tree():
		return
	var body_text: String = JSON.stringify(batch)
	var req: HTTPRequest = HTTPRequest.new()
	add_child(req)
	req.request_completed.connect(func(_result: int, _response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
		req.queue_free()
	)
	var headers: PackedStringArray = ["Content-Type: text/plain"]
	var err: Error = req.request(endpoint_url, headers, HTTPClient.METHOD_POST, body_text)
	if err != OK:
		req.queue_free()


## Trimite folosind fetch() cu keepalive pe Web la închiderea paginii.
func flush_keepalive() -> void:
	if _queue.is_empty():
		return
	if not is_telemetry_enabled():
		_queue.clear()
		return
	
	var count: int = mini(_queue.size(), MAX_BATCH_SIZE)
	var batch: Array = _queue.slice(0, count)
	_queue = _queue.slice(count)
	
	last_batch = batch
	sent_batches.append(batch)
	flushed.emit(batch.size())
	
	if endpoint_url != "" and OS.has_feature("web"):
		var body_text: String = JSON.stringify(batch)
		var js_code: String = """
		(function(url, body) {
			try {
				fetch(url, {
					method: 'POST',
					headers: {'Content-Type': 'text/plain'},
					body: body,
					keepalive: true,
					credentials: 'omit'
				});
			} catch(e) {}
		})('%s', %s);
		""" % [endpoint_url.c_escape(), JSON.stringify(body_text)]
		JavaScriptBridge.eval(js_code)


func get_queue() -> Array:
	return _queue


func clear_queue() -> void:
	_queue.clear()


func reset_session() -> void:
	_init_session()
	_queue.clear()


func _has_quit_event() -> bool:
	for ev in _queue:
		if ev.get("event") == "quit":
			return true
	return false


## Validează evenimentul și extrage doar câmpurile acceptate din catalog.
## Returnează Dictionary cu câmpurile curate sau null dacă validarea eșuează.
func _clean_and_validate_data(event: String, data: Dictionary) -> Variant:
	match event:
		"session_start":
			# Catalog v1: session_start nu are date
			return {}
		
		"chapter_enter":
			if not data.has("chapter"):
				return null
			var ch: Variant = data["chapter"]
			if typeof(ch) != TYPE_INT and typeof(ch) != TYPE_FLOAT:
				return null
			var ch_int: int = int(ch)
			if ch_int < 1 or ch_int > 99:
				return null
			return {"chapter": ch_int}
		
		"answer":
			# Obligatorii: encounter_id, qid, item_id, mode, correct, elapsed_ms, chosen
			if not (data.has("encounter_id") and data.has("qid") and data.has("item_id") and data.has("mode") and data.has("correct") and data.has("elapsed_ms") and data.has("chosen")):
				return null
			
			var encounter_id: String = str(data["encounter_id"])
			var qid: String = str(data["qid"])
			var item_id: String = str(data["item_id"])
			var mode: String = str(data["mode"])
			var chosen: String = str(data["chosen"])
			
			if typeof(data["correct"]) != TYPE_BOOL:
				return null
			var correct: bool = bool(data["correct"])
			
			var elapsed: Variant = data["elapsed_ms"]
			if typeof(elapsed) != TYPE_INT and typeof(elapsed) != TYPE_FLOAT:
				return null
			var elapsed_ms: int = int(elapsed)
			if elapsed_ms < 0 or elapsed_ms > 2147483647:
				return null
			
			if not _re_encounter_id.search(encounter_id):
				return null
			if not _re_qid.search(qid):
				return null
			if not _re_snake_id.search(item_id):
				return null
			if mode not in MODES:
				return null
			
			# Regula contract: în modul "type", chosen TREBUIE să fie gol ("")
			if mode == "type":
				if chosen != "":
					return null
			else:
				if not _re_reading.search(chosen):
					return null
			
			return {
				"encounter_id": encounter_id,
				"qid": qid,
				"item_id": item_id,
				"mode": mode,
				"correct": correct,
				"elapsed_ms": elapsed_ms,
				"chosen": chosen if mode == "choice" else "",
			}
		
		"battle_end":
			if not (data.has("encounter_id") and data.has("outcome") and data.has("correct") and data.has("wrong")):
				return null
			
			var encounter_id: String = str(data["encounter_id"])
			var outcome: String = str(data["outcome"])
			if not _re_encounter_id.search(encounter_id):
				return null
			if outcome not in OUTCOMES:
				return null
			
			var corr_v: Variant = data["correct"]
			var wrong_v: Variant = data["wrong"]
			if (typeof(corr_v) != TYPE_INT and typeof(corr_v) != TYPE_FLOAT) or (typeof(wrong_v) != TYPE_INT and typeof(wrong_v) != TYPE_FLOAT):
				return null
			var correct: int = int(corr_v)
			var wrong: int = int(wrong_v)
			if correct < 0 or correct > 999 or wrong < 0 or wrong > 999:
				return null
			
			return {
				"encounter_id": encounter_id,
				"outcome": outcome,
				"correct": correct,
				"wrong": wrong,
			}
		
		"pretest":
			if not (data.has("form") and data.has("score") and data.has("n_items")):
				return null
			var form: String = str(data["form"])
			if form not in FORMS:
				return null
			var score_v: Variant = data["score"]
			var n_items_v: Variant = data["n_items"]
			if (typeof(score_v) != TYPE_INT and typeof(score_v) != TYPE_FLOAT) or (typeof(n_items_v) != TYPE_INT and typeof(n_items_v) != TYPE_FLOAT):
				return null
			var score: int = int(score_v)
			var n_items: int = int(n_items_v)
			if n_items < 1 or n_items > 100:
				return null
			if score < 0 or score > n_items:
				return null
			
			return {
				"form": form,
				"score": score,
				"n_items": n_items,
			}
		
		"posttest":
			if not (data.has("form") and data.has("score") and data.has("n_items") and data.has("pre_form") and data.has("pre_score")):
				return null
			var form: String = str(data["form"])
			if form not in FORMS:
				return null
			var pre_form: String = str(data["pre_form"])
			if pre_form not in ["A", "B", ""]:
				return null
			
			var score_v: Variant = data["score"]
			var n_items_v: Variant = data["n_items"]
			var pre_score_v: Variant = data["pre_score"]
			if (typeof(score_v) != TYPE_INT and typeof(score_v) != TYPE_FLOAT) or (typeof(n_items_v) != TYPE_INT and typeof(n_items_v) != TYPE_FLOAT) or (typeof(pre_score_v) != TYPE_INT and typeof(pre_score_v) != TYPE_FLOAT):
				return null
			var score: int = int(score_v)
			var n_items: int = int(n_items_v)
			var pre_score: int = int(pre_score_v)
			
			if n_items < 1 or n_items > 100:
				return null
			if score < 0 or score > n_items:
				return null
			
			if pre_form == "":
				if pre_score != -1:
					return null
			else:
				if pre_score < 0 or pre_score > n_items:
					return null
			
			return {
				"form": form,
				"score": score,
				"n_items": n_items,
				"pre_form": pre_form,
				"pre_score": pre_score,
			}
		
		"quit":
			var scene: String = str(data.get("scene", ""))
			if scene == "":
				scene = get_current_scene_name()
			if not _re_scene.search(scene):
				return null
			return {"scene": scene}
		
		_:
			# Eveniment necunoscut în afara catalogului
			return null
