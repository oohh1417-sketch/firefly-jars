extends Node
## Game text in 11 languages. The English text is the key; the other languages come from i18n_data.gd,
## which tools/i18n/build.py makes from tools/i18n/strings.py.
## Labels and buttons whose text is exactly an English key translate by themselves (Godot's auto-translate).
## Text with numbers in it goes through t("Level {0}", [5]).
## The game follows the phone's language unless the player picks one in Settings.

const Data := preload("res://scripts/i18n_data.gd")
## Extra fonts for the letters Baloo 2 and Fredoka don't have, cut down to just what the game uses.
const LANG_FONTS := {
	"ar": "res://fonts/lang/ar.woff2",
	"ru": "res://fonts/lang/ru.woff2",
	"ja": "res://fonts/lang/ja.woff2",
	"ko": "res://fonts/lang/ko.woff2",
	"zh": "res://fonts/lang/zh.woff2",
}
const BALOO := "res://fonts/Baloo2-Bold.woff2"
const BALOO_HEAVY := "res://fonts/Baloo2-ExtraBold.woff2"
const FREDOKA := "res://fonts/Fredoka-Bold.woff2"

signal changed

var lang := "en"

func _ready() -> void:
	for l in Data.DATA:
		var tr_res := Translation.new()
		tr_res.locale = l
		var d: Dictionary = Data.DATA[l]
		for k in d:
			tr_res.add_message(k, d[k])
		TranslationServer.add_translation(tr_res)
	apply(Save.language)

## "" = follow the phone. Otherwise one of Data.LANGS.
func apply(choice: String) -> void:
	lang = choice if Data.LANGS.has(choice) else phone_language()
	TranslationServer.set_locale(lang)
	_set_fonts()
	changed.emit()

func languages() -> Array:
	return Data.LANGS

func phone_language() -> String:
	var l := OS.get_locale_language()
	return l if Data.LANGS.has(l) else "en"

func is_rtl() -> bool:
	return lang == "ar"

## Translated text with {0}, {1} filled in.
func t(key: String, args: Array = []) -> String:
	var s := TranslationServer.translate(key)
	return s.format(args) if not args.is_empty() else s

## Capitals that are right for Turkish (i -> İ).
func up(s: String) -> String:
	if lang == "tr":
		s = s.replace("i", "İ")
	return s.to_upper()

func native_name(l: String) -> String:
	return Data.NATIVE.get(l, l)

## "Nov 24" in the player's language.
func date_text(month: int, day: int) -> String:
	var m: Dictionary = Data.MONTHS.get(lang, Data.MONTHS["en"])
	return str(m.fmt).format([m.names[month - 1], day])

## Every font falls back to the language fonts, the player's own language first
## (Japanese and Chinese share many characters but draw them differently).
func _set_fonts() -> void:
	var order := ["ar", "ru", "ja", "zh", "ko"]
	if order.has(lang):
		order.erase(lang)
		order.push_front(lang)
	var fb: Array[Font] = []
	for l in order:
		var f: Font = load(LANG_FONTS[l])
		if f:
			fb.append(f)
	for p in [BALOO, BALOO_HEAVY]:
		var base: FontFile = load(p)
		base.fallbacks = fb
	var logo: FontFile = load(FREDOKA)
	var logo_fb: Array[Font] = [load(BALOO_HEAVY)]   # Fredoka has no Turkish ğ ş İ
	logo_fb.append_array(fb)
	logo.fallbacks = logo_fb
