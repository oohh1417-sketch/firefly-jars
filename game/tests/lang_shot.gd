extends Node
## Screenshots of the main screens in every language (for checking text fits): /tmp/claude-0/work/shots/<lang>-<screen>.png
## Run: godot --path game res://tests/run_lang_shot.tscn  (needs a display; set LANGS env to a comma list to limit)
const OUT := "/tmp/claude-0/work/shots/"

func _shot(main: Node, name: String) -> void:
	await get_tree().create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + I18n.lang + "-" + name + ".png")

func _ready():
	var S = get_tree().root.get_node("Save")
	S.level = 15; S.coins = 120; S.hints = 0
	S.seen = {"cracked_jar": true, "color_jar": true, "lid": true, "daily": true, "hard": true, "extreme": true, "coins": true, "map": true, "lives": true, "tutorial": true, "streak": true}
	var main = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main)
	await get_tree().create_timer(4.0).timeout
	var langs: Array = I18n.languages()
	if OS.get_environment("LANGS") != "":
		langs = OS.get_environment("LANGS").split(",")
	for l in langs:
		S.language = l
		I18n.apply(l)
		main._show_menu()
		await _shot(main, "1menu")
		main._show_settings()
		await _shot(main, "2settings")
		main.settings_layer.hide()
		main._show_gifts()
		await _shot(main, "3gifts")
		main.gifts_layer.hide()
		main._start_level()
		await get_tree().create_timer(1.2).timeout
		await _shot(main, "4level")
		main._offer("hint")
		await _shot(main, "5offer")
		main.offer_layer.hide()
		main._show_trophies()
		await _shot(main, "6trophies")
		main.trophies_layer.hide()
		main.moves = 1
		main._confirm_leave("restart", func(): pass)
		await _shot(main, "7leave")
		main.leave_layer.hide()
		main._show_tip("lid")
		await _shot(main, "8tip")
		main.tip_layer.hide()
		main._show_skins()
		await _shot(main, "skins")
		main.skins_layer.hide()
		main._show_languages()
		await _shot(main, "9langs")
		main.lang_layer.hide()
	print("LANG SHOTS done")
	get_tree().quit()
