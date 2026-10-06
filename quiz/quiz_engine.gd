class_name QuizEngine
extends RefCounted
## One quiz for one battle: picks the questions, checks the answers and remembers what the
## player knows. Contract: docs/contracts.md, section 8.
## No nodes, no UI, no timers: the battle shows the question, measures the time and
## decides the damage. v0.1 asks only "choice" questions (kana -> 4 readings).

## Emitted once for every answered question. The battle forwards it to Telemetry.
signal answered(qid: String, item_id: String, correct: bool, elapsed_ms: int)

const MODE_CHOICE: String = "choice"
const CHOICE_COUNT: int = 4
const FIRST_BOX: int = 1
const LAST_BOX: int = 3
## The order in which the rows are taught. ん / ン (n_final) comes after the w row.
const ROW_ORDER: Array[String] = ["a", "k", "s", "t", "n", "h", "m", "y", "r", "w", "n_final"]

var _bank: Object = null           # QuestionBank, or a test object with the same methods
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _pool: Array[String] = []      # item ids of the current pool
var _met_rows: Array[String] = []  # rows the player has met in this pool
var _queue: Array[String] = []     # item ids still to ask in this round
var _last_item_id: String = ""
var _open: Dictionary = {}         # qid -> { "item_id": String, "expected": String }
var _next_number: int = 1
var _state: Dictionary = {}        # item id -> { "box": int, "seen": int, "wrong": int }


## [param bank] gives the data. Leave it null to use the QuestionBank autoload;
## tests pass their own object with get_pool(), get_item() and items_for().
func _init(bank: Object = null) -> void:
	_bank = bank


## Starts a quiz on [param pool_id]. [param rng_seed] -1 means random; any other value
## gives the same questions and choices every time (the tests use this).
func start(pool_id: String, rng_seed: int = -1) -> void:
	if _bank == null:
		_bank = _autoload_bank()
	if rng_seed == -1:
		_rng.randomize()
	else:
		_rng.seed = rng_seed
	_pool.clear()
	_queue.clear()
	_open.clear()
	_last_item_id = ""
	if _bank == null:
		push_error("QuizEngine: no QuestionBank (no autoload and no bank given)")
		return
	_pool.assign(_bank.get_pool(pool_id))
	if _pool.is_empty():
		push_error("QuizEngine: unknown or empty pool \"%s\"" % pool_id)
		return
	_met_rows = _rows_met_in_pool()


## The next question (keys in the contract), or {} if start() found no items.
func next_question() -> Dictionary:
	if _pool.is_empty():
		push_error("QuizEngine: call start() with a valid pool first")
		return {}
	if _queue.is_empty():
		_refill_queue()
	var item_id: String = _queue.pop_back()
	_last_item_id = item_id
	var item: Dictionary = _bank.get_item(item_id)
	var qid: String = "q_%04d" % _next_number
	_next_number += 1
	_open[qid] = {"item_id": item_id, "expected": str(item.get("romaji", ""))}
	return {
		"qid": qid,
		"item_id": item_id,
		"mode": MODE_CHOICE,
		"prompt_text": str(item.get("kana", "")),
		"prompt_audio": "",
		"choices": _choices_for(item),
	}


## Checks [param answer] for [param qid], emits [signal answered] once and returns
## { "correct", "expected", "explain" }. An unknown or repeated qid gives {} and push_error().
func submit(qid: String, answer: String, elapsed_ms: int) -> Dictionary:
	if not _open.has(qid):
		push_error("QuizEngine: unknown or already answered qid \"%s\"" % qid)
		return {}
	var question: Dictionary = _open[qid]
	_open.erase(qid)
	var item_id: String = question["item_id"]
	var expected: String = question["expected"]
	var correct: bool = answer == expected
	_remember(item_id, correct)
	answered.emit(qid, item_id, correct, elapsed_ms)
	var mnemonic: Variant = _bank.get_item(item_id).get("mnemonic", {})
	if not (mnemonic is Dictionary):
		mnemonic = {}
	return {
		"correct": correct,
		"expected": expected,
		"explain": {"ro": str(mnemonic.get("ro", "")), "en": str(mnemonic.get("en", ""))},
	}


## What the player knows, for the save file: { item_id: { "box", "seen", "wrong" } }.
func get_state() -> Dictionary:
	return _state.duplicate(true)


## Restores what get_state() returned. Numbers are cast with int() (a JSON save gives
## floats) and box stays between 1 and 3. Entries that are not dictionaries are skipped.
func set_state(state: Dictionary) -> void:
	_state.clear()
	for item_id in state:
		var entry: Variant = state[item_id]
		if not (entry is Dictionary):
			continue
		_state[str(item_id)] = {
			"box": clampi(int(entry.get("box", FIRST_BOX)), FIRST_BOX, LAST_BOX),
			"seen": maxi(int(entry.get("seen", 0)), 0),
			"wrong": maxi(int(entry.get("wrong", 0)), 0),
		}


## Leitner boxes: a correct answer moves the item one box up, a wrong one sends it to box 1.
func _remember(item_id: String, correct: bool) -> void:
	var entry: Dictionary = _state.get(item_id, {"box": FIRST_BOX, "seen": 0, "wrong": 0})
	entry["seen"] += 1
	if correct:
		entry["box"] = mini(entry["box"] + 1, LAST_BOX)
	else:
		entry["wrong"] += 1
		entry["box"] = FIRST_BOX
	_state[item_id] = entry


## Puts every item of the pool back in a random order, without the last item first.
func _refill_queue() -> void:
	_queue.assign(_pool)
	_shuffle(_queue)
	if _queue.size() > 1 and _queue.back() == _last_item_id:
		var last: int = _queue.size() - 1
		_queue[last] = _queue[0]
		_queue[0] = _last_item_id


## The expected reading plus up to 3 distractors, in a random order.
func _choices_for(item: Dictionary) -> Array[String]:
	var expected: String = str(item.get("romaji", ""))
	var choices: Array[String] = [expected]
	for romaji in _distractors_for(item, expected):
		if choices.size() == CHOICE_COUNT:
			break
		choices.append(romaji)
	_shuffle(choices)
	return choices


## Readings from the rows already met: confusable kana first, then the others.
## Never the expected reading, never the same reading twice.
func _distractors_for(item: Dictionary, expected: String) -> Array[String]:
	var met: Array[Dictionary] = []
	met.assign(_bank.items_for(int(item.get("chapter", 0)), _met_rows))
	var confusable_ids: Array = item.get("confusable_ids", [])
	var first: Array[String] = []
	var rest: Array[String] = []
	for other in met:
		var romaji: String = str(other.get("romaji", ""))
		if romaji == "" or romaji == expected or first.has(romaji) or rest.has(romaji):
			continue
		if confusable_ids.has(other.get("id")):
			first.append(romaji)
		else:
			rest.append(romaji)
	_shuffle(first)
	_shuffle(rest)
	var result: Array[String] = []
	result.append_array(first)
	result.append_array(rest)
	return result


## Every row in ROW_ORDER up to the last row that an item of the pool uses.
func _rows_met_in_pool() -> Array[String]:
	var last_index: int = 0
	for item_id in _pool:
		var row: String = str(_bank.get_item(item_id).get("row", "a"))
		last_index = maxi(last_index, ROW_ORDER.find(row))
	var rows: Array[String] = []
	for index in last_index + 1:
		rows.append(ROW_ORDER[index])
	return rows


## Fisher-Yates with our own RandomNumberGenerator, so a seed repeats the same order.
func _shuffle(values: Array) -> void:
	for i in range(values.size() - 1, 0, -1):
		var j: int = _rng.randi_range(0, i)
		var temp: Variant = values[i]
		values[i] = values[j]
		values[j] = temp


## The QuestionBank autoload, or null when it is not registered (for example in a test).
func _autoload_bank() -> Object:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null("QuestionBank")
