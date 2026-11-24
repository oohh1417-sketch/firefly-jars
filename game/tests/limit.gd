extends Node
## Hard level move limit: counter, out-of-moves card, undo refund, +5 video, retry, shortest path fits.
func any_move(s) -> Array:
	for a in s.jars.size():
		for c in s.jars.size():
			if a != c and Puzzle.can_pour(s, a, c): return [a, c]
	return []
func _ready():
	var S = get_tree().root.get_node("Save")
	S.level = 10; S.hints = 3; S.seen = {"cracked_jar": true, "color_jar": true, "lid": true, "daily": true, "hard": true, "extreme": true, "coins": true, "map": true, "lives": true, "tutorial": true}
	var main = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main)
	await get_tree().create_timer(4.0).timeout
	main._start_level()
	var t0 := Time.get_ticks_msec()
	while main.moves_max == 0 and Time.get_ticks_msec() - t0 < 10000: await get_tree().process_frame
	print("LIMIT ready after ", Time.get_ticks_msec() - t0, "ms limit=", main.move_limit, " pill=", main.moves_label.text, " visible=", main.moves_pill.visible)
	await get_tree().create_timer(1.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/claude-0/shots/gd_limit1.png")
	for k in 80:
		if main._out_of_moves(): break
		var m := any_move(main.state)
		if m.is_empty(): break
		main._on_jar_tapped(m[0]); main._on_jar_tapped(m[1]); main.board._busy_until = 0.0
		await get_tree().process_frame
	await get_tree().create_timer(1.5).timeout
	print("LIMIT out card=", main.out_layer != null and main.out_layer.visible, " moves=", main.moves, "/", main.moves_max, " pill=", main.moves_label.text)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/claude-0/shots/gd_limit2.png")
	main.out_layer.hide(); main._undo(); await get_tree().create_timer(0.7).timeout
	print("LIMIT after undo moves=", main.moves, " pill=", main.moves_label.text)
	main._on_reward("moves"); print("LIMIT after +5 max=", main.moves_max, " pill=", main.moves_label.text)
	main._load_state(Puzzle.copy(main.start_state), true); await get_tree().create_timer(1.5).timeout
	var p = Puzzle.shortest_path(main.state)
	print("LIMIT retry moves=", main.moves, "/", main.moves_max, " shortest=", p.size())
	main._on_hint_pressed(); print("LIMIT hint=", main.board.hint_move, " path0=", p[0])
	for m in p:
		main._on_jar_tapped(m[0]); main._on_jar_tapped(m[1]); await get_tree().create_timer(0.65).timeout
	await get_tree().create_timer(4.0).timeout
	print("LIMIT won=", main.win_layer.visible, " level=", S.level, " out=", main.out_layer.visible)
	get_tree().quit()
