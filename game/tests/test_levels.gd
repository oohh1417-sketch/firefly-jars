extends SceneTree
func check(s, label, bad):
	var p = Puzzle.solve(s)
	if p == null:
		bad.append(label); return
	var t = Puzzle.copy(s)
	for m in p:
		if Puzzle.pour(t, m[0], m[1]) == 0:
			bad.append(label + " illegal"); return
	if not Puzzle.is_solved(t): bad.append(label + " unsolved")
func _init():
	var t0 = Time.get_ticks_msec()
	var bad = []
	var worst = 0
	var cj = 0
	var lid = 0
	for lv in range(1, 201):
		var a = Time.get_ticks_msec()
		var s = Puzzle.generate(lv)
		worst = max(worst, Time.get_ticks_msec() - a)
		var sp = Puzzle.spec_for_level(lv)
		var has_cj = s.only.any(func(x): return x >= 0)
		var nl = s.locks.filter(func(x): return x > 0).size()
		if has_cj != sp.color_jar or nl != sp.lids: bad.append("L%d spec" % lv)
		if has_cj: cj += 1
		if nl: lid += 1
		check(s, "L%d" % lv, bad)
	for d in 90:
		var ds = Time.get_date_string_from_unix_time(1795305600 + d * 86400)
		var s = Puzzle.generate_daily(ds)
		if not s.only.any(func(x): return x >= 0) or not s.locks.any(func(x): return x > 0): bad.append("D" + ds + " twist")
		check(s, "D" + ds, bad)
	var S = {"jars": [[0, 1], [1], [], [2, 2, 2]], "only": [-1, -1, 0, -1], "locks": [0, 0, 0, 2]}
	print("color jar rejects other: ", not Puzzle.can_pour(S, 1, 2))
	print("locked blocked: ", not Puzzle.can_pour(S, 3, 2) and not Puzzle.can_pour(S, 1, 3))
	var T2 = Puzzle.copy(S); Puzzle.pour(T2, 0, 1); print("lid counts down: ", T2.locks[3] == 1, " original untouched: ", S.locks[3] == 2)
	print("bad=", bad, " colorjar levels=", cj, " lid levels=", lid, " worst_ms=", worst, " total_ms=", Time.get_ticks_msec() - t0)
	quit()
