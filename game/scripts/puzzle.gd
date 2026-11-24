class_name Puzzle
extends RefCounted
## Pure game rules: jars, pouring, win check, level generator and solver.
## Same rules as the web test version (web/firefly-jars.html).
##
## A puzzle state is a Dictionary:
##   jars:  Array of Arrays of color ids, bottom first. Each jar holds CAPACITY.
##   only:  per jar, -1 or a color id. A COLOR JAR accepts only that color.
##   locks: per jar, pours left before its LID pops off. While > 0, nothing goes in or out.

const CAPACITY := 4
const MAX_COLORS := 10
const SOLVER_NODE_LIMIT := 80000

# ---------- rules ----------

static func top_run(jar: Array) -> int:
	if jar.is_empty():
		return 0
	var c = jar[-1]
	var n := 0
	for i in range(jar.size() - 1, -1, -1):
		if jar[i] != c:
			break
		n += 1
	return n

static func can_pour(s: Dictionary, from: int, to: int) -> bool:
	if from == to:
		return false
	var a: Array = s.jars[from]
	var b: Array = s.jars[to]
	if a.is_empty() or b.size() >= CAPACITY or s.locks[from] > 0 or s.locks[to] > 0:
		return false
	if s.only[to] >= 0 and s.only[to] != a[-1]:
		return false
	return b.is_empty() or b[-1] == a[-1]

## Moves fireflies and returns how many moved (0 if not allowed). Counts every lid down by one.
static func pour(s: Dictionary, from: int, to: int) -> int:
	if not can_pour(s, from, to):
		return 0
	var a: Array = s.jars[from]
	var b: Array = s.jars[to]
	var n: int = min(top_run(a), CAPACITY - b.size())
	for i in n:
		b.append(a.pop_back())
	for i in s.locks.size():
		if s.locks[i] > 0:
			s.locks[i] -= 1
	return n

static func is_jar_done(jar: Array) -> bool:
	return jar.size() == CAPACITY and top_run(jar) == CAPACITY

static func is_solved(s: Dictionary) -> bool:
	for jar in s.jars:
		if not jar.is_empty() and not is_jar_done(jar):
			return false
	return true

static func copy(s: Dictionary) -> Dictionary:
	var jars := []
	for jar in s.jars:
		jars.append(jar.duplicate())
	return {"jars": jars, "only": s.only.duplicate(), "locks": s.locks.duplicate()}

# ---------- level design ----------

## GUESS on difficulty curve: start with 3 colors, add one every 4 levels, cap at 10.
static func colors_for_level(level: int) -> int:
	return clampi(3 + (level - 1) / 4, 3, MAX_COLORS)

## GUESS on pacing: color jars from level 10, lids from level 16, two lids from level 30.
static func spec_for_level(level: int) -> Dictionary:
	var lids := 0
	if level >= 16 and level % 3 == 2:
		lids = 2 if level >= 30 else 1
	# After the colors max out (level 29), normal levels keep getting a little harder every chapter:
	# more lids (on every level from 81), lids that need more pours to open, and the trickiest of several layouts.
	if level >= 41 and level % 3 == 0:
		lids = 1
	if level >= 81 and level % 3 == 1:
		lids = 1
	var pick := 1 + mini(3, (level - 21) / 20) if level >= 41 else 1
	var lock_min := 3 + mini(2, (level - 41) / 40) if level >= 41 else 3
	var spec := {"colors": colors_for_level(level), "color_jar": level >= 10 and level % 3 == 1, "lids": lids, "hard": false, "pick": pick, "lock_min": lock_min}
	if not is_hard(level):
		return spec
	# Hard level: two more colors than its neighbours; Extreme: three more, and from level 30 always a twist.
	# Levels 5 and 10 are gentle versions (one and two more colors) so new players aren't scared off.
	# Once the colors are maxed out, it gets a color jar and two lids instead.
	var ext := is_extreme(level)
	var more := colors_for_level(level) + (1 if level == 5 else (2 if level == 10 else (3 if ext else 2)))
	var hard_lids := lids
	if more > MAX_COLORS:
		hard_lids = maxi(lids, 2)
	elif ext and level >= 30:
		hard_lids = maxi(lids, 1)
	return {"colors": mini(MAX_COLORS, more),
		"color_jar": level >= 20 and (spec.color_jar or more > MAX_COLORS or (ext and level >= 30)),   # never a new twist on the first hard levels
		"lids": hard_lids, "hard": true, "extreme": ext, "lock_min": lock_min}

## Every chapter: its 5th level is Hard and its 10th (last) level is Extreme. is_hard is true for both.
static func is_hard(level: int) -> bool:
	return level >= 5 and level % 5 == 0

static func is_extreme(level: int) -> bool:
	return level >= 10 and level % 10 == 0

static func tier_name(level: int) -> String:
	return "Extreme" if is_extreme(level) else ("Hard" if is_hard(level) else "")

## Same level number always gives the same puzzle.
static func generate(level: int) -> Dictionary:
	return generate_spec(spec_for_level(level), "level-%d" % level)

## Same puzzle for everyone on the same date; medium-hard, uses both twists.
static func generate_daily(date_str: String) -> Dictionary:
	return generate_spec({"colors": 7, "color_jar": true, "lids": 1}, "daily-" + date_str)

static func generate_spec(spec: Dictionary, seed_text: String) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	var nc: int = spec.colors
	# Hard levels: try a few solvable layouts and keep the one the solver found hardest
	var want: int = 8 if spec.get("extreme", false) else (5 if spec.get("hard", false) else int(spec.get("pick", 1)))
	var best := {}
	var best_nodes := -1
	var found := 0
	for attempt in 300:
		rng.seed = hash("%s-%d" % [seed_text, attempt])
		var pool := []
		for c in nc:
			for i in CAPACITY:
				pool.append(c)
		_shuffle(pool, rng)
		var jars := []
		var only := []
		var locks := []
		for c in nc:
			jars.append(pool.slice(c * CAPACITY, (c + 1) * CAPACITY))
			only.append(-1)
			locks.append(0)
		for e in 2:
			jars.append([])
			only.append(-1)
			locks.append(0)
		if _too_easy(jars):
			continue
		if spec.color_jar:
			only[nc + 1] = rng.randi_range(0, nc - 1)
		var lid_jars := []
		while lid_jars.size() < spec.lids:
			var i := rng.randi_range(0, nc - 1)
			if not lid_jars.has(i):
				lid_jars.append(i)
		for i in lid_jars:
			locks[i] = rng.randi_range(int(spec.get("lock_min", 3)), int(spec.get("lock_min", 3)) + 3)
		# mix the jar order so special jars aren't always in the same spot
		var order := range(jars.size())
		_shuffle(order, rng)
		var s := {"jars": [], "only": [], "locks": []}
		for i in order:
			s.jars.append(jars[i])
			s.only.append(only[i])
			s.locks.append(locks[i])
		var res := solve_counted(s)
		if res[0] != null:
			if res[1] > best_nodes:
				best = s
				best_nodes = res[1]
			found += 1
			if found >= want:
				return best
	if not best.is_empty():
		return best
	push_warning("%s: fell back to a plain level" % seed_text)
	return generate_spec({"colors": nc, "color_jar": false, "lids": 0}, seed_text + "-plain")

static func _shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = arr[i]
		arr[i] = arr[j]
		arr[j] = t

static func _too_easy(jars: Array) -> bool:
	for jar in jars:
		if jar.size() > 0 and top_run(jar) >= CAPACITY - 1:
			return true
	return false

# ---------- solver (used for hints and to prove every level can be won) ----------

static func _key(s: Dictionary) -> String:
	var parts := PackedStringArray()
	for i in s.jars.size():
		var jar: Array = s.jars[i]
		parts.append(",".join(PackedStringArray(jar.map(func(x): return str(x)))) + "/%d/%d" % [s.only[i], s.locks[i]])
	parts.sort()
	return "|".join(parts)

## Returns an Array of [from, to] moves that solves the puzzle ([] if already solved),
## or null if no solution was found.
static func solve(start: Dictionary):
	return solve_counted(start)[0]

## Like solve(), but also says how many positions the search had to look at ([path or null, count]).
## Hard levels use the count to pick tough layouts. (No shared state, so it is safe on background threads.)
static func solve_counted(start: Dictionary) -> Array:
	if is_solved(start):
		return [[], 0]
	var seen := {}
	var stack := [[copy(start), []]]
	seen[_key(start)] = true
	var nodes := 0
	while not stack.is_empty():
		var item = stack.pop_back()
		var s: Dictionary = item[0]
		var path: Array = item[1]
		nodes += 1
		if nodes > SOLVER_NODE_LIMIT:
			return [null, nodes]
		var moves := _ordered_moves(s)
		for k in range(moves.size() - 1, -1, -1):
			var m = moves[k]
			var next := copy(s)
			pour(next, m[0], m[1])
			var key := _key(next)
			if seen.has(key):
				continue
			seen[key] = true
			var next_path := path.duplicate()
			next_path.append(m)
			if is_solved(next):
				return [next_path, nodes]
			stack.append([next, next_path])
	return [null, nodes]

static func _ordered_moves(s: Dictionary) -> Array:
	var good := []
	var other := []
	for i in s.jars.size():
		var a: Array = s.jars[i]
		if a.is_empty() or is_jar_done(a) or s.locks[i] > 0:
			continue
		var uniform := top_run(a) == a.size()
		var tried_empty := {}
		for j in s.jars.size():
			if not can_pour(s, i, j):
				continue
			var b: Array = s.jars[j]
			if b.is_empty():
				# a one-color jar poured into a plain empty jar changes nothing
				if uniform and s.only[j] < 0 and s.only[i] < 0:
					continue
				if tried_empty.has(s.only[j]):
					continue
				tried_empty[s.only[j]] = true
				if s.only[j] >= 0:
					good.append([i, j])
				else:
					other.append([i, j])
			else:
				good.append([i, j])
	return good + other

# ---------- move limit for Hard levels ----------

## Fewest pours that solve the puzzle (A* search), as an Array of [from, to] moves, or null if not
## found within `limit` positions. The estimate counts color changes inside jars: one pour can fix
## at most one, so the answer is exact.
## weight > 1 trades the guaranteed shortest route for a much faster search (a near-shortest one).
static func shortest_path(start: Dictionary, limit := 40000, weight := 1):
	var best := {_key(start): 0}
	var heap := [[_breaks(start), 0, copy(start), []]]
	var nodes := 0
	while not heap.is_empty():
		var item: Array = _heap_pop(heap)
		var s: Dictionary = item[2]
		var d: int = item[1]
		if is_solved(s):
			return item[3]
		nodes += 1
		if nodes > limit:
			return null
		if best.get(_key(s), 1 << 30) < d:
			continue
		for m in _ordered_moves(s):
			var nx := copy(s)
			pour(nx, m[0], m[1])
			var k := _key(nx)
			if best.has(k) and best[k] <= d + 1:
				continue
			best[k] = d + 1
			var np: Array = item[3].duplicate()
			np.append(m)
			_heap_push(heap, [d + 1 + weight * _breaks(nx), d + 1, nx, np])
	return null

static func _breaks(s: Dictionary) -> int:
	var n := 0
	for jar in s.jars:
		for k in range(1, jar.size()):
			if jar[k] != jar[k - 1]:
				n += 1
	return n

static func _heap_push(h: Array, x: Array) -> void:
	h.append(x)
	var i := h.size() - 1
	while i > 0:
		var p := (i - 1) >> 1
		if h[p][0] <= h[i][0]:
			break
		var t = h[p]; h[p] = h[i]; h[i] = t
		i = p

static func _heap_pop(h: Array) -> Array:
	var top: Array = h[0]
	var last: Array = h.pop_back()
	if not h.is_empty():
		h[0] = last
		var i := 0
		while true:
			var l := 2 * i + 1
			var r := l + 1
			var m := i
			if l < h.size() and h[l][0] < h[m][0]: m = l
			if r < h.size() and h[r][0] < h[m][0]: m = r
			if m == i: break
			var t = h[m]; h[m] = h[i]; h[i] = t
			i = m
	return top

## Hard levels allow the fewest possible pours plus a fair buffer (35%, at least 5). 0 = no limit.
## GUESS: the buffer size; easy to tune.
static func move_limit(level: int, s: Dictionary) -> int:
	if not is_hard(level):
		return 0
	var path = shortest_path(s)
	if path == null:
		path = solve(s)
	return limit_for(path.size() if path != null else 60, level)

## Hard: 35% spare (at least 5). Extreme: 20% (at least 3). The gentle first ones: level 5 gets 60% (at least 8),
## level 10 gets 35%. GUESS: tunable. Same numbers as the web version (limitFor).
static func limit_for(best: int, level := 15) -> int:
	if level == 5:
		return best + maxi(8, ceili(best * 0.6))
	if is_extreme(level) and level > 10:
		return best + maxi(3, ceili(best * 0.2))
	return best + maxi(5, ceili(best * 0.35))
