extends GutTest
## Theme v1 and font glyphs tests (Mariana).
## Contract: docs/contracts.md, section 2 (Fonts) and section 3 (Ownership).
## Issue #37: [ui] Theme v1: Pixelify Sans + DotGothic16 fallback.

const THEME_PATH := "res://ui/theme.tres"
const UI_CSV_PATH := "res://i18n/ui.csv"

var theme: Theme
var font: Font


func before_all() -> void:
	theme = load(THEME_PATH)
	if theme != null:
		font = theme.default_font


func test_theme_resource_loads() -> void:
	assert_not_null(theme, "Tema res://ui/theme.tres trebuie să poată fi încărcată.")
	assert_not_null(font, "Tema trebuie să aibă definit un default_font.")


func test_project_settings_custom_theme() -> void:
	var custom_theme: String = ProjectSettings.get_setting("gui/theme/custom", "")
	assert_eq(custom_theme, THEME_PATH, "project.godot trebuie să aibă gui/theme/custom configurat.")


func test_include_text_server_data_is_enabled() -> void:
	var text_server_data: bool = ProjectSettings.get_setting("internationalization/locale/include_text_server_data", false)
	assert_true(text_server_data, "include_text_server_data trebuie să rămână activat pentru web și mobil.")


func test_romanian_glyphs() -> void:
	assert_not_null(font, "Fontul temei trebuie să existe.")
	# Verificăm diacriticele românești cu virgulă dedesubt (U+0218 - U+021B)
	var ro_chars := "ăâîșțĂÂÎȘȚ"
	for i in ro_chars.length():
		var code: int = ro_chars.unicode_at(i)
		assert_true(font.has_char(code), "Fontul trebuie să conțină glifa pentru '%s' (U+%04X)" % [ro_chars[i], code])

	var sample_ro := "Zigzagul e o scară de evacuare. Joc nou, Setări, Înapoi, Continuă."
	for i in sample_ro.length():
		var code: int = sample_ro.unicode_at(i)
		assert_true(font.has_char(code), "Fontul trebuie să conțină glifa pentru '%s' din textul românesc" % sample_ro[i])


func test_japanese_kana_and_symbols_fallback() -> void:
	assert_not_null(font, "Fontul temei trebuie să existe.")
	# Hiragana de bază
	var hiragana := "あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをん"
	for i in hiragana.length():
		var code: int = hiragana.unicode_at(i)
		assert_true(font.has_char(code), "Fallback-ul DotGothic16 trebuie să aibă Hiragana '%s'" % hiragana[i])

	# Katakana de bază
	var katakana := "アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン"
	for i in katakana.length():
		var code: int = katakana.unicode_at(i)
		assert_true(font.has_char(code), "Fallback-ul DotGothic16 trebuie să aibă Katakana '%s'" % katakana[i])

	# Simboluri de feedback din joc (○, ×, →)
	var symbols := "○×→"
	for i in symbols.length():
		var code: int = symbols.unicode_at(i)
		assert_true(font.has_char(code), "Fallback-ul DotGothic16 trebuie să aibă simbolul '%s'" % symbols[i])


func test_all_ui_csv_characters_have_glyphs() -> void:
	assert_not_null(font, "Fontul temei trebuie să existe.")
	assert_true(FileAccess.file_exists(UI_CSV_PATH), "i18n/ui.csv trebuie să existe.")
	var file := FileAccess.open(UI_CSV_PATH, FileAccess.READ)
	assert_not_null(file, "i18n/ui.csv trebuie să poată fi deschis.")

	# Ignorăm antetul
	var _header := file.get_csv_line()

	while not file.eof_reached():
		var line := file.get_csv_line()
		if line.size() < 3 or line[0].strip_edges().is_empty():
			continue
		var en_text: String = line[1]
		var ro_text: String = line[2]
		for text in [en_text, ro_text]:
			for i in text.length():
				var code: int = text.unicode_at(i)
				assert_true(font.has_char(code), "Caracterul '%s' din ui.csv trebuie să aibă glifă în tema globală" % text[i])

	file.close()
