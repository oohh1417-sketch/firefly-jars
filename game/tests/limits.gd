extends SceneTree
func _init():
	for lv in range(10, 101, 5):
		var s = Puzzle.generate(lv)
		var t0 = Time.get_ticks_msec()
		var best = Puzzle.shortest_moves(s)
		var ms = Time.get_ticks_msec() - t0
		var dfs = Puzzle.solve(s).size()
		print("LIM L%d best=%d dfs=%d limit=%d %dms" % [lv, best, dfs, Puzzle.move_limit(lv, s), ms])
	quit()
