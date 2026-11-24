extends Node
var main
func play_all() -> Array:
	await get_tree().create_timer(1.0).timeout
	var path = Puzzle.solve(main.state)
	for m in path:
		main._on_jar_tapped(m[0]); main._on_jar_tapped(m[1])
		await get_tree().create_timer(0.65).timeout
	await get_tree().create_timer(4.5).timeout
	return [path.size(), Puzzle.is_solved(main.state), main.win_layer.visible]
func _ready():
	main = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main)
	await get_tree().create_timer(0.3).timeout
	var S = get_tree().root.get_node("Save")
	S.level = 13   # first color jar level (level 10 is now a Hard level with no new twist)
	main._start_level()
	print("tip: ", main.tip_layer.visible, " ", main.tip_title.text)
	main._show_next_tip()
	await get_tree().create_timer(0.9).timeout
	var cj = main.state.only.find(main.state.only.filter(func(x): return x >= 0)[0])
	var src = -1
	for i in main.state.jars.size():
		if main.state.jars[i].size() > 0 and main.state.jars[i][-1] != main.state.only[cj] and main.state.locks[i] == 0: src = i; break
	main._on_jar_tapped(src); main._on_jar_tapped(cj)
	print("color jar blocked: ", main.state.jars[cj].size() == 0, " msg=", main.info_label.text)
	print("L13: ", await play_all(), " level now ", S.level)
	main.win_layer.hide()
	S.level = 17
	main._start_level()
	print("tip: ", main.tip_title.text)
	main._show_next_tip()
	await get_tree().create_timer(0.9).timeout
	var l = main.state.locks.find(main.state.locks.filter(func(x): return x > 0)[0])
	main._on_jar_tapped(l)
	print("locked tap msg=", main.info_label.text, " selected=", main.board.selected)
	# undo restores lids
	var start = Puzzle.copy(main.state)
	var p = Puzzle.solve(main.state)
	for m in p.slice(0, 3):
		main._on_jar_tapped(m[0]); main._on_jar_tapped(m[1]); await get_tree().create_timer(0.65).timeout
	var mid = main.state.locks.duplicate()
	for k in 3:
		main._undo(); await get_tree().create_timer(0.65).timeout
	var ok = true
	for i in main.state.jars.size():
		if main.board.flies[i].size() != main.state.jars[i].size(): ok = false
	print("undo: start=", start.locks, " mid=", mid, " back=", main.state.locks, " same=", JSON.stringify(start) == JSON.stringify(main.state), " flies ok=", ok)
	print("L17: ", await play_all(), " level now ", S.level)
	main.win_layer.hide()
	main._start_daily()
	print("daily tip: ", main.tip_title.text)
	while main.tip_layer.visible: main._show_next_tip()
	print("daily: ", await play_all(), " streak=", S.streak, " done=", S.daily_done, " label=", main.win_label.text.replace("\n", " | "))
	main._refresh()
	print("menu daily btn: ", main.daily_sub.text, " streak ", main.daily_streak.text)
	get_tree().quit()
