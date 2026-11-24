class_name Scenes
extends RefCounted
## The chapter scenes, drawn with code. Each scene paints into a W x H area, so the same
## drawing is used behind the jars and in each part of the chapter map.
## Same scenes and numbers as the web version (web/firefly-jars.html: paintSky, paintLand, paintLive).

const WATER := ["pond", "creek", "falls", "frozen", "lighthouse", "lagoon"]
const MUSHROOMS := [[0.1, 0.9, 0.12], [0.24, 0.7, 0.08], [0.42, 0.95, 0.1], [0.62, 0.75, 0.07], [0.8, 0.9, 0.13], [0.93, 0.7, 0.07]]
const RAINBOW := [Color(1, 0.35, 0.43), Color(1, 0.63, 0.27), Color(1, 0.9, 0.35), Color(0.43, 0.94, 0.51), Color(0.35, 0.78, 1), Color(0.47, 0.55, 1), Color(0.75, 0.47, 1)]

static var _petals: Array = []
static var _flakes: Array = []
static var _lagoon: Array = []

static func _seed_lists() -> void:
	if not _petals.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 29
	for i in 16:
		_petals.append({"x": rng.randf(), "o": rng.randf(), "v": 0.03 + rng.randf() * 0.03, "s": 0.6 + rng.randf() * 0.6, "a": rng.randf() * TAU})
	for i in 40:
		_flakes.append({"x": rng.randf(), "o": rng.randf(), "v": 0.02 + rng.randf() * 0.025, "s": 0.6 + rng.randf() * 1.2, "a": rng.randf() * TAU})
	for i in 18:
		_lagoon.append([rng.randf(), rng.randf(), rng.randf(), rng.randf()])

static func water_top(n: String, H: float) -> float:
	return H * 0.78 + (-H * 0.06 if n == "lighthouse" else (-H * 0.02 if n == "lagoon" else H * 0.02))

static func falls_rect(W: float, H: float) -> Rect2:
	return Rect2(W * 0.43, H * 0.36, W * 0.14, H * 0.8 - H * 0.36)

static func lamp_pos(W: float, H: float) -> Vector2:
	return Vector2(W * 0.845, H * 0.78 - H * 0.135 - H * 0.22 - H * 0.023)

static func ellipse(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color, rot := 0.0, from := 0.0, to := TAU) -> void:
	var pts := PackedVector2Array()
	var n := 20
	var full := to - from >= TAU - 0.001
	for k in (n if full else n + 1):
		var a := from + (to - from) * k / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
	if pts.size() >= 3:
		ci.draw_colored_polygon(pts, col)

static func _hill(ci: CanvasItem, W: float, H: float, base_y: float, amp: float, freq: float, phase: float, col: Color) -> void:
	Art.hill(ci, Vector2(W, H), base_y, amp, freq, phase, col)

static func _vgrad2(ci: CanvasItem, r: Rect2, c0: Color, c1: Color) -> void:
	ci.draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]), PackedColorArray([c0, c0, c1, c1]))

static func _curve(p0: Vector2, p1: Vector2, p2: Vector2, steps := 8) -> PackedVector2Array:
	var pts := PackedVector2Array([p0])
	Art._quad(p0, p1, p2, pts, steps)
	return pts

## Sky gradient, the rainbow (Rainbow Sky) and the crescent moon.
static func sky(ci: CanvasItem, T: Dictionary, W: float, H: float, moon := true) -> void:
	Art.vgradient(ci, Rect2(0, 0, W, H), Color(T.sky[0]), Color(T.sky[1]), Color(T.sky[2]), 0.6)
	if T.name == "rainbow":
		for k in 7:
			ci.draw_arc(Vector2(W * 0.5, H * 0.95), W * (0.78 - k * 0.035), PI, TAU, 64, Color(RAINBOW[k], 0.13), W * 0.035)
	if moon:
		var m := Vector2(W * 0.8, H * 0.13)
		var mr: float = min(W, H) * 0.045
		Art.glow(ci, m, mr * 6.0, Color("#c9d8ff"), 0.16)
		Art.crescent(ci, m, mr, Color("#f4fbff") if T.name == "frozen" else Color("#efeedd"))

static func _round_tree(ci: CanvasItem, x: float, base: float, h: float, trunk: Color, leaf: Color, dot: Color, seed_v: int) -> void:
	var w := h * 0.07
	ci.draw_line(Vector2(x, base), Vector2(x + h * 0.03, base - h * 0.55), trunk, w)
	ci.draw_line(Vector2(x + h * 0.02, base - h * 0.35), Vector2(x - h * 0.18, base - h * 0.62), trunk, w)
	ci.draw_line(Vector2(x + h * 0.03, base - h * 0.45), Vector2(x + h * 0.2, base - h * 0.7), trunk, w)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	for k in 7:
		var a := k / 7.0 * TAU
		ellipse(ci, Vector2(x + cos(a) * h * 0.22, base - h * 0.72 + sin(a) * h * 0.14), h * (0.2 + rng.randf() * 0.06), h * (0.17 + rng.randf() * 0.05), leaf)
	ellipse(ci, Vector2(x, base - h * 0.74), h * 0.26, h * 0.2, leaf)
	for k in 14:
		ci.draw_circle(Vector2(x + (rng.randf() - 0.5) * h * 0.62, base - h * 0.74 + (rng.randf() - 0.5) * h * 0.4), h * 0.025, dot)

static func _palm(ci: CanvasItem, x: float, base: float, h: float, col: Color) -> void:
	var top := Vector2(x + h * 0.18, base - h)
	ci.draw_polyline(_curve(Vector2(x, base), Vector2(x + h * 0.02, base - h * 0.6), top), col, h * 0.07)
	for k in 6:
		var a := -2.9 + k * 0.58
		var e := Vector2(top.x + cos(a) * h * 0.45, top.y + sin(a) * h * 0.2 + h * 0.18)
		ci.draw_polyline(_curve(top, Vector2(top.x + cos(a) * h * 0.3, top.y + sin(a) * h * 0.3 - h * 0.08), e), col, h * 0.045)

static func _sunflower(ci: CanvasItem, x: float, base: float, h: float, stem: Color, petal: Color, mid: Color) -> void:
	ci.draw_line(Vector2(x, base), Vector2(x, base - h), stem, max(1.5, h * 0.05))
	ellipse(ci, Vector2(x - h * 0.1, base - h * 0.45), h * 0.1, h * 0.035, stem)
	ellipse(ci, Vector2(x + h * 0.1, base - h * 0.62), h * 0.1, h * 0.035, stem)
	var r := h * 0.17
	for k in 10:
		var a := k / 10.0 * TAU
		ci.draw_circle(Vector2(x + cos(a) * r, base - h + sin(a) * r), r * 0.55, petal)
	ci.draw_circle(Vector2(x, base - h), r * 0.8, mid)

static func _tri(ci: CanvasItem, a: Vector2, b: Vector2, c: Vector2, col: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([a, b, c]), col)

## The hills and everything standing on them that doesn't move.
static func land(ci: CanvasItem, T: Dictionary, W: float, H: float) -> void:
	var n: String = T.name
	var hz := H * 0.78
	var c0 := Color(T.hills[0])
	var c1 := Color(T.hills[1])
	var c2 := Color(T.hills[2])
	if n == "lighthouse":
		var wy := water_top(n, H)
		_vgrad2(ci, Rect2(0, wy, W, H - wy), Color(T.sky[2]), c2)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(W * 0.6, H), Vector2(W * 0.64, hz + H * 0.02), Vector2(W * 0.72, hz - H * 0.12), Vector2(W, hz - H * 0.15), Vector2(W, H)]), c1)
		var bx := W * 0.845
		var by := hz - H * 0.135
		var th := H * 0.22
		var bw := W * 0.05
		var tw := W * 0.033
		ci.draw_colored_polygon(PackedVector2Array([Vector2(bx - bw, by), Vector2(bx - tw, by - th), Vector2(bx + tw, by - th), Vector2(bx + bw, by)]), Color("#6f6c6a"))
		for u in [[0.2, 0.38], [0.56, 0.74]]:
			var s0: float = bw + (tw - bw) * u[0]
			var s1: float = bw + (tw - bw) * u[1]
			ci.draw_colored_polygon(PackedVector2Array([Vector2(bx - s0, by - th * u[0]), Vector2(bx - s1, by - th * u[1]), Vector2(bx + s1, by - th * u[1]), Vector2(bx + s0, by - th * u[0])]), Color("#5e2a30"))
		ci.draw_rect(Rect2(bx - tw * 1.5, by - th - H * 0.006, tw * 3, H * 0.008), Color("#1a2030"))
		ci.draw_rect(Rect2(bx - tw * 0.8, by - th - H * 0.04, tw * 1.6, H * 0.034), Color("#ffe9a8"))
		_tri(ci, Vector2(bx - tw * 1.1, by - th - H * 0.04), Vector2(bx, by - th - H * 0.065), Vector2(bx + tw * 1.1, by - th - H * 0.04), Color("#1a2030"))
		for k in 3:
			ellipse(ci, Vector2(W * (0.08 + k * 0.17), wy + H * 0.05 + k * 6), W * (0.05 + (k % 2) * 0.03), W * (0.05 + (k % 2) * 0.03), c2, 0.0, PI, TAU)
		return
	if n == "falls":
		ci.draw_colored_polygon(PackedVector2Array([Vector2(W * 0.22, hz), Vector2(W * 0.3, H * 0.42), Vector2(W * 0.38, H * 0.35), Vector2(W * 0.62, H * 0.34), Vector2(W * 0.7, H * 0.4), Vector2(W * 0.8, hz)]), c0)
	_hill(ci, W, H, hz - H * 0.1, H * 0.03, 4.0, 1.1, c1 if n == "lagoon" else c0)
	if n == "woods":
		for i in 14:
			Art.pine(ci, (i + 0.3) / 13.0 * W, hz - H * 0.05 + sin(i * 1.7) * 10.0, H * (0.16 + (i % 3) * 0.04), c1)
	if n == "frozen":
		for i in 9:
			var x := (i + 0.5) / 9.0 * W
			var b := hz - H * 0.05 + sin(i * 1.3) * 8.0
			var h := H * (0.12 + (i % 3) * 0.03)
			Art.pine(ci, x, b, h, c1)
			for k in 4:
				var y := b - h * 0.12 - k * h * 0.21 - h * 0.32
				var w := h * (0.32 - k * 0.06) * 0.35
				_tri(ci, Vector2(x - w, y + h * 0.1), Vector2(x, y), Vector2(x + w, y + h * 0.1), Color(0.92, 0.97, 1, 0.55))
	if n == "garden":
		for i in 26:
			var x := (i + 0.5) / 26.0 * W
			var y := hz - H * 0.04 + sin(i) * 6.0
			ci.draw_line(Vector2(x, y + 20), Vector2(x, y - 18 - (i % 4) * 6), c1, 2.0)
			ci.draw_circle(Vector2(x, y - 20 - (i % 4) * 6), 6 + (i % 3) * 2, c1)
	if n == "blossom":
		var xs := [0.06, 0.3, 0.56, 0.8, 0.97]
		for i in xs.size():
			_round_tree(ci, W * xs[i], hz - H * 0.02, H * (0.2 + (i % 2) * 0.05), c2, Color("#4a1a44"), Color(1, 0.63, 0.82, 0.5), i * 7 + 1)
	if n == "orchard":
		var xs := [0.1, 0.36, 0.64, 0.9]
		for i in xs.size():
			_round_tree(ci, W * xs[i], hz - H * 0.02, H * (0.21 + (i % 2) * 0.04), c2, Color("#3e1c12"), Color(1, 0.59, 0.24, 0.6), i * 5 + 3)
	if n == "mushroom":
		for m in MUSHROOMS:
			var bx: float = W * m[0]
			var by := hz - H * 0.02
			var h: float = H * 0.12 * m[1]
			var cr: float = W * m[2] * 0.5
			ci.draw_rect(Rect2(bx - cr * 0.18, by - h, cr * 0.36, h), c2)
			ellipse(ci, Vector2(bx, by - h), cr, cr * 0.62, Color("#2e1a52"), 0.0, PI, TAU)
			for k in 3:
				ellipse(ci, Vector2(bx + (k - 1) * cr * 0.45, by - h - cr * (0.25 + (k % 2) * 0.15)), cr * 0.1, cr * 0.08, Color(0.82, 0.59, 1, 0.45))
	_hill(ci, W, H, hz - H * 0.04, H * 0.025, 6.0, 2.6, c1)
	if n == "falls":
		var f := falls_rect(W, H)
		_vgrad2(ci, f, Color(0.75, 0.94, 1, 0.3), Color(0.75, 0.94, 1, 0.16))
	if n == "oasis":
		_palm(ci, W * 0.86, hz + H * 0.02, H * 0.2, c2)
	if n == "sunflower":
		for i in 18:
			var x := (i + 0.5) / 18.0 * W + sin(i * 2.1) * 8.0
			_sunflower(ci, x, hz + H * 0.03, H * (0.08 + (i % 3) * 0.025), c2, Color("#3a300e"), Color("#171006"))
	if n in WATER:
		var wy := water_top(n, H)
		_vgrad2(ci, Rect2(0, wy, W, H - wy), Color("#5a7ea6") if n == "frozen" else Color(T.sky[2]), c2)
		if n == "frozen":
			for k in 5:
				var x := W * (0.1 + k * 0.2)
				var y := wy + H * (0.05 + (k % 3) * 0.04)
				ci.draw_polyline(PackedVector2Array([Vector2(x, y), Vector2(x + W * 0.05, y + H * 0.02), Vector2(x + W * 0.11, y + H * 0.01)]), Color(0.9, 0.96, 1, 0.18), 1.5)
		if n == "lagoon":
			ellipse(ci, Vector2(W * 0.2, wy + 2), W * 0.16, H * 0.03, c1, 0.0, PI, TAU)
			_palm(ci, W * 0.2, wy, H * 0.13, c1)
	else:
		_hill(ci, W, H, hz + H * 0.02, H * 0.015, 3.0, 0.3, c2)
		if n == "oasis":
			var pc := Vector2(W * 0.45, hz + H * 0.1)
			ellipse(ci, pc, W * 0.3, H * 0.035, Color("#141020"))
			ellipse(ci, pc - Vector2(0, H * 0.008), W * 0.28, H * 0.024, Color(T.sky[2]).lerp(Color("#141020"), 0.35))
			_palm(ci, W * 0.14, hz + H * 0.1, H * 0.24, c2)
			_palm(ci, W * 0.7, hz + H * 0.09, H * 0.17, c2)

## Moving parts. part "sky" sits behind the clouds and grass, part "ground" in front.
static func live(ci: CanvasItem, T: Dictionary, W: float, H: float, t: float, part: String) -> void:
	_seed_lists()
	var n: String = T.name
	var hz := H * 0.78
	if part == "sky":
		if n == "aurora":
			var cols := [Color(0.31, 1, 0.67, 0.1), Color(0.35, 0.7, 1, 0.08), Color(0.7, 0.47, 1, 0.07)]
			for k in 3:
				var pts := PackedVector2Array()
				var x := 0.0
				while x <= W + 12.0:
					pts.append(Vector2(x, H * (0.18 + k * 0.05) + sin(x / W * 5.0 + t * 0.4 + k) * 18.0))
					x += 12.0
				ci.draw_polyline(pts, cols[k], 34.0, true)
		if n == "islands":
			var isl := [[0.2, 0.34, 1.0], [0.72, 0.24, 0.8], [0.55, 0.48, 0.55]]
			for k in 3:
				var x: float = W * isl[k][0]
				var y: float = H * isl[k][1] + sin(t * 0.6 + k * 2) * H * 0.008
				var w: float = W * 0.2 * isl[k][2]
				Art.glow(ci, Vector2(x, y + w * 0.3), w * 0.8, Color("#9fb4ff"), 0.12)
				ci.draw_colored_polygon(PackedVector2Array([Vector2(x - w / 2, y), Vector2(x + w / 2, y), Vector2(x + w * 0.28, y + w * 0.3), Vector2(x + w * 0.05, y + w * 0.62), Vector2(x - w * 0.22, y + w * 0.34)]), Color("#262c66"))
				ellipse(ci, Vector2(x, y), w * 0.52, w * 0.07, Color("#34407e"))
				ci.draw_line(Vector2(x + w * 0.15, y), Vector2(x + w * 0.15, y - w * 0.25), Color("#1c2050"), max(1.5, w * 0.04))
				ellipse(ci, Vector2(x + w * 0.15, y - w * 0.3), w * 0.12, w * 0.1, Color("#2c3a78"))
				ci.draw_line(Vector2(x - w * 0.1, y + w * 0.3), Vector2(x - w * 0.1, y + w * 0.3 + fmod(t * 30.0 + k * 20.0, w * 0.5)), Color(0.75, 0.9, 1, 0.25), max(1.0, w * 0.02))
		if n == "rainbow":
			for k in 9:
				var a := PI + (k + 0.5) / 9.0 * PI
				var r := W * (0.78 - (k % 7) * 0.035)
				Art.glow(ci, Vector2(W * 0.5 + cos(a) * r, H * 0.95 + sin(a) * r), 14, Color.WHITE, 0.25 + 0.25 * sin(t * 2.0 + k * 1.7))
		return
	if n == "marsh":
		for k in 3:
			var y := H * (0.62 + k * 0.1)
			var x := fmod(t * 8.0 * (k + 1), W + 300.0) - 150.0
			Art.glow(ci, Vector2(x, y), 160, Color("#b8c8d0"), 0.06)
			Art.glow(ci, Vector2(W - x, y + 30), 140, Color("#b8c8d0"), 0.05)
	if n in WATER and n != "frozen":
		for k in 7:
			var y := water_top(n, H) + H * 0.04 + k * 14
			if y > H:
				break
			ci.draw_rect(Rect2(W * (0.15 + fmod(k * 0.37, 0.7)) + sin(t + k) * 10.0, y, 30 + (k * 23 % 50), 2), Color(0.78, 0.9, 1, 0.07))
	if n == "woods":
		for k in 3:
			Art.glow(ci, Vector2(W * (0.15 + k * 0.35), H * 0.7 - (k % 2) * 20), 60, Color("#ff9f43"), 0.12 + 0.06 * sin(t * 3 + k))
	if n == "blossom" or n == "orchard":
		var pc := Color(1, 0.7, 0.84, 0.6) if n == "blossom" else Color(1, 0.59, 0.24, 0.55)
		for p in _petals:
			var u := fmod(p.o + t * p.v, 1.0)
			var x := fmod(p.x + sin(t * 0.5 + p.a) * 0.05 + u * 0.15 + 1.0, 1.0) * W
			ellipse(ci, Vector2(x, u * H * 1.05 - H * 0.03), 4.0 * p.s * W / 390.0, 2.2 * p.s * W / 390.0, pc, t * 1.5 * p.s + p.a)
	if n == "frozen":
		for f in _flakes:
			var u := fmod(f.o + t * f.v, 1.0)
			ci.draw_circle(Vector2((f.x + sin(t * 0.7 + f.a) * 0.02) * W, u * H), 1.3 * f.s * W / 390.0, Color(0.94, 0.98, 1, 0.6))
	if n == "falls":
		var f := falls_rect(W, H)
		for k in 12:
			var x := f.position.x + (k + 0.5) / 12.0 * f.size.x
			var y := f.position.y + fmod(t * H * 0.25 + k * 97.0, f.size.y)
			ci.draw_rect(Rect2(x - 1, y, 2, min(H * 0.05, f.end.y - y)), Color(0.9, 0.98, 1, 0.25))
		for k in 3:
			Art.glow(ci, Vector2(f.position.x + f.size.x * k / 2.0, f.end.y), W * 0.1, Color("#c8f4ff"), 0.1 + 0.05 * sin(t * 2 + k))
	if n == "mushroom":
		for m in MUSHROOMS:
			Art.glow(ci, Vector2(W * m[0], hz - H * 0.02 - H * 0.12 * m[1] - W * m[2] * 0.2), W * m[2] * 1.1, Color("#c77dff"), 0.16 + 0.08 * sin(t * 1.5 + m[0] * 9.0))
	if n == "lighthouse":
		var L := lamp_pos(W, H)
		var d := cos(t * 0.8)
		var ln := W * 1.1 * absf(d)
		var dir := -1.0 if d < 0 else 1.0
		if ln > 4.0:
			var a0 := Color(1, 0.94, 0.7, 0.3 * absf(d))
			var a1 := Color(1, 0.94, 0.7, 0.0)
			ci.draw_polygon(PackedVector2Array([L + Vector2(0, -3), L + Vector2(dir * ln, -H * 0.05), L + Vector2(dir * ln, H * 0.05), L + Vector2(0, 3)]), PackedColorArray([a0, a1, a1, a0]))
		Art.glow(ci, L, W * 0.08, Color("#fff0a0"), 0.5 + 0.2 * absf(sin(t * 0.8)))
	if n == "bamboo":
		for i in 13:
			var x := (i + 0.3) / 12.5 * W
			var top := H * (0.28 + (i % 4) * 0.06)
			var sw := sin(t * 0.6 + i * 1.3) * W * 0.012
			var col := Color(T.hills[1]) if i % 2 else Color(T.hills[0])
			ci.draw_polyline(_curve(Vector2(x, H), Vector2(x, (H + top) / 2.0), Vector2(x + sw, top), 10), col, W * 0.022)
			for k in range(1, 6):
				var u := k / 6.0
				var yy := H - (H - top) * u
				var xx := x + sw * u * u
				ci.draw_rect(Rect2(xx - W * 0.014, yy, W * 0.028, 2), Color(T.hills[2]))
				if (k + i) % 2:
					var side := -1.0 if i % 2 else 1.0
					var rot := (-0.6 if i % 2 else 0.6) + sw * 0.01
					ellipse(ci, Vector2(xx, yy) + Vector2(side * W * 0.03, 0).rotated(rot), W * 0.035, W * 0.008, col, rot)
		for k in 3:
			var p := Vector2(W * (0.2 + k * 0.3), H * (0.55 + (k % 2) * 0.06) + sin(t + k) * 3.0)
			ellipse(ci, p, W * 0.022, W * 0.03, Color("#b8432e"))
			Art.glow(ci, p, 50, Color("#ffb347"), 0.2 + 0.06 * sin(t * 3 + k))
	if n == "lagoon":
		for k in 18:
			var r: Array = _lagoon[k]
			Art.glow(ci, Vector2(r[0] * W, water_top(n, H) + H * 0.02 + r[1] * H * 0.2), 10 + r[2] * 8, Color("#3dfcff"), 0.2 * max(0.0, sin(t * (0.6 + r[3]) + k)))
	if n == "oasis":
		for k in 3:
			ci.draw_rect(Rect2(W * (0.32 + k * 0.08) + sin(t + k) * 6.0, hz + H * (0.09 + k * 0.01), W * 0.06, 2), Color(0.78, 0.86, 1, 0.08))
