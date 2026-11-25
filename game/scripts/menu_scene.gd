extends Control
## The animated night scene on the main menu: a big jar of fireflies on a hill,
## with fireflies rising out of it into the sky. Same scene as the iPhone version.

var hero := Rect2(260, 420, 200, 320)   # where the jar stands, set by main.gd
var _now := 0.0
var _meteor_state := {"list": [], "next": 0.0}
var _stars: Array = []
var _in_jar: Array = []
var _out: Array = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 90:
		_stars.append([rng.randf(), rng.randf() * 0.7, rng.randf() * TAU, 1.0 + rng.randf() * 2.0])
	for i in 9:
		_in_jar.append({"c": i % 7, "a": rng.randf() * TAU, "b": rng.randf() * TAU, "sp": 0.5 + rng.randf() * 0.6, "flap": rng.randf() * 6.0})
	for i in 12:
		_out.append({"c": (i * 3) % 7, "t": float(i) / 12.0, "seed": rng.randf() * 20.0, "flap": rng.randf() * 6.0})

func _process(delta: float) -> void:
	_now += delta
	queue_redraw()

## Jar World: the menu shows every world (a bubble for each, mixed things in the jar), not just one.
const ORBS := [Vector2(0.13, 0.2), Vector2(0.88, 0.47), Vector2(0.23, 0.31), Vector2(0.75, 0.56), Vector2(0.2, 0.45), Vector2(0.27, 0.56)]

func _draw() -> void:
	var W := size.x
	var H := size.y
	var T := _now
	var J := hero
	var ground := J.end.y - J.size.y * 0.03
	Regions.hub = true
	Regions.hub_sky(self, W, H, T, ground - H * 0.05)
	Regions.hub_land(self, W, H, ground)
	Art.glow(self, Vector2(J.get_center().x, J.position.y + J.size.y * 0.55), J.size.x * 1.9, Color("#ffcf4a"), 0.2 + 0.04 * sin(T * 2.0))
	Regions.hub_orbs(self, W, H, T, ORBS, min(W * 0.055, 34.0))
	_draw_jar(W, T)
	Regions.hub = false

func _draw_jar(W: float, T: float) -> void:
	var J := hero
	var ground := J.end.y - J.size.y * 0.03
	# the jar with its lid propped open on the rim
	var R := J.size.x * 0.11
	_hero_back(J, T, ground)
	for k in _in_jar.size():
		var f: Dictionary = _in_jar[k]
		var p := Vector2(J.get_center().x + sin(T * f.sp + f.a) * J.size.x * 0.3, J.position.y + J.size.y * 0.6 + sin(T * f.sp * 1.4 + f.b) * J.size.y * 0.26)
		f.flap += 0.25
		Regions.mix_fly(self, Regions.MIX[k % 6], p, R, Art.COLORS[f.c], f.flap, true, f.a * 10.0, T)
	_hero_front(J, T)
	for k in _out.size():
		var f: Dictionary = _out[k]
		var e := fmod(f.t + T * 0.045, 1.0)
		var x: float = J.get_center().x + sin(e * 6.0 + f.seed) * W * 0.45 * min(1.0, e * 2.2) + sin(T * 1.7 + f.seed) * 6.0
		var y: float = J.position.y + J.size.y * 0.08 - e * (J.position.y + J.size.y * 0.1 + 40.0) + cos(T * 1.3 + f.seed) * 5.0
		var alpha: float = min(1.0, min(e * 6.0, (1.0 - e) * 4.0))
		f.flap += 0.3
		Regions.mix_fly(self, Regions.MIX[k % 6], Vector2(x, y), R * (0.55 + 0.45 * (1.0 - e)), Color(Art.COLORS[f.c], alpha), f.flap, true, f.seed * 7.0, _now)

func modulate_fly(p: Vector2, r: float, c: Color, flap: float, phase: float, alpha: float) -> void:
	# fade a firefly in and out by fading its color
	Art.fly(self, p, r, Color(c, alpha), flap, true, true, phase, _now)


# ---------- the menu jar (same drawing as the iPhone version) ----------

var _tex := {}

func _grad(key: String, stops: Array, radial := false, vertical := false) -> GradientTexture2D:
	if _tex.has(key):
		return _tex[key]
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(stops.map(func(s): return s[0]))
	g.colors = PackedColorArray(stops.map(func(s): return s[1]))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 128
	t.height = 128
	if radial:
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
	elif vertical:
		t.fill_from = Vector2(0, 0)
		t.fill_to = Vector2(0, 1)
	else:
		t.fill_from = Vector2(0, 0)
		t.fill_to = Vector2(1, 0)
	_tex[key] = t
	return t

## Fill a shape with a gradient laid over the rectangle r (clamped outside it).
func _tex_poly(pts: PackedVector2Array, tex: Texture2D, r: Rect2, tint := Color.WHITE) -> void:
	var uv := PackedVector2Array()
	for p in pts:
		uv.append((p - r.position) / r.size)
	draw_colored_polygon(pts, tint, uv, tex)

func _ell(c: Vector2, rx: float, ry: float, a0 := 0.0, a1 := TAU, rot := 0.0, n := 36) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var full := a1 - a0 >= TAU - 0.001
	for k in (n if full else n + 1):
		var a := a0 + (a1 - a0) * k / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
	return pts

func _rrect(r: Rect2, rad: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	rad = min(rad, r.size.x * 0.5, r.size.y * 0.5)
	var cs := [[r.end.x - rad, r.position.y + rad, -PI / 2], [r.end.x - rad, r.end.y - rad, 0.0], [r.position.x + rad, r.end.y - rad, PI / 2], [r.position.x + rad, r.position.y + rad, PI]]
	for c in cs:
		for k in 7:
			var a: float = c[2] + PI / 2 * k / 6.0
			var q := Vector2(c[0], c[1]) + Vector2(cos(a), sin(a)) * rad
			if pts.is_empty() or pts[pts.size() - 1].distance_to(q) > 0.01:
				pts.append(q)
	if pts.size() > 2 and pts[0].distance_to(pts[pts.size() - 1]) <= 0.01:
		pts.remove_at(pts.size() - 1)
	return pts

func _closed(pts: PackedVector2Array) -> PackedVector2Array:
	var out := pts.duplicate()
	out.append(pts[0])
	return out

func _hero_body(J: Rect2) -> Rect2:
	return Rect2(J.position.x, J.position.y + J.size.y * 0.1, J.size.x, J.size.y * 0.9)

func _hero_back(J: Rect2, T: float, ground: float) -> void:
	var b := _hero_body(J)
	var cx := b.get_center().x
	# shadow and warm light pooling on the ground
	draw_colored_polygon(_ell(Vector2(cx, ground + 2), b.size.x * 0.62, b.size.x * 0.09), Color(0, 0, 0.04, 0.45))
	Art.glow(self, Vector2(cx, ground), b.size.x * 1.1, Color("#ffc94a"), 0.2 + 0.03 * sin(T * 2.0))
	# the glass behind the fireflies: clearer in the middle, denser toward the edges
	var pts := Art.jar_points(b, b.size.x * 0.15)
	_tex_poly(pts, _grad("glass", [[0.0, Color8(175, 210, 255, 66)], [0.18, Color8(140, 180, 240, 23)], [0.6, Color8(120, 160, 230, 13)], [0.88, Color8(150, 190, 250, 26)], [1.0, Color8(175, 210, 255, 61)]]), b)
	# warm glow of the fireflies inside, kept inside the glass
	var gr := b.size.x * 0.85
	var gc := Vector2(cx, b.position.y + b.size.y * 0.62)
	var glow_a := 0.32 + 0.05 * sin(T * 1.6)
	_tex_poly(pts, _grad("inglow", [[0.0, Color(1, 1, 1, 1)], [0.35, Color(1, 1, 1, 0.53)], [1.0, Color(1, 1, 1, 0)]], true), Rect2(gc - Vector2(gr, gr), Vector2(gr, gr) * 2.0), Color(Color("#ffcf4a"), glow_a))
	# the open mouth: a dark oval inside the rim, and the glass thickness along its back edge
	var m := b.size.x * 0.15
	draw_colored_polygon(_ell(Vector2(cx, b.position.y), b.size.x * 0.37, m * 0.82), Color(0.02, 0.03, 0.1, 0.28))
	draw_polyline(_ell(Vector2(cx, b.position.y), b.size.x * 0.37, m * 0.82, PI, TAU), Color8(200, 225, 255, 77), max(1.5, b.size.x * 0.012), true)

func _hero_front(J: Rect2, T: float) -> void:
	var b := _hero_body(J)
	var x := b.position.x
	var w := b.size.x
	var top := b.position.y
	var bot := b.end.y
	var cx := x + w / 2.0
	var lw: float = max(2.5, w * 0.022)
	var pts := Art.jar_points(b, b.size.x * 0.15)
	# thick glass bottom with a bright lens edge
	_tex_poly(pts, _grad("bottom", [[0.0, Color8(200, 230, 255, 0)], [1.0, Color8(200, 230, 255, 56)]], false, true), Rect2(x, bot - w * 0.2, w, w * 0.2))
	draw_polyline(_ell(Vector2(cx, bot - w * 0.11), w * 0.38, w * 0.05, 0.1, PI - 0.1), Color8(230, 245, 255, 89), lw * 0.7, true)
	# the wall: a bright outer line and a fainter inner line give the glass its thickness
	draw_polyline(_closed(pts), Color8(215, 235, 255, 158), lw, true)
	var inset := w * 0.035
	draw_polyline(_closed(Art.jar_points(Rect2(x + inset, top + inset * 0.3, w - inset * 2.0, b.size.y - inset * 1.3), w * 0.13)), Color8(190, 220, 255, 46), lw * 0.6, true)
	# screw threads on the neck
	for k in 2:
		var y := top + w * (0.04 + k * 0.045)
		draw_polyline(_ell(Vector2(cx, y), w * 0.4, w * 0.135, 0.12, PI - 0.12), Color8(220, 240, 255, 115), lw * 0.7, true)
	# front edge of the mouth
	draw_polyline(_ell(Vector2(cx, top), w * 0.4, w * 0.15, 0.0, PI), Color8(235, 248, 255, 179), lw * 0.9, true)
	# highlights: a long soft streak on the left, a thin one on the right, a glint on the shoulder
	var hr := Rect2(x + w * 0.09, top + w * 0.3, w * 0.075, b.size.y - w * 0.52)
	_tex_poly(_rrect(hr, w * 0.04), _grad("streak", [[0.0, Color(1, 1, 1, 0)], [0.25, Color(1, 1, 1, 0.34)], [0.75, Color(1, 1, 1, 0.2)], [1.0, Color(1, 1, 1, 0)]], false, true), Rect2(x, top + w * 0.3, w, bot - w * 0.2 - (top + w * 0.3)))
	draw_colored_polygon(_rrect(Rect2(x + w * 0.2, top + w * 0.36, w * 0.025, b.size.y * 0.35), w * 0.015), Color(1, 1, 1, 0.16))
	draw_colored_polygon(_rrect(Rect2(x + w * 0.86, top + w * 0.42, w * 0.03, b.size.y * 0.4), w * 0.015), Color(1, 1, 1, 0.14))
	draw_arc(Vector2(x + w * 0.24, top + w * 0.3), w * 0.14, PI * 1.08, PI * 1.42, 16, Color(1, 1, 1, 0.5), lw * 0.8, true)
	Art.glow(self, Vector2(x + w * 0.8, top + w * 0.36), w * 0.07, Color("#dfe8ff"), 0.45)   # the moon caught in the glass
	# the gold lid, propped open on the rim so the fireflies can get out
	var lid := w * 0.8
	var lh := w * 0.13
	draw_set_transform(Vector2(x + w * 0.92, top + w * 0.005), 0.4 + 0.03 * sin(T * 1.3), Vector2.ONE)
	Art.glow(self, Vector2(-lid * 0.5, lh * 0.3), lid * 0.6, Color("#ffd36a"), 0.25)
	# a real round lid: its side follows the same oval as its top, like a short cylinder
	var ry := lh * 0.42
	var side_pts := PackedVector2Array([Vector2(-lid, -lh)])
	side_pts.append_array(_ell(Vector2(-lid / 2.0, 0), lid / 2.0, ry, PI, 0.0))   # bottom edge, curving down in front
	side_pts.append_array(_ell(Vector2(-lid / 2.0, -lh), lid / 2.0, ry, 0.0, PI).slice(0, -1))   # top edge (hidden under the disc)
	var side := Rect2(-lid, -lh, lid, lh + ry)
	_tex_poly(side_pts, _grad("lid", [[0.0, Color("#f5cf6a")], [0.5, Color("#d79b34")], [1.0, Color("#8f5a17")]], false, true), side)
	draw_polyline(_ell(Vector2(-lid / 2.0, 0), lid / 2.0, ry, 0.02, PI - 0.02), Color8(110, 60, 12, 153), max(1.0, w * 0.008), true)
	# ridges around the side, closer together toward the edges as they turn away
	for k in range(1, 18):
		var a := PI - k * PI / 18.0
		var lx := -lid / 2.0 + cos(a) * lid / 2.0
		var dy := sin(a) * ry
		draw_line(Vector2(lx, -lh * 0.78 + dy), Vector2(lx, -lh * 0.12 + dy), Color8(90, 50, 10, 140), max(0.6, w * 0.008 * (0.4 + 0.6 * sin(a))), true)
	var disc := _ell(Vector2(-lid / 2.0, -lh), lid / 2.0, lh * 0.42)
	_tex_poly(disc, _grad("lidtop", [[0.0, Color("#fff0b0")], [1.0, Color("#e2a940")]], false, true), Rect2(-lid, -lh * 1.45, lid, lh * 0.85))
	draw_polyline(_closed(_ell(Vector2(-lid / 2.0, -lh), lid * 0.36, lh * 0.26)), Color8(150, 95, 25, 153), max(1.0, w * 0.01), true)
	draw_colored_polygon(_ell(Vector2(-lid * 0.68, -lh * 1.12), lid * 0.12, lh * 0.08, 0.0, TAU, -0.1, 20), Color(1, 1, 1, 0.55))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
