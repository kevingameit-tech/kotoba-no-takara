extends GutTest

func test_sanitize_input():
	var raw_text = "  KOTOBA  "
	var clean_text = TextFormatter.sanitize_input(raw_text)
	assert_eq(clean_text, "kotoba", "Textul ar trebui să fie fără spații la capete și cu litere mici.")

func test_format_score():
	var formatted = TextFormatter.format_score(42)
	assert_eq(formatted, "Scor: 00042", "Scorul ar trebui să aibă pad de 5 cifre.")
