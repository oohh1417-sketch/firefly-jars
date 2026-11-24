extends Node
func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/claude-0/work/%s.png" % name)

func _ready():
	var S = get_tree().root.get_node("Save")
	S.level = 45; S.map_ch = 0; S.coins = 120; S.seen = {"cracked_jar": true, "color_jar": true, "lid": true, "daily": true, "hard": true, "extreme": true, "coins": true, "map": true, "lives": true, "tutorial": true}
	var main = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main)
	await get_tree().create_timer(4.0).timeout
	var bad := []
	main.menu_play_btn.pressed.emit()
	await get_tree().create_timer(0.8).timeout
	if not main.map_layer.visible: bad.append("map not shown")
	if S.map_ch != 5: bad.append("map_ch %d" % S.map_ch)
	await _shot("gdmap1")
	# drag up to look ahead
	var mv = main.map_view
	var s0: float = mv.scroll
	var ev := InputEventMouseButton.new(); ev.button_index = MOUSE_BUTTON_LEFT; ev.pressed = true; ev.position = Vector2(360, 400)
	mv._gui_input(ev)
	for k in 10:
		var m := InputEventMouseMotion.new(); m.position = Vector2(360, 400 + k * 60)
		mv._gui_input(m)
		await get_tree().process_frame
	ev = ev.duplicate(); ev.pressed = false; ev.position = Vector2(360, 940)
	mv._gui_input(ev)
	await get_tree().create_timer(1.0).timeout
	if mv.scroll >= s0: bad.append("drag did not scroll")
	await _shot("gdmap2")
	# tap on the current stone plays
	main._show_map("menu")
	await get_tree().create_timer(0.3).timeout
	var G: Dictionary = mv.geom()
	var p: Vector2 = mv.stop_pos(G, S.level) - Vector2(0, mv.scroll)
	ev = InputEventMouseButton.new(); ev.button_index = MOUSE_BUTTON_LEFT; ev.pressed = true; ev.position = p
	mv._gui_input(ev)
	ev = ev.duplicate(); ev.pressed = false
	mv._gui_input(ev)
	await get_tree().create_timer(0.5).timeout
	if main.map_layer.visible or main.menu_layer.visible: bad.append("tap did not start level")
	# a finished chapter: the map celebrates the new one
	S.level = 51; S.map_ch = 5
	main._show_map("win")
	await get_tree().create_timer(2.6).timeout
	await _shot("gdmap3")
	if S.map_ch != 6: bad.append("celebrate map_ch %d" % S.map_ch)
	if mv._banner.is_empty(): bad.append("no banner")
	# back from a win-opened map goes to the menu
	main.map_layer.get_child(1).pressed.emit()
	await get_tree().create_timer(0.3).timeout
	if not main.menu_layer.visible: bad.append("back did not show menu")
	# map play button starts the level
	main.menu_play_btn.pressed.emit()
	await get_tree().create_timer(0.3).timeout
	main._map_play()
	await get_tree().create_timer(0.5).timeout
	if main.map_layer.visible or main.menu_layer.visible or main.mode != "level": bad.append("play button")
	print("MAP bad=", bad)
	get_tree().quit()
