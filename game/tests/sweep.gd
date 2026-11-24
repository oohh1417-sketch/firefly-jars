extends Node
## Chaotic sweep with real board input (taps and drags), hard levels, out of moves, hints, settings, practice.
var main
var issues := {}
func ev_btn(pos: Vector2, down: bool) -> void:
	var e := InputEventMouseButton.new(); e.button_index = MOUSE_BUTTON_LEFT; e.pressed = down; e.position = pos
	main.board._gui_input(e)
func ev_move(pos: Vector2) -> void:
	var e := InputEventMouseMotion.new(); e.position = pos
	main.board._gui_input(e)
func center(i: int) -> Vector2:
	return main.board._rects[i].get_center() if i < main.board._rects.size() else Vector2(360, 600)
func check(tag: String) -> void:
	var st: Dictionary = main.state
	if st.is_empty(): return
	for i in st.jars.size():
		if i < main.board.flies.size() and main.board.flies[i].size() != st.jars[i].size(): issues[tag + " flies/jar mismatch"] = 1
		if st.jars[i].size() > Puzzle.CAPACITY: issues[tag + " overfull"] = 1
	var counts := {}
	for j in st.jars:
		for c in j: counts[c] = counts.get(c, 0) + 1
	for c in counts:
		if counts[c] != Puzzle.CAPACITY: issues[tag + " color count"] = 1
	for i in main.board.corks.keys():
		if not Puzzle.is_jar_done(st.jars[i]): issues[tag + " lid on unfinished jar"] = 1
	if main.moves_max > 0 and main.moves > main.moves_max: issues[tag + " moves over limit"] = 1
	if main.out_layer and main.out_layer.visible and (main.won or main.moves_max == 0): issues[tag + " out card wrongly shown"] = 1
	if main.out_layer and main.out_layer.visible and main.win_layer.visible: issues[tag + " out+win stacked"] = 1
	if main.hard_tint.visible and main.menu_layer.visible: issues[tag + " hard tint on menu"] = 1
	if main.board._particles.size() > 600: issues[tag + " particle leak"] = 1
func _ready():
	var S = get_tree().root.get_node("Save")
	S.level = 9; S.hints = 5; S.seen = {}
	main = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main)
	await get_tree().create_timer(4.0).timeout
	for round in 10:
		S.lives = 5
		if main.nolives_layer and main.nolives_layer.visible: main.nolives_layer.hide()
		if main.tip_layer.visible: main._show_next_tip()
		if main.win_layer.visible: main.win_layer.hide()
		match round % 5:
			2: main._start_daily()
			4: main._start_practice()
			_: main._start_level()
		await get_tree().create_timer(1.0).timeout
		for k in 60:
			if main.tip_layer.visible: main._show_next_tip()
			if main.leave_layer and main.leave_layer.visible:
				if randf() < 0.5: main.leave_layer.hide()
				else: main.leave_yes.emit_signal("pressed")
			if main.menu_layer.visible: break
			var n: int = main.state.jars.size()
			var r := randf()
			if r < 0.35:
				var c := center(randi() % n); ev_btn(c, true); ev_btn(c, false)
			elif r < 0.6:
				var a := center(randi() % n); var d := center(randi() % n) + Vector2(randf_range(-60, 60), -randf() * 300)
				ev_btn(a, true)
				for s in 6: ev_move(a.lerp(d, (s + 1) / 6.0)); await get_tree().process_frame
				ev_btn(d, false)
			elif r < 0.68: main._undo()
			elif r < 0.73: main._on_hint_pressed()
			elif r < 0.76: main._restart()
			elif r < 0.78: if main.out_layer and main.out_layer.visible: main._on_reward("moves"); main.out_layer.hide()
			elif r < 0.8: main.board.selected = -1
			elif r < 0.81: main._show_settings(); main._switches.cb.button_pressed = not S.color_blind; main.settings_layer.hide()
			await get_tree().create_timer(0.03 if randf() < 0.5 else 0.3).timeout
			if k % 5 == 0: check("r%d" % round)
		# finish by following hints
		for k in 80:
			if main.won or main.menu_layer.visible: break
			if main.tip_layer.visible: main._show_next_tip()
			if main.out_layer and main.out_layer.visible:
				main.out_layer.hide(); main._on_reward("moves")
			main.board.selected = -1
			var p: Array = main._hint_path()
			if p.is_empty():
				main._restart(); await get_tree().create_timer(1.2).timeout; continue
			var a := center(p[0][0]); var d := center(p[0][1])
			if randf() < 0.5:
				ev_btn(a, true); ev_btn(a, false); ev_btn(d, true); ev_btn(d, false)
			else:
				ev_btn(a, true)
				for s in 5: ev_move(a.lerp(d, (s + 1) / 5.0)); await get_tree().process_frame
				ev_btn(d, false)
			await get_tree().create_timer(0.7).timeout
		await get_tree().create_timer(4.0).timeout
		check("end r%d" % round)
		print("SWEEP round ", round, " mode=", main.mode, " level=", S.level, " won=", main.won, " moves=", main.moves, "/", main.moves_max)
	print("SWEEP issues: ", issues.keys())
	S.color_blind = false; S.save_game()
	get_tree().quit()
