extends Node
## Settings: switches save, color-blind symbols draw, privacy opens, tutorial replay keeps progress.
func _ready():
	var S = get_tree().root.get_node("Save")
	S.level = 13; S.seen = {"cracked_jar": true, "color_jar": true, "lid": true, "daily": true, "hard": true, "extreme": true, "coins": true, "map": true, "lives": true, "tutorial": true}; S.color_blind = false; S.vibrate_on = true
	var main = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main)
	await get_tree().create_timer(4.0).timeout
	main._show_settings(); await get_tree().create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/claude-0/shots/gd_set1.png")
	main._switches.cb.button_pressed = true; main._switches.vibrate.button_pressed = false
	var cfg := ConfigFile.new(); cfg.load("user://save.cfg")
	print("SET saved cb=", cfg.get_value("settings", "color_blind"), " vibrate=", cfg.get_value("settings", "vibrate"))
	main._show_privacy(); await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/claude-0/shots/gd_set2.png")
	main.privacy_layer.hide(); main.settings_layer.hide()
	main._start_level(); await get_tree().create_timer(2.0).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/claude-0/shots/gd_set3.png")
	main._show_menu(); main._show_settings(); main._start_practice(); main.settings_layer.hide()
	await get_tree().create_timer(1.8).timeout
	print("SET practice mode=", main.mode, " tut=", not main.tut.is_empty(), " label=", main.level_label.text)
	for k in 6:
		var t: int = main._tut_target()
		if t < 0: break
		main._on_jar_tapped(t); await get_tree().create_timer(0.7).timeout
	for m in Puzzle.solve(main.state):
		main._on_jar_tapped(m[0]); main._on_jar_tapped(m[1]); await get_tree().create_timer(0.7).timeout
	await get_tree().create_timer(4.0).timeout
	print("SET practice won=", main.win_layer.visible, " title=", main.win_title.text, " next=", main.next_btn.text, " level=", S.level)
	main.next_btn.pressed.emit(); await get_tree().create_timer(0.3).timeout
	print("SET back to menu=", main.menu_layer.visible)
	S.color_blind = false; S.vibrate_on = true; S.save_game()
	get_tree().quit()
