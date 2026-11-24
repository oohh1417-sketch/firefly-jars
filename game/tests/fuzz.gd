extends Node
func _ready():
	var S = get_tree().root.get_node("Save")
	S.level = 28; S.seen = {"cracked_jar": true, "color_jar": true, "lid": true, "daily": true, "hard": true, "extreme": true, "coins": true, "map": true, "lives": true}
	var main = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main)
	await get_tree().create_timer(0.5).timeout
	var issues := []
	for round in 5:
		main._start_level()
		await get_tree().create_timer(1.5).timeout
		for k in 80:
			var n: int = main.state.jars.size()
			var r := randf()
			if r < 0.75: main._on_jar_tapped(randi() % n)
			elif r < 0.85: main._undo()
			elif r < 0.9: main._on_hint_pressed()
			elif r < 0.94: main._restart()
			await get_tree().create_timer(0.02 if randf() < 0.5 else 0.25).timeout
		await get_tree().create_timer(1.6).timeout
		for i in main.state.jars.size():
			if main.board.flies[i].size() != main.state.jars[i].size(): issues.append("r%d jar %d flies %d vs %d" % [round, i, main.board.flies[i].size(), main.state.jars[i].size()])
		for i in main.board.corks.keys():
			if not Puzzle.is_jar_done(main.state.jars[i]): issues.append("r%d lid on unfinished jar %d" % [round, i])
		main.board.selected = -1
		main.board.hint_move = []
		main.moves_max = 0   # random play above may have used up a Hard level move limit
		var path = Puzzle.solve(main.state)
		if path == null:
			main._restart(); await get_tree().create_timer(1.5).timeout; path = Puzzle.solve(main.state)
		var before: int = S.level
		for m in path:
			main._on_jar_tapped(m[0]); main._on_jar_tapped(m[1]); await get_tree().create_timer(0.7).timeout
		await get_tree().create_timer(0.3).timeout
		main._restart(); main._undo()
		await get_tree().create_timer(4.0).timeout
		if not main.win_layer.visible or S.level != before + 1: issues.append("r%d win=%s level %d->%d" % [round, main.win_layer.visible, before, S.level])
		main.win_layer.hide()
	# home during celebration
	main._start_level(); await get_tree().create_timer(1.5).timeout
	main.moves_max = 0
	for m in Puzzle.solve(main.state):
		main._on_jar_tapped(m[0]); main._on_jar_tapped(m[1]); await get_tree().create_timer(0.7).timeout
	await get_tree().create_timer(0.3).timeout
	main._show_menu(); await get_tree().create_timer(4.0).timeout
	if main.win_layer.visible: issues.append("win card over menu")
	print("FUZZ issues: ", issues)
	get_tree().quit()
