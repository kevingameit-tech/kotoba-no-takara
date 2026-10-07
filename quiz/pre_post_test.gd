class_name PrePostTest
extends RefCounted
## The short test before chapter 1 (pre-test) and after the Tengu (post-test): the 10 hiragana
## of form A or B, each asked once. Contract: docs/contracts.md, sections 12 and 13 (decision 9).
## The screen shows the questions and measures the time; this class picks the form, counts the
## score and builds the data for GameState.pretest and Telemetry. It never tells the player
## whether an answer was right and never saves the quiz state.

const KIND_PRE: String = "pre"
const KIND_POST: String = "post"
const FORM_POOLS: Dictionary = {"A": "c1_test_a", "B": "c1_test_b"}
const N_ITEMS: int = 10

var kind: String = ""
var form: String = ""
var _engine: QuizEngine = null
var _open_qid: String = ""
var _answered: int = 0
var _score: int = 0


## Form for a new pre-test: A or B at random ([param rng_seed] -1), or fixed by a seed in tests.
static func pick_pre_form(rng_seed: int = -1) -> String:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	if rng_seed == -1:
		rng.randomize()
	else:
		rng.seed = rng_seed
	return "A" if rng.randi_range(0, 1) == 0 else "B"


## Form for the post-test: the other one than [param pretest] (GameState.pretest), so nobody
## answers the same items twice. If the pre-test is unknown (for example the save was deleted),
## a random form.
static func post_form_for(pretest: Dictionary, rng_seed: int = -1) -> String:
	match str(pretest.get("form", "")):
		"A":
			return "B"
		"B":
			return "A"
	return pick_pre_form(rng_seed)


## [param test_kind] is "pre" or "post", [param test_form] "A" or "B". [param bank] works as in
## QuizEngine: null uses the QuestionBank autoload, tests pass their own object.
func _init(test_kind: String, test_form: String, bank: Object = null, rng_seed: int = -1) -> void:
	if test_kind != KIND_PRE and test_kind != KIND_POST:
		push_error("PrePostTest: kind must be \"pre\" or \"post\", not \"%s\"" % test_kind)
		return
	if not FORM_POOLS.has(test_form):
		push_error("PrePostTest: form must be \"A\" or \"B\", not \"%s\"" % test_form)
		return
	kind = test_kind
	form = test_form
	_engine = QuizEngine.new(bank)
	_engine.start(FORM_POOLS[test_form], rng_seed)


## The next question (the keys of QuizEngine.next_question()), or {} once the 10 answers
## are in. Ask one question at a time: answer the open one first.
func next_question() -> Dictionary:
	if _engine == null or is_finished():
		return {}
	if _open_qid != "":
		push_error("PrePostTest: answer question %s before asking the next one" % _open_qid)
		return {}
	var question: Dictionary = _engine.next_question()
	if not question.is_empty():
		_open_qid = question["qid"]
	return question


## Records the answer to the open question. Returns true when the answer was recorded, right
## or wrong: the test shows no correct answers. An unknown qid returns false.
func submit(qid: String, answer: String, elapsed_ms: int) -> bool:
	if qid == "" or qid != _open_qid:
		push_error("PrePostTest: \"%s\" is not the open question" % qid)
		return false
	var result: Dictionary = _engine.submit(qid, answer, elapsed_ms)
	_open_qid = ""
	_answered += 1
	if result.get("correct", false):
		_score += 1
	return true


func is_finished() -> bool:
	return _answered >= N_ITEMS


func score() -> int:
	return _score


## What the pre-test screen writes to GameState.pretest: { "form": "A", "score": 6 }.
func result() -> Dictionary:
	return {"form": form, "score": _score}


## The telemetry event for this test: "pretest" or "posttest".
func event_name() -> String:
	return "pretest" if kind == KIND_PRE else "posttest"


## The data of the event (contracts.md, section 13). For the post-test, [param pretest] is
## GameState.pretest; when it is {} or broken, pre_form is "" and pre_score is -1.
func telemetry_data(pretest: Dictionary = {}) -> Dictionary:
	var data: Dictionary = {"form": form, "score": _score, "n_items": N_ITEMS}
	if kind == KIND_POST:
		var known: bool = _is_valid_pretest(pretest)
		data["pre_form"] = str(pretest["form"]) if known else ""
		data["pre_score"] = int(pretest["score"]) if known else -1
	return data


## A save file gives numbers as floats, so 6.0 is a valid score. Anything else is unknown.
func _is_valid_pretest(pretest: Dictionary) -> bool:
	if not FORM_POOLS.has(str(pretest.get("form", ""))):
		return false
	var value: Variant = pretest.get("score")
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return false
	return value == floorf(value) and value >= 0 and value <= N_ITEMS
