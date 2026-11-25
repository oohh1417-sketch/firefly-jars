class_name Regions
extends RefCounted
## Jar World: each chapter is a region with its own scene, its own things to sort and its own jar.
## Same regions as the web test page (tools/web/regions.js). Night ("meadow") keeps the original firefly look.

## Which region's jars and things are drawn right now (set by main.gd from the chapter being played).
static func cur() -> Dictionary:
	return Art.THEMES[Art.region % Art.THEMES.size()]

# ---------- small drawing helpers ----------
static func _ell(c: Vector2, rx: float, ry: float, rot := 0.0, n := 24) -> PackedVector2Array:
	var p := PackedVector2Array()
	for k in n:
		var a := TAU * k / n
		p.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
	return p

static func _arc(c: Vector2, rx: float, ry: float, a0: float, a1: float, n := 20) -> PackedVector2Array:
	var p := PackedVector2Array()
	for k in n + 1:
		var a := a0 + (a1 - a0) * k / n
		p.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return p

static func _closed(p: PackedVector2Array) -> PackedVector2Array:
	var q := p.duplicate()
	q.append(p[0])
	return q

static func _shape(ci: CanvasItem, p: PackedVector2Array, fill: Color, line := Color(0, 0, 0, 0), w := 1.0) -> void:
	if p.size() >= 3:
		ci.draw_colored_polygon(p, fill)
	if line.a > 0.0:
		ci.draw_polyline(_closed(p), line, w, true)

static func _a(c: Color, a: float) -> Color:
	return Color(c.r, c.g, c.b, c.a * a)

static func _quad(p0: Vector2, p1: Vector2, p2: Vector2, out: PackedVector2Array, steps := 8) -> void:
	Art._quad(p0, p1, p2, out, steps)

# ---------- the things to sort ----------
## Draws the region's thing at pos. Returns false in the firefly region, so Art.fly draws a firefly.
static func item(ci: CanvasItem, pos: Vector2, r: float, col: Color, flap: float, awake: bool, phase: float, now: float) -> bool:
	var kind: String = cur().get("item", "fly")
	if kind == "fly":
		return false
	var A: float = col.a * (1.0 if awake else 0.5)
	var c := Color(col, 1.0)
	match kind:
		"fish": _fish(ci, pos, r, c, flap, A, phase)
		"flower": _flower(ci, pos, r, c, flap, A, phase)
		"gem": _gem(ci, pos, r, c, A, phase, now, awake)
		"candy": _candy(ci, pos, r, c, flap, A, phase)
		"planet": _planet(ci, pos, r, c, A, phase, awake)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return true

static func _fish(ci: CanvasItem, p: Vector2, r: float, col: Color, flap: float, A: float, ph: float) -> void:
	var d := 1.0 if posmod(int(round(ph)), 2) == 1 else -1.0
	var ol := Color(0.06, 0.16, 0.27, 0.4 * A)
	var lw: float = max(1.0, r * 0.08)
	var dk := _a(col.darkened(0.14), A)
	ci.draw_set_transform(p, 0.0, Vector2(d, 1.0))
	var wag := sin(flap) * 0.3
	var o := Vector2(r * 0.55, 0)
	var tail := PackedVector2Array()
	for q in [Vector2(0, 0), Vector2(r * 0.5, -r * 0.45), Vector2(r * 0.38, 0), Vector2(r * 0.5, r * 0.45)]:
		tail.append(o + q.rotated(wag))
	_shape(ci, tail, dk, ol, lw)
	var fin := PackedVector2Array([Vector2(-r * 0.3, -r * 0.42)])
	_quad(Vector2(-r * 0.3, -r * 0.42), Vector2(0, -r * 0.9), Vector2(r * 0.35, -r * 0.36), fin)
	_shape(ci, fin, dk, ol, lw)
	_shape(ci, _ell(Vector2.ZERO, r * 0.78, r * 0.56), _a(col, A), ol, lw)
	_shape(ci, _ell(Vector2(-r * 0.08, r * 0.2), r * 0.45, r * 0.16), Color(1, 1, 1, 0.35 * A))
	var st := PackedVector2Array([Vector2(r * 0.14, -r * 0.46)])
	_quad(Vector2(r * 0.14, -r * 0.46), Vector2(r * 0.3, 0), Vector2(r * 0.14, r * 0.46), st)
	ci.draw_polyline(st, Color(1, 1, 1, 0.65 * A), max(1.0, r * 0.11), true)
	ci.draw_circle(Vector2(-r * 0.44, -r * 0.1), r * 0.17, Color(1, 1, 1, A))
	ci.draw_circle(Vector2(-r * 0.48, -r * 0.1), r * 0.09, Color(0.07, 0.14, 0.23, A))

static func _flower(ci: CanvasItem, p: Vector2, r: float, col: Color, flap: float, A: float, ph: float) -> void:
	ci.draw_set_transform(p, ph * 0.9 + sin(flap * 0.15) * 0.15, Vector2.ONE)
	var ol := Color(0.35, 0.12, 0.08, 0.32 * A)
	for k in 5:
		var ang := k * TAU / 5.0
		_shape(ci, _ell(Vector2(0, -r * 0.47).rotated(ang), r * 0.36, r * 0.47, ang), _a(col, A), ol, max(1.0, r * 0.07))
		ci.draw_colored_polygon(_ell(Vector2(0, -r * 0.55).rotated(ang), r * 0.12, r * 0.24, ang, 12), Color(1, 1, 1, 0.35 * A))
	var mid := Color("#ff9f43") if col.is_equal_approx(Color("#ffd93b")) else Color("#ffd54a")
	ci.draw_circle(Vector2.ZERO, r * 0.26, _a(mid, A))
	ci.draw_arc(Vector2.ZERO, r * 0.26, 0, TAU, 20, Color(0.67, 0.35, 0.04, 0.6 * A), max(1.0, r * 0.07), true)
	ci.draw_circle(Vector2(-r * 0.07, -r * 0.07), r * 0.09, Color(1, 0.98, 0.82, 0.9 * A))

static func _gem(ci: CanvasItem, p: Vector2, r: float, col: Color, A: float, ph: float, now: float, awake: bool) -> void:
	if awake:
		Art.glow(ci, p, r * 2.4, col, (0.32 + 0.1 * sin(now / 0.3 + ph)) * A)
	var h := r * 0.84
	var w := r * 0.7
	ci.draw_set_transform(p, sin(now / 0.7 + ph) * 0.08, Vector2.ONE)
	var out := PackedVector2Array([Vector2(0, -h), Vector2(w, -h * 0.35), Vector2(w, h * 0.35), Vector2(0, h), Vector2(-w, h * 0.35), Vector2(-w, -h * 0.35)])
	ci.draw_colored_polygon(out, _a(col, A))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(0, -h), Vector2(w, -h * 0.35), Vector2(0, -h * 0.05), Vector2(-w, -h * 0.35)]), Color(1, 1, 1, 0.5 * A))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(0, -h * 0.05), Vector2(w, -h * 0.35), Vector2(w, h * 0.35), Vector2(0, h)]), Color(0, 0, 0, 0.18 * A))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(0, -h * 0.75), Vector2(w * 0.35, -h * 0.45), Vector2(0, -h * 0.3)]), Color(1, 1, 1, 0.85 * A))
	ci.draw_polyline(_closed(out), Color(0.04, 0.12, 0.08, 0.4 * A), max(1.0, r * 0.06), true)

static func _candy(ci: CanvasItem, p: Vector2, r: float, col: Color, flap: float, A: float, ph: float) -> void:
	ci.draw_set_transform(p, -0.3 + sin(flap * 0.2 + ph) * 0.06, Vector2.ONE)
	var ol := Color(0.43, 0.08, 0.24, 0.35 * A)
	var lw: float = max(1.0, r * 0.07)
	for s in [-1.0, 1.0]:
		var wr := PackedVector2Array([Vector2(s * r * 0.5, 0), Vector2(s * r * 0.98, -r * 0.38), Vector2(s * r * 0.86, 0), Vector2(s * r * 0.98, r * 0.38)])
		_shape(ci, wr, _a(col.lightened(0.35), A), ol, lw)
	_shape(ci, _ell(Vector2.ZERO, r * 0.6, r * 0.5), _a(col, A), ol, lw)
	var sc := Color(1, 0.36, 0.54, 0.6 * A) if col.is_equal_approx(Color.WHITE) else Color(1, 1, 1, 0.55 * A)
	for k in [-0.3, 0.0, 0.3]:
		var x: float = k * r
		var hh: float = r * 0.5 * sqrt(max(0.0, 1.0 - pow(x / (r * 0.6), 2))) * 0.8
		ci.draw_line(Vector2(x - r * 0.12, -hh), Vector2(x + r * 0.12, hh), sc, r * 0.12, true)
	ci.draw_colored_polygon(_ell(Vector2(-r * 0.22, -r * 0.22), r * 0.14, r * 0.08, -0.5, 12), Color(1, 1, 1, 0.75 * A))

static func _planet(ci: CanvasItem, p: Vector2, r: float, col: Color, A: float, ph: float, awake: bool) -> void:
	if awake:
		Art.glow(ci, p, r * 2.2, col, 0.28 * A)
	var ring := _a(col.lightened(0.55), A)
	var rw: float = max(1.5, r * 0.12)
	ci.draw_set_transform(p, -0.35 + (posmod(int(round(ph)), 3) - 1) * 0.15, Vector2.ONE)
	ci.draw_polyline(_arc(Vector2.ZERO, r * 0.98, r * 0.3, PI, TAU), ring, rw, true)
	ci.draw_circle(Vector2.ZERO, r * 0.6, _a(col, A))
	ci.draw_circle(Vector2(-r * 0.12, -r * 0.12), r * 0.42, _a(col.lightened(0.18), A))
	ci.draw_circle(Vector2(-r * 0.22, -r * 0.22), r * 0.2, _a(col.lightened(0.45), A))
	for b in [[-0.1, 0.06], [0.24, 0.04]]:
		var y: float = b[0] * r
		var hw: float = sqrt(max(0.0, pow(r * 0.6, 2) - y * y))
		ci.draw_line(Vector2(-hw, y), Vector2(hw, y), Color(0, 0, 0, 0.13 * A), b[1] * r * 2.0)
	ci.draw_arc(Vector2.ZERO, r * 0.6, 0, TAU, 28, Color(0.04, 0, 0.12, 0.35 * A), max(1.0, r * 0.06), true)
	ci.draw_polyline(_arc(Vector2.ZERO, r * 0.98, r * 0.3, 0, PI), ring, rw, true)

# ---------- jars ----------
## The region's jar shape, or an empty array for the mason jar.
static func jar_points(r: Rect2, mouth: float) -> PackedVector2Array:
	var st: String = cur().get("jar", "mason")
	var x := r.position.x
	var w := r.size.x
	var top := r.position.y
	var bot := r.end.y
	var pts := PackedVector2Array()
	if st == "tube":
		var rad := w * 0.44
		pts.append(Vector2(x + w * 0.06, top))
		pts.append(Vector2(x + w * 0.06, bot - rad))
		for k in range(1, 20):
			var a := PI - PI * k / 20.0
			pts.append(Vector2(x + w * 0.5 + cos(a) * rad, bot - rad + sin(a) * rad))
		pts.append(Vector2(x + w * 0.94, bot - rad))
		pts.append(Vector2(x + w * 0.94, top))
		if mouth > 0.0:
			for k in range(1, 24):
				var a := -PI * k / 24.0
				pts.append(Vector2(x + w * 0.5 + cos(a) * rad, top + sin(a) * mouth))
	elif st == "vase":
		pts.append(Vector2(x + w * 0.14, top))
		pts.append(Vector2(x + w * 0.14, top + w * 0.14))
		_quad(Vector2(x + w * 0.14, top + w * 0.14), Vector2(x - w * 0.04, top + w * 0.38), Vector2(x, top + w * 0.66), pts)
		pts.append(Vector2(x, bot - w * 0.3))
		_quad(Vector2(x, bot - w * 0.3), Vector2(x, bot), Vector2(x + w * 0.3, bot), pts)
		pts.append(Vector2(x + w * 0.7, bot))
		_quad(Vector2(x + w * 0.7, bot), Vector2(x + w, bot), Vector2(x + w, bot - w * 0.3), pts)
		pts.append(Vector2(x + w, top + w * 0.66))
		_quad(Vector2(x + w, top + w * 0.66), Vector2(x + w * 1.04, top + w * 0.38), Vector2(x + w * 0.86, top + w * 0.14), pts)
		pts.append(Vector2(x + w * 0.86, top))
		if mouth > 0.0:
			for k in range(1, 24):
				var a := -PI * k / 24.0
				pts.append(Vector2(x + w * 0.5 + cos(a) * w * 0.36, top + sin(a) * mouth))
	return pts

## The painted extras of the region's jar (bubbles, clay rim, lantern frame, candy stripes, metal bands).
static func deco(ci: CanvasItem, r: Rect2) -> void:
	var x := r.position.x
	var w := r.size.x
	var top := r.position.y
	var bot := r.end.y
	var lw: float = max(1.5, w * 0.04)
	match cur().get("deco", ""):
		"bubbles":
			for b in [Vector3(1.08, 0.35, 0.07), Vector3(1.16, 0.2, 0.045), Vector3(1.1, 0.08, 0.03)]:
				ci.draw_arc(Vector2(x + w * b.x, top + w * b.y), w * b.z, 0, TAU, 16, Color(1, 1, 1, 0.75), max(1.0, w * 0.025), true)
			var sc := PackedVector2Array([Vector2(x + w * 0.08, bot + w * 0.02)])
			for k in 4:
				var x0 := x + w * (0.08 + k * 0.21)
				_quad(Vector2(x0, bot + w * 0.02), Vector2(x0 + w * 0.105, bot - w * 0.12), Vector2(x0 + w * 0.21, bot + w * 0.02), sc, 5)
			_shape(ci, sc, Color("#ff9d8c"), Color("#d9675a"), max(1.0, w * 0.03))
		"clay":
			var rim := Rect2(x + w * 0.06, top - w * 0.03, w * 0.88, w * 0.12)
			Art.vgradient(ci, rim, Color("#f2a27b"), Color("#d9744a"), Color("#b9562f"), 0.5)
			ci.draw_rect(rim, Color(0.43, 0.16, 0.06, 0.6), false, max(1.0, w * 0.025))
			var stem := PackedVector2Array([Vector2(x + w * 0.5, bot)])
			_quad(Vector2(x + w * 0.5, bot), Vector2(x + w * 0.5, bot + w * 0.1), Vector2(x + w * 0.32, bot + w * 0.12), stem, 6)
			ci.draw_polyline(stem, Color("#5fa640"), lw, true)
			ci.draw_colored_polygon(_ell(Vector2(x + w * 0.66, bot + w * 0.07), w * 0.1, w * 0.05), Color("#6fb14d"))
		"lantern":
			var wood := Color("#6b4a26")
			var dark := Color(0.2, 0.12, 0.05, 0.8)
			for sx in [-0.03, 0.95]:
				var bar := Rect2(x + w * sx, top + w * 0.28, w * 0.08, r.size.y - w * 0.36)
				ci.draw_rect(bar, wood)
				ci.draw_rect(bar, dark, false, max(1.0, w * 0.025))
			var base := Rect2(x - w * 0.06, bot - w * 0.1, w * 1.12, w * 0.14)
			ci.draw_rect(base, wood)
			ci.draw_rect(base, dark, false, max(1.0, w * 0.025))
			ci.draw_arc(Vector2(x + w * 0.5, top - w * 0.32), w * 0.14, PI * 1.05, PI * 1.95, 12, Color("#c9a45a"), lw, true)
			Art.glow(ci, Vector2(x + w * 0.5, bot - w * 0.05), w * 0.6, Color("#ffd36a"), 0.18)
		"stripes":
			var y0 := bot - w * 0.62
			var band := Rect2(x + w * 0.06, y0, w * 0.88, w * 0.16)
			ci.draw_rect(band, Color(1, 1, 1, 0.75))
			for k in 4:
				var bx := x + w * (0.1 + k * 0.22)
				ci.draw_colored_polygon(PackedVector2Array([Vector2(bx, y0 + w * 0.16), Vector2(bx + w * 0.08, y0 + w * 0.16), Vector2(bx + w * 0.16, y0), Vector2(bx + w * 0.08, y0)]), Color(1, 0.36, 0.54, 0.55))
			for s in [[0.18, 0.9, "#7dff6b"], [0.8, 1.3, "#5cf2ff"], [0.25, 1.6, "#ffd93b"]]:
				ci.draw_rect(Rect2(x + w * s[0], top + w * s[1], w * 0.1, w * 0.035), Color(Color(s[2]), 0.7))
		"metal":
			for yy in [top + w * 0.14, bot - w * 0.5]:
				var mb := Rect2(x - w * 0.02, yy, w * 1.04, w * 0.1)
				var c0 := Color("#59607a")
				var c1 := Color("#e6ecff")
				var mid := mb.position.x + mb.size.x * 0.4
				ci.draw_polygon(PackedVector2Array([mb.position, Vector2(mid, mb.position.y), Vector2(mid, mb.end.y), Vector2(mb.position.x, mb.end.y)]), PackedColorArray([c0, c1, c1, c0]))
				ci.draw_polygon(PackedVector2Array([Vector2(mid, mb.position.y), Vector2(mb.end.x, mb.position.y), mb.end, Vector2(mid, mb.end.y)]), PackedColorArray([c1, Color("#4a5068"), Color("#4a5068"), c1]))
				for k in [0.15, 0.5, 0.85]:
					ci.draw_circle(Vector2(x + w * k, yy + w * 0.05), w * 0.022, Color("#2c3147"))
			for s in [Vector2(0.3, 0.7), Vector2(0.7, 1.2), Vector2(0.4, 1.7)]:
				ci.draw_colored_polygon(Art._spark(Vector2(x + w * s.x, top + w * s.y), w * 0.06, w * 0.015), Color(1, 1, 1, 0.8))

## A shelf in the region's colors. Returns false for the night region (the wooden shelf).
static func shelf(ci: CanvasItem, sh: Rect2) -> bool:
	var T := cur()
	if not T.has("shelf"):
		return false
	var s: Array = T.shelf
	ci.draw_set_transform(Vector2(sh.get_center().x, sh.end.y + sh.size.y * 0.7), 0.0, Vector2(1.0, 0.12))
	ci.draw_circle(Vector2.ZERO, sh.size.x * 0.5, Color(0, 0, 0, 0.2))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	Art.vgradient(ci, sh, Color(s[0]), Color(s[0]).lerp(Color(s[1]), 0.5), Color(s[1]), 0.5)
	ci.draw_rect(Rect2(sh.position.x + 3, sh.position.y, sh.size.x - 6, max(2.0, sh.size.y * 0.25)), Color(s[2]))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(sh.position.y)
	match T.name:
		"candy":
			for k in 14:
				ci.draw_rect(Rect2(sh.position.x + rng.randf() * sh.size.x, sh.position.y + sh.size.y * (0.35 + rng.randf() * 0.45), 4, 2), Art.COLORS[k % 7])
		"reef":
			for k in 3:
				ci.draw_colored_polygon(_arc(Vector2(sh.position.x + sh.size.x * (0.2 + k * 0.3), sh.position.y + sh.size.y * 0.7), sh.size.y * 0.3, sh.size.y * 0.3, PI, TAU, 10), Color("#ffd2c2"))
		"grove":
			for k in 6:
				ci.draw_colored_polygon(_ell(Vector2(sh.position.x + sh.size.x * (0.08 + k * 0.17), sh.position.y + 1), sh.size.y * 0.5, sh.size.y * 0.25), Color("#4f9a3a"))
		"space":
			for k in 6:
				ci.draw_circle(Vector2(sh.position.x + sh.size.x * (0.08 + k * 0.168), sh.position.y + sh.size.y * 0.6), 2.0, Color("#2c3147"))
	if not T.get("day", false):
		Art.glow(ci, Vector2(sh.get_center().x, sh.position.y), sh.size.x * 0.5, Color(T.glow), 0.1)
	return true

## The lid's colors: [top dark, top light, band dark, band mid, band light, band mid, band darkest, rim].
static func cap_cols() -> Array:
	var T := cur()
	if not T.has("cap"):
		return [Color("#b9843a"), Color("#ecc675"), Color("#8a5d22"), Color("#d9a74e"), Color("#fbe7a6"), Color("#d6a24c"), Color("#7a5220"), Color("#fff1c2")]
	var d := Color(T.cap[0])
	var m := Color(T.cap[1])
	var l := Color(T.cap[2])
	return [d.lerp(m, 0.5), m.lerp(l, 0.5), d, m, l, m, d.darkened(0.1), l.lerp(Color.WHITE, 0.5)]

# ---------- scenes ----------
static var _bub: Array = []
static var _spore: Array = []
static var _spark_pts: Array = []
static var _space_stars: Array = []
static var _meteors := {}

static func _seed() -> void:
	if not _bub.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for k in 16:
		_bub.append([rng.randf(), 0.04 + rng.randf() * 0.05, rng.randf(), 2.0 + rng.randf() * 5.0])
	for k in 18:
		_spore.append([rng.randf(), 0.01 + rng.randf() * 0.02, rng.randf()])
	for k in 14:
		_spark_pts.append([rng.randf(), rng.randf(), 0.8 + rng.randf()])
	for k in 110:
		_space_stars.append([rng.randf(), rng.randf() * 0.8, 0.6 + rng.randf() * 1.6, 0.3 + rng.randf() * 0.6])

static func _rays(ci: CanvasItem, W: float, H: float, col: Color, list: Array) -> void:
	var clear := Color(col, 0.0)
	for q in list:
		ci.draw_polygon(PackedVector2Array([Vector2(W * q[0], 0), Vector2(W * q[1], 0), Vector2(W * q[3], H * 0.8), Vector2(W * q[2], H * 0.8)]), PackedColorArray([col, col, clear, clear]))

static func _puff(ci: CanvasItem, x: float, y: float, s: float, col: Color) -> void:
	ci.draw_colored_polygon(_ell(Vector2(x, y), 42 * s, 15 * s), col)
	ci.draw_circle(Vector2(x - 15 * s, y - 9 * s), 17 * s, col)
	ci.draw_circle(Vector2(x + 12 * s, y - 13 * s), 21 * s, col)

static func _coral(ci: CanvasItem, x: float, base: float, s: float, col: Color) -> void:
	var w := 9.0 * s
	ci.draw_line(Vector2(x, base), Vector2(x, base - 50 * s), col, w)
	var a := PackedVector2Array([Vector2(x, base - 22 * s)])
	_quad(Vector2(x, base - 22 * s), Vector2(x - 20 * s, base - 28 * s), Vector2(x - 22 * s, base - 55 * s), a)
	ci.draw_polyline(a, col, w)
	var b := PackedVector2Array([Vector2(x, base - 30 * s)])
	_quad(Vector2(x, base - 30 * s), Vector2(x + 18 * s, base - 36 * s), Vector2(x + 20 * s, base - 64 * s), b)
	ci.draw_polyline(b, col, w)
	for e in [Vector2(x, base - 50 * s), Vector2(x - 22 * s, base - 55 * s), Vector2(x + 20 * s, base - 64 * s)]:
		ci.draw_circle(e, w * 0.5, col)

static func _mush(ci: CanvasItem, x: float, base: float, s: float, cap: Color) -> void:
	ci.draw_rect(Rect2(x - 5 * s, base - 22 * s, 10 * s, 22 * s), Color("#f3e8cf"))
	var c := PackedVector2Array([Vector2(x - 22 * s, base - 18 * s)])
	_quad(Vector2(x - 22 * s, base - 18 * s), Vector2(x - 20 * s, base - 44 * s), Vector2(x, base - 46 * s), c)
	_quad(Vector2(x, base - 46 * s), Vector2(x + 20 * s, base - 44 * s), Vector2(x + 22 * s, base - 18 * s), c)
	ci.draw_colored_polygon(c, cap)
	ci.draw_circle(Vector2(x - 8 * s, base - 32 * s), 3 * s, Color(1, 1, 1, 0.8))
	ci.draw_circle(Vector2(x + 7 * s, base - 36 * s), 2.5 * s, Color(1, 1, 1, 0.8))

static func _lolly(ci: CanvasItem, x: float, base: float, h: float, col: Color) -> void:
	ci.draw_line(Vector2(x, base), Vector2(x, base - h), Color.WHITE, max(2.0, h * 0.05))
	var rr := h * 0.28
	var c := Vector2(x, base - h)
	ci.draw_circle(c, rr, col)
	var sp := PackedVector2Array()
	var a := 0.0
	while a < 12.0:
		sp.append(c + Vector2(cos(a), sin(a)) * rr * a / 12.0)
		a += 0.3
	ci.draw_polyline(sp, Color(1, 1, 1, 0.8), max(1.5, rr * 0.18), true)

static func _big_planet(ci: CanvasItem, c: Vector2, r: float) -> void:
	Art.glow(ci, c, r * 2.4, Color("#ff9f43"), 0.22)
	ci.draw_set_transform(c, -0.3, Vector2.ONE)
	var ring := Color(1, 0.86, 0.67, 0.75)
	ci.draw_polyline(_arc(Vector2.ZERO, r * 1.7, r * 0.45, PI * 0.97, PI * 2.03), ring, r * 0.1, true)
	ci.draw_circle(Vector2.ZERO, r, Color("#d9662f"))
	ci.draw_circle(Vector2(-r * 0.15, -r * 0.15), r * 0.75, Color("#ec8a4a"))
	ci.draw_circle(Vector2(-r * 0.3, -r * 0.3), r * 0.35, Color("#ffd29a"))
	ci.draw_polyline(_arc(Vector2.ZERO, r * 1.7, r * 0.45, PI * 0.03, PI * 0.97), ring, r * 0.1, true)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

static func _hill(ci: CanvasItem, W: float, H: float, y: float, amp: float, freq: float, ph: float, col) -> void:
	Art.hill(ci, Vector2(W, H), y, amp, freq, ph, Color(col))

static func sky(ci: CanvasItem, T: Dictionary, W: float, H: float) -> void:
	_seed()
	match T.name:
		"reef":
			Art.vgradient(ci, Rect2(0, 0, W, H), Color(T.sky[0]), Color(T.sky[1]), Color(T.sky[2]), 0.5)
			_rays(ci, W, H, Color(1, 1, 1, 0.28), [[0.08, 0.2, 0.3, 0.5], [0.55, 0.63, 0.7, 0.9], [0.82, 0.88, 0.92, 1.05]])
			var wave := PackedVector2Array()
			var x := 0.0
			while x <= W:
				wave.append(Vector2(x, H * 0.012 + sin(x / 22.0) * 3.0))
				x += 6.0
			ci.draw_polyline(wave, Color(1, 1, 1, 0.55), 3.0, true)
		"sunpetal":
			Art.vgradient(ci, Rect2(0, 0, W, H * 0.75), Color(T.sky[0]), Color(T.sky[1]), Color(T.sky[2]), 0.5)
			ci.draw_rect(Rect2(0, H * 0.75, W, H * 0.25), Color(T.sky[2]))
			Art.glow(ci, Vector2(W * 0.72, H * 0.2), W * 0.45, Color("#fff3b0"), 0.55)
			ci.draw_circle(Vector2(W * 0.72, H * 0.2), W * 0.11, Color("#fff8d6"))
			_puff(ci, W * 0.18, H * 0.12, W / 380.0, Color(1, 1, 1, 0.85))
			_puff(ci, W * 0.8, H * 0.36, W / 520.0, Color(1, 1, 1, 0.75))
		"grove":
			Art.vgradient(ci, Rect2(0, 0, W, H), Color(T.sky[0]), Color(T.sky[1]), Color(T.sky[2]), 0.5)
			_rays(ci, W, H, Color(0.92, 1, 0.69, 0.3), [[0.3, 0.48, 0.6, 0.9], [0.6, 0.7, 0.9, 1.05]])
			for q in [[0.0, 0.09], [0.9, 0.12], [0.76, 0.04], [0.15, 0.035]]:
				ci.draw_rect(Rect2(W * q[0], 0, W * q[1], H), Color(0.07, 0.22, 0.14, 0.7))
			ci.draw_colored_polygon(_ell(Vector2(W * 0.05, -10), W * 0.3, H * 0.09), Color("#1b5233"))
			ci.draw_colored_polygon(_ell(Vector2(W * 0.95, -20), W * 0.32, H * 0.1), Color("#1b5233"))
			ci.draw_colored_polygon(_ell(Vector2(W * 0.5, -30), W * 0.24, H * 0.07), Color("#22603b"))
		"candy":
			Art.vgradient(ci, Rect2(0, 0, W, H), Color(T.sky[0]), Color(T.sky[1]), Color(T.sky[2]), 0.5)
			var cols := [Color(1, 0.35, 0.43), Color(1, 0.63, 0.27), Color(1, 0.9, 0.35), Color(0.43, 0.94, 0.51), Color(0.35, 0.78, 1), Color(0.75, 0.47, 1)]
			for k in 6:
				ci.draw_arc(Vector2(W * 0.5, H * 0.62), W * (0.62 - k * 0.03), PI, TAU, 64, Color(cols[k], 0.22), W * 0.03)
			_puff(ci, W * 0.2, H * 0.14, W / 330.0, Color.WHITE)
			_puff(ci, W * 0.82, H * 0.3, W / 420.0, Color("#ffe6f3"))
			_puff(ci, W * 0.55, H * 0.08, W / 600.0, Color.WHITE)
		"space":
			Art.vgradient(ci, Rect2(0, 0, W, H), Color(T.sky[0]), Color(T.sky[1]), Color(T.sky[2]), 0.5)
			Art.glow(ci, Vector2(W * 0.75, H * 0.35), W * 0.6, Color("#c058ff"), 0.22)
			Art.glow(ci, Vector2(W * 0.2, H * 0.55), W * 0.5, Color("#4d8bff"), 0.2)
			for s in _space_stars:
				ci.draw_rect(Rect2(s[0] * W, s[1] * H, s[2], s[2]), Color(1, 1, 1, s[3]))
			_big_planet(ci, Vector2(W * 0.24, H * 0.17), min(W, H) * 0.09)
			ci.draw_circle(Vector2(W * 0.85, H * 0.1), W * 0.03, Color("#e9e4ff"))

static func land(ci: CanvasItem, T: Dictionary, W: float, H: float) -> void:
	var k: float = min(1.5, W / 360.0)
	match T.name:
		"reef":
			_hill(ci, W, H, H * 0.84, H * 0.018, 3.0, 0.5, T.hills[1])
			_coral(ci, W * 0.1, H * 0.9, k, Color("#ff7a8a"))
			_coral(ci, W * 0.9, H * 0.9, 0.9 * k, Color("#ffa24d"))
			_coral(ci, W * 0.72, H * 0.9, 0.6 * k, Color("#c77dff"))
			_hill(ci, W, H, H * 0.9, H * 0.012, 5.0, 2.0, T.hills[0])
			for i in 3:
				ci.draw_colored_polygon(_arc(Vector2(W * (0.3 + i * 0.2), H * (0.95 + (i % 2) * 0.02)), 9, 9, PI, TAU, 10), Color("#ffd2c2"))
		"sunpetal":
			_hill(ci, W, H, H * 0.66, H * 0.02, 3.0, 1.0, "#b8e08a")
			Scenes._round_tree(ci, W * 0.12, H * 0.7, H * 0.14, Color("#7a4a2a"), Color("#6fb14d"), Color(1, 1, 1, 0.35), 2)
			Scenes._round_tree(ci, W * 0.86, H * 0.7, H * 0.14, Color("#7a4a2a"), Color("#6fb14d"), Color(1, 1, 1, 0.35), 7)
			_hill(ci, W, H, H * 0.74, H * 0.02, 4.0, 2.2, T.hills[0])
			_hill(ci, W, H, H * 0.83, H * 0.018, 3.0, 0.7, T.hills[1])
			_hill(ci, W, H, H * 0.91, H * 0.012, 5.0, 1.4, T.hills[2])
			var rng := RandomNumberGenerator.new()
			rng.seed = 5
			var fc := [Color.WHITE, Color("#ff5c8a"), Color("#ffd93b"), Color("#b98cff")]
			for i in 26:
				var p := Vector2(rng.randf() * W, H * (0.76 + rng.randf() * 0.22))
				_flower(ci, p, 5.0 + rng.randf() * 3.0, fc[i % 4], 0.0, 1.0, float(i))
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"grove":
			_hill(ci, W, H, H * 0.86, H * 0.015, 4.0, 1.1, T.hills[1])
			for m in [[0.1, 1.1], [0.88, 0.9], [0.22, 0.6], [0.7, 0.7], [0.5, 0.5]]:
				_mush(ci, W * m[0], H * 0.89, m[1] * k, Color("#7dffd0"))
			_hill(ci, W, H, H * 0.93, H * 0.01, 6.0, 2.6, T.hills[2])
		"candy":
			_hill(ci, W, H, H * 0.76, H * 0.02, 3.0, 0.4, T.hills[0])
			_lolly(ci, W * 0.12, H * 0.82, H * 0.14, Color("#5cf2ff"))
			_lolly(ci, W * 0.86, H * 0.82, H * 0.17, Color("#ffd93b"))
			_lolly(ci, W * 0.3, H * 0.82, H * 0.1, Color("#7dff6b"))
			_hill(ci, W, H, H * 0.84, H * 0.016, 4.0, 1.8, T.hills[1])
			_hill(ci, W, H, H * 0.92, H * 0.01, 6.0, 2.8, T.hills[2])
			for i in 7:
				var c := Vector2(W * (0.08 + i * 0.14), H * (0.9 + 0.025 * (1 + sin(i * 2.3))))
				ci.draw_colored_polygon(_arc(c, 11, 10, PI, TAU, 12), Art.COLORS[(i * 3) % 7])
				ci.draw_colored_polygon(_ell(c + Vector2(-3, -5), 3, 2), Color(1, 1, 1, 0.6))
		"space":
			_hill(ci, W, H, H * 0.85, H * 0.02, 3.0, 0.6, T.hills[0])
			_hill(ci, W, H, H * 0.91, H * 0.012, 5.0, 2.0, T.hills[1])
			var rng := RandomNumberGenerator.new()
			rng.seed = 4
			for i in 6:
				var s := 6.0 + rng.randf() * 10.0
				ci.draw_colored_polygon(_ell(Vector2(rng.randf() * W, H * (0.9 + rng.randf() * 0.07)), s * 1.6, s * 0.5), Color(0.04, 0, 0.12, 0.35))

static func live(ci: CanvasItem, T: Dictionary, W: float, H: float, t: float, part: String) -> void:
	_seed()
	match T.name:
		"reef":
			if part == "sky":
				for k in 3:
					var dir := -1.0 if k % 2 else 1.0
					var u := fmod(t * 0.03 * (1 + k * 0.3) + k * 0.37, 1.3) - 0.15
					var x := u * W if dir > 0 else W - u * W
					var y := H * (0.3 + k * 0.14) + sin(t + k) * 6.0
					ci.draw_set_transform(Vector2(x, y), 0.0, Vector2(-dir, 1))
					var c := Color(0.04, 0.44, 0.56, 0.35)
					ci.draw_colored_polygon(_ell(Vector2.ZERO, 14, 7), c)
					ci.draw_colored_polygon(PackedVector2Array([Vector2(10, 0), Vector2(20, -7), Vector2(20, 7)]), c)
				ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				for k in _bub.size():
					var b: Array = _bub[k]
					var u := fmod(b[2] + t * b[1], 1.0)
					ci.draw_arc(Vector2(b[0] * W + sin(t * 1.5 + k) * 6.0, H * (1.02 - u * 1.05)), b[3], 0, TAU, 14, Color(1, 1, 1, 0.7), 1.3, true)
			else:
				for k in 6:
					var x := W * (0.05 + k * 0.19)
					var base := H * 0.93
					var h := H * (0.1 + (k % 3) * 0.03)
					var p := PackedVector2Array([Vector2(x, base)])
					for s in range(1, 9):
						var u := s / 8.0
						p.append(Vector2(x + sin(t * 1.2 + k + u * 4.0) * 8.0 * u, base - h * u))
					ci.draw_polyline(p, Color(T.hills[2]), 6.0, true)
		"sunpetal":
			if part == "sky":
				_puff(ci, (fmod(t * 0.01, 1.4) - 0.2) * W, H * 0.26, W / 620.0, Color(1, 1, 1, 0.55))
			else:
				Scenes._seed_lists()
				for p in Scenes._petals:
					var u := fmod(p.o + t * p.v, 1.0)
					var x := fmod(p.x + sin(t * 0.5 + p.a) * 0.05 + u * 0.2 + 1.0, 1.0) * W
					ci.draw_colored_polygon(_ell(Vector2(x, u * H), 4.0 * p.s, 2.2 * p.s, t * 1.5 * p.s + p.a, 10), Color(1, 0.55, 0.67, 0.75))
				for k in 2:
					var c := Vector2(W * (0.3 + k * 0.4) + sin(t * 0.7 + k * 2) * W * 0.12, H * (0.55 + k * 0.08) + sin(t * 1.9 + k) * 12.0)
					var f := absf(sin(t * 9.0 + k))
					for s in [-1.0, 1.0]:
						ci.draw_colored_polygon(_ell(c + Vector2(s * 5.0 * f, 0), 5.0 * f + 1.0, 7.0, s * 0.4, 10), Color.WHITE if k else Color("#ffb347"))
		"grove":
			if part == "sky":
				return
			var k := 0
			for m in [[0.1, 1.1], [0.88, 0.9], [0.22, 0.6], [0.7, 0.7], [0.5, 0.5]]:
				Art.glow(ci, Vector2(W * m[0], H * 0.89 - 34.0 * m[1] * min(1.5, W / 320.0)), 50.0 * m[1], Color("#7dffd0"), 0.18 + 0.1 * sin(t * 1.6 + k))
				k += 1
			for i in _spore.size():
				var s: Array = _spore[i]
				var u := fmod(s[2] + t * s[1], 1.0)
				var p := Vector2((s[0] + sin(t * 0.4 + i) * 0.03) * W, H * (1.0 - u))
				Art.glow(ci, p, 8.0, Color("#d7ff9a"), 0.5 * absf(sin(t + i)))
				ci.draw_rect(Rect2(p - Vector2(1, 1), Vector2(2, 2)), Color(0.9, 1, 0.7, 0.8))
		"candy":
			if part == "sky":
				_puff(ci, (fmod(t * 0.012, 1.4) - 0.2) * W, H * 0.46, W / 640.0, Color(1, 1, 1, 0.7))
			else:
				for i in _spark_pts.size():
					var s: Array = _spark_pts[i]
					var a: float = max(0.0, sin(t * s[2] + i * 2.0))
					if a > 0.01:
						ci.draw_colored_polygon(Art._spark(Vector2(s[0] * W, s[1] * H * 0.7), 6.0 * a + 1.0, 1.5), Color(1, 1, 1, 0.9 * a))
		"space":
			if part != "sky":
				return
			for i in _spark_pts.size():
				var s: Array = _spark_pts[i]
				var a: float = max(0.0, sin(t * s[2] + i))
				if a > 0.01:
					ci.draw_colored_polygon(Art._spark(Vector2(s[1] * W, s[0] * H * 0.75), 5.0 * a + 1.0, 1.2), Color(1, 1, 1, a))
			var key := "%dx%d" % [int(W), int(H)]
			if not _meteors.has(key):
				_meteors[key] = {"list": [], "next": 0.0}
			Art.meteors(ci, _meteors[key], t, W, H, false)
