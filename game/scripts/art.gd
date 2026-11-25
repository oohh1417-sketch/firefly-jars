class_name Art
extends RefCounted
## Shared drawing helpers: glows, hills, the crescent moon, mason jars, fireflies and icons.
## Everything is drawn with code, so there are no image files to license.

const COLORS := [
	Color("#ffd93b"), Color("#5cf2ff"), Color("#ff5c8a"), Color("#7dff6b"), Color("#b98cff"),
	Color("#ff9f43"), Color("#4d8bff"), Color("#ffffff"), Color("#ff4040"), Color("#2fe0a0"),
]

## Skins sold for coins in the shop. The first of each list is free and always owned.
## GUESS: prices, so the first skin takes about 20 levels and the last about 80.
const SKINS := {
	"jar": [["classic", "Clear glass", 0], ["frost", "Frosted glass", 200], ["honey", "Honey glass", 350], ["moon", "Moonlight glass", 500], ["rose", "Rose glass", 800]],
	"fly": [["classic", "Classic", 0], ["bug", "Little antennae", 200], ["fairy", "Fairy wings", 350], ["star", "Starlight", 500], ["royal", "Royal crown", 800]],
}
static var jar_skin := "classic"   # set by main.gd from the save
static var fly_skin := "classic"

## The outline color of a plain jar in this skin.
static func jar_line(skin := "") -> Color:
	var RT: Dictionary = THEMES[region % THEMES.size()]
	if RT.has("line") and (skin if skin != "" else jar_skin) == "classic":
		return Color(RT.line)
	match skin if skin != "" else jar_skin:
		"frost": return Color(0.93, 0.97, 1.0, 0.75)
		"honey": return Color(1.0, 0.8, 0.45, 0.7)
		"moon": return Color(0.75, 0.72, 1.0, 0.7)
		"rose": return Color(1.0, 0.7, 0.82, 0.7)
	return Color(0.84, 0.92, 1.0, 0.6)

## Jar World: one region per chapter (every 10 levels), each with its own scene, things to sort and jar.
## The night region ("meadow") is drawn in scenes.gd; the others in regions.gd. Same as the web test page.
const THEMES := [
	{"name": "reef", "stone": "#0b5470e6", "custom": true, "day": true, "item": "fish", "jar": "tube", "deco": "bubbles",
		"sky": ["#8af3ea", "#2ec7d7", "#0e86ae"], "hills": ["#f2d9a0", "#e0bf80", "#2e9e6a"], "glow": "#bff9ff",
		"cap": ["#a8574c", "#f29b8a", "#ffe6df"], "shelf": ["#e9cf94", "#b98f55", "#fff1cc"]},
	{"name": "sunpetal", "stone": "#7a3a22e6", "custom": true, "day": true, "item": "flower", "jar": "vase", "deco": "clay",
		"sky": ["#ff8f8f", "#ffb877", "#ffe3a3"], "hills": ["#a6d872", "#86c45c", "#62a843"], "glow": "#ffb347",
		"cap": ["#8c3f22", "#d9744a", "#ffc7a6"], "shelf": ["#a86b3c", "#6e4223", "#c98a55"]},
	{"name": "grove", "stone": "#1e4a2ce6", "custom": true, "item": "gem", "jar": "mason", "deco": "lantern",
		"sky": ["#2f7a4f", "#1e5b3c", "#123826"], "hills": ["#1b5233", "#2c5e2a", "#16391f"], "glow": "#7dffd0",
		"cap": ["#5a3c1c", "#c9a45a", "#f5e0a0"], "shelf": ["#5a3d22", "#3a2614", "#6fae4b"]},
	{"name": "meadow", "item": "fly", "jar": "mason", "deco": "twine", "sky": ["#040a18", "#0d2140", "#1b3d55"], "hills": ["#0f2a3a", "#0a1f2c", "#06131d"], "glow": "#ffd93b"},
	{"name": "candy", "stone": "#a33a78e6", "custom": true, "day": true, "item": "candy", "jar": "tube", "deco": "stripes", "line": "#ffffffe6",
		"sky": ["#ff8fc8", "#ffaed6", "#ffd0e8"], "hills": ["#ff7fbd", "#ffa3cf", "#fff2f8"], "glow": "#ff8fc8",
		"cap": ["#c2407a", "#ff7fb5", "#ffe0ee"], "shelf": ["#f7c9a0", "#d99a6a", "#fff0e0"]},
	{"name": "space", "stone": "#2e1a66e6", "custom": true, "item": "planet", "jar": "tube", "deco": "metal",
		"sky": ["#0c0626", "#2a1258", "#5a2a8a"], "hills": ["#3b2370", "#2a1756", "#1a0d3a"], "glow": "#c58bff",
		"cap": ["#4a5570", "#aab6d0", "#f2f6ff"], "shelf": ["#59607a", "#363b52", "#9aa4c4"]},
]
const CHAPTERS := ["Bubble Reef", "Sunpetal Meadow", "Lantern Grove", "Firefly Night", "Candy Clouds", "Starlight Space"]
## The region being drawn right now (index into THEMES), set by main.gd.
static var region := 0

static func chapter_of(level: int) -> Dictionary:
	var i := (level - 1) / 10
	var name: String = TranslationServer.translate(CHAPTERS[i % CHAPTERS.size()])
	if i >= CHAPTERS.size():
		name += " %d" % (i / CHAPTERS.size() + 1)
	return {"num": i + 1, "name": name, "done": (level - 1) % 10, "theme": i % THEMES.size()}

## Soft round glow, drawn from one shared radial-gradient texture tinted to the color.
static var _glow_tex: GradientTexture2D

static func glow(ci: CanvasItem, pos: Vector2, rad: float, col: Color, alpha: float) -> void:
	if alpha <= 0.0 or rad <= 0.0:
		return
	if _glow_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.35, Color(1, 1, 1, 0.53))
		_glow_tex = GradientTexture2D.new()
		_glow_tex.gradient = g
		_glow_tex.fill = GradientTexture2D.FILL_RADIAL
		_glow_tex.fill_from = Vector2(0.5, 0.5)
		_glow_tex.fill_to = Vector2(1.0, 0.5)
		_glow_tex.width = 128
		_glow_tex.height = 128
	ci.draw_texture_rect(_glow_tex, Rect2(pos - Vector2(rad, rad), Vector2(rad, rad) * 2.0), false, Color(col.r, col.g, col.b, min(1.0, alpha)))

## Vertical three-stop gradient filling a rectangle.
static func vgradient(ci: CanvasItem, rect: Rect2, c0: Color, c1: Color, c2: Color, mid := 0.6) -> void:
	var ym := rect.position.y + rect.size.y * mid
	var a := rect.position
	var b := Vector2(rect.end.x, rect.position.y)
	var c := Vector2(rect.end.x, ym)
	var d := Vector2(rect.position.x, ym)
	ci.draw_polygon(PackedVector2Array([a, b, c, d]), PackedColorArray([c0, c0, c1, c1]))
	var e := Vector2(rect.end.x, rect.end.y)
	var f := Vector2(rect.position.x, rect.end.y)
	ci.draw_polygon(PackedVector2Array([d, c, e, f]), PackedColorArray([c1, c1, c2, c2]))

static func hill(ci: CanvasItem, size: Vector2, base_y: float, amp: float, freq: float, phase: float, col: Color) -> void:
	var pts := PackedVector2Array()
	pts.append(Vector2(0, size.y))
	var x := 0.0
	while x <= size.x + 12.0:
		pts.append(Vector2(x, base_y + sin(x / size.x * freq + phase) * amp + sin(x / size.x * freq * 2.3 + phase * 1.7) * amp * 0.4))
		x += 12.0
	pts.append(Vector2(size.x, size.y))
	ci.draw_colored_polygon(pts, col)

static func crescent(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	# outer circle minus an offset inner circle, built as one polygon
	var off := Vector2(r * 0.45, -r * 0.2)
	var r2 := r * 0.9
	var pts := PackedVector2Array()
	for k in 48:
		var a := TAU * k / 48.0
		var p := c + Vector2(cos(a), sin(a)) * r
		if p.distance_to(c + off) > r2:
			pts.append(p)
	# order the outer points by angle around the side away from the cut
	var base_ang := (-off).angle()
	var outer := Array(pts)
	outer.sort_custom(func(p, q): return wrapf((p - c).angle() - base_ang, -PI, PI) < wrapf((q - c).angle() - base_ang, -PI, PI))
	var inner := []
	for k in 48:
		var a := TAU * k / 48.0
		var p := c + off + Vector2(cos(a), sin(a)) * r2
		if p.distance_to(c) < r:
			inner.append(p)
	var in_ang := (-off).angle()
	inner.sort_custom(func(p, q): return wrapf((p - c - off).angle() - in_ang, -PI, PI) > wrapf((q - c - off).angle() - in_ang, -PI, PI))
	var poly := PackedVector2Array(outer + inner)
	if poly.size() >= 3:
		ci.draw_colored_polygon(poly, col)

static func pine(ci: CanvasItem, x: float, base: float, h: float, col: Color) -> void:
	ci.draw_rect(Rect2(x - h * 0.03, base - h * 0.15, h * 0.06, h * 0.15), col)
	for k in 4:
		var y := base - h * 0.12 - k * h * 0.21
		var w := h * (0.32 - k * 0.06)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x - w, y), Vector2(x, y - h * 0.32), Vector2(x + w, y)]), col)

static func _quad(p0: Vector2, p1: Vector2, p2: Vector2, out: PackedVector2Array, steps := 6) -> void:
	for k in range(1, steps + 1):
		var t := float(k) / steps
		out.append(p0.lerp(p1, t).lerp(p1.lerp(p2, t), t))

## Outline of a mason jar: screw-thread neck, rounded shoulders, rounded bottom.
## mouth > 0 closes the top with the back half of an oval, so the opening looks round instead of flat.
static func jar_points(r: Rect2, mouth := 0.0) -> PackedVector2Array:
	var rp := Regions.jar_points(r, mouth)
	if not rp.is_empty():
		return rp
	var x := r.position.x
	var w := r.size.x
	var top := r.position.y
	var sh := top + w * 0.3
	var bot := r.end.y
	var br := w * 0.36
	var nx := w * 0.1
	var pts := PackedVector2Array()
	pts.append(Vector2(x + nx, top))
	pts.append(Vector2(x + nx, top + w * 0.12))
	_quad(Vector2(x + nx, top + w * 0.12), Vector2(x, top + w * 0.14), Vector2(x, sh), pts)
	pts.append(Vector2(x, bot - br))
	_quad(Vector2(x, bot - br), Vector2(x, bot), Vector2(x + br, bot), pts)
	pts.append(Vector2(x + w - br, bot))
	_quad(Vector2(x + w - br, bot), Vector2(x + w, bot), Vector2(x + w, bot - br), pts)
	pts.append(Vector2(x + w, sh))
	_quad(Vector2(x + w, sh), Vector2(x + w, top + w * 0.14), Vector2(x + w - nx, top + w * 0.12), pts)
	pts.append(Vector2(x + w - nx, top))
	if mouth > 0.0:
		for k in range(1, 24):
			var a := -PI * k / 24.0
			pts.append(Vector2(x + w / 2.0 + cos(a) * (w / 2.0 - nx), top + sin(a) * mouth))
	return pts

## Glass behind the fireflies: light at the edges, clearer in the middle.
static func jar_back(ci: CanvasItem, r: Rect2, tint = null, skin := "") -> void:
	var pts := jar_points(r)
	var cols := PackedColorArray()
	for p in pts:
		var edge: float = absf((p.x - r.get_center().x) / (r.size.x * 0.5))
		cols.append(Color(0.67, 0.8, 1.0, lerpf(0.06, 0.2, edge)))
	ci.draw_polygon(pts, cols)
	var glass = {"frost": Color(0.92, 0.96, 1.0, 0.13), "honey": Color(1.0, 0.7, 0.28, 0.14), "moon": Color(0.5, 0.42, 1.0, 0.14), "rose": Color(1.0, 0.45, 0.7, 0.13)}.get(skin if skin != "" else jar_skin)
	if glass != null:
		ci.draw_colored_polygon(pts, glass)
	if tint != null:
		ci.draw_colored_polygon(pts, tint)
	ci.draw_set_transform(Vector2(r.get_center().x, r.end.y - r.size.x * 0.09), 0.0, Vector2(1.0, 0.18))
	ci.draw_circle(Vector2.ZERO, r.size.x * 0.4, Color(0.82, 0.92, 1.0, 0.13))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	Regions.back(ci, r)

## Glass in front of the fireflies: outline, shine and screw threads.
static func jar_front(ci: CanvasItem, r: Rect2, line: Color, width: float, skin := "") -> void:
	Regions.deco(ci, r)
	var pts := jar_points(r)
	pts.append(pts[0])
	ci.draw_polyline(pts, line, width, true)
	var w := r.size.x
	_jar_deco(ci, r, skin if skin != "" else jar_skin)
	ci.draw_rect(Rect2(r.position.x + w * 0.12, r.position.y + w * 0.42, w * 0.12, r.size.y * 0.55), Color(1, 1, 1, 0.16))
	ci.draw_rect(Rect2(r.position.x + w * 0.8, r.position.y + w * 0.5, w * 0.05, r.size.y * 0.3), Color(1, 1, 1, 0.1))
	for k in ([0.03, 0.08] if Regions.cur().get("jar", "mason") == "mason" and not Regions.cur().has("deco") else []):
		ci.draw_line(Vector2(r.position.x + w * 0.1, r.position.y + w * k), Vector2(r.position.x + w * 0.9, r.position.y + w * (k + 0.015)), Color(0.84, 0.92, 1.0, 0.5), max(1.5, width * 0.6))

## The small painted extras of each jar skin, on the glass in front of the fireflies.
static func _jar_deco(ci: CanvasItem, r: Rect2, skin: String) -> void:
	var w := r.size.x
	var x := r.position.x
	var bot := r.end.y
	match skin:
		"frost":
			# a frosty drift along the bottom and a few snowflakes
			var d := PackedVector2Array([Vector2(x + w * 0.16, bot - w * 0.02)])
			for k in 13:
				var t := k / 12.0
				d.append(Vector2(x + w * (0.06 + 0.88 * t), bot - w * (0.12 + 0.05 * sin(t * 9.0))))
			d.append(Vector2(x + w * 0.84, bot - w * 0.02))
			ci.draw_colored_polygon(d, Color(0.95, 0.98, 1.0, 0.22))
			for f in [Vector2(0.74, 0.55), Vector2(0.3, 0.78), Vector2(0.68, 1.25)]:
				var c := Vector2(x + w * f.x, r.position.y + w * f.y)
				for k in 3:
					var a := PI * k / 3.0
					ci.draw_line(c - Vector2(cos(a), sin(a)) * w * 0.06, c + Vector2(cos(a), sin(a)) * w * 0.06, Color(1, 1, 1, 0.55), max(1.0, w * 0.018), true)
		"honey":
			# golden threads and a drop of honey running down from the neck
			for k in [0.03, 0.08]:
				ci.draw_line(Vector2(x + w * 0.1, r.position.y + w * k), Vector2(x + w * 0.9, r.position.y + w * (k + 0.015)), Color(1.0, 0.82, 0.4, 0.8), max(1.5, w * 0.025))
			var dx := x + w * 0.72
			var top := r.position.y + w * 0.16
			ci.draw_line(Vector2(dx, top), Vector2(dx, top + w * 0.3), Color(1.0, 0.72, 0.2, 0.6), max(2.0, w * 0.05), true)
			ci.draw_circle(Vector2(dx, top + w * 0.33), w * 0.05, Color(1.0, 0.72, 0.2, 0.65))
			for hx in [Vector2(0.3, 0.88), Vector2(0.42, 0.95)]:
				var hc := Vector2(x + w * hx.x, bot - w * hx.y * 0.5)
				var hp := PackedVector2Array()
				for k in 7:
					hp.append(hc + Vector2(cos(PI / 3.0 * k), sin(PI / 3.0 * k)) * w * 0.06)
				ci.draw_polyline(hp, Color(1.0, 0.82, 0.4, 0.45), max(1.0, w * 0.015), true)
		"moon":
			# a little painted moon and stars
			var mc := Vector2(x + w * 0.72, r.position.y + w * 0.62)
			ci.draw_circle(mc, w * 0.1, Color(1.0, 0.95, 0.75, 0.7))
			ci.draw_circle(mc + Vector2(w * 0.045, -w * 0.03), w * 0.085, Color(0.3, 0.26, 0.6, 0.85))
			for st in [Vector2(0.3, 0.75), Vector2(0.62, 1.05), Vector2(0.36, 1.35), Vector2(0.75, 1.55)]:
				ci.draw_colored_polygon(star_points(Vector2(x + w * st.x, r.position.y + w * st.y), w * 0.05, w * 0.02), Color(1.0, 0.95, 0.75, 0.6))
		"rose":
			# three small painted hearts
			for h in [Vector2(0.28, 0.16), Vector2(0.72, 0.24), Vector2(0.5, 0.42)]:
				ci.draw_colored_polygon(heart_points(Vector2(x + w * h.x, bot - w * h.y), w * 0.14), Color(1.0, 0.55, 0.75, 0.5))

static func shelf(ci: CanvasItem, sh: Rect2) -> void:
	if Regions.shelf(ci, sh):
		return
	ci.draw_set_transform(Vector2(sh.get_center().x, sh.end.y + sh.size.y * 0.7), 0.0, Vector2(1.0, 0.12))
	ci.draw_circle(Vector2.ZERO, sh.size.x * 0.5, Color(0, 0, 0, 0.35))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	vgradient(ci, sh, Color("#7a5532"), Color("#61432a"), Color("#4a301b"), 0.5)
	ci.draw_rect(Rect2(sh.position.x + 3, sh.position.y, sh.size.x - 6, max(3.0, sh.size.y * 0.18)), Color("#9a7045"))
	for k in range(1, 4):
		var x := sh.position.x + sh.size.x * k / 4.0
		ci.draw_line(Vector2(x - 30, sh.position.y + sh.size.y * 0.55), Vector2(x + 28, sh.position.y + sh.size.y * 0.6), Color(0.16, 0.09, 0.04, 0.3), 1.5)
	glow(ci, Vector2(sh.get_center().x, sh.position.y), sh.size.x * 0.5, Color("#ffcf4a"), 0.1)

## The firefly: round glowing body with little wings. Asleep: dim, wings folded, eyes closed.
static func fly(ci: CanvasItem, pos: Vector2, r: float, col: Color, flap: float, awake: bool, moving: bool, phase: float, now: float, skin := "") -> void:
	if Regions.item(ci, pos, r, col, flap, awake, phase, now):
		if awake and (skin if skin != "" else fly_skin) != "fairy":
			fly_extra(ci, pos, r, col, now, phase, skin if skin != "" else fly_skin)
		return
	if not awake:
		for side in [-1.0, 1.0]:
			ci.draw_set_transform(pos + Vector2(side * r * 0.5, -r * 0.5), side * 0.5, Vector2(1.0, 0.55))
			ci.draw_circle(Vector2.ZERO, r * 0.3, Color(0.63, 0.69, 0.82, 0.3))
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		ci.draw_circle(pos, r * 0.74, Color(col, 0.45))
		for sx in [-1.0, 1.0]:
			ci.draw_arc(pos + Vector2(sx * r * 0.26, -r * 0.05), r * 0.14, 0.2, 2.94, 8, Color(0.04, 0.05, 0.12, 0.8), max(1.0, r * 0.1))
		return
	var flicker := 0.75 + 0.25 * sin(now / 0.2 + phase * 1.3)
	glow(ci, pos, r * (3.2 if moving else 2.8), col, 0.5 * flicker * col.a)
	var wy := 0.35 + 0.65 * absf(sin(flap))
	if (skin if skin != "" else fly_skin) == "fairy":
		# butterfly wings in the firefly's own color: a big upper pair and a small lower pair
		var wc := Color(col.lightened(0.35), 0.55 * col.a)
		for side in [-1.0, 1.0]:
			ci.draw_set_transform(pos + Vector2(side * r * 0.72, -r * 0.55), side * 0.7, Vector2(1.0, wy))
			ci.draw_circle(Vector2.ZERO, r * 0.55, wc)
			ci.draw_circle(Vector2.ZERO, r * 0.25, Color(1, 1, 1, 0.35 * col.a))
			ci.draw_set_transform(pos + Vector2(side * r * 0.62, r * 0.12), side * -0.5, Vector2(1.0, wy))
			ci.draw_circle(Vector2.ZERO, r * 0.32, wc)
	else:
		for side in [-1.0, 1.0]:
			ci.draw_set_transform(pos + Vector2(side * r * 0.62, -r * 0.5), side * 0.5, Vector2(1.0, wy))
			ci.draw_circle(Vector2.ZERO, r * 0.42, Color(0.9, 0.94, 1.0, 0.45 * col.a))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	ci.draw_circle(pos, r * 0.74, col)
	ci.draw_circle(pos + Vector2(-r * 0.22, -r * 0.25), r * 0.2, Color(1, 1, 1, 0.8 * col.a))
	fly_extra(ci, pos, r, col, now, phase, skin if skin != "" else fly_skin)

## The extra look of each firefly skin, drawn over the body. The body color never changes,
## so the puzzle colors stay easy to tell apart.
static func fly_extra(ci: CanvasItem, pos: Vector2, r: float, col: Color, now: float, phase: float, skin: String) -> void:
	var a := col.a
	match skin:
		"bug":
			for sx in [-1.0, 1.0]:
				var p0 := pos + Vector2(sx * r * 0.22, -r * 0.62)
				var p2 := pos + Vector2(sx * r * 0.55, -r * 1.2)
				var pts := PackedVector2Array([p0])
				_quad(p0, pos + Vector2(sx * r * 0.18, -r * 1.05), p2, pts, 8)
				ci.draw_polyline(pts, Color(0.1, 0.12, 0.25, 0.85 * a), max(1.0, r * 0.09), true)
				ci.draw_circle(p2, r * 0.13, Color(col.lightened(0.45), a))
		"star":
			var tw := 0.55 + 0.45 * sin(now * 3.0 + phase)
			var c := pos + Vector2(-r * 0.2, -r * 0.24)
			ci.draw_colored_polygon(_spark(c, r * 0.36, r * 0.07), Color(1, 1, 1, 0.95 * a))
			var sp := pos + Vector2(r * 0.95, -r * 0.7)
			ci.draw_colored_polygon(_spark(sp, r * 0.3 * tw, r * 0.06 * tw), Color(1, 1, 0.9, 0.85 * a * tw))
		"royal":
			var b := pos.y - r * 0.6
			var cw := r * 0.42
			var pts := PackedVector2Array([Vector2(pos.x - cw, b), Vector2(pos.x - cw, b - r * 0.3), Vector2(pos.x - cw * 0.5, b - r * 0.12),
				Vector2(pos.x, b - r * 0.42), Vector2(pos.x + cw * 0.5, b - r * 0.12), Vector2(pos.x + cw, b - r * 0.3), Vector2(pos.x + cw, b)])
			ci.draw_colored_polygon(pts, Color(Color("#ffc83c"), a))
			pts.append(pts[0])
			ci.draw_polyline(pts, Color(0.55, 0.33, 0.05, 0.9 * a), max(1.0, r * 0.06), true)
			ci.draw_circle(Vector2(pos.x, b - r * 0.42), r * 0.07, Color(Color("#fff3b0"), a))
			ci.draw_circle(Vector2(pos.x, b - r * 0.1), r * 0.06, Color(Color("#ff5c8a"), a))

## A four-pointed twinkle.
static func _spark(c: Vector2, ro: float, ri: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in 8:
		var ang := PI / 4.0 * k - PI / 2.0
		pts.append(c + Vector2(cos(ang), sin(ang)) * (ro if k % 2 == 0 else ri))
	return pts

## Simple line icons for the buttons, so no emoji font is needed on the phone.
static func icon(ci: CanvasItem, name: String, c: Vector2, s: float, col: Color) -> void:
	var w: float = max(2.0, s * 0.11)
	match name:
		"home":
			ci.draw_polyline(PackedVector2Array([c + Vector2(-s * .45, -s * .02), c + Vector2(0, -s * .42), c + Vector2(s * .45, -s * .02)]), col, w, true)
			ci.draw_polyline(PackedVector2Array([c + Vector2(-s * .32, -s * .1), c + Vector2(-s * .32, s * .38), c + Vector2(s * .32, s * .38), c + Vector2(s * .32, -s * .1)]), col, w, true)
		"restart":
			ci.draw_arc(c, s * .34, -PI * 0.35, PI * 1.45, 24, col, w, true)
			var tip := c + Vector2(cos(-PI * 0.35), sin(-PI * 0.35)) * s * .34
			ci.draw_colored_polygon(PackedVector2Array([tip + Vector2(-s * .02, -s * .2), tip + Vector2(s * .2, s * .02), tip + Vector2(-s * .16, s * .1)]), col)
		"undo":
			ci.draw_arc(c + Vector2(s * .05, s * .08), s * .3, -PI * 1.0, PI * 0.35, 20, col, w, true)
			var t2 := c + Vector2(s * .05 - s * .3, s * .08)
			ci.draw_colored_polygon(PackedVector2Array([t2 + Vector2(-s * .16, -s * .02), t2 + Vector2(s * .16, -s * .02), t2 + Vector2(0, s * .18)]), col)
		"sound_on", "sound_off":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * .42, -s * .14), c + Vector2(-s * .22, -s * .14), c + Vector2(0, -s * .36), c + Vector2(0, s * .36), c + Vector2(-s * .22, s * .14), c + Vector2(-s * .42, s * .14)]), col)
			if name == "sound_on":
				ci.draw_arc(c + Vector2(s * .02, 0), s * .2, -0.9, 0.9, 10, col, w, true)
				ci.draw_arc(c + Vector2(s * .02, 0), s * .36, -0.9, 0.9, 12, col, w, true)
			else:
				ci.draw_line(c + Vector2(s * .17, -s * .1), c + Vector2(s * .38, s * .1), col, w, true)
				ci.draw_line(c + Vector2(s * .17, s * .1), c + Vector2(s * .38, -s * .1), col, w, true)
		"music", "music_off":
			# two eighth notes joined by a beam, same as the iPhone version
			var u := s / 24.0
			ci.draw_polyline(PackedVector2Array([c + Vector2(-3, 6) * u, c + Vector2(-3, -6) * u, c + Vector2(7, -8) * u, c + Vector2(7, 4) * u]), col, w, true)
			ci.draw_circle(c + Vector2(-5.5, 6) * u, 2.5 * u, col)
			ci.draw_circle(c + Vector2(4.5, 4) * u, 2.5 * u, col)
			if name == "music_off":
				ci.draw_line(c + Vector2(-9, -9) * u, c + Vector2(9, 9) * u, col, w, true)
		"bell":
			var pts := PackedVector2Array([c + Vector2(-s * .34, s * .2), c + Vector2(-s * .26, s * .06), c + Vector2(-s * .26, -s * .12)])
			_quad(c + Vector2(-s * .26, -s * .12), c + Vector2(-s * .24, -s * .38), c + Vector2(0, -s * .38), pts)
			_quad(c + Vector2(0, -s * .38), c + Vector2(s * .24, -s * .38), c + Vector2(s * .26, -s * .12), pts)
			pts.append(c + Vector2(s * .26, s * .06))
			pts.append(c + Vector2(s * .34, s * .2))
			ci.draw_colored_polygon(pts, col)
			ci.draw_circle(c + Vector2(0, s * .3), s * .08, col)
		"bulb":
			ci.draw_circle(c + Vector2(0, -s * .08), s * .27, col)
			ci.draw_rect(Rect2(c + Vector2(-s * .13, s * .14), Vector2(s * .26, s * .2)), col)
			ci.draw_line(c + Vector2(-s * .1, s * .4), c + Vector2(s * .1, s * .4), col, w)
		"gear":
			ci.draw_arc(c, s * .25, 0.0, TAU, 32, col, w, true)
			ci.draw_arc(c, s * .1, 0.0, TAU, 20, col, w, true)
			for k in 8:
				var a := TAU * k / 8.0
				ci.draw_line(c + Vector2(cos(a), sin(a)) * s * .25, c + Vector2(cos(a), sin(a)) * s * .4, col, w * 1.2, true)
		"sun":
			ci.draw_circle(c, s * .2, col)
			for k in 8:
				var a := TAU * k / 8.0
				ci.draw_line(c + Vector2(cos(a), sin(a)) * s * .3, c + Vector2(cos(a), sin(a)) * s * .44, col, w, true)
		"heart":
			ci.draw_colored_polygon(heart_points(c + Vector2(0, s * .04), s * .9), Color("#ff4d6d") if col.a > 0.5 else col)
			ci.draw_polyline(PackedVector2Array([c + Vector2(-s * .3, -s * .14), c + Vector2(-s * .22, -s * .26)]), Color(1, 0.82, 0.86, 0.9), max(1.5, w * 0.7), true)
		"gift":
			ci.draw_rect(Rect2(c + Vector2(-s * .36, -s * .06), Vector2(s * .72, s * .46)), Color("#b98cff"))
			ci.draw_rect(Rect2(c + Vector2(-s * .42, -s * .2), Vector2(s * .84, s * .18)), Color("#d2b3ff"))
			ci.draw_rect(Rect2(c + Vector2(-s * .06, -s * .2), Vector2(s * .12, s * .6)), Color("#ffd93b"))
			for sx in [-1.0, 1.0]:
				ci.draw_circle(c + Vector2(sx * s * .13, -s * .3), s * .1, Color("#ffd93b"))
		"noads":
			var bx := StyleBoxFlat.new()
			bx.bg_color = Color("#2a3470")
			bx.border_color = Color("#9fb4ff")
			bx.set_border_width_all(int(max(2.0, s * 0.05)))
			bx.set_corner_radius_all(int(s * 0.12))
			ci.draw_style_box(bx, Rect2(c + Vector2(-s * .42, -s * .26), Vector2(s * .84, s * .52)))
			# "AD" in simple strokes
			var aw := s * .1
			ci.draw_polyline(PackedVector2Array([c + Vector2(-s * .26, s * .14), c + Vector2(-s * .15, -s * .14), c + Vector2(-s * .04, s * .14)]), Color.WHITE, aw * 0.6, true)
			ci.draw_line(c + Vector2(-s * .21, s * .03), c + Vector2(-s * .09, s * .03), Color.WHITE, aw * 0.5)
			ci.draw_line(c + Vector2(s * .06, -s * .14), c + Vector2(s * .06, s * .14), Color.WHITE, aw * 0.6)
			ci.draw_arc(c + Vector2(s * .1, 0), s * .14, -PI * 0.5, PI * 0.5, 12, Color.WHITE, aw * 0.6, true)
			ci.draw_line(c + Vector2(-s * .4, s * .4), c + Vector2(s * .4, -s * .4), Color("#ff4d6d"), max(3.0, s * 0.1))
		"skins":   # a little jar with a pink firefly and a gold sparkle
			var jr := Rect2(c + Vector2(-s * .3, -s * .34), Vector2(s * .6, s * .74))
			jar_back(ci, jr, Color(0.6, 0.8, 1.0, 0.15), "classic")
			ci.draw_circle(c + Vector2(0, s * .14), s * .16, Color("#ff5c8a"))
			ci.draw_circle(c + Vector2(-s * .05, s * .09), s * .05, Color(1, 1, 1, 0.8))
			var jp := jar_points(jr)
			jp.append(jp[0])
			ci.draw_polyline(jp, Color(0.84, 0.92, 1.0, 0.9), max(2.0, s * 0.05), true)
			ci.draw_colored_polygon(_spark(c + Vector2(s * .34, -s * .3), s * .2, s * .05), Color("#ffd93b"))
		"check":
			ci.draw_polyline(PackedVector2Array([c + Vector2(-s * .3, 0), c + Vector2(-s * .08, s * .24), c + Vector2(s * .34, -s * .26)]), col, w * 1.4, true)
		"flame":
			var fp := PackedVector2Array([c + Vector2(0, s * .4)])
			_quad(c + Vector2(0, s * .4), c + Vector2(-s * .38, s * .3), c + Vector2(-s * .22, -s * .1), fp)
			_quad(c + Vector2(-s * .22, -s * .1), c + Vector2(-s * .1, -s * .2), c + Vector2(0, -s * .42), fp)
			_quad(c + Vector2(0, -s * .42), c + Vector2(s * .34, -s * .1), c + Vector2(s * .26, s * .2), fp)
			_quad(c + Vector2(s * .26, s * .2), c + Vector2(s * .2, s * .38), c + Vector2(0, s * .4), fp)
			ci.draw_colored_polygon(fp, col)
		"coin":   # always gold, whatever col is
			ci.draw_circle(c, s * .46, Color("#b36b0c"))
			ci.draw_circle(c, s * .4, Color("#ffc23d"))
			ci.draw_arc(c, s * .29, 0, TAU, 28, Color(1, 0.94, 0.63, 0.9), max(1.5, s * .06), true)
			ci.draw_colored_polygon(star_points(c, s * .2, s * .09), Color("#fff6c8"))
		"trophy":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * .26, -s * .36), c + Vector2(s * .26, -s * .36), c + Vector2(s * .22, -s * .08), c + Vector2(0, s * .1), c + Vector2(-s * .22, -s * .08)]), col)
			ci.draw_arc(c + Vector2(-s * .26, -s * .2), s * .12, PI * 0.5, PI * 1.5, 10, col, w, true)
			ci.draw_arc(c + Vector2(s * .26, -s * .2), s * .12, -PI * 0.5, PI * 0.5, 10, col, w, true)
			ci.draw_line(c + Vector2(0, s * .1), c + Vector2(0, s * .26), col, w, true)
			ci.draw_rect(Rect2(c + Vector2(-s * .2, s * .26), Vector2(s * .4, s * .12)), col)
		"play":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * .2, -s * .3), c + Vector2(s * .32, 0), c + Vector2(-s * .2, s * .3)]), col)

## A heart shape, w wide, centered on c.
static func heart_points(c: Vector2, w: float) -> PackedVector2Array:
	var h := w * 0.9
	var pts := PackedVector2Array([c + Vector2(0, h * .42)])
	for half in [-1.0, 1.0]:
		var a := c + Vector2(0, h * .42) if half < 0 else c + Vector2(0, -h * .22)
		var b := c + Vector2(0, -h * .22) if half < 0 else c + Vector2(0, h * .42)
		var c1 := c + Vector2(-w * .62, -h * .05) if half < 0 else c + Vector2(w * .38, -h * .55)
		var c2 := c + Vector2(-w * .38, -h * .55) if half < 0 else c + Vector2(w * .62, -h * .05)
		for k in range(1, 13):
			pts.append(a.bezier_interpolate(c1, c2, b, k / 12.0))
	pts.remove_at(pts.size() - 1)
	return pts

static func star_points(c: Vector2, ro: float, ri: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in 10:
		var a := -PI * 0.5 + k * PI / 5.0
		pts.append(c + Vector2(cos(a), sin(a)) * (ro if k % 2 == 0 else ri))
	return pts

## A golden mason-jar lid that drops onto the neck and screws itself tight. Same as the iPhone version.
const CAP_DROP := 0.22
const CAP_TURN := 0.9
const CAP_TURNS := 3
const CAP_TOTAL := CAP_DROP + CAP_TURN

## Height above the seat (in jar widths), spin angle, click squash and fade-in for a lid of this age.
static func cap_timeline(age: float) -> Dictionary:
	if age < CAP_DROP:
		var t := age / CAP_DROP
		return {"lift": 0.09 + (1.0 - t * t), "spin": 0.0, "squash": 1.0, "alpha": min(1.0, t * 3.0)}
	if age < CAP_TOTAL:
		var p := (age - CAP_DROP) / CAP_TURN
		var ease := 2.0 * p * p if p < 0.5 else 1.0 - pow(-2.0 * p + 2.0, 2.0) / 2.0
		var turns := ease * CAP_TURNS
		var whole := floorf(turns)
		var stepped: float = (whole + min(1.0, (turns - whole) * 1.6)) / CAP_TURNS
		return {"lift": 0.09 * (1.0 - stepped), "spin": turns * TAU, "squash": 1.0, "alpha": 1.0}
	var tc := (age - CAP_TOTAL) / 0.16
	return {"lift": 0.0, "spin": CAP_TURNS * TAU, "squash": 1.0 - sin(tc * PI) * 0.14 if tc < 1.0 else 1.0, "alpha": 1.0}


static func cap(ci: CanvasItem, r: Rect2, age: float) -> void:
	if Regions.cap(ci, r, age):
		return
	var w := r.size.x
	var CC := Regions.cap_cols()
	var T := cap_timeline(age)
	var a: float = T.alpha
	var cx := r.get_center().x
	var cw := w * 0.9
	var x0 := cx - cw * 0.5
	var bh: float = w * 0.2 * T.squash
	var top: float = r.position.y - w * 0.04 - T.lift * w + (w * 0.2 - bh)
	# a round lid seen a little from above: its top is an oval and the band curves along it
	var bend := w * 0.055
	var half := cw * 0.5
	var dy := func(x: float) -> float:
		var t := clampf((x - cx) / half, -1.0, 1.0)
		return bend * sqrt(1.0 - t * t)
	# the flat top of the lid
	ci.draw_colored_polygon(_oval(Vector2(cx, top), half, bend, 0.0, TAU, 40).slice(0, -1), Color(CC[0], a))
	ci.draw_colored_polygon(_oval(Vector2(cx, top + bend * 0.12), half * 0.86, bend * 0.78, 0.0, TAU, 40).slice(0, -1), Color(CC[1], a))
	# metal cylinder shading: dark at the sides, bright just left of center
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.18, 0.4, 0.62, 1.0])
	grad.colors = PackedColorArray([CC[2], CC[3], CC[4], CC[5], CC[6]])
	var cols := 32
	for k in cols:
		var xa := x0 + cw * k / cols
		var xb := x0 + cw * (k + 1) / cols
		var ya: float = top + dy.call(xa)
		var yb: float = top + dy.call(xb)
		var ca := Color(grad.sample(float(k) / cols), a)
		var cb := Color(grad.sample(float(k + 1) / cols), a)
		ci.draw_polygon(PackedVector2Array([Vector2(xa, ya), Vector2(xb, yb), Vector2(xb, yb + bh), Vector2(xa, ya + bh)]), PackedColorArray([ca, cb, cb, ca]))
	# ridges around the band travel across the front as it turns, bunching up at the sides
	var spin: float = T.spin
	for k in 18:
		var ang := k / 18.0 * TAU + spin
		var front := sin(ang)
		if front <= 0.0:
			continue
		var x := cx + cos(ang) * cw * 0.5
		x = clampf(x, x0 + w * 0.03, x0 + cw - w * 0.03)
		var ry: float = top + dy.call(x)
		ci.draw_line(Vector2(x, ry + bh * 0.28), Vector2(x, ry + bh * 0.94), Color(0.31, 0.19, 0.05, (0.15 + 0.35 * front) * a), max(1.0, w * 0.022 * front))
		ci.draw_line(Vector2(x + w * 0.014, ry + bh * 0.3), Vector2(x + w * 0.014, ry + bh * 0.92), Color(1, 0.94, 0.75, 0.25 * front * a), max(1.0, w * 0.01 * front))
	# one bright mark so the turning is easy to follow
	var ma := spin + 1.2
	var mf := sin(ma)
	if mf > 0.0:
		var mx: float = clampf(cx + cos(ma) * cw * 0.5, x0 + w * 0.05, x0 + cw - w * 0.05)
		ci.draw_rect(Rect2(mx - w * 0.03 * mf, top + dy.call(mx) + bh * 0.3, w * 0.06 * mf, bh * 0.6), Color(1, 1, 1, 0.55 * mf * a))
	# shine sweeping across once it clicks shut
	var gt := (age - CAP_TOTAL - 0.12) / 0.42
	if gt > 0.0 and gt < 1.0:
		var gx := x0 + gt * cw
		var hw := w * 0.12
		var l: float = max(x0 + w * 0.02, gx - hw)
		var rr: float = min(x0 + cw - w * 0.02, gx + hw)
		var c0 := Color(1, 1, 1, 0)
		var c1 := Color(1, 1, 1, 0.75)
		if gx > l:
			ci.draw_polygon(PackedVector2Array([Vector2(l, top + dy.call(l)), Vector2(gx, top + dy.call(gx)), Vector2(gx, top + dy.call(gx) + bh), Vector2(l, top + dy.call(l) + bh)]), PackedColorArray([c0, c1, c1, c0]))
		if rr > gx:
			ci.draw_polygon(PackedVector2Array([Vector2(gx, top + dy.call(gx)), Vector2(rr, top + dy.call(rr)), Vector2(rr, top + dy.call(rr) + bh), Vector2(gx, top + dy.call(gx) + bh)]), PackedColorArray([c1, c0, c0, c1]))
	# rolled top edge and outline, both following the round shape
	ci.draw_polyline(_oval(Vector2(cx, top + bh * 0.08), half * 0.97, bend, 0.08, PI - 0.08, 24), Color(CC[7], a), max(2.0, bh * 0.18), true)
	var ol := _oval(Vector2(cx, top), half, bend, PI, TAU, 20)
	ol.append_array(_oval(Vector2(cx, top + bh), half, bend, 0.0, PI, 24))
	ol.append(ol[0])
	ci.draw_polyline(ol, Color(0.27, 0.16, 0.04, 0.55 * a), max(1.0, w * 0.015), true)


## Points along an oval from angle a0 to a1 (y grows downward, so 0..PI is the lower half).
static func _oval(c: Vector2, rx: float, ry: float, a0: float, a1: float, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in n + 1:
		var ang := a0 + (a1 - a0) * k / n
		pts.append(c + Vector2(cos(ang) * rx, sin(ang) * ry))
	return pts

# ---------------- tutorial hand ----------------

## A cartoon pointing hand; the fingertip is at `tip`. `s` is its size, `press` 0..1 animates a tap.
static func hand(ci: CanvasItem, tip: Vector2, s: float, press: float, alpha: float) -> void:
	if press > 0.6:
		ci.draw_arc(tip, s * (0.5 - press * 0.3), 0.0, TAU, 40, Color(1.0, 0.93, 0.59, (press - 0.6) * 2.0 * alpha), 3.0, true)
	glow(ci, tip, s * 0.45, Color("#fff3b0"), 0.5 * alpha)
	ci.draw_set_transform(tip, -0.42, Vector2(s / 100.0, s / 100.0))
	var ink := Color(0.17, 0.13, 0.31, alpha)
	var white := Color(1.0, 0.98, 0.94, alpha)
	for pass_i in 2:
		var grow := 4.5 if pass_i == 0 else 0.0
		var col := ink if pass_i == 0 else white
		ci.draw_colored_polygon(_hand_rrect(Rect2(-11, 0, 22, 66).grow(grow), 11.0 + grow), col)    # pointing finger
		ci.draw_colored_polygon(_hand_rrect(Rect2(-16, 44, 64, 60).grow(grow), 16.0 + grow), col)   # palm
		for f in [Vector2(10, 50), Vector2(27, 53), Vector2(43, 58)]:                              # folded fingers
			ci.draw_colored_polygon(_hand_ellipse(f, Vector2(9, 11) + Vector2(grow, grow), 0.0), col)
		ci.draw_colored_polygon(_hand_ellipse(Vector2(-17, 74), Vector2(10, 18) + Vector2(grow, grow), -0.5), col)   # thumb
	var line := Color(0.17, 0.13, 0.31, 0.35 * alpha)
	ci.draw_polyline(PackedVector2Array([Vector2(-6, 9), Vector2(0, 6), Vector2(6, 9)]), line, 2.5, true)   # fingernail
	ci.draw_line(Vector2(-2, 96), Vector2(36, 96), line, 2.5, true)                                          # cuff
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

static func _hand_rrect(r: Rect2, rad: float) -> PackedVector2Array:
	rad = minf(rad, minf(r.size.x, r.size.y) * 0.5)
	var pts := PackedVector2Array()
	var corners := [r.position + Vector2(r.size.x - rad, rad), r.end - Vector2(rad, rad), Vector2(r.position.x + rad, r.end.y - rad), r.position + Vector2(rad, rad)]
	for k in 4:
		for j in 7:
			var a := -PI / 2.0 + (k + j / 6.0) * PI / 2.0
			pts.append(corners[k] + Vector2(cos(a), sin(a)) * rad)
	return pts

static func _hand_ellipse(c: Vector2, rr: Vector2, rot: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in 24:
		var a := k * TAU / 24.0
		pts.append(c + Vector2(cos(a) * rr.x, sin(a) * rr.y).rotated(rot))
	return pts

# ---------------- color-blind symbols ----------------

## Color-blind mode: every color also has its own shape, drawn in dark ink.
## yellow dot, sky blue triangle, pink square, green plus, violet diamond, orange cross, blue ring, white bars, red chevron, mint line
static func symbol(ci: CanvasItem, p: Vector2, s: float, c: int) -> void:
	var ink := Color(0.04, 0.05, 0.12, 0.82)
	var w := maxf(1.4, s * 0.38)
	match c % 10:
		0: ci.draw_circle(p, s * 0.62, ink)
		1: ci.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -s), p + Vector2(s * 0.95, s * 0.7), p + Vector2(-s * 0.95, s * 0.7)]), ink)
		2: ci.draw_rect(Rect2(p - Vector2(s, s) * 0.72, Vector2(s, s) * 1.44), ink)
		3:
			ci.draw_line(p + Vector2(-s, 0), p + Vector2(s, 0), ink, w, true)
			ci.draw_line(p + Vector2(0, -s), p + Vector2(0, s), ink, w, true)
		4: ci.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -s), p + Vector2(s * 0.8, 0), p + Vector2(0, s), p + Vector2(-s * 0.8, 0)]), ink)
		5:
			ci.draw_line(p + Vector2(-s, -s) * 0.75, p + Vector2(s, s) * 0.75, ink, w, true)
			ci.draw_line(p + Vector2(s, -s) * 0.75, p + Vector2(-s, s) * 0.75, ink, w, true)
		6: ci.draw_arc(p, s * 0.7, 0.0, TAU, 24, ink, w, true)
		7:
			ci.draw_line(p + Vector2(-s * 0.85, -s * 0.4), p + Vector2(s * 0.85, -s * 0.4), ink, w, true)
			ci.draw_line(p + Vector2(-s * 0.85, s * 0.4), p + Vector2(s * 0.85, s * 0.4), ink, w, true)
		8: ci.draw_polyline(PackedVector2Array([p + Vector2(-s * 0.85, s * 0.45), p + Vector2(0, -s * 0.5), p + Vector2(s * 0.85, s * 0.45)]), ink, w, true)
		9: ci.draw_line(p + Vector2(0, -s), p + Vector2(0, s), ink, w, true)

## Shooting stars: a bright streak with a glowing head and a long fading tail, then a little sparkle
## where it burns out. st = {"list": [], "next": 0.0} kept by the caller. Same as the iPhone version.
static func meteors(ci: CanvasItem, st: Dictionary, t: float, W: float, H: float, often: bool) -> void:
	if st.next == 0.0:
		st.next = t + 1.2 + randf() * 1.5
	if t > st.next:
		var left := randf() < 0.5
		var n := 2 if randf() < 0.2 else 1
		for k in n:
			st.list.append({"t0": t + k * 0.3, "p": Vector2(W * (0.02 + randf() * 0.35 if left else 0.63 + randf() * 0.35), H * (0.02 + randf() * 0.1)),
				"d": Vector2((1.0 if left else -1.0) * W * (0.45 + randf() * 0.2), H * (0.05 + randf() * 0.06)), "dur": 0.9 + randf() * 0.4})
		st.next = t + (1.0 + randf() * 1.8 if often else 3.0 + randf() * 4.0)
	st.list = st.list.filter(func(m): return t - m.t0 < m.dur + 0.6)
	for m in st.list:
		var u: float = (t - m.t0) / m.dur
		if u < 0.0:
			continue
		var e := minf(1.0, u)
		var fade := 1.0 - (u - 1.0) / 0.6 if u > 1.0 else minf(1.0, u * 6.0)
		var head: Vector2 = m.p + m.d * e
		if u <= 1.0:
			var tail: Vector2 = m.p + m.d * maxf(0.0, e - 0.4)
			var pts := PackedVector2Array()
			var cols := PackedColorArray()
			for k in 11:
				pts.append(tail.lerp(head, k / 10.0))
				cols.append(Color(1, 0.97, 0.86, fade * pow(k / 10.0, 1.5)))
			ci.draw_polyline_colors(pts, cols, 5.0, true)
			glow(ci, head, 40.0, Color("#fff3c0"), 0.9 * fade)
			ci.draw_circle(head, 4.0, Color(1, 1, 0.98, fade))
		else:
			glow(ci, head, 34.0 + 46.0 * (u - 1.0), Color("#fff3c0"), 0.6 * fade)
			var r := 6.0 + 15.0 * (u - 1.0)
			var c := Color(1, 0.98, 0.86, 0.8 * fade)
			ci.draw_line(head - Vector2(r, 0), head + Vector2(r, 0), c, 2.0, true)
			ci.draw_line(head - Vector2(0, r), head + Vector2(0, r), c, 2.0, true)
