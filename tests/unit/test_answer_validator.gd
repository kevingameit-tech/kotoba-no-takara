extends GutTest

func test_is_answer_correct():
	var result = AnswerValidator.is_answer_correct("  NEKO  ", "neko")
	assert_true(result, "Răspunsul '  NEKO  ' ar trebui să fie validat ca fiind corect pentru 'neko'.")

func test_is_answer_in_list():
	var valid_answers = ["cat", "kitty", "feline"]
	var result = AnswerValidator.is_answer_in_list(" Kitty ", valid_answers)
	assert_true(result, "Răspunsul ' Kitty ' ar trebui găsit în lista de răspunsuri valide.")

func test_wrong_answer():
	var result = AnswerValidator.is_answer_correct("dog", "neko")
	assert_false(result, "Răspunsul 'dog' ar trebui să fie invalid pentru 'neko'.")
