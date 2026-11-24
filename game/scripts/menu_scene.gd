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

func _draw() -> void:
	var W := size.x
	var H := size.y
	var T := _now
	Art.vgradient(self, Rect2(0, 0, W, H * 0.8), Color("#050716"), Color("#101a44"), Color("#1c2b5e"), 0.69)
	draw_rect(Rect2(0, H * 0.8, W, H * 0.2), Color("#0a1030"))
	for s in _stars:
		var a := 0.25 + 0.55 * absf(sin(T * 0.6 * s[3] * 0.5 + s[2]))
		draw_rect(Rect2(s[0] * W, s[1] * H, s[3], s[3]), Color(1, 0.98, 0.9, a))
	Art.meteors(self, _meteor_state, T, size.x, size.y * 0.7, false)
	# full moon
	var m := Vector2(W * 0.15, H * 0.36)
	var mr: float = min(W, H) * 0.05
	Art.glow(self, m, mr * 5.0, Color("#c9d8ff"), 0.22)
	draw_circle(m, mr, Color("#f4f1dc"))
	draw_circle(m + Vector2(-mr * 0.3, -mr * 0.2), mr * 0.22, Color(0.7, 0.69, 0.59, 0.35))
	draw_circle(m + Vector2(mr * 0.35, mr * 0.3), mr * 0.15, Color(0.7, 0.69, 0.59, 0.35))
	var J := hero
	var ground := J.end.y - J.size.y * 0.03
	Art.hill(self, size, ground - H * 0.14, H * 0.03, 5.0, 1.2, Color("#121c46"))
	Art.hill(self, size, ground - H * 0.06, H * 0.025, 7.0, 3.1, Color("#0c1434"))
	Art.glow(self, Vector2(J.get_center().x, J.position.y + J.size.y * 0.55), J.size.x * 1.9, Color("#ffcf4a"), 0.22 + 0.04 * sin(T * 2.0))
	Art.hill(self, size, ground, H * 0.012, 4.0, 0.4, Color("#070b22"))
	draw_rect(Rect2(0, ground + H * 0.012, W, H), Color("#070b22"))
	for i in 70:
		var x := (i / 70.0) * W + (i % 3) * 4
		var y := ground + sin(x / W * 4.0 + 0.4) * H * 0.012 + 2.0
		var sway := sin(T * 1.3 + i) * 3.0
		draw_polyline(PackedVector2Array([Vector2(x, y), Vector2(x + sway * 0.5, y - 10), Vector2(x + sway, y - 18 - (i % 4) * 4)]), Color("#0b1230"), 3.0)
	# the jar: a mason jar with its gold lid propped open on the rim
	var R := J.size.x * 0.11
	_hero_back(J, T, ground)
	for f in _in_jar:
		var p := Vector2(J.get_center().x + sin(T * f.sp + f.a) * J.size.x * 0.3, J.position.y + J.size.y * 0.6 + sin(T * f.sp * 1.4 + f.b) * J.size.y * 0.26)
		f.flap += 0.25
		Art.fly(self, p, R, Art.COLORS[f.c], f.flap, true, true, f.a * 10.0, T)
	_hero_front(J, T)
	for f in _out:
		var e := fmod(f.t + T * 0.045, 1.0)
		var x: float = J.get_center().x + sin(e * 6.0 + f.seed) * W * 0.45 * min(1.0, e * 2.2) + sin(T * 1.7 + f.seed) * 6.0
		var y: float = J.position.y + J.size.y * 0.08 - e * (J.position.y + J.size.y * 0.1 + 40.0) + cos(T * 1.3 + f.seed) * 5.0
		var alpha: float = min(1.0, min(e * 6.0, (1.0 - e) * 4.0))
		f.flap += 0.3
		modulate_fly(Vector2(x, y), R * (0.55 + 0.45 * (1.0 - e)), Art.COLORS[f.c], f.flap, f.seed * 7.0, alpha)

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
	var pts := Art.jar_points(b)
	_tex_poly(pts, _grad("glass", [[0.0, Color8(175, 210, 255, 66)], [0.18, Color8(140, 180, 240, 23)], [0.6, Color8(120, 160, 230, 13)], [0.88, Color8(150, 190, 250, 26)], [1.0, Color8(175, 210, 255, 61)]]), b)
	# warm glow of the fireflies inside, kept inside the glass
	var gr := b.size.x * 0.85
	var gc := Vector2(cx, b.position.y + b.size.y * 0.62)
	var glow_a := 0.32 + 0.05 * sin(T * 1.6)
	_tex_poly(pts, _grad("inglow", [[0.0, Color(1, 1, 1, 1)], [0.35, Color(1, 1, 1, 0.53)], [1.0, Color(1, 1, 1, 0)]], true), Rect2(gc - Vector2(gr, gr), Vector2(gr, gr) * 2.0), Color(Color("#ffcf4a"), glow_a))
	# back edge of the open mouth
	draw_polyline(_ell(Vector2(cx, b.position.y), b.size.x * 0.4, b.size.x * 0.055, PI, TAU), Color8(200, 225, 255, 89), max(1.5, b.size.x * 0.012), true)

func _hero_front(J: Rect2, T: float) -> void:
	var b := _hero_body(J)
	var x := b.position.x
	var w := b.size.x
	var top := b.position.y
	var bot := b.end.y
	var cx := x + w / 2.0
	var lw: float = max(2.5, w * 0.022)
	var pts := Art.jar_points(b)
	# thick glass bottom with a bright lens edge
	_tex_poly(pts, _grad("bottom", [[0.0, Color8(200, 230, 255, 0)], [1.0, Color8(200, 230, 255, 56)]], false, true), Rect2(x, bot - w * 0.2, w, w * 0.2))
	draw_polyline(_ell(Vector2(cx, bot - w * 0.11), w * 0.38, w * 0.05, 0.1, PI - 0.1), Color8(230, 245, 255, 89), lw * 0.7, true)
	# the wall: a bright outer line and a fainter inner line give the glass its thickness
	draw_polyline(_closed(pts), Color8(215, 235, 255, 158), lw, true)
	var inset := w * 0.035
	draw_polyline(_closed(Art.jar_points(Rect2(x + inset, top + inset * 0.3, w - inset * 2.0, b.size.y - inset * 1.3))), Color8(190, 220, 255, 46), lw * 0.6, true)
	# screw threads on the neck
	for k in 2:
		var y := top + w * (0.035 + k * 0.045)
		var th := PackedVector2Array()
		Art._quad(Vector2(x + w * 0.11, y + w * 0.012), Vector2(cx, y + w * 0.04), Vector2(x + w * 0.89, y - w * 0.004), th, 14)
		th.insert(0, Vector2(x + w * 0.11, y + w * 0.012))
		draw_polyline(th, Color8(220, 240, 255, 115), lw * 0.7, true)
	# front edge of the mouth
	draw_polyline(_ell(Vector2(cx, top), w * 0.4, w * 0.055, 0.0, PI), Color8(235, 248, 255, 179), lw * 0.9, true)
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
	var side := Rect2(-lid, -lh, lid, lh)
	_tex_poly(_rrect(side, lh * 0.22), _grad("lid", [[0.0, Color("#f5cf6a")], [0.5, Color("#d79b34")], [1.0, Color("#8f5a17")]], false, true), side)
	for k in range(1, 14):
		var lx := -lid + k * lid / 14.0
		draw_line(Vector2(lx, -lh * 0.78), Vector2(lx, -lh * 0.12), Color8(90, 50, 10, 140), max(1.0, w * 0.008), true)
	var disc := _ell(Vector2(-lid / 2.0, -lh), lid / 2.0, lh * 0.42)
	_tex_poly(disc, _grad("lidtop", [[0.0, Color("#fff0b0")], [1.0, Color("#e2a940")]], false, true), Rect2(-lid, -lh * 1.45, lid, lh * 0.85))
	draw_polyline(_closed(_ell(Vector2(-lid / 2.0, -lh), lid * 0.36, lh * 0.26)), Color8(150, 95, 25, 153), max(1.0, w * 0.01), true)
	draw_colored_polygon(_ell(Vector2(-lid * 0.68, -lh * 1.12), lid * 0.12, lh * 0.08, 0.0, TAU, -0.1, 20), Color(1, 1, 1, 0.55))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
