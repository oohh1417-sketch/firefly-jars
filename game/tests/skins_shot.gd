extends Node
## Screenshots of the skins shop and a level with skins on: /tmp/claude-0/work/skins/g-*.png
const OUT := "/tmp/claude-0/work/skins/g-"

func _shot(name: String) -> void:
	await get_tree().create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + I18n.lang + "-" + name + ".png")

func _ready():
	var S = get_tree().root.get_node("Save")
	S.level = 15; S.coins = 700; S.hints = 0; S.skins = {}; S.jar_skin = "classic"; S.fly_skin = "classic"
	S.seen = {"cracked_jar": true, "color_jar": true, "lid": true, "daily": true, "hard": true, "extreme": true, "coins": true, "map": true, "lives": true, "tutorial": true, "streak": true}
	var main = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main)
	await get_tree().create_timer(4.0).timeout
	var l := OS.get_environment("LANGS") if OS.get_environment("LANGS") != "" else "en"
	S.language = l
	I18n.apply(l)
	main._show_menu()
	await _shot("1menu")
	main._show_skins()
	await _shot("2shop")
	main.skins_grid.get_child(3).pressed.emit()   # pick Moonlight (500)
	await _shot("3picked")
	main._skins_action()
	print("BUY jar=", S.jar_skin, " coins=", S.coins, " owned=", S.skins)
	await _shot("4bought")
	main.skins_tabs["fly"].pressed.emit()
	await _shot("5flies")
	for id in ["bug", "fairy", "star", "royal"]:
		S.skins["fly_" + id] = true
	main.skins_grid.get_child(2).pressed.emit()
	print("USE fly=", S.fly_skin)
	await _shot("6flies_owned")
	main.skins_layer.hide()
	main._start_level()
	await get_tree().create_timer(1.5).timeout
	await _shot("7level")
	Store.buy_coins("coins_500")
	await _shot("8pack")
	Store.confirm_test_purchase()
	print("PACK coins=", S.coins)
	main.store_layer.hide()
	print("SKINS SHOTS done")
	get_tree().quit()
