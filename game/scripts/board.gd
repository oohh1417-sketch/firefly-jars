extends Control
## Draws the jars and fireflies, runs all the animations, and turns taps into signals.
## All art is drawn with code, so there are no image files to license.
##
## Every firefly is its own little object that flies toward where it belongs, so
## selecting, pouring, undoing and starting a level all animate on their own.

signal jar_tapped(index: int)
signal empty_tapped
signal drag_dropped(from: int, to: int)   # to = -1 when dropped in the air
signal extra_tapped                       # the cracked jar was tapped

const COLORS := Art.COLORS
const ARC_TIME := 0.43
const ARC_STAGGER := 0.08

var state: Dictionary = {"jars": [], "only": [], "locks": []}
var jars: Array = []          # same Array as state.jars
var flies: Array = []          # flies[jar] = Array of Dictionary, same order as jars[jar]
var selected := -1
var hint_move: Array = []
var corks := {}                # jar index -> time the cork landed
var lids_off := {}             # jar index -> time its lid popped off
var win_time := -1.0
var tut_jar := -1:             # the tutorial hand points at this jar (-1 = no hand)
	set(v):
		if v != tut_jar:
			_tut_since = _now
		tut_jar = v
var tut_drag_from := -1       # second tutorial pour: the hand shows a drag from this jar...
var tut_drag_to := -1         # ...into this jar
var drag := {}                 # {"i", "pos", "start", "moved", "trail": [[pos, time]], "defer"} while a finger holds lifted fireflies
var tut_nudge := -100.0        # time the wrong jar was tapped, so the hand shakes
var _tut_since := 0.0

var _rects: Array[Rect2] = []
var _shelves: Array[Rect2] = []
var _now := 0.0
var _busy_until := 0.0
var _shake_jar := -1
var _shake_start := 0.0
var _particles: Array = []
var _next_id := 1

# The cracked jar: drawn after the real jars until helper fireflies mend it (main.gd adds the jar).
var extra_state := ""          # "" (none), "cracked", "repairing" or "fixed"
var _repair_t0 := -100.0
var _repair_rect := Rect2()
var _flash_t := -100.0
var _twinkle_t := -100.0
var _drag_dist := 0.0
var _helper_tw := -1
const FLY_IN := 0.8
const MEND := 1.3
const FLY_OUT := 0.8
const CRACKS := [[Vector2(.62, .2), Vector2(.53, .33), Vector2(.6, .42), Vector2(.47, .55), Vector2(.55, .64), Vector2(.44, .79)],
	[Vector2(.53, .33), Vector2(.38, .39), Vector2(.29, .36)], [Vector2(.47, .55), Vector2(.66, .6), Vector2(.74, .71)],
	[Vector2(.24, .68), Vector2(.33, .75), Vector2(.27, .86)]]
const HELPER_GOLD := Color("#fff0a0")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(_layout)

# ---------------- public API used by main.gd ----------------

func set_state(new_state: Dictionary, fly_in: bool) -> void:
	state = new_state
	_busy_until = 0.0
	jars = state.jars
	selected = -1
	hint_move = []
	corks = {}
	lids_off = {}
	win_time = -1.0
	_repair_t0 = -100.0
	_layout()
	flies = []
	for i in jars.size():
		var list := []
		for s in jars[i].size():
			var f := _new_fly(jars[i][s])
			f.pos = _slot_pos(i, s)
			if fly_in:
				var ang := randf() * TAU
				f.pos = size * 0.5 + Vector2(cos(ang), sin(ang)) * max(size.x, size.y) * 0.7
				_launch(f, (i * Puzzle.CAPACITY + s) * 0.022 + randf() * 0.12, 0.65 + randf() * 0.25, 0.25)
			list.append(f)
		flies.append(list)
	if fly_in:
		_busy_until = _now + 0.7
		for t in [0.2, 0.52]:
			get_tree().create_timer(t).timeout.connect(func(): twinkle(-4.0))

func now() -> float:
	return _now

func is_busy() -> bool:
	return _now < _busy_until or win_time >= 0.0

## Stop taps while the last lid screws on before the celebration.
func hold(seconds: float) -> void:
	_busy_until = max(_busy_until, _now + seconds)

## Fly the top n fireflies from one jar to another. on_landed runs when the last one lands.
func move_flies(from: int, to: int, n: int, on_landed: Callable = Callable()) -> void:
	var src: Array = flies[from]
	var moving := src.slice(src.size() - n)
	src.resize(src.size() - n)
	for k in moving.size():
		var f: Dictionary = moving[k]
		flies[to].append(f)
		_launch(f, k * ARC_STAGGER, ARC_TIME, 0.55)
		if k == moving.size() - 1 and on_landed.is_valid():
			f.on_land = on_landed
		get_tree().create_timer(k * ARC_STAGGER + 0.03).timeout.connect(func(): twinkle())
	_busy_until = _now + (n - 1) * ARC_STAGGER + 0.3

## Used by undo: swap in an earlier state without rebuilding the fireflies.
func replace_state(new_state: Dictionary) -> void:
	state = new_state
	jars = state.jars
	for i in state.locks.size():
		if state.locks[i] > 0:
			lids_off.erase(i)

func pop_lid(index: int) -> void:
	lids_off[index] = _now
	sparkle(jar_top_point(index), COLORS[0], 18, 1.3)

func shake(index: int) -> void:
	_shake_jar = index
	_shake_start = _now

func pop_cork(index: int) -> void:
	corks[index] = _now
	var r := _rects[index]
	var col: Color = COLORS[jars[index][0]]
	var started: float = _now
	for k in 7:
		var at: float = CAP_DROP + 0.06 + k * 0.12 + (max(0, k - 3) * 0.015)
		get_tree().create_timer(at).timeout.connect(func():
			if corks.get(index, -1.0) == started:
				Sound.play("tick", 0.9 + k * 0.05, -4.0))
	get_tree().create_timer(CAP_TOTAL).timeout.connect(func():
		if corks.get(index, -1.0) == started:
			Sound.play("lock")
			Save.buzz(12)
			sparkle(Vector2(r.get_center().x, r.position.y), col, 26, 1.6, 1.3))

func remove_cork(index: int) -> void:
	corks.erase(index)

func celebrate() -> void:
	win_time = _now
	for r in _rects:
		sparkle(Vector2(r.get_center().x, r.position.y), COLORS[0], 10, 2.0)

func jar_top_point(i: int) -> Vector2:
	return Vector2(_rects[i].get_center().x, _rects[i].position.y)

func sparkle(pos: Vector2, col: Color, n: int, speed := 1.0, size_mul := 1.0) -> void:
	for k in n:
		var a := randf() * TAU
		var v := (20.0 + randf() * 90.0) * speed
		_particles.append({"p": pos, "v": Vector2(cos(a), sin(a)) * v + Vector2(0, -20), "life": 0.0,
			"max": 0.5 + randf() * 0.6, "c": col, "s": (1.0 + randf() * 2.0) * size_mul})

## A soft high twinkle that follows flying fireflies, at a slightly different pitch each time.
func twinkle(volume_db := -3.0) -> void:
	if _now - _twinkle_t < 0.11:
		return
	_twinkle_t = _now
	Sound.play("twinkle", randf_range(0.82, 1.32), volume_db)

func extra_index() -> int:
	return jars.size() if extra_state == "cracked" or extra_state == "repairing" else -1

func _jar_count() -> int:
	return jars.size() + (1 if extra_index() >= 0 else 0)

## Two golden helper fireflies fly in, circle the cracked jar while it mends, then fly away.
func start_repair() -> void:
	extra_state = "repairing"
	_repair_t0 = _now
	_repair_rect = _rects[extra_index()] if extra_index() < _rects.size() else Rect2()
	_helper_tw = -1
	Sound.play("whoosh", 1.3, -6.0)

## main.gd has added the new empty jar to the state: the board now treats it as a normal jar.
func repair_done() -> void:
	extra_state = "fixed"
	if flies.size() < jars.size():
		flies.append([])
	_layout()
	_flash_t = _now
	var r := _rects[jars.size() - 1]
	sparkle(r.get_center(), Regions.helper_col(), 30, 1.5, 1.3)

func mend_amount() -> float:
	if extra_state != "repairing":
		return 0.0
	return smoothstep(0.0, 1.0, (_now - _repair_t0 - FLY_IN) / MEND)

# ---------------- layout ----------------

## Jars stand on wooden shelves, up to 4 per shelf so they stay big. Same layout as the iPhone version.
func _layout() -> void:
	_rects.clear()
	_shelves.clear()
	var n := _jar_count()
	if n == 0 or size.x <= 0:
		return
	var rows := 1 if n <= 4 else (2 if n <= 8 else 3)
	var per := int(ceil(float(n) / rows))
	var cell_w: float = min(size.x / per, 240.0)
	var jw: float = min(cell_w * 0.7, 192.0)
	var jh := jw * 2.5
	var row_h: float = min(size.y / rows, jh * 1.9)
	jh = min(jh, row_h / 1.78)
	jw = jh / 2.5
	var top := (size.y - row_h * rows) * 0.5
	var idx := 0
	for r in rows:
		var in_row: int = min(per, n - idx)
		var left := (size.x - cell_w * in_row) * 0.5
		var y0 := top + row_h * (r + 1) - row_h * 0.14 - jh
		for c in in_row:
			_rects.append(Rect2(left + cell_w * (c + 0.5) - jw * 0.5, y0, jw, jh))
			idx += 1
		_shelves.append(Rect2(left + cell_w * 0.5 - jw * 0.9, y0 + jh, cell_w * (in_row - 1) + jw * 1.8, jw * 0.2))

func _slot_pos(i: int, slot: int) -> Vector2:
	if i >= _rects.size():
		return size * 0.5
	var r := _rects[i]
	var step := (r.size.y - r.size.x * 0.42) / Puzzle.CAPACITY
	return Vector2(r.get_center().x, r.end.y - r.size.x * 0.16 - step * (slot + 0.5))

## Lifted fireflies hover above their jar and circle around each other.
func _hover_pos(i: int, k: int, n: int) -> Vector2:
	var r := _rects[i]
	var rad := _radius()
	var ang: float = _now / 0.52 + k * TAU / max(1, n)
	var spread := 1.1 if n > 1 else 0.25
	var cy := r.position.y - r.size.x * 0.75 - (rad * 0.4 if n > 1 else 0.0)
	return Vector2(r.get_center().x + cos(ang) * rad * spread, cy + sin(ang * 1.3) * rad * (0.7 if n > 1 else 0.25))

func _radius() -> float:
	return _rects[0].size.x * 0.29 if not _rects.is_empty() else 10.0

func _new_fly(color: int) -> Dictionary:
	_next_id += 1
	return {"id": _next_id, "c": color, "pos": Vector2.ZERO, "arc": {}, "flap": randf() * 6.0, "speed": 0.0, "on_land": Callable()}

func _launch(f: Dictionary, delay: float, dur: float, lift: float) -> void:
	f.arc = {"from": f.pos, "start": _now + delay, "dur": dur, "lift": lift}

func dragging() -> bool:
	return not drag.is_empty() and drag.moved and selected == drag.i

func _is_dragged(i: int, s: int) -> bool:
	return dragging() and i == drag.i and s >= jars[i].size() - Puzzle.top_run(jars[i])

## Where the k-th dragged firefly flies: it follows the finger's path a moment behind the one before it.
func _drag_pos(k: int) -> Vector2:
	var rad := _radius()
	var tr: Array = drag.trail
	var when := _now - 0.055 * k
	var p: Vector2 = drag.pos
	for m in range(tr.size() - 1, -1, -1):
		p = tr[m][0]
		if tr[m][1] <= when:
			break
	var ang := _now / 0.26 + k * 2.1
	var wob := rad * (0.28 if k > 0 else 0.12)
	return p + Vector2(cos(ang) * wob, -rad * 1.6 + sin(ang * 1.3) * wob)

func _jar_at(p: Vector2, pad := 14.0) -> int:
	for i in _rects.size():
		var r := _rects[i]
		if r.grow_individual(pad, r.size.x * 1.4, pad, r.size.x * 0.6).has_point(p):
			return i
	return -1

func _target(i: int, s: int) -> Vector2:
	var jar: Array = jars[i]
	var run := Puzzle.top_run(jar) if i == selected else 0
	if s >= jar.size() - run:
		if dragging() and i == drag.i:
			return _drag_pos(s - (jar.size() - run))
		return _hover_pos(i, s - (jar.size() - run), run)
	var ph := float(i * 7 + s * 3)
	var rad := _radius()
	var sleepy := 0.3 if state.locks[i] > 0 else 1.0
	return _slot_pos(i, s) + Vector2(sin(_now / 0.48 + ph), cos(_now / 0.59 + ph)) * rad * 0.07 * sleepy

# ---------------- input ----------------

# Tap a jar, then tap another to pour. Or: lift the fireflies and drag them with a finger into a jar.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press(event.position)
		else:
			_release(event.position)
		accept_event()
	elif event is InputEventMouseMotion and not drag.is_empty():
		drag.pos = event.position
		if not drag.moved and event.position.distance_to(drag.start) > 20.0 and selected == drag.i:
			drag.moved = true
			Sound.play("whoosh", 1.4, -9.0)
		if drag.moved:
			_drag_dist += event.relative.length()
			if _drag_dist > _radius() * 3.5:
				_drag_dist = 0.0
				twinkle(-6.0)
			drag.trail.append([event.position, _now])
			while drag.trail.size() > 2 and _now - drag.trail[0][1] > 0.9:
				drag.trail.pop_front()

func _press(p: Vector2) -> void:
	drag = {}
	if is_busy() or win_time >= 0.0:
		return
	var xi := extra_index()
	if xi >= 0 and _jar_at(p, 4.0) == xi:
		extra_tapped.emit()
		return
	# pressing on the lifted fireflies (or their jar) picks them up for dragging; a plain tap there still puts them back
	if selected != -1 and selected < _rects.size():
		var near := p.distance_to(_hover_pos(selected, 0, 1)) < _radius() * 3.2
		if near or _jar_at(p) == selected:
			drag = {"i": selected, "pos": p, "start": p, "moved": false, "trail": [], "defer": true}
			return
	var i := _jar_at(p)
	if i == -1 or i >= jars.size():
		empty_tapped.emit()
		return
	jar_tapped.emit(i)
	if selected == i:
		drag = {"i": i, "pos": p, "start": p, "moved": false, "trail": [], "defer": false}

func _release(p: Vector2) -> void:
	if drag.is_empty():
		return
	var d := drag
	drag = {}
	if not d.moved:
		if d.defer and selected == d.i:
			jar_tapped.emit(d.i)   # it was just a tap
		return
	if selected != d.i or win_time >= 0.0:
		return
	var j := _jar_at(p + Vector2(0, _radius() * 1.6), 40.0)
	drag_dropped.emit(d.i, j if j < jars.size() else -1)   # the fireflies float a little above the finger

# ---------------- update ----------------

func _process(delta: float) -> void:
	delta = min(delta, 0.05)
	_now += delta
	if _rects.size() != _jar_count():
		_layout()
	if _rects.is_empty():
		queue_redraw()
		return
	var k := 1.0 - exp(-delta * 11.0)
	for i in flies.size():
		var list: Array = flies[i]
		for s in list.size():
			var f: Dictionary = list[s]
			var before: Vector2 = f.pos
			if win_time >= 0.0:
				var t: float = _now - win_time - (f.id % 17) * 0.03
				if t > 0.0:
					f.pos += Vector2(sin(_now / 0.2 + f.id) * 60.0, -(120.0 + (f.id % 7) * 40.0) * t * 2.2) * delta
			else:
				var target := _target(i, s)
				if not f.arc.is_empty():
					var a: Dictionary = f.arc
					var t: float = (_now - a.start) / a.dur
					if t >= 0.0:
						var u: float = min(1.0, t * (2.0 - t))
						var from: Vector2 = a.from
						var mid := Vector2((from.x + target.x) * 0.5, min(from.y, target.y) - _rects[0].size.y * a.lift)
						f.pos = from.lerp(mid, u).lerp(mid.lerp(target, u), u)
						if randf() < 0.6:
							_particles.append({"p": f.pos, "v": Vector2(randf() - 0.5, randf() - 0.5) * 20.0, "life": 0.0,
								"max": 0.45, "c": COLORS[f.c], "s": 1.6})
						if t >= 1.0:
							f.arc = {}
							var cb: Callable = f.on_land
							f.on_land = Callable()
							if cb.is_valid():
								cb.call()
				elif _is_dragged(i, s):
					f.pos = f.pos.lerp(target, 1.0 - exp(-delta * 22.0))
					if randf() < 0.5:
						_particles.append({"p": f.pos, "v": Vector2(randf() - 0.5, randf() - 0.5 + 0.3) * 30.0, "life": 0.0,
							"max": 0.55, "c": COLORS[f.c], "s": 1.8})
				else:
					f.pos = f.pos.lerp(target, k)
			f.speed = before.distance_to(f.pos) / max(delta, 0.001)
	var alive := []
	for p in _particles:
		p.life += delta
		p.p += p.v * delta
		p.v = Vector2(p.v.x * 0.97, p.v.y + 30.0 * delta)
		if p.life < p.max:
			alive.append(p)
	_particles = alive
	queue_redraw()

# ---------------- drawing ----------------
# Order: shelves, the glass behind, the fireflies, the glass in front, then sparkles.

func _jar_rect(i: int) -> Rect2:
	var rect := _rects[i]
	rect.position.x += _cap_wobble(i) * rect.size.x
	if i == _shake_jar:
		var left := 1.0 - (_now - _shake_start) / 0.38
		if left > 0.0:
			rect.position.x += sin(_now * 66.0) * 7.0 * left
	return rect

func _draw() -> void:
	if _rects.is_empty():
		return
	var rad := _radius()
	for sh in _shelves:
		Art.shelf(self, sh)
	for i in jars.size():
		_draw_jar_back(i, _jar_rect(i))
	if dragging():
		_draw_drag()
	# a hint: the fireflies that should move glow and bob, the jar they go into glows gold
	var hn := 0
	if hint_move.size() == 2:
		hn = mini(Puzzle.top_run(state.jars[hint_move[0]]), Puzzle.CAPACITY - state.jars[hint_move[1]].size())
	for i in flies.size():
		for k in flies[i].size():
			var f = flies[i][k]
			var moving: bool = f.speed > 25.0
			f.flap += 0.9 if moving else 0.12
			var lit: bool = hn > 0 and i == hint_move[0] and k >= flies[i].size() - hn and f.arc.is_empty()
			var awake: bool = state.locks[i] == 0 or not f.arc.is_empty() or lit
			var wob := Vector2(_cap_wobble(i) * _rects[i].size.x, 0) if f.arc.is_empty() else Vector2.ZERO
			if lit:
				wob.y = -rad * 0.25 * absf(sin(_now / 0.3))
				Art.glow(self, f.pos + wob, rad * 3.2, Color("#fff3a0"), 0.55 + 0.25 * sin(_now / 0.2))
				f.flap += 0.6
			Art.fly(self, f.pos + wob, rad, COLORS[f.c], f.flap, awake, moving or lit, float(f.id), _now)
			if Save.color_blind and awake:
				Art.symbol(self, f.pos + wob + Vector2(rad * 0.08, rad * 0.12), rad * 0.3, f.c)
	for i in jars.size():
		_draw_jar_front(i, _jar_rect(i), rad)
	var xi := extra_index()
	if xi >= 0 and xi < _rects.size():
		_draw_cracked(_rects[xi], mend_amount(), rad, extra_state == "cracked")
	if hint_move.size() == 2 and hint_move[1] < _rects.size():
		var hr: Rect2 = _rects[hint_move[1]]
		var ay := hr.position.y - rad * 0.9 - rad * 0.35 * absf(sin(_now / 0.25))
		var ax := hr.get_center().x
		var tri := PackedVector2Array([Vector2(ax - rad * 0.55, ay - rad * 0.5), Vector2(ax + rad * 0.55, ay - rad * 0.5), Vector2(ax, ay + rad * 0.2)])
		draw_colored_polygon(tri, Color("#ffd93b"))
		tri.append(tri[0])
		draw_polyline(tri, Color(0.24, 0.14, 0, 0.6), 2.0, true)
	_draw_helpers(rad)
	for p in _particles:
		var a: float = 1.0 - p.life / p.max
		if not p.has("rot"):
			p["rot"] = randf() * TAU
		if Regions.particle(self, p.p, p.c, p.s, a, p.rot + p.life * 6.0):
			continue
		Art.glow(self, p.p, p.s * 3.0, p.c, 0.5 * a)
		draw_rect(Rect2(p.p - Vector2(p.s, p.s) * 0.5, Vector2(p.s, p.s)), Color(1, 1, 0.94, a))
	_draw_tutorial_hand()

## A jar with cracks running through the glass, a broken-off shard at its foot and a "play" badge above.
func _draw_cracked(r: Rect2, mend: float, rad: float, badge: bool) -> void:
	Art.jar_back(self, r, Color(0.6, 0.7, 0.9, 0.04 * (1.0 - mend)))
	Art.jar_front(self, r, Color(0.84, 0.92, 1.0, 0.32 + 0.28 * mend), max(2.0, rad * 0.11))
	for c in CRACKS:
		var pts := PackedVector2Array()
		for q in c:
			pts.append(r.position + q * r.size)
		draw_polyline(pts, Color(0.04, 0.05, 0.14, 0.55 * (1.0 - mend)), max(2.5, rad * 0.2), true)
		draw_polyline(pts, Color(0.9, 0.95, 1.0, 0.85 * (1.0 - mend)), max(1.2, rad * 0.08), true)
		if mend > 0.0 and mend < 1.0:
			for q in c:   # golden light seals the cracks
				Art.glow(self, r.position + q * r.size, rad * 1.1, Regions.helper_col(), 0.5 * sin(mend * PI))
	if mend < 1.0:
		var sp := Vector2(r.end.x + r.size.x * 0.02, r.end.y)
		var shard := PackedVector2Array([sp, sp + Vector2(r.size.x * 0.16, -r.size.x * 0.12), sp + Vector2(r.size.x * 0.26, 0)])
		draw_colored_polygon(shard, Color(0.67, 0.8, 1.0, 0.25 * (1.0 - mend)))
		shard.append(sp)
		draw_polyline(shard, Color(0.84, 0.92, 1.0, 0.6 * (1.0 - mend)), 1.5, true)
	if badge:
		var b := Vector2(r.get_center().x, r.position.y - r.size.x * 0.5 + sin(_now / 0.4) * 3.0)
		var br: float = max(22.0, r.size.x * 0.24)
		Art.glow(self, b, br * 2.4, Color("#ffd93b"), 0.35 + 0.15 * sin(_now / 0.3))
		draw_circle(b, br, Color("#ffc23d"))
		draw_arc(b, br, 0, TAU, 32, Color("#fff0a0"), 3.0, true)
		Art.icon(self, "play", b + Vector2(br * 0.08, 0), br * 1.3, Color("#3a2205"))

func _helper_pos(k: int, t: float, r: Rect2) -> Vector2:
	var a := t * 4.6 + k * PI
	var orbit := Vector2(r.get_center().x + cos(a) * r.size.x * 0.85, r.position.y + r.size.y * 0.48 + sin(a * 1.4) * r.size.y * 0.36)
	var from := Vector2(size.x + 50.0 if k == 1 else -50.0, -70.0 + k * 40.0)
	var away := Vector2(-60.0 if k == 1 else size.x + 60.0, -90.0)
	if t < FLY_IN:
		var e := smoothstep(0.0, 1.0, t / FLY_IN)
		return from.lerp(orbit, e) - Vector2(0, sin(e * PI) * 40.0)
	var tt := t - FLY_IN - MEND
	if tt <= 0.0:
		return orbit
	return orbit.lerp(away, smoothstep(0.0, 1.0, tt / FLY_OUT))

func _draw_helpers(rad: float) -> void:
	if _now - _flash_t < 0.7 and jars.size() > 0 and jars.size() <= _rects.size():
		var fr := _rects[jars.size() - 1]
		Art.glow(self, fr.get_center(), fr.size.y * 0.9, Regions.helper_col(), 0.6 * (1.0 - (_now - _flash_t) / 0.7))
	var t := _now - _repair_t0
	if t < 0.0 or t > FLY_IN + MEND + FLY_OUT or _repair_rect.size == Vector2.ZERO:
		return
	var r := _repair_rect
	if int(t / 0.26) != _helper_tw:
		_helper_tw = int(t / 0.26)
		if Regions.helper_trail() > 0.9:
			twinkle(-4.0)
	for k in 2:
		var p := _helper_pos(k, t, r)
		var prev := _helper_pos(k, t - 0.03, r)
		if _particles.size() < 260 and randf() < Regions.helper_trail():
			_particles.append({"p": p, "v": Vector2(randf() - 0.5, randf() - 0.5 + 0.5) * 30.0, "life": 0.0, "max": 0.6, "c": Regions.helper_col(), "s": 2.0})
		if t > FLY_IN and t < FLY_IN + MEND and randf() < 0.12:
			var c: Array = CRACKS[randi() % CRACKS.size()]
			sparkle(r.position + c[randi() % c.size()] * r.size, Regions.helper_col(), 3, 0.5)
		_draw_helper(p, rad * Regions.helper_size(), t / 0.03 + k * 2.0, p.x < prev.x)

func _draw_helper(p: Vector2, r: float, flap: float, left: bool) -> void:
	if Regions.helper(self, p, r, flap, left):
		return
	Art.glow(self, p, r * 3.6, Color("#ffe9a0"), 0.55)
	var wy := 0.35 + 0.65 * absf(sin(flap))
	for side in [-1.0, 1.0]:
		draw_set_transform(p + Vector2(side * r * 0.62, -r * 0.5), side * 0.5, Vector2(1.0, wy))
		draw_circle(Vector2.ZERO, r * 0.45, Color(1, 1, 0.94, 0.6))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(p, r * 0.74, Color("#fff6c8"))
	draw_circle(p + Vector2(0, r * 0.15), r * 0.5, Color("#ffd24a"))
	var s := r * (0.35 + 0.15 * sin(flap * 0.7))
	var sp := p + Vector2((-1.0 if left else 1.0) * r * 0.2, -r * 1.25)
	draw_line(sp - Vector2(s, 0), sp + Vector2(s, 0), Color("#fffbe6"), max(1.0, r * 0.12), true)
	draw_line(sp - Vector2(0, s), sp + Vector2(0, s), Color("#fffbe6"), max(1.0, r * 0.12), true)
	for sx in [-1.0, 1.0]:
		draw_circle(p + Vector2(sx * r * 0.22, -r * 0.08), r * 0.1, Color(0.04, 0.05, 0.12, 0.85))

## Glowing ribbon behind the dragged fireflies, and a glow on the jar they would land in.
func _draw_drag() -> void:
	var rad := _radius()
	var col: Color = COLORS[jars[drag.i][-1]]
	for m in drag.trail:
		var a: float = 1.0 - (_now - m[1]) / 0.9
		if a > 0.0:
			Art.glow(self, m[0] - Vector2(0, rad * 1.6), rad * (0.5 + a * 0.9), col, a * 0.5)
	var j := _jar_at(drag.pos + Vector2(0, rad * 1.6), 40.0)
	if j != -1 and j != drag.i and j < jars.size():
		var r := _rects[j]
		var ok := Puzzle.can_pour(state, drag.i, j)
		Art.glow(self, r.get_center(), r.size.x * 1.1, col if ok else Color("#ff4d6d"), 0.55 if ok else 0.3)

## Second guided pour: the hand presses the jar, carries the top fireflies along a glowing trail and drops them in the target jar.
func _draw_drag_demo() -> void:
	var rad := _radius()
	var jar: Array = jars[tut_drag_from]
	var c_idx: int = jar[-1]
	var n := 0
	for k in range(jar.size() - 1, -1, -1):
		if jar[k] != c_idx:
			break
		n += 1
	var col: Color = COLORS[c_idx]
	var rs := _rects[tut_drag_from]
	var r := _rects[tut_drag_to]
	var lifted := selected == tut_drag_from
	var from := Vector2(rs.get_center().x, _hover_pos(tut_drag_from, 0, 1).y + rad * 1.6 if lifted else rs.position.y + rs.size.y * 0.45)
	var to := Vector2(r.get_center().x, r.position.y + r.size.y * 0.45)
	var c := fmod(_now, 2.6) / 2.6          # press 0-.15, carry .15-.7, drop .7-.85, fade out
	var pos_at := func(cc: float) -> Vector2:
		var e := clampf((cc - 0.15) / 0.55, 0.0, 1.0)
		var u := e * e * (3.0 - 2.0 * e)
		return from.lerp(to, u) - Vector2(0, sin(u * PI) * rad * 2.6)
	var p: Vector2 = pos_at.call(c)
	var fade := 1.0 - (c - 0.85) / 0.15 if c > 0.85 else minf(1.0, c / 0.06)
	Art.glow(self, r.get_center(), r.size.x * 1.15, col, (0.3 + 0.2 * sin(_now / 0.18)) * fade)
	if c > 0.15 and c < 0.85:
		for k in 10:
			var q: Vector2 = pos_at.call(c - 0.018 * (k + 1))
			Art.glow(self, q - Vector2(0, rad * 1.6), rad * (1.8 - k * 0.12), col, 0.35 * (1.0 - k / 10.0) * fade)
		var shrink := 1.0 - clampf((c - 0.7) / 0.15, 0.0, 1.0) * 0.6
		for k in n:
			var off := Vector2((k - (n - 1) / 2.0) * rad * 1.1, -rad * 1.6 - absf(k - (n - 1) / 2.0) * rad * 0.3)
			Art.glow(self, p + off, rad * 2.0, col, 0.5 * fade)
			Art.fly(self, p + off, rad * 0.8 * shrink, col, _now / 0.04 + k, true, true, 990.0 + k, _now)
	var press := sin(c / 0.15 * PI) * 0.7 if c < 0.15 else (0.6 if c < 0.7 else 0.0)
	Art.hand(self, p + Vector2(rad * 0.3, 0), rs.size.x * 1.05, press, fade)

func _draw_tutorial_hand() -> void:
	if tut_jar < 0 or tut_jar >= _rects.size() or is_busy() or win_time >= 0.0:
		return
	var fade := clampf((_now - maxf(_busy_until, _tut_since) - 0.25) / 0.3, 0.0, 1.0)
	if fade <= 0.0:
		return
	var r := _rects[tut_jar]
	if tut_drag_from >= 0 and tut_drag_from < jars.size() and tut_drag_to >= 0 and tut_drag_to < jars.size() and not jars[tut_drag_from].is_empty() and not dragging():
		_draw_drag_demo()
		return
	var cyc := fmod(_now, 1.3) / 1.3
	var press := sin(cyc / 0.5 * PI) if cyc < 0.5 else 0.0          # tap... pause... tap
	var wig := sin((_now - tut_nudge) * 40.0) * 6.0 if _now - tut_nudge < 0.4 else 0.0
	Art.hand(self, Vector2(r.position.x + r.size.x * 0.58 + wig, r.position.y + r.size.y * 0.55 + press * r.size.x * 0.12), r.size.x * 1.05, press, fade)

func _draw_jar_back(i: int, r: Rect2) -> void:
	var jar: Array = jars[i]
	var only: int = state.only[i]
	var done := corks.has(i) and not jar.is_empty()
	if done:
		Art.glow(self, Vector2(r.get_center().x, r.position.y + r.size.y * 0.55), r.size.y * 0.8, COLORS[jar[0]], 0.22 + 0.06 * sin(_now / 0.3 + i))
	var tint = null
	if done:
		tint = Color(COLORS[jar[0]], 0.15)
	elif only >= 0:
		tint = Color(COLORS[only], 0.11)
	Art.jar_back(self, r, tint)

func _draw_jar_front(i: int, r: Rect2, rad: float) -> void:
	var jar: Array = jars[i]
	var only: int = state.only[i]
	var w := r.size.x
	var done := corks.has(i) and not jar.is_empty()
	var line := Art.jar_line()
	if done:
		line = COLORS[jar[0]]
	if i == selected:
		line = Color("#ffe27a")
		Art.glow(self, r.get_center(), r.size.y * 0.7, Color("#ffd93b"), 0.12)
	if hint_move.size() == 2 and hint_move[1] == i:
		var pu := absf(sin(_now / 0.25))
		line = Color(1.0, 0.85, 0.23, 0.55 + 0.45 * pu)
		Art.glow(self, r.get_center(), r.size.y * 0.75, Color("#ffd93b"), 0.16 + 0.14 * pu)
	Art.jar_front(self, r, line, max(2.0, rad * 0.11))
	if only >= 0:
		# a ribbon in the jar's color tied around the neck, with a bow
		var c: Color = COLORS[only]
		var ny := r.position.y + w * 0.1
		draw_rect(Rect2(r.position.x + w * 0.08, ny, w * 0.84, w * 0.09), c)
		var b := Vector2(r.position.x + w * 0.78, ny + w * 0.045)
		draw_colored_polygon(PackedVector2Array([b, b + Vector2(w * 0.2, -w * 0.12), b + Vector2(w * 0.22, w * 0.06)]), c)
		draw_colored_polygon(PackedVector2Array([b, b + Vector2(-w * 0.14, -w * 0.13), b + Vector2(-w * 0.16, w * 0.05)]), c)
		draw_colored_polygon(PackedVector2Array([b, b + Vector2(w * 0.06, w * 0.3), b + Vector2(w * 0.12, w * 0.26)]), c)
		Art.glow(self, b, w * 0.35, c, 0.35)
		draw_circle(b, w * 0.05, c.darkened(0.3))
		if Save.color_blind:
			var tp := Vector2(r.position.x + w * 0.36, b.y)
			draw_circle(tp, w * 0.17, c)
			Art.symbol(self, tp, w * 0.09, only)
	if done:
		_draw_cap(r, _now - float(corks[i]))
	# lid: wooden cap with the number of pours left; flies off when it opens
	var lock: int = state.locks[i]
	var lid_t := -1.0
	if lock > 0:
		lid_t = 0.0
	elif lids_off.has(i) and _now - lids_off[i] < 0.7:
		lid_t = (_now - lids_off[i]) / 0.7
	if lid_t >= 0.0:
		var a := 1.0 - lid_t
		draw_set_transform(Vector2(r.get_center().x, r.position.y + w * 0.02 - lid_t * lid_t * r.size.y * 1.2), lid_t * 2.5, Vector2.ONE)
		if not Regions.lock_art(self, w, a):
			Art.vgradient(self, Rect2(-w * 0.5, -w * 0.2, w, w * 0.34), Color(Color("#8a6239"), a), Color(Color("#71502e"), a), Color(Color("#5a3c22"), a), 0.5)
			for k in range(-2, 3):
				draw_line(Vector2(k * w * 0.18, -w * 0.18), Vector2(k * w * 0.18, w * 0.12), Color(0.16, 0.09, 0.04, 0.35 * a), 1.5)
		if lock > 0:
			draw_circle(Vector2(0, -w * 0.03), w * 0.22, Color("#fff6d6"))
			var font: Font = NUMBER_FONT
			var fs := int(w * 0.3)
			var txt := str(lock)
			var sz := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
			draw_string(font, Vector2(-sz.x * 0.5, -w * 0.03 + font.get_ascent(fs) * 0.5 - fs * 0.08), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#3a2716"))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

const NUMBER_FONT := preload("res://fonts/Baloo2-ExtraBold.woff2")

func _round_rect(r: Rect2, rad: float, col: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(int(rad))
	sb.anti_aliasing = true
	draw_style_box(sb, r)

## The golden lid's timing lives in art.gd so the loading screen can use it too.
const CAP_DROP := Art.CAP_DROP
const CAP_TURN := Art.CAP_TURN
const CAP_TURNS := Art.CAP_TURNS
const CAP_TOTAL := Art.CAP_TOTAL

## After the click the jar gives a tiny wobble (sideways, in pixels per jar width).
func _cap_wobble(i: int) -> float:
	if not corks.has(i):
		return 0.0
	var t := (_now - float(corks[i]) - CAP_TOTAL) / 0.38
	return sin(t * PI * 4.0) * (1.0 - t) * 0.06 if t > 0.0 and t < 1.0 else 0.0

func _draw_cap(r: Rect2, age: float) -> void:
	Art.cap(self, r, age)
