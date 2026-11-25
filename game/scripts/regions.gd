class_name Regions
extends RefCounted
## Jar World: each chapter is a region with its own scene, its own things to sort and its own jar.
## Same regions as the web test page (tools/web/regions.js). Night ("meadow") keeps the original firefly look.

## Which region's jars and things are drawn right now (set by main.gd from the chapter being played).
static func cur() -> Dictionary:
	if hub:
		return Art.THEMES[3]
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
	var kind: String = force_kind if force_kind != "" else cur().get("item", "fly")
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

# ---------- each world's own jar (same drawing as tools/web/regions.js) ----------
static func _t() -> float:
	return Time.get_ticks_msec() / 1000.0

## Colors each point by where it sits between `from` and `to` (along x or y), through the given stops.
static func _grad_poly(ci: CanvasItem, pts: PackedVector2Array, stops: Array, from: float, to: float, vertical := true) -> void:
	# Drop repeated points (e.g. a fully round pill shape) so triangulation never fails.
	var clean := PackedVector2Array()
	for q in pts:
		if clean.is_empty() or clean[clean.size() - 1].distance_squared_to(q) > 0.0001:
			clean.append(q)
	if clean.size() > 1 and clean[0].distance_squared_to(clean[clean.size() - 1]) <= 0.0001:
		clean.remove_at(clean.size() - 1)
	pts = clean
	if pts.size() < 3:
		return
	var cols := PackedColorArray()
	for p in pts:
		var k := clampf(((p.y if vertical else p.x) - from) / max(0.001, to - from), 0.0, 1.0)
		var c: Color = stops[0][1]
		for s in range(1, stops.size()):
			if k <= stops[s][0]:
				var a: float = stops[s - 1][0]
				c = (stops[s - 1][1] as Color).lerp(stops[s][1], (k - a) / max(0.001, stops[s][0] - a))
				break
			c = stops[s][1]
		cols.append(c)
	ci.draw_polygon(pts, cols)

static func _rr(r: Rect2, rad: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	rad = min(rad, r.size.x * 0.5, r.size.y * 0.5)
	var cs := [[r.end.x - rad, r.position.y + rad, -PI / 2], [r.end.x - rad, r.end.y - rad, 0.0], [r.position.x + rad, r.end.y - rad, PI / 2], [r.position.x + rad, r.position.y + rad, PI]]
	for c in cs:
		for k in 6:
			var a: float = c[2] + PI / 2 * k / 5.0
			var q := Vector2(c[0], c[1]) + Vector2(cos(a), sin(a)) * rad
			if pts.is_empty() or pts[pts.size() - 1].distance_squared_to(q) > 0.0001:
				pts.append(q)
	if pts.size() > 1 and pts[0].distance_squared_to(pts[pts.size() - 1]) <= 0.0001:
		pts.remove_at(pts.size() - 1)
	return pts

## Draws `poly` cut to the inside of the jar glass.
static func _in_jar(ci: CanvasItem, poly: PackedVector2Array, jar: PackedVector2Array, stops: Array, y0: float, y1: float) -> void:
	for p in Geometry2D.intersect_polygons(poly, jar):
		_grad_poly(ci, p, stops, y0, y1)

static func _star(c: Vector2, ro: float, ri: float) -> PackedVector2Array:
	var p := PackedVector2Array()
	for k in 10:
		var a := -PI / 2 + k * PI / 5
		p.append(c + Vector2(cos(a), sin(a)) * (ro if k % 2 == 0 else ri))
	return p

static func _leaf(ci: CanvasItem, p: Vector2, s: float, rot: float, col: Color) -> void:
	var pts := PackedVector2Array([Vector2.ZERO])
	_quad(Vector2.ZERO, Vector2(s * 0.5, -s * 0.45), Vector2(s, 0), pts, 6)
	_quad(Vector2(s, 0), Vector2(s * 0.5, s * 0.45), Vector2.ZERO, pts, 6)
	pts.remove_at(pts.size() - 1)
	var out := PackedVector2Array()
	for q in pts:
		out.append(p + q.rotated(rot))
	ci.draw_colored_polygon(out, col)

static func _daisy(ci: CanvasItem, c: Vector2, s: float, petal: Color, mid: Color) -> void:
	for k in 6:
		var a := k * PI / 3
		ci.draw_circle(c + Vector2(cos(a), sin(a)) * s * 0.55, s * 0.42, petal)
	ci.draw_circle(c, s * 0.38, mid)

const BRASS := [[0.0, Color("#7a5a20")], [0.45, Color("#f3d98c")], [1.0, Color("#80601f")]]
const STEEL := [[0.0, Color("#4a5068")], [0.4, Color("#eef2ff")], [1.0, Color("#3e4460")]]

static func _bar(ci: CanvasItem, r: Rect2, rad: float, stops: Array, line := Color(0, 0, 0, 0), lw := 1.0) -> void:
	var p := _rr(r, rad)
	_grad_poly(ci, p, stops, r.position.x, r.end.x, false)
	if line.a > 0.0:
		ci.draw_polyline(_closed(p), line, lw, true)

## Behind the things inside: water and sand, warm light, candy stripes, a starry glass.
static func back(ci: CanvasItem, r: Rect2) -> void:
	var x := r.position.x
	var w := r.size.x
	var top := r.position.y
	var bot := r.end.y
	var t := _t()
	var ph := x * 0.05
	var jar := Art.jar_points(r)
	match cur().get("deco", ""):
		"bubbles":
			var wy := top + w * 0.34
			var surf := PackedVector2Array()
			for k in 9:
				surf.append(Vector2(x + w * k / 8.0, wy + sin(t * 2.2 + k * 1.3 + ph) * w * 0.025))
			var water := surf.duplicate()
			water.append(Vector2(x + w, bot))
			water.append(Vector2(x, bot))
			_in_jar(ci, water, jar, [[0.0, Color(0.47, 0.92, 1.0, 0.16)], [1.0, Color(0.08, 0.55, 0.82, 0.34)]], wy, bot)
			ci.draw_polyline(surf, Color(0.9, 1, 1, 0.55), max(1.0, w * 0.03), true)
			var sand := PackedVector2Array([Vector2(x, bot - w * 0.1)])
			_quad(Vector2(x, bot - w * 0.1), Vector2(x + w * 0.3, bot - w * 0.17), Vector2(x + w * 0.55, bot - w * 0.11), sand, 6)
			_quad(Vector2(x + w * 0.55, bot - w * 0.11), Vector2(x + w * 0.8, bot - w * 0.06), Vector2(x + w, bot - w * 0.13), sand, 6)
			sand.append(Vector2(x + w, bot + 2))
			sand.append(Vector2(x, bot + 2))
			_in_jar(ci, sand, jar, [[0.0, Color("#f8e2ab")], [1.0, Color("#d6ad62")]], bot - w * 0.16, bot)
			for k in 4:
				var p := fmod(t * 0.35 + k * 0.27 + ph * 0.13, 1.0)
				var yy := bot - w * 0.15 - p * (bot - w * 0.15 - wy)
				var xx := x + w * (0.18 + 0.64 * fmod(k * 0.37 + ph * 0.21, 1.0)) + sin(t * 3.0 + k) * w * 0.04
				ci.draw_arc(Vector2(xx, yy), w * (0.03 + 0.015 * (k % 2)), 0, TAU, 12, Color(1, 1, 1, 0.6), max(0.8, w * 0.022), true)
		"clay":
			ci.draw_colored_polygon(jar, Color(1, 0.8, 0.59, 0.1))
		"lantern":
			Art.glow(ci, Vector2(x + w * 0.5, bot - w * 0.4), w * 1.0, Color("#ffcf5a"), 0.2 + 0.05 * sin(t * 7.0 + ph) * sin(t * 3.1 + ph))
		"stripes":
			ci.draw_colored_polygon(jar, Color(1, 0.69, 0.84, 0.12))
			var sy := bot - w * 0.16
			_in_jar(ci, PackedVector2Array([Vector2(x - 2, sy), Vector2(x + w + 2, sy), Vector2(x + w + 2, bot + 2), Vector2(x - 2, bot + 2)]), jar, [[0.0, Color(1, 1, 1, 0.7)], [1.0, Color(1, 1, 1, 0.7)]], sy, bot)
			for k in range(-1, 6):
				var bx := x + k * w * 0.22
				_in_jar(ci, PackedVector2Array([Vector2(bx, bot), Vector2(bx + w * 0.1, bot), Vector2(bx + w * 0.26, sy), Vector2(bx + w * 0.16, sy)]), jar, [[0.0, Color(1, 0.36, 0.54, 0.6)], [1.0, Color(1, 0.36, 0.54, 0.6)]], sy, bot)
		"metal":
			_grad_poly(ci, jar, [[0.0, Color(0.35, 0.16, 0.63, 0.0)], [1.0, Color(0.35, 0.16, 0.63, 0.3)]], top, bot)
			for k in 6:
				var a := 0.3 + 0.7 * absf(sin(t * 1.5 + k * 1.7 + ph))
				ci.draw_rect(Rect2(x + w * (0.15 + fmod(k * 0.41 + ph * 0.17, 0.7)), top + r.size.y * (0.25 + fmod(k * 0.23 + ph * 0.11, 0.65)), 1.5, 1.5), Color(1, 1, 1, a * 0.8))
			ci.draw_polyline(_ring(r, PI, TAU), Color(0.8, 0.69, 1.0, 0.38), max(2.0, w * 0.07), true)

static func _ring(r: Rect2, a0: float, a1: float) -> PackedVector2Array:
	var c := Vector2(r.get_center().x, r.position.y + r.size.y * 0.56)
	var p := PackedVector2Array()
	for k in 25:
		var a := a0 + (a1 - a0) * k / 24.0
		p.append(c + Vector2(cos(a) * r.size.x * 0.68, sin(a) * r.size.x * 0.15).rotated(-0.12))
	return p

## In front of the things inside: rims, frames, twine, icing, rings and little decorations.
static func deco(ci: CanvasItem, r: Rect2) -> void:
	var x := r.position.x
	var w := r.size.x
	var top := r.position.y
	var bot := r.end.y
	var t := _t()
	var ph := x * 0.05
	var thin: float = max(1.0, w * 0.025)
	match cur().get("deco", ""):
		"bubbles":
			var col := Rect2(x - w * 0.01, top - w * 0.04, w * 1.02, w * 0.13)
			var cp := _rr(col, w * 0.065)
			_grad_poly(ci, cp, [[0.0, Color("#ffc0b0")], [1.0, Color("#e2665a")]], col.position.y, col.end.y)
			ci.draw_polyline(_closed(cp), Color(0.55, 0.18, 0.16, 0.55), thin, true)
			for k in 5:
				ci.draw_circle(Vector2(x + w * (0.12 + k * 0.19), top + w * 0.025), w * 0.022, Color(1, 0.94, 0.9, 0.85))
			var sc := Vector2(x + w * 0.5, top - w * 0.02 + w * 0.08)
			var sh := PackedVector2Array([sc])
			for k in 7:
				var a := PI * (1.1 + k * 0.8 / 6.0)
				sh.append(sc + Vector2(cos(a), sin(a)) * w * 0.16 * (1.0 if k % 2 == 0 else 1.08))
			_shape(ci, sh, Color("#fff1e2"), Color("#d9826e"), max(1.0, w * 0.022))
			for k in range(1, 5):
				var a := PI * (1.1 + k * 0.8 / 5.0)
				ci.draw_line(sc, sc + Vector2(cos(a), sin(a)) * w * 0.13, Color("#d9826e"), max(1.0, w * 0.02), true)
			for b in [Vector4(1.1, 0.45, 0.07, 0), Vector4(1.18, 0.25, 0.045, 1), Vector4(1.1, 0.1, 0.03, 2)]:
				ci.draw_arc(Vector2(x + w * b.x + sin(t * 2.0 + b.w) * w * 0.02, top + w * b.y), w * b.z, 0, TAU, 14, Color(1, 1, 1, 0.8), thin, true)
			var weed := PackedVector2Array([Vector2(x + w * 0.9, bot + w * 0.02)])
			_quad(weed[0], Vector2(x + w * 1.08 + sin(t * 1.6 + ph) * w * 0.05, bot - w * 0.2), Vector2(x + w * 0.98, bot - w * 0.4), weed, 8)
			ci.draw_polyline(weed, Color("#2ea36a"), max(1.5, w * 0.05), true)
			_shape(ci, _star(Vector2(x + w * 0.06, bot - w * 0.02), w * 0.14, w * 0.06), Color("#ff9f43"), Color("#c8651c"), max(1.0, w * 0.02))
		"clay":
			var rim := Rect2(x + w * 0.06, top - w * 0.03, w * 0.88, w * 0.12)
			var rp := _rr(rim, w * 0.05)
			_grad_poly(ci, rp, [[0.0, Color("#f2a27b")], [1.0, Color("#b9562f")]], rim.position.y, rim.end.y)
			ci.draw_polyline(_closed(rp), Color(0.43, 0.16, 0.06, 0.6), thin, true)
			for k in 6:
				ci.draw_circle(Vector2(x + w * (0.17 + k * 0.133), top + w * 0.03), w * 0.02, Color("#fff3dc"))
			for k in 3:
				var yy := top + w * (0.13 + k * 0.05)
				ci.draw_line(Vector2(x + w * 0.15, yy + w * 0.03), Vector2(x + w * 0.85, yy), Color("#caa06a"), max(1.2, w * 0.035), true)
			_daisy(ci, Vector2(x + w * 0.84, top + w * 0.17), w * 0.13, Color.WHITE, Color("#ffc93b"))
			var vine := PackedVector2Array()
			var p0 := Vector2(x + w * 0.86, bot - w * 0.1)
			var p3 := Vector2(x + w * 0.82, top + r.size.y * 0.3)
			var c1 := Vector2(x + w * 0.7, bot - r.size.y * 0.3)
			var c2 := Vector2(x + w * 0.95, top + r.size.y * 0.5)
			for k in 17:
				var u := k / 16.0
				vine.append(p0.bezier_interpolate(c1, c2, p3, u))
			ci.draw_polyline(vine, Color(0.31, 0.63, 0.24, 0.75), thin, true)
			for f in [Vector2(0.75, -2.4), Vector2(0.55, -0.6), Vector2(0.38, -2.5)]:
				_leaf(ci, Vector2(x + w * 0.84, top + r.size.y * f.x), w * 0.16, f.y, Color(0.43, 0.75, 0.31, 0.85))
			var foot := Rect2(x + w * 0.1, bot - w * 0.05, w * 0.8, w * 0.12)
			var fp := _rr(foot, w * 0.05)
			_grad_poly(ci, fp, [[0.0, Color("#e88a5e")], [1.0, Color("#9c4524")]], foot.position.y, foot.end.y)
			ci.draw_polyline(_closed(fp), Color(0.43, 0.16, 0.06, 0.6), max(1.0, w * 0.02), true)
			for k in 5:
				ci.draw_circle(Vector2(x + w * (0.22 + k * 0.14), bot + w * 0.01), w * 0.018, Color("#fff3dc"))
		"lantern":
			var dark := Color(0.24, 0.15, 0.04, 0.85)
			var lw: float = max(1.0, w * 0.022)
			for sx in [-0.05, 0.95]:
				_bar(ci, Rect2(x + w * sx, top + w * 0.2, w * 0.1, r.size.y - w * 0.26), w * 0.04, BRASS, dark, lw)
				for fy in [0.3, 0.55, 0.8]:
					ci.draw_circle(Vector2(x + w * (sx + 0.05), top + r.size.y * fy), w * 0.025, Color("#5a4012"))
			_bar(ci, Rect2(x - w * 0.08, top + w * 0.1, w * 1.16, w * 0.12), w * 0.05, BRASS, dark, lw)
			_bar(ci, Rect2(x - w * 0.1, bot - w * 0.1, w * 1.2, w * 0.15), w * 0.05, BRASS, dark, lw)
			for fx in [-0.04, 0.86]:
				ci.draw_rect(Rect2(x + w * fx, bot + w * 0.04, w * 0.18, w * 0.07), Color("#6b4c16"))
			var bail := PackedVector2Array()
			for k in 17:
				bail.append(Vector2(x - w * 0.02, top + w * 0.16).bezier_interpolate(Vector2(x - w * 0.02, top - w * 0.5), Vector2(x + w * 1.02, top - w * 0.5), Vector2(x + w * 1.02, top + w * 0.16), k / 16.0))
			ci.draw_polyline(bail, Color("#d9b865"), max(1.5, w * 0.055), true)
			var ivy := PackedVector2Array()
			for k in 17:
				ivy.append(Vector2(x, bot - w * 0.1).bezier_interpolate(Vector2(x - w * 0.12, bot - r.size.y * 0.25), Vector2(x + w * 0.1, top + r.size.y * 0.55), Vector2(x - w * 0.03, top + r.size.y * 0.4), k / 16.0))
			ci.draw_polyline(ivy, Color("#3f8a2e"), thin, true)
			for f in [Vector2(0.78, 3.6), Vector2(0.62, -0.4), Vector2(0.47, 3.3)]:
				_leaf(ci, Vector2(x - w * 0.02, top + r.size.y * f.x), w * 0.17, f.y, Color("#5cb23f"))
			Art.glow(ci, Vector2(x + w * 0.5, bot - w * 0.05), w * 0.6, Color("#ffd36a"), 0.16)
		"twine":
			# twine wrapped twice around the neck, and a little paper tag hanging from it
			for k in 2:
				ci.draw_polyline(_arc(Vector2(x + w * 0.5, top + w * (0.05 + k * 0.045)), w * 0.41, w * 0.06, 0.05, PI - 0.05, 16), Color("#c9a36a"), max(1.2, w * 0.035), true)
			var tp := Vector2(x + w * 0.88, top + w * 0.1)
			var rot := 0.15 + sin(t * 1.4 + ph) * 0.08
			var hang := tp + Vector2(w * 0.1, w * 0.2)
			ci.draw_line(tp, hang, Color("#c9a36a"), max(1.0, w * 0.03), true)
			var tag := _rr(Rect2(-w * 0.11, 0, w * 0.22, w * 0.27), w * 0.03)
			var tg := PackedVector2Array()
			for q in tag:
				tg.append(hang + q.rotated(rot))
			_shape(ci, tg, Color("#f6ecd0"), Color(0.47, 0.35, 0.16, 0.6), max(1.0, w * 0.02))
			ci.draw_circle(hang + Vector2(0, w * 0.035).rotated(rot), w * 0.02, Color(0.47, 0.35, 0.16, 0.7))
			ci.draw_colored_polygon(_star(hang + Vector2(0, w * 0.15).rotated(rot), w * 0.07, w * 0.03), Color("#ffc93b"))
		"stripes":
			var ic := PackedVector2Array([Vector2(x - w * 0.02, top - w * 0.04), Vector2(x + w * 1.02, top - w * 0.04), Vector2(x + w * 1.02, top + w * 0.1)])
			var drips := [0.1, 0.22, 0.12, 0.28, 0.14, 0.1]
			for k in range(5, -1, -1):
				var dx := x + w * k / 5.0
				var dy: float = top + w * (0.1 + drips[k])
				_quad(ic[ic.size() - 1], Vector2(dx + w * 0.1, top + w * 0.1), Vector2(dx + w * 0.025, dy), ic, 4)
				for j in 7:
					var a := PI * j / 6.0
					ic.append(Vector2(dx, dy) + Vector2(cos(a), sin(a)) * w * 0.025)
			ci.draw_colored_polygon(ic, Color("#ff8fc0"))
			ci.draw_colored_polygon(_rr(Rect2(x + w * 0.05, top - w * 0.03, w * 0.9, w * 0.03), w * 0.015), Color(1, 1, 1, 0.55))
			for s in [[0.15, 0.03, "#7dff6b"], [0.35, 0.06, "#5cf2ff"], [0.55, 0.02, "#ffd93b"], [0.75, 0.05, "#ffffff"], [0.9, 0.02, "#b98cff"]]:
				var c := Vector2(x + w * s[0], top + w * s[1])
				var d := Vector2(cos(s[0] * 9.0), sin(s[0] * 9.0)) * w * 0.045
				ci.draw_line(c - d, c + d, Color(s[2]), w * 0.03, true)
			for sd in [-1.0, 1.0]:
				var ex := x - w * 0.02 if sd < 0 else x + w * 1.02
				var ey := top + w * 0.03
				var wr := PackedVector2Array([Vector2(ex, ey), Vector2(ex + sd * w * 0.2, ey - w * 0.13)])
				for k in 3:
					var y0 := ey - w * 0.13 + k * w * 0.1
					_quad(Vector2(ex + sd * w * 0.2, y0), Vector2(ex + sd * w * 0.3, y0 + w * 0.05), Vector2(ex + sd * w * 0.2, y0 + w * 0.1), wr, 4)
				wr.append(Vector2(ex, ey + w * 0.04))
				ci.draw_colored_polygon(wr, Color("#ffd93b") if sd < 0 else Color("#5cf2ff"))
				ci.draw_line(Vector2(ex + sd * w * 0.03, ey), Vector2(ex + sd * w * 0.16, ey - w * 0.06), Color(1, 1, 1, 0.7), max(1.0, w * 0.02), true)
				ci.draw_line(Vector2(ex + sd * w * 0.03, ey + w * 0.02), Vector2(ex + sd * w * 0.16, ey + w * 0.1), Color(1, 1, 1, 0.7), max(1.0, w * 0.02), true)
		"metal":
			ci.draw_polyline(_ring(r, 0.0, PI), Color(0.86, 0.76, 1.0, 0.85), max(2.0, w * 0.07), true)
			ci.draw_polyline(_ring(r, 0.3, 1.2), Color(1, 1, 1, 0.6), max(1.0, w * 0.02), true)
			_bar(ci, Rect2(x - w * 0.04, top - w * 0.03, w * 1.08, w * 0.12), w * 0.05, STEEL)
			for k in [0.15, 0.5, 0.85]:
				ci.draw_circle(Vector2(x + w * k, top + w * 0.03), w * 0.02, Color("#2c3147"))
			ci.draw_line(Vector2(x + w * 0.85, top - w * 0.03), Vector2(x + w * 0.98, top - w * 0.3), Color("#9aa4c4"), max(1.0, w * 0.03), true)
			var on := sin(t * 4.0 + ph) > 0.0
			Art.glow(ci, Vector2(x + w * 0.98, top - w * 0.32), w * 0.2, Color("#ff5c8a") if on else Color("#5cf2ff"), 0.5)
			ci.draw_circle(Vector2(x + w * 0.98, top - w * 0.32), w * 0.045, Color("#ff8fb0") if on else Color("#aaf8ff"))
			for sd in [-1.0, 1.0]:
				var fx := x + w * 0.06 if sd < 0 else x + w * 0.94
				ci.draw_colored_polygon(PackedVector2Array([Vector2(fx, bot - w * 0.5), Vector2(fx + sd * w * 0.2, bot - w * 0.05), Vector2(fx + sd * w * 0.2, bot + w * 0.06), Vector2(fx, bot - w * 0.08)]), Color("#6a5aa8"))
			_bar(ci, Rect2(x + w * 0.08, bot - w * 0.06, w * 0.84, w * 0.12), w * 0.04, STEEL)
			Art.glow(ci, Vector2(x + w * 0.5, bot + w * 0.1), w * 0.45, Color("#5cf2ff"), 0.35 + 0.1 * sin(t * 6.0 + ph))

## The shelf the jars stand on, in the world's style. Returns false for the night world (the wooden shelf).
static func shelf(ci: CanvasItem, sh: Rect2) -> bool:
	var T := cur()
	if not T.has("shelf"):
		return false
	var x := sh.position.x
	var y := sh.position.y
	var w := sh.size.x
	var h: float = max(sh.size.y * 1.7, 12.0)
	var t := _t()
	var rng := RandomNumberGenerator.new()
	rng.seed = int(y) + 3
	ci.draw_colored_polygon(_ell(Vector2(x + w / 2, y + h * 1.35), w * 0.5, h * 0.45), Color(0, 0, 0, 0.22))
	match T.name:
		"reef":   # a coral rock ledge with sand on top
			var p := PackedVector2Array([Vector2(x, y + h * 0.2)])
			var xx := x
			while xx <= x + w:
				p.append(Vector2(xx, y + sin(xx * 0.13 + 1) * 1.2 + sin(xx * 0.37 + 2) * 0.6))
				xx += 6.0
			p.append(Vector2(x + w, y + h * 0.5))
			xx = x + w
			while xx >= x:
				p.append(Vector2(xx, y + h + absf(sin(xx * 0.09)) * h * 0.45))
				xx -= 9.0
			_grad_poly(ci, p, [[0.0, Color("#f6b9a3")], [1.0, Color("#b9645a")]], y, y + h * 1.4)
			ci.draw_polyline(_closed(p), Color(0.47, 0.18, 0.16, 0.5), 1.2, true)
			for k in int(w / 16):
				ci.draw_colored_polygon(_ell(Vector2(x + rng.randf() * w, y + h * (0.45 + rng.randf() * 0.5)), 1.5 + rng.randf() * 2, 1 + rng.randf() * 1.5, 0.0, 10), Color(0.47, 0.16, 0.16, 0.35))
			ci.draw_rect(Rect2(x + 2, y - 0.5, w - 4, 4), Color("#f8e2ab"))
			for k in int(w / 40):
				ci.draw_colored_polygon(_arc(Vector2(x + 8 + rng.randf() * (w - 16), y + h * (0.5 + rng.randf() * 0.4)), 2.2, 2.2, PI, TAU, 6), Color("#fff4ec"))
		"sunpetal":   # a wooden garden plank with moss and little flowers
			var pr := _rr(Rect2(x, y + 2, w, h - 2), 3)
			_grad_poly(ci, pr, [[0.0, Color("#c48850")], [1.0, Color("#7a4a26")]], y, y + h)
			ci.draw_polyline(_closed(pr), Color(0.27, 0.14, 0.05, 0.6), 1.2, true)
			for k in 3:
				var yy := y + h * (0.45 + k * 0.17)
				var g := PackedVector2Array([Vector2(x + 6 + rng.randf() * 20, yy)])
				_quad(g[0], Vector2(x + w / 2, yy + (rng.randf() - 0.5) * 3), Vector2(x + w - 6 - rng.randf() * 20, yy), g, 10)
				ci.draw_polyline(g, Color(0.27, 0.14, 0.05, 0.35), 1.0, true)
			for nx in [x + 6, x + w - 6]:
				ci.draw_circle(Vector2(nx, y + h * 0.6), 1.6, Color("#4a2c12"))
			var moss := PackedVector2Array([Vector2(x + 2, y + 5)])
			var mx := x + 2
			while mx <= x + w - 2:
				moss.append(Vector2(mx, y + 1 - absf(sin(mx * 0.21)) * 2.5))
				mx += 5.0
			moss.append(Vector2(x + w - 2, y + 5))
			ci.draw_colored_polygon(moss, Color("#79bf55"))
			for k in int(w / 22):
				ci.draw_circle(Vector2(x + 6 + rng.randf() * (w - 12), y + 1 + rng.randf() * 2), 1.6, [Color.WHITE, Color("#ff8fc8"), Color("#ffd93b")][k % 3])
		"grove":   # a mossy log with a glowing mushroom
			var lr := _rr(Rect2(x, y + 1, w, h), h / 2)
			_grad_poly(ci, lr, [[0.0, Color("#7a5532")], [0.5, Color("#5a3c20")], [1.0, Color("#38240f")]], y, y + h)
			for k in int(w / 12):
				var bx := x + h / 2 + rng.randf() * (w - h)
				ci.draw_line(Vector2(bx, y + h * 0.3), Vector2(bx + 4, y + h * 0.8), Color(0.12, 0.07, 0.02, 0.55), 1.0, true)
			for ex in [x + h * 0.45, x + w - h * 0.45]:
				ci.draw_colored_polygon(_ell(Vector2(ex, y + 1 + h / 2), h * 0.32, h * 0.45), Color("#c99a62"))
				ci.draw_polyline(_closed(_ell(Vector2(ex, y + 1 + h / 2), h * 0.18, h * 0.26)), Color(0.43, 0.27, 0.12, 0.7), 1.0, true)
			var moss := PackedVector2Array([Vector2(x + h / 2, y + 4)])
			var mx := x + h / 2
			while mx <= x + w - h / 2:
				moss.append(Vector2(mx, y + 1 - absf(sin(mx * 0.17 + 1)) * 2.5))
				mx += 5.0
			moss.append(Vector2(x + w - h / 2, y + 5))
			ci.draw_colored_polygon(moss, Color("#4f9a3a"))
			var mu := x + w * 0.85
			Art.glow(ci, Vector2(mu, y - 3), 14, Color("#7dffd0"), 0.35 + 0.1 * sin(t * 2.0))
			ci.draw_rect(Rect2(mu - 1, y - 4, 2, 5), Color("#e9f7ff"))
			ci.draw_colored_polygon(_arc(Vector2(mu, y - 4), 4, 4, PI, TAU, 8), Color("#7dffd0"))
		"candy":   # a wafer with pink frosting and sprinkles
			var wr := Rect2(x, y + 2, w, h - 1)
			ci.draw_colored_polygon(_rr(wr, 3), Color("#e8b77a"))
			var xx := x - h
			while xx < x + w + h:
				for seg in [[Vector2(xx, y), Vector2(xx + h, y + h + 2)], [Vector2(xx + h, y), Vector2(xx, y + h + 2)]]:
					var c := Geometry2D.clip_polyline_with_polygon(PackedVector2Array(seg), _rr(wr, 3))
					for part in c:
						ci.draw_polyline(part, Color(0.67, 0.41, 0.18, 0.55), 1.0, true)
				xx += 7.0
			var ic := PackedVector2Array([Vector2(x, y + 4), Vector2(x, y), Vector2(x + w, y), Vector2(x + w, y + 4)])
			var dx := x + w
			while dx > x:
				var d := 2.0 + (int(round(dx)) % 3) * 2.0
				ic.append(Vector2(dx - 3, y + 4 + d))
				ic.append(Vector2(dx - 5, y + 6 + d))
				ic.append(Vector2(dx - 7, y + 4 + d))
				ic.append(Vector2(dx - 10, y + 4))
				dx -= 10.0
			ci.draw_colored_polygon(ic, Color("#e8458a"))
			for k in int(w / 10):
				ci.draw_rect(Rect2(x + rng.randf() * w, y + 0.5 + rng.randf() * 2, 3, 1.5), Art.COLORS[k % 7])
		"space":   # a floating metal platform with lights and thrusters
			for fx in [0.2, 0.5, 0.8]:
				var fl := 6.0 + sin(t * 20.0 + fx * 9.0) * 2.0
				ci.draw_polygon(PackedVector2Array([Vector2(x + w * fx - 4, y + h), Vector2(x + w * fx + 4, y + h), Vector2(x + w * fx, y + h + fl * 2)]), PackedColorArray([Color(0.47, 0.94, 1, 0.9), Color(0.47, 0.94, 1, 0.9), Color(0.47, 0.55, 1, 0)]))
			Art.glow(ci, Vector2(x + w / 2, y + h + 6), w * 0.4, Color("#5cf2ff"), 0.2)
			_grad_poly(ci, PackedVector2Array([Vector2(x, y + 1), Vector2(x + w, y + 1), Vector2(x + w - h * 0.6, y + h), Vector2(x + h * 0.6, y + h)]), STEEL, x, x + w, false)
			ci.draw_rect(Rect2(x + 2, y + 1, w - 4, 1.5), Color(1, 1, 1, 0.75))
			for k in int(w / 26):
				var lx := x + 14 + k * 26
				var on := sin(t * 3.0 + k) > 0.0
				ci.draw_circle(Vector2(lx, y + h * 0.55), 1.8, Color("#5cf2ff") if on else Color("#ff5c8a"))
				if on:
					Art.glow(ci, Vector2(lx, y + h * 0.55), 6, Color("#5cf2ff"), 0.5)
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

# ---------- Jar World hub: the loading screen and the main menu show every world ----------
## True while the hub is drawn: the jar is the classic glass jar with the gold lid.
static var hub := false
## The colors of buttons and panels in the world being played ([background, border]), or empty for the night look.
static var ui_glass: Array = []
## When set, Art.fly draws this thing instead of the region's own ("fish", "flower", "gem", "fly", "candy", "planet").
static var force_kind := ""
const MIX := ["fish", "flower", "gem", "fly", "candy", "planet"]
const HUB_STARS := 90

static func mix_fly(ci: CanvasItem, kind: String, pos: Vector2, r: float, col: Color, flap: float, moving: bool, phase: float, now: float) -> void:
	force_kind = kind
	Art.fly(ci, pos, r, col, flap, true, moving, phase, now)
	force_kind = ""

## A twilight sky: deep blue at the top, purple, then a warm glow at the horizon.
static func hub_sky(ci: CanvasItem, W: float, H: float, t: float, horizon: float) -> void:
	var bands := [[0.0, Color("#0b0a2a")], [0.45, Color("#271b5c")], [0.75, Color("#573287")], [0.9, Color("#a9528e")], [1.0, Color("#f09a7a")]]
	for k in bands.size() - 1:
		var y0: float = horizon * bands[k][0]
		var y1: float = horizon * bands[k + 1][0]
		ci.draw_polygon(PackedVector2Array([Vector2(0, y0), Vector2(W, y0), Vector2(W, y1), Vector2(0, y1)]), PackedColorArray([bands[k][1], bands[k][1], bands[k + 1][1], bands[k + 1][1]]))
	ci.draw_rect(Rect2(0, horizon, W, H - horizon), Color("#f09a7a"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 29
	for i in HUB_STARS:
		var sx := rng.randf()
		var sy := rng.randf() * horizon * 0.8
		var ph := rng.randf() * TAU
		var sz := 1.0 + rng.randf() * 2.0
		var a := (0.2 + 0.55 * absf(sin(t * 0.6 * sz * 0.5 + ph))) * (1.0 - sy / horizon)
		ci.draw_rect(Rect2(sx * W, sy, sz, sz), Color(1, 0.98, 0.92, a))

static func hub_land(ci: CanvasItem, W: float, H: float, ground: float) -> void:
	var sz := Vector2(W, H)
	Art.hill(ci, sz, ground - H * 0.11, H * 0.03, 5.0, 1.2, Color("#4a2a72"))
	Art.hill(ci, sz, ground - H * 0.05, H * 0.025, 7.0, 3.1, Color("#331c5c"))
	Art.hill(ci, sz, ground, H * 0.012, 4.0, 0.4, Color("#1d1040"))
	ci.draw_rect(Rect2(0, ground + H * 0.012, W, H), Color("#1d1040"))

## A little glass bubble showing one world, with its thing inside.
static func world_orb(ci: CanvasItem, c: Vector2, R: float, i: int, t: float) -> void:
	var Wd: Dictionary = Art.THEMES[i]
	Art.glow(ci, c, R * 1.9, Color(Wd.glow), 0.22)
	var circle := _ell(c, R, R, 0.0, 40)
	_grad_poly(ci, circle, [[0.0, Color(Wd.sky[0])], [0.6, Color(Wd.sky[1])], [1.0, Color(Wd.sky[2])]], c.y - R, c.y + R)
	for p in Geometry2D.intersect_polygons(_ell(c + Vector2(0, R * 1.15), R * 1.3, R * 0.55, 0.0, 30), circle):
		ci.draw_colored_polygon(p, Color(Wd.hills[0]))
	mix_fly(ci, Wd.item, c - Vector2(0, R * 0.04), R * 0.5, Art.COLORS[[0, 6, 4, 0, 2, 5][i]], t * 8.0 + i, true, i * 3.0, t)
	ci.draw_arc(c, R, 0, TAU, 40, Color(1, 1, 1, 0.8), max(1.5, R * 0.08), true)
	ci.draw_arc(c, R * 0.74, PI * 1.1, PI * 1.4, 10, Color(1, 1, 1, 0.7), max(1.5, R * 0.1), true)

static func hub_orbs(ci: CanvasItem, W: float, H: float, t: float, spots: Array, R: float) -> void:
	for i in spots.size():
		world_orb(ci, Vector2(spots[i].x * W, spots[i].y * H + sin(t * 1.2 + i * 1.7) * 4.0), R, i, t)

# ---------- each world's own lid (closing a full jar, and the locked lid with a number) ----------
const CAP_KIND := {"reef": "shell", "sunpetal": "cork", "grove": "dome", "candy": "bonbon", "space": "hatch"}

static func cap_kind() -> String:
	return CAP_KIND.get(cur().name, "")

## The lid that screws onto a full jar. Returns false in the night world (the gold screw cap).
static func cap(ci: CanvasItem, r: Rect2, age: float) -> bool:
	var kind := cap_kind()
	if kind == "":
		return false
	var T := Art.cap_timeline(age)
	var w := r.size.x
	var cx := r.get_center().x
	var yb: float = r.position.y + w * 0.1 - T.lift * w
	var sq: float = T.squash
	ci.draw_set_transform(Vector2(cx, yb), 0.0, Vector2(1.0 + (1.0 - sq) * 0.5, sq))
	cap_shape(ci, kind, 0.0, 0.0, w, T.spin, T.alpha)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var gt := (age - Art.CAP_TOTAL - 0.12) / 0.42
	if gt > 0.0 and gt < 1.0:
		Art.glow(ci, Vector2(cx - w * 0.5 + gt * w, yb - w * 0.12), w * 0.35, Color.WHITE, 0.55 * sin(gt * PI))
	return true

## The locked lid, drawn around (0, 0) after the board sets its transform. Returns false in the night world.
static func lock_art(ci: CanvasItem, w: float, a: float) -> bool:
	var kind := cap_kind()
	if kind == "":
		return false
	cap_shape(ci, kind, 0.0, w * 0.14, w, 0.0, a)
	return true

static func _poly_pts(pts: PackedVector2Array, off: Vector2) -> PackedVector2Array:
	var o := PackedVector2Array()
	for p in pts:
		o.append(p + off)
	return o

static func cap_shape(ci: CanvasItem, kind: String, cx: float, yb: float, w: float, turn: float, A := 1.0) -> void:
	var ol: float = max(1.0, w * 0.022)
	var t := _t()
	match kind:
		"shell":
			var R := w * 0.5
			var h := Vector2(cx, yb + w * 0.02)
			var p := PackedVector2Array([h + Vector2(-R * 0.25, 0)])
			for k in 9:
				var a0 := PI * (1.02 + k * 0.96 / 8.0)
				var pt := h + Vector2(cos(a0) * R, sin(a0) * R * 0.9)
				if k == 0:
					p.append(pt)
				else:
					var am := PI * (1.02 + (k - 0.5) * 0.96 / 8.0)
					_quad(p[p.size() - 1], h + Vector2(cos(am) * R * 1.1, sin(am) * R), pt, p, 4)
			p.append(h + Vector2(R * 0.25, 0))
			_grad_poly(ci, p, [[0.0, _a(Color("#fff2ea"), A)], [0.6, _a(Color("#ffc2b2"), A)], [1.0, _a(Color("#ee8a80"), A)]], h.y - R, h.y)
			ci.draw_polyline(_closed(p), _a(Color("#c96a5e"), A), ol, true)
			for k in range(1, 8):
				var a1 := PI * (1.02 + k * 0.96 / 8.0)
				ci.draw_line(h, h + Vector2(cos(a1) * R * 0.95, sin(a1) * R * 0.85), Color(0.78, 0.39, 0.35, 0.55 * A), max(1.0, w * 0.018), true)
			ci.draw_colored_polygon(_rr(Rect2(h.x - R * 0.3, h.y - w * 0.03, R * 0.6, w * 0.07), w * 0.03), _a(Color("#e9877b"), A))
			var pearl := h + Vector2(0, -R * 0.92)
			Art.glow(ci, pearl, w * 0.2, Color.WHITE, 0.5 * A)
			ci.draw_circle(pearl, w * 0.065, _a(Color("#ece6f8"), A))
			ci.draw_circle(pearl + Vector2(-w * 0.02, -w * 0.02), w * 0.025, Color(1, 1, 1, A))
		"cork":
			var hh := w * 0.28
			var tw := w * 0.86
			var bw := w * 0.7
			var top := yb - hh
			var body := PackedVector2Array([Vector2(cx - bw / 2, yb), Vector2(cx - tw / 2, top + w * 0.03), Vector2(cx + tw / 2, top + w * 0.03), Vector2(cx + bw / 2, yb)])
			_grad_poly(ci, body, [[0.0, _a(Color("#a8703c"), A)], [0.4, _a(Color("#e8b77a"), A)], [1.0, _a(Color("#9a6534"), A)]], cx - tw / 2, cx + tw / 2, false)
			ci.draw_polyline(_closed(body), Color(0.35, 0.2, 0.08, 0.7 * A), ol, true)
			var rr := RandomNumberGenerator.new()
			rr.seed = 7
			for k in 14:
				ci.draw_rect(Rect2(cx - bw / 2 + rr.randf() * bw, top + w * 0.06 + rr.randf() * hh * 0.8, w * 0.025, w * 0.02), Color(0.43, 0.25, 0.1, 0.45 * A))
			var lidtop := _ell(Vector2(cx, top + w * 0.03), tw / 2, w * 0.06)
			ci.draw_colored_polygon(lidtop, _a(Color("#f0c58c"), A))
			ci.draw_polyline(_closed(lidtop), Color(0.35, 0.2, 0.08, 0.6 * A), ol, true)
			_leaf(ci, Vector2(cx, top + w * 0.01), w * 0.22, -2.7, _a(Color("#5cb23f"), A))
			_leaf(ci, Vector2(cx, top + w * 0.01), w * 0.22, -0.4, _a(Color("#6fc24c"), A))
			_daisy(ci, Vector2(cx, top - w * 0.02), w * 0.13, Color(1, 1, 1, A), _a(Color("#ffc93b"), A))
		"dome":
			var bh := w * 0.11
			var top := yb - bh
			var dark := Color(0.24, 0.15, 0.04, 0.8 * A)
			var band := _rr(Rect2(cx - w * 0.5, top, w, bh), w * 0.03)
			_grad_poly(ci, band, _fade(BRASS, A), cx - w * 0.5, cx + w * 0.5, false)
			ci.draw_polyline(_closed(band), dark, ol, true)
			for k in [-0.36, -0.12, 0.12, 0.36]:
				ci.draw_circle(Vector2(cx + w * k, top + bh / 2), w * 0.022, _a(Color("#5a4012"), A))
			var dome := PackedVector2Array([Vector2(cx - w * 0.42, top)])
			_quad(Vector2(cx - w * 0.42, top), Vector2(cx - w * 0.4, top - w * 0.3), Vector2(cx, top - w * 0.32), dome, 10)
			_quad(Vector2(cx, top - w * 0.32), Vector2(cx + w * 0.4, top - w * 0.3), Vector2(cx + w * 0.42, top), dome, 10)
			_grad_poly(ci, dome, _fade(BRASS, A), cx - w * 0.42, cx + w * 0.42, false)
			ci.draw_polyline(_closed(dome), dark, ol, true)
			var hl := PackedVector2Array([Vector2(cx - w * 0.25, top - w * 0.05)])
			_quad(hl[0], Vector2(cx - w * 0.22, top - w * 0.22), Vector2(cx - w * 0.05, top - w * 0.26), hl, 8)
			ci.draw_polyline(hl, Color(1, 0.96, 0.78, 0.6 * A), max(1.0, w * 0.025), true)
			ci.draw_circle(Vector2(cx, top - w * 0.34), w * 0.055, _a(Color("#d9b865"), A))
			ci.draw_arc(Vector2(cx, top - w * 0.45), w * 0.08, 0, TAU, 16, _a(Color("#d9b865"), A), max(1.5, w * 0.035), true)
			Art.glow(ci, Vector2(cx, top - w * 0.1), w * 0.5, Color("#ffd36a"), 0.18 * A)
		"bonbon":
			var top := yb - w * 0.3
			for sd in [-1.0, 1.0]:
				var ex: float = cx + sd * w * 0.42
				var ey := yb - w * 0.12
				var wr := PackedVector2Array([Vector2(ex, ey), Vector2(ex + sd * w * 0.2, ey - w * 0.13)])
				for k in 3:
					var y0 := ey - w * 0.13 + k * w * 0.09
					_quad(Vector2(ex + sd * w * 0.2, y0), Vector2(ex + sd * w * 0.29, y0 + w * 0.045), Vector2(ex + sd * w * 0.2, y0 + w * 0.09), wr, 4)
				wr.append(Vector2(ex, ey + w * 0.02))
				ci.draw_colored_polygon(wr, _a(Color("#ffd93b") if sd < 0 else Color("#5cf2ff"), A))
			var dome := PackedVector2Array([Vector2(cx - w * 0.46, yb)])
			_quad(Vector2(cx - w * 0.46, yb), Vector2(cx - w * 0.46, top), Vector2(cx, top), dome, 10)
			_quad(Vector2(cx, top), Vector2(cx + w * 0.46, top), Vector2(cx + w * 0.46, yb), dome, 10)
			ci.draw_colored_polygon(dome, _a(Color("#ff7fb5"), A))
			for k in range(-4, 5):
				var x0 := cx + k * w * 0.16 + fmod(turn * w * 0.05, w * 0.16)
				for p in Geometry2D.intersect_polygons(PackedVector2Array([Vector2(x0, yb), Vector2(x0 + w * 0.06, yb), Vector2(x0 + w * 0.2, top), Vector2(x0 + w * 0.14, top)]), dome):
					ci.draw_colored_polygon(p, Color(1, 1, 1, 0.85 * A))
			ci.draw_polyline(_closed(dome), Color(0.67, 0.16, 0.4, 0.7 * A), ol, true)
			ci.draw_colored_polygon(_rr(Rect2(cx - w * 0.48, yb - w * 0.05, w * 0.96, w * 0.07), w * 0.03), _a(Color("#fff0f6"), A))
			var stem := PackedVector2Array([Vector2(cx, top - w * 0.02)])
			_quad(stem[0], Vector2(cx + w * 0.04, top - w * 0.14), Vector2(cx + w * 0.1, top - w * 0.17), stem, 6)
			ci.draw_polyline(stem, _a(Color("#3f8a2e"), A), max(1.0, w * 0.03), true)
			ci.draw_circle(Vector2(cx, top - w * 0.02), w * 0.085, _a(Color("#e8283c"), A))
			ci.draw_circle(Vector2(cx - w * 0.03, top - w * 0.05), w * 0.022, Color(1, 1, 1, 0.8 * A))
		"hatch":
			var bh := w * 0.11
			var top := yb - bh
			_grad_poly(ci, _rr(Rect2(cx - w * 0.5, top, w, bh), w * 0.04), _fade(STEEL, A), cx - w * 0.5, cx + w * 0.5, false)
			for k in 6:
				var a2 := turn + k * 1.047
				if sin(a2) > 0.0:
					ci.draw_circle(Vector2(cx + cos(a2) * w * 0.44, top + bh / 2), w * 0.02, _a(Color("#2c3147"), A))
			var dome := _arc(Vector2(cx, top), w * 0.4, w * 0.3, PI, TAU, 24)
			_grad_poly(ci, dome, [[0.0, Color(0.67, 0.94, 1.0, 0.85 * A)], [1.0, Color(0.35, 0.47, 0.86, 0.75 * A)]], top - w * 0.3, top)
			ci.draw_polyline(_closed(dome), Color(0.86, 0.92, 1.0, 0.9 * A), ol, true)
			ci.draw_polyline(_arc(Vector2(cx, top), w * 0.3, w * 0.22, PI * 1.2, PI * 1.45, 8), Color(1, 1, 1, 0.8 * A), max(1.0, w * 0.03), true)
			var on := sin(t * 4.0) > 0.0
			Art.glow(ci, Vector2(cx, top - w * 0.32), w * 0.2, Color("#5cf2ff") if on else Color("#ff5c8a"), 0.6 * A)
			ci.draw_circle(Vector2(cx, top - w * 0.32), w * 0.045, _a(Color("#bff9ff") if on else Color("#ff9fbf"), A))

static func _fade(stops: Array, A: float) -> Array:
	var o := []
	for s in stops:
		o.append([s[0], _a(s[1], A)])
	return o

## Sparks in the world's style: bubbles, petals, gem glints, sprinkles, little stars. False in the night world.
static func particle(ci: CanvasItem, p: Vector2, col: Color, s0: float, a: float, rot: float) -> bool:
	var kind := cap_kind()
	if kind == "":
		return false
	var s := s0 * 1.6
	match kind:
		"shell":
			ci.draw_arc(p, s, 0, TAU, 12, Color(1, 1, 1, 0.9 * a), max(1.0, s * 0.3), true)
			ci.draw_circle(p + Vector2(-s * 0.35, -s * 0.35), s * 0.25, Color(1, 1, 1, 0.9 * a))
		"cork":
			ci.draw_colored_polygon(_ell(p, s * 1.2, s * 0.55, rot, 12), Color(col, a))
			ci.draw_colored_polygon(_ell(p, s * 0.6, s * 0.25, rot, 10), Color(1, 1, 1, 0.5 * a))
		"dome":
			Art.glow(ci, p, s * 2.5, col, 0.5 * a)
			var d := PackedVector2Array([Vector2(0, -s), Vector2(s * 0.6, 0), Vector2(0, s), Vector2(-s * 0.6, 0)])
			ci.draw_colored_polygon(_poly_pts(_rot(d, rot * 0.3), p), Color(1, 0.98, 0.88, a))
		"bonbon":
			ci.draw_colored_polygon(_poly_pts(_rot(_rr(Rect2(-s, -s * 0.3, s * 2, s * 0.6), s * 0.3), rot), p), Color(col, a))
		"hatch":
			Art.glow(ci, p, s * 2.5, col, 0.45 * a)
			ci.draw_colored_polygon(Art._spark(p, s * 1.2, s * 0.3), Color(1, 1, 1, a))
	return true

static func _rot(pts: PackedVector2Array, a: float) -> PackedVector2Array:
	var o := PackedVector2Array()
	for q in pts:
		o.append(q.rotated(a))
	return o

# ---------- the little helpers that mend a cracked jar: one per world (the night world keeps its fireflies) ----------
static func _eyes(ci: CanvasItem, c: Vector2, s: float, f: float) -> void:
	for sx in [-1.0, 1.0]:
		ci.draw_circle(c + Vector2(sx * s * 1.1, 0), s, Color.WHITE)
		ci.draw_circle(c + Vector2(sx * s * 1.1 + f * s * 0.25, s * 0.1), s * 0.55, Color("#1a1430"))

## Returns false in the night world, so the board draws its firefly helper.
## The repair sparkles, trail and glow follow each world's helper (the night world keeps golden firefly light).
const HELPER_COL := {"reef": "#bff9ff", "sunpetal": "#ffc6e0", "grove": "#a8ffb8", "candy": "#ff9fd0", "space": "#c4b6ff"}
static func helper_col() -> Color:
	return Color(HELPER_COL.get(cur().name, "#fff0a0"))
static func helper_size() -> float:
	return 1.3 if HELPER_COL.has(cur().name) else 0.8
static func helper_trail() -> float:
	return 0.3 if HELPER_COL.has(cur().name) else 1.0

static func helper(ci: CanvasItem, p: Vector2, r: float, flap: float, left: bool) -> bool:
	var n: String = cur().name
	if not n in ["reef", "sunpetal", "grove", "candy", "space"]:
		return false
	var f := -1.0 if left else 1.0
	var wy := 0.35 + 0.65 * absf(sin(flap))
	var x := p.x
	var y := p.y
	match n:
		"reef":   # a little crab
			Art.glow(ci, p, r * 3.0, Color("#bff9ff"), 0.45)
			var lc := Color("#c8402c")
			var lw: float = max(1.2, r * 0.12)
			for sx in [-1.0, 1.0]:
				for k in 3:
					var lx: float = x + sx * r * (0.35 + k * 0.18)
					var kick := sin(flap * 2.0 + k) * r * 0.12
					ci.draw_polyline(PackedVector2Array([Vector2(lx, y + r * 0.2), Vector2(lx + sx * r * 0.35, y + r * 0.45 + kick), Vector2(lx + sx * r * 0.4, y + r * 0.75 + kick)]), lc, lw, true)
			for sx in [-1.0, 1.0]:
				var cc := Vector2(x + sx * r, y - r * 0.45 + sin(flap + sx) * r * 0.1)
				ci.draw_line(Vector2(x + sx * r * 0.55, y - r * 0.05), cc + Vector2(0, r * 0.2), lc, lw, true)
				ci.draw_colored_polygon(_ell(cc, r * 0.32, r * 0.26), Color("#ff6a4d"))
				ci.draw_colored_polygon(PackedVector2Array([cc + Vector2(sx * r * 0.05, -r * 0.04), cc + Vector2(sx * r * 0.36, -r * 0.2), cc + Vector2(sx * r * 0.34, r * 0.02)]), Color("#bff9ff"))
			ci.draw_colored_polygon(_ell(p, r * 0.78, r * 0.52), Color("#ff6a4d"))
			ci.draw_colored_polygon(_ell(p + Vector2(-r * 0.2, -r * 0.2), r * 0.3, r * 0.12), Color(1, 1, 1, 0.35))
			for sx in [-1.0, 1.0]:
				ci.draw_line(Vector2(x + sx * r * 0.22, y - r * 0.4), Vector2(x + sx * r * 0.26, y - r * 0.7), lc, max(1.0, r * 0.1), true)
				ci.draw_circle(Vector2(x + sx * r * 0.26, y - r * 0.74), r * 0.14, Color.WHITE)
				ci.draw_circle(Vector2(x + sx * r * 0.26 + f * r * 0.04, y - r * 0.73), r * 0.07, Color("#1a1430"))
		"sunpetal":   # a bee
			Art.glow(ci, p, r * 3.0, Color("#ffe9a0"), 0.45)
			for sx in [-1.0, 1.0]:
				ci.draw_colored_polygon(_ell(p + Vector2(sx * r * 0.3, -r * 0.6), r * 0.32, r * 0.5 * wy, sx * 0.4), Color(1, 1, 1, 0.75))
			var body := _ell(p, r * 0.82, r * 0.58, 0.0, 30)
			ci.draw_colored_polygon(body, Color("#ffcf3b"))
			for k in [-0.15, 0.25]:
				for q in Geometry2D.intersect_polygons(PackedVector2Array([Vector2(x + f * r * k - r * 0.09, y - r), Vector2(x + f * r * k + r * 0.09, y - r), Vector2(x + f * r * k + r * 0.09, y + r), Vector2(x + f * r * k - r * 0.09, y + r)]), body):
					ci.draw_colored_polygon(q, Color("#2a1c10"))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(x - f * r * 0.8, y - r * 0.08), Vector2(x - f * r * 1.05, y), Vector2(x - f * r * 0.8, y + r * 0.08)]), Color("#2a1c10"))
			ci.draw_circle(Vector2(x + f * r * 0.45, y - r * 0.08), r * 0.14, Color.WHITE)
			ci.draw_circle(Vector2(x + f * r * 0.5, y - r * 0.06), r * 0.07, Color("#1a1430"))
			var ant := PackedVector2Array([Vector2(x + f * r * 0.55, y - r * 0.45)])
			_quad(ant[0], Vector2(x + f * r * 0.7, y - r * 0.8), Vector2(x + f * r * 0.9, y - r * 0.8), ant, 6)
			ci.draw_polyline(ant, Color("#2a1c10"), max(1.0, r * 0.07), true)
		"grove":   # a glowing forest sprite with leaf wings
			Art.glow(ci, p, r * 3.6, Color("#7dffd0"), 0.6)
			for sx in [-1.0, 1.0]:
				_leaf(ci, p + Vector2(sx * r * 0.3, -r * 0.2), r * (0.6 + 0.4 * wy), PI + 0.5 if sx < 0 else -0.5, Color(0.55, 0.9, 0.47, 0.85))
			ci.draw_circle(p, r * 0.7, Color("#d9fff0"))
			ci.draw_circle(p + Vector2(0, r * 0.15), r * 0.45, Color("#7dffd0"))
			_eyes(ci, p + Vector2(0, -r * 0.05), r * 0.1, f)
			_leaf(ci, p + Vector2(0, -r * 0.62), r * 0.5, -1.9, Color("#5cb23f"))
		"candy":   # a gumdrop with little wings
			Art.glow(ci, p, r * 3.0, Color("#ffc0de"), 0.45)
			for sx in [-1.0, 1.0]:
				ci.draw_colored_polygon(_ell(p + Vector2(sx * r * 0.75, -r * 0.35), r * 0.35, r * 0.45 * wy, sx * 0.6), Color(1, 1, 1, 0.75))
			var gd := PackedVector2Array([Vector2(x - r * 0.75, y + r * 0.5)])
			_quad(gd[0], Vector2(x - r * 0.8, y - r * 0.75), Vector2(x, y - r * 0.75), gd, 8)
			_quad(Vector2(x, y - r * 0.75), Vector2(x + r * 0.8, y - r * 0.75), Vector2(x + r * 0.75, y + r * 0.5), gd, 8)
			ci.draw_colored_polygon(gd, Color("#ff5c9a"))
			for d in [Vector2(-0.4, -0.3), Vector2(0.3, -0.45), Vector2(0.45, 0.1), Vector2(-0.2, 0.25), Vector2(0, -0.1)]:
				ci.draw_circle(p + d * r, r * 0.05, Color(1, 1, 1, 0.85))
			_eyes(ci, p + Vector2(0, r * 0.05), r * 0.11, f)
		"space":   # a tiny flying saucer
			Art.glow(ci, p, r * 3.2, Color("#5cf2ff"), 0.45)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(x - r * 0.3, y + r * 0.25), Vector2(x + r * 0.3, y + r * 0.25), Vector2(x + r * 0.6, y + r * 1.3), Vector2(x - r * 0.6, y + r * 1.3)]), Color(0.47, 0.94, 1, 0.18))
			ci.draw_colored_polygon(_arc(p + Vector2(0, -r * 0.15), r * 0.45, r * 0.45, PI, TAU, 16), Color(0.59, 0.94, 1, 0.85))
			_eyes(ci, p + Vector2(0, -r * 0.3), r * 0.09, f)
			_grad_poly(ci, _ell(p, r, r * 0.3, 0.0, 30), STEEL, x - r, x + r, false)
			for k in 5:
				var on := sin(flap * 0.8 + k) > 0.0
				ci.draw_circle(Vector2(x + (k - 2) * r * 0.38, y + r * 0.05), r * 0.07, Color("#ffd93b") if on else Color("#ff5c8a"))
	return true
