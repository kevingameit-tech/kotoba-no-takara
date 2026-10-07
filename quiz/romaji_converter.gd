class_name RomajiConverter
extends RefCounted
## Turns what the player types in "type" mode into kana, so "shi", "si" and " SHI " all become し.
## Contract: docs/contracts.md, section 8 ("type" answers are normalised: trim, lower case,
## romaji to kana). Static functions only, nothing to create or free.
## The rules follow a Japanese keyboard (IME): "kitte" gives きって, "kon'ya" こんや, "nn" ん.

const SCRIPT_HIRA: String = "hira"
const SCRIPT_KATA: String = "kata"
const VOWELS: String = "aeiou"
## A doubled one of these gives the small っ ("kk", "tt", ...). Never "n": "nn" is ん.
const DOUBLE_CONSONANTS: String = "bcdfghjkmpqrstvwxyz"
const LONGEST_KEY: int = 4
const HIRA_FIRST: int = 0x3041
const HIRA_LAST: int = 0x3096
const KATA_OFFSET: int = 0x60
const FULL_WIDTH_FIRST: int = 0xFF01
const FULL_WIDTH_LAST: int = 0xFF5E
const FULL_WIDTH_OFFSET: int = 0xFEE0
const IDEOGRAPHIC_SPACE: int = 0x3000

## Hiragana for each spelling: Hepburn, Kunrei (si, ti, tu, hu, zi), keyboard extras
## (small kana with x or l) and "-" for the long vowel mark of katakana words.
const TABLE: Dictionary = {
	"a": "あ", "i": "い", "u": "う", "e": "え", "o": "お",
	"ka": "か", "ki": "き", "ku": "く", "ke": "け", "ko": "こ",
	"sa": "さ", "shi": "し", "si": "し", "su": "す", "se": "せ", "so": "そ",
	"ta": "た", "chi": "ち", "ti": "ち", "tsu": "つ", "tu": "つ", "te": "て", "to": "と",
	"na": "な", "ni": "に", "nu": "ぬ", "ne": "ね", "no": "の",
	"ha": "は", "hi": "ひ", "fu": "ふ", "hu": "ふ", "he": "へ", "ho": "ほ",
	"ma": "ま", "mi": "み", "mu": "む", "me": "め", "mo": "も",
	"ya": "や", "yu": "ゆ", "yo": "よ",
	"ra": "ら", "ri": "り", "ru": "る", "re": "れ", "ro": "ろ",
	"wa": "わ", "wo": "を",
	"ga": "が", "gi": "ぎ", "gu": "ぐ", "ge": "げ", "go": "ご",
	"za": "ざ", "ji": "じ", "zi": "じ", "zu": "ず", "ze": "ぜ", "zo": "ぞ",
	"da": "だ", "di": "ぢ", "du": "づ", "dzu": "づ", "de": "で", "do": "ど",
	"ba": "ば", "bi": "び", "bu": "ぶ", "be": "べ", "bo": "ぼ",
	"pa": "ぱ", "pi": "ぴ", "pu": "ぷ", "pe": "ぺ", "po": "ぽ",
	"kya": "きゃ", "kyu": "きゅ", "kyo": "きょ",
	"sha": "しゃ", "shu": "しゅ", "sho": "しょ", "she": "しぇ",
	"sya": "しゃ", "syu": "しゅ", "syo": "しょ",
	"cha": "ちゃ", "chu": "ちゅ", "cho": "ちょ", "che": "ちぇ",
	"tya": "ちゃ", "tyu": "ちゅ", "tyo": "ちょ", "cya": "ちゃ", "cyu": "ちゅ", "cyo": "ちょ",
	"nya": "にゃ", "nyu": "にゅ", "nyo": "にょ",
	"hya": "ひゃ", "hyu": "ひゅ", "hyo": "ひょ",
	"mya": "みゃ", "myu": "みゅ", "myo": "みょ",
	"rya": "りゃ", "ryu": "りゅ", "ryo": "りょ",
	"gya": "ぎゃ", "gyu": "ぎゅ", "gyo": "ぎょ",
	"ja": "じゃ", "ju": "じゅ", "jo": "じょ", "je": "じぇ",
	"jya": "じゃ", "jyu": "じゅ", "jyo": "じょ", "zya": "じゃ", "zyu": "じゅ", "zyo": "じょ",
	"dya": "ぢゃ", "dyu": "ぢゅ", "dyo": "ぢょ",
	"bya": "びゃ", "byu": "びゅ", "byo": "びょ",
	"pya": "ぴゃ", "pyu": "ぴゅ", "pyo": "ぴょ",
	"fa": "ふぁ", "fi": "ふぃ", "fe": "ふぇ", "fo": "ふぉ",
	"thi": "てぃ", "dhi": "でぃ", "wi": "うぃ", "we": "うぇ", "ye": "いぇ",
	"xa": "ぁ", "xi": "ぃ", "xu": "ぅ", "xe": "ぇ", "xo": "ぉ",
	"la": "ぁ", "li": "ぃ", "lu": "ぅ", "le": "ぇ", "lo": "ぉ",
	"xya": "ゃ", "xyu": "ゅ", "xyo": "ょ", "lya": "ゃ", "lyu": "ゅ", "lyo": "ょ",
	"xtu": "っ", "xtsu": "っ", "ltu": "っ", "ltsu": "っ", "xwa": "ゎ", "lwa": "ゎ",
	"-": "ー",
}


## Trim, lower case, and full-width letters (ｓｈｉ from a Japanese keyboard) to normal ones.
static func normalize(text: String) -> String:
	var out: String = ""
	for character in text:
		var code: int = character.unicode_at(0)
		if code >= FULL_WIDTH_FIRST and code <= FULL_WIDTH_LAST:
			out += String.chr(code - FULL_WIDTH_OFFSET)
		elif code == IDEOGRAPHIC_SPACE:
			out += " "
		else:
			out += character
	return out.strip_edges().to_lower()


## Romaji to kana in [param script] ("hira" or "kata"). What is not romaji (kana typed
## directly, digits, unknown letters) stays as it is, so it never matches by accident.
static func to_kana(text: String, script: String = SCRIPT_HIRA) -> String:
	var romaji: String = normalize(text)
	var out: String = ""
	var i: int = 0
	while i < romaji.length():
		var c: String = romaji[i]
		var next: String = romaji[i + 1] if i + 1 < romaji.length() else ""
		if c == "n" and not _starts_syllable(next):
			# ん: "n" before a consonant or at the end, "nn", or "n'" before a vowel.
			var after: String = romaji[i + 2] if i + 2 < romaji.length() else ""
			if next == "'" or (next == "n" and not _starts_syllable(after)):
				i += 2
			else:
				i += 1
			out += _in_script("ん", script)
			continue
		if (c == next and DOUBLE_CONSONANTS.contains(c)) or (c == "t" and romaji.substr(i + 1, 2) == "ch"):
			out += _in_script("っ", script)
			i += 1
			continue
		var size: int = _longest_match(romaji, i)
		if size == 0:
			out += c
			i += 1
		else:
			out += _in_script(TABLE[romaji.substr(i, size)], script)
			i += size
	return out


## True when [param typed] is the reading of [param item], a kana item from data/: its romaji,
## one of its alt_romaji (for example "o" for を), or the same kana after conversion.
static func is_correct(typed: String, item: Dictionary) -> bool:
	var answer: String = normalize(typed)
	if answer == "":
		return false
	if answer == str(item.get("romaji", "")):
		return true
	var alternatives: Variant = item.get("alt_romaji", [])
	if alternatives is Array and (alternatives as Array).has(answer):
		return true
	return to_kana(answer, str(item.get("script", SCRIPT_HIRA))) == str(item.get("kana", ""))


static func _starts_syllable(character: String) -> bool:
	return character != "" and (VOWELS.contains(character) or character == "y")


## The length of the longest TABLE key at [param start], or 0 when there is none.
static func _longest_match(romaji: String, start: int) -> int:
	for size in range(LONGEST_KEY, 0, -1):
		var part: String = romaji.substr(start, size)
		if part.length() == size and TABLE.has(part):
			return size
	return 0


static func _in_script(hiragana: String, script: String) -> String:
	if script != SCRIPT_KATA:
		return hiragana
	var out: String = ""
	for character in hiragana:
		var code: int = character.unicode_at(0)
		if code >= HIRA_FIRST and code <= HIRA_LAST:
			code += KATA_OFFSET
		out += String.chr(code)
	return out
