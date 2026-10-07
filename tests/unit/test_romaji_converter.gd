extends GutTest
## Tests for quiz/romaji_converter.gd: romaji to kana like a Japanese keyboard, and the check
## used by "type" mode. The last test reads data/ on purpose: every kana of the game must
## accept its own romaji and alt_romaji.


func test_the_46_basic_readings() -> void:
	var rows: Dictionary = {
		"aiueo": "あいうえお", "kakikukeko": "かきくけこ", "sashisuseso": "さしすせそ",
		"tachitsuteto": "たちつてと", "naninuneno": "なにぬねの", "hahifuheho": "はひふへほ",
		"mamimumemo": "まみむめも", "yayuyo": "やゆよ", "rarirurero": "らりるれろ", "wawon": "わをん",
	}
	for romaji in rows:
		assert_eq(RomajiConverter.to_kana(romaji), rows[romaji], romaji)


func test_kunrei_spellings_give_the_same_kana() -> void:
	for pair in [["si", "し"], ["ti", "ち"], ["tu", "つ"], ["hu", "ふ"], ["zi", "じ"], ["sya", "しゃ"]]:
		assert_eq(RomajiConverter.to_kana(pair[0]), pair[1], pair[0])


func test_n_like_a_japanese_keyboard() -> void:
	var words: Dictionary = {
		"san": "さん", "kanji": "かんじ", "konnichiwa": "こんにちわ", "onna": "おんな",
		"kon'ya": "こんや", "konya": "こにゃ", "nn": "ん", "ten'in": "てんいん", "tenin": "てにん",
	}
	for romaji in words:
		assert_eq(RomajiConverter.to_kana(romaji), words[romaji], romaji)


func test_double_consonants_give_small_tsu() -> void:
	var words: Dictionary = {"kitte": "きって", "zasshi": "ざっし", "matcha": "まっちゃ", "kocchi": "こっち"}
	for romaji in words:
		assert_eq(RomajiConverter.to_kana(romaji), words[romaji], romaji)


func test_combined_and_voiced_sounds() -> void:
	var words: Dictionary = {
		"kyou": "きょう", "shashin": "しゃしん", "chotto": "ちょっと", "jaa": "じゃあ",
		"ryokou": "りょこう", "gakkou": "がっこう", "denwa": "でんわ", "pan": "ぱん",
	}
	for romaji in words:
		assert_eq(RomajiConverter.to_kana(romaji), words[romaji], romaji)


func test_katakana_with_the_long_vowel_mark() -> void:
	assert_eq(RomajiConverter.to_kana("ko-hi-", "kata"), "コーヒー")
	assert_eq(RomajiConverter.to_kana("tesuto", "kata"), "テスト")
	assert_eq(RomajiConverter.to_kana("ra-men", "kata"), "ラーメン")
	assert_eq(RomajiConverter.to_kana("chi-zu", "kata"), "チーズ")


func test_spaces_capitals_and_full_width_letters() -> void:
	assert_eq(RomajiConverter.to_kana("  SHI "), "し")
	assert_eq(RomajiConverter.to_kana("Ka"), "か")
	assert_eq(RomajiConverter.to_kana("ｓｈｉ"), "し", "full-width letters from a Japanese keyboard")


func test_what_is_not_romaji_stays_as_it_is() -> void:
	assert_eq(RomajiConverter.to_kana(""), "")
	assert_eq(RomajiConverter.to_kana("q"), "q")
	assert_eq(RomajiConverter.to_kana("し", "kata"), "し", "typed hiragana never turns into katakana")


func test_is_correct_for_a_hiragana_item() -> void:
	var shi: Dictionary = {"kana": "し", "romaji": "shi", "alt_romaji": ["si"], "script": "hira"}
	for typed in ["shi", "si", " Shi ", "し"]:
		assert_true(RomajiConverter.is_correct(typed, shi), typed)
	for typed in ["su", "", "   ", "chi", "シ"]:
		assert_false(RomajiConverter.is_correct(typed, shi), typed)


func test_is_correct_uses_alt_romaji() -> void:
	var wo: Dictionary = {"kana": "を", "romaji": "wo", "alt_romaji": ["o"], "script": "hira"}
	assert_true(RomajiConverter.is_correct("wo", wo))
	assert_true(RomajiConverter.is_correct("o", wo), "o is accepted for を")
	assert_false(RomajiConverter.is_correct("wa", wo))


func test_is_correct_for_a_katakana_item() -> void:
	var shi: Dictionary = {"kana": "シ", "romaji": "shi", "alt_romaji": ["si"], "script": "kata"}
	assert_true(RomajiConverter.is_correct("si", shi))
	assert_true(RomajiConverter.is_correct("シ", shi))
	assert_false(RomajiConverter.is_correct("し", shi), "hiragana is not the katakana answer")
	assert_false(RomajiConverter.is_correct("tsu", shi), "シ and ツ are not the same")


func test_every_kana_in_data_accepts_its_romaji_and_alt_romaji() -> void:
	var checked: int = 0
	for path in ["res://data/hiragana.json", "res://data/katakana.json"]:
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		assert_typeof(parsed, TYPE_DICTIONARY, path)
		if not (parsed is Dictionary):
			continue
		for item in parsed["items"]:
			var label: String = "%s %s" % [item["id"], item["romaji"]]
			assert_eq(RomajiConverter.to_kana(item["romaji"], item["script"]), item["kana"], label)
			assert_true(RomajiConverter.is_correct(item["romaji"], item), label)
			for alt in item["alt_romaji"]:
				assert_true(RomajiConverter.is_correct(alt, item), "%s alt %s" % [item["id"], alt])
			checked += 1
	assert_true(checked >= 92, "46 hiragana and 46 katakana, found %d" % checked)
