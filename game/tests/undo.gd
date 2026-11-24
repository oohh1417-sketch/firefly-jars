extends Node
func _ready():
	var S = get_tree().root.get_node("Save")
	S.level = 8; S.seen = {"cracked_jar": true, "color_jar": true, "lid": true, "daily": true, "hard": true, "extreme": true, "coins": true, "map": true, "lives": true}
	var main = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main)
	await get_tree().create_timer(0.5).timeout
	main._start_level(); await get_tree().create_timer(1.5).timeout
	var p = Puzzle.solve(main.state)
	for m in p.slice(0, 5):
		main._on_jar_tapped(m[0]); main._on_jar_tapped(m[1]); await get_tree().create_timer(0.7).timeout
	var res := []
	for k in 5:
		var h: int = main.history.size()
		main._undo(); await get_tree().create_timer(0.7).timeout
		res.append("%d:%d->%d badge=%s" % [k, h, main.history.size(), main.undo_btn.badge])
	main._restart(); await get_tree().create_timer(1.5).timeout
	print("UNDO ", res, " after restart badge=", main.undo_btn.badge)
	get_tree().quit()
