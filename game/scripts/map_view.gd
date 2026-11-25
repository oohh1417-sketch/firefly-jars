extends Control
## The chapter map: a winding firefly trail with one glowing stone per level, climbing
## through each chapter's scene (level 1 at the bottom). Opens when the player taps Play.
## Same map as the web version (web/firefly-jars.html: drawMap).

signal play_requested

const NUM_FONT := preload("res://fonts/Baloo2-ExtraBold.woff2")
const NAME_FONT := preload("res://fonts/Baloo2-Bold.woff2")

var scroll := 0.0
var _vel := 0.0
var _drag := {}
var _anim := {}
var _burst: Array = []
var _banner := {}
var _now := 0.0
var _flap := 0.0
var _flies: Array = []
var _stars := {}   # chapter -> star list

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	for i in 14:
		_flies.append({"x": rng.randf(), "y": rng.randf(), "a": rng.randf() * TAU, "b": rng.randf() * TAU, "s": 0.4 + rng.randf() * 0.6, "c": i % 7})

## Layout: each chapter is one band; stones fill its top, its sign sits at the bottom where you enter it.
func geom() -> Dictionary:
	var W := size.x
	var step := roundf(clampf(W * 0.2, 62.0, 200.0))
	var sign_h := roundf(step * 1.3)
	var band := step * 10.0 + sign_h
	var n: int = max(Art.CHAPTERS.size(), Art.chapter_of(Save.level).num + 1)
	return {"W": W, "step": step, "sign": sign_h, "band": band, "n": n, "total": band * n, "r": step * 0.27}

func band_top(G: Dictionary, i: int) -> float:
	return (G.n - 1 - i) * G.band

func stop_pos(G: Dictionary, lv: int) -> Vector2:
	var i := (lv - 1) / 10
	var j := (lv - 1) % 10
	return Vector2(G.W * (0.5 + 0.3 * sin((lv - 1) * 0.8)), band_top(G, i) + (9 - j + 0.5) * G.step)

func _clamp(G: Dictionary, y: float) -> float:
	return clampf(y, -170.0, G.total - size.y + 280.0)

func _centre(G: Dictionary, lv: int) -> float:
	return _clamp(G, stop_pos(G, lv).y - size.y * 0.55)

static func chapter_name(i: int) -> String:
	var name: String = TranslationServer.translate(Art.CHAPTERS[i % Art.CHAPTERS.size()])
	if i >= Art.CHAPTERS.size():
		name += " %d" % (i / Art.CHAPTERS.size() + 1)
	return name

func new_chapter_waiting() -> bool:
	return Art.chapter_of(Save.level).num > maxi(1, Save.map_ch)

## Called each time the map opens. Returns true when a new chapter opening is celebrated.
func open() -> bool:
	var G := geom()
	_vel = 0.0
	_anim = {}
	_burst = []
	_banner = {}
	_drag = {}
	var ch: int = Art.chapter_of(Save.level).num
	if Save.map_ch == 0:
		Save.map_ch = ch
		Save.save_game()
	if ch > Save.map_ch and Save.level > 1:
		# a chapter was just finished: start at the old chapter's last stone, then climb to the new one
		scroll = _centre(G, Save.level - 1)
		_anim = {"from": scroll, "to": _centre(G, Save.level), "t0": _now + 0.7, "dur": 1.5, "ch": ch - 1}
		Save.map_ch = ch
		Save.save_game()
		return true
	scroll = _centre(G, Save.level)
	return false

func _celebrate(i: int) -> void:
	var G := geom()
	var sy: float = band_top(G, i) + G.step * 10.0 + G.sign * 0.5
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for k in 46:
		var a := rng.randf() * TAU
		var v: float = (80.0 + rng.randf() * 220.0) * G.W / 390.0
		_burst.append({"p": Vector2(G.W * 0.5 + cos(a) * 30.0, sy), "v": Vector2(cos(a) * v, sin(a) * v - 80.0), "life": 0.0, "max": 1.0 + rng.randf() * 0.8, "c": Art.COLORS[k % 7]})
	_banner = {"ch": i, "t0": _now}
	Sound.play("unlock")
	Analytics.log_event("chapter_open", {"chapter": i + 1})

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_now += delta
	_flap += 0.3
	var G := geom()
	if not _anim.is_empty():
		var k := clampf((_now - _anim.t0) / _anim.dur, 0.0, 1.0)
		var e := 2.0 * k * k if k < 0.5 else 1.0 - pow(-2.0 * k + 2.0, 2.0) / 2.0
		scroll = lerpf(_anim.from, _anim.to, e)
		if k >= 1.0:
			var ch: int = _anim.get("ch", -1)
			_anim = {}
			if ch >= 0:
				_celebrate(ch)
	elif _drag.is_empty() and absf(_vel) > 1.0:
		scroll += _vel * delta
		_vel *= pow(0.93, delta * 60.0)
	scroll = _clamp(G, scroll)
	for b in _burst:
		b.life += delta
		b.p += b.v * delta
		b.v.y += 60.0 * delta
	_burst = _burst.filter(func(b): return b.life < b.max)
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if mb.pressed:
				_anim = {}
				_vel = 0.0
				scroll += -60.0 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else 60.0
			return
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			_drag = {"y0": mb.position.y, "x0": mb.position.x, "s0": scroll, "ly": mb.position.y, "lt": _now, "moved": 0.0}
			_vel = 0.0
			_anim = {}
		elif not _drag.is_empty():
			var d := _drag
			_drag = {}
			if _now - d.lt > 0.12:
				_vel = 0.0
			if d.moved < 14.0:
				_vel = 0.0
				var G := geom()
				var p := stop_pos(G, Save.level)
				if p.distance_to(mb.position + Vector2(0, scroll)) < G.r * 1.8:
					play_requested.emit()
		accept_event()
	elif event is InputEventMouseMotion and not _drag.is_empty():
		var mm := event as InputEventMouseMotion
		var d := _drag
		d.moved = max(d.moved, absf(mm.position.y - d.y0) + absf(mm.position.x - d.x0))
		scroll = d.s0 - (mm.position.y - d.y0)
		var dt: float = max(0.001, _now - d.lt)
		_vel = _vel * 0.5 + (-(mm.position.y - d.ly) / dt) * 0.5
		d.ly = mm.position.y
		d.lt = _now
		accept_event()

func _star_list(i: int, W: float, H: float) -> Array:
	if not _stars.has(i):
		var rng := RandomNumberGenerator.new()
		rng.seed = i * 97 + 13
		var l := []
		for k in 70:
			l.append([rng.randf() * W, rng.randf() * H * 0.7, 0.6 + rng.randf() * 1.4, 0.25 + rng.randf() * 0.5])
		_stars[i] = l
	return _stars[i]

func _draw() -> void:
	var G := geom()
	var W: float = G.W
	var H := size.y
	var t := _now
	var cur := Save.level
	var cur_ch := (cur - 1) / 10
	var k_scale := W / 390.0
	draw_rect(Rect2(Vector2.ZERO, size), Color("#050716"))
	var vis: Array = []
	for i in range(maxi(0, G.n - 1 - int(floor((scroll + H) / G.band))), mini(G.n - 1, G.n - 1 - int(floor(scroll / G.band))) + 1):
		vis.append(i)
	for i in vis:
		var T: Dictionary = Art.THEMES[i % Art.THEMES.size()]
		var y0: float = band_top(G, i) - scroll
		if _stars.size() > 40:
			_stars.clear()
		draw_set_transform(Vector2(0, y0))
		Scenes.sky(self, T, W, G.band, false)
		for s in ([] if T.has("custom") else _star_list(i, W, G.band)):
			draw_rect(Rect2(s[0], s[1], s[2] * k_scale, s[2] * k_scale), Color(1, 0.98, 0.9, s[3]))
		Scenes.live(self, T, W, G.band, t, "sky")
		Scenes.land(self, T, W, G.band)
		Scenes.live(self, T, W, G.band, t, "ground")
		draw_set_transform(Vector2.ZERO)
		if i > cur_ch:
			draw_rect(Rect2(0, y0, W, G.band), Color(0.016, 0.024, 0.063, 0.45))
	for i in vis:   # soften the seam between two scenes
		var y0: float = band_top(G, i) - scroll
		var a := Color(0.012, 0.016, 0.047, 0.0)
		var b := Color(0.012, 0.016, 0.047, 0.45)
		var h1 := 70.0 * k_scale
		var h2 := 90.0 * k_scale
		draw_polygon(PackedVector2Array([Vector2(0, y0 - h1), Vector2(W, y0 - h1), Vector2(W, y0), Vector2(0, y0)]), PackedColorArray([a, a, b, b]))
		draw_polygon(PackedVector2Array([Vector2(0, y0), Vector2(W, y0), Vector2(W, y0 + h2), Vector2(0, y0 + h2)]), PackedColorArray([b, b, a, a]))
	# the trail: dotted, golden where you've been
	var lo: int = maxi(1, vis[0] * 10 - 1)
	var hi: int = (vis[vis.size() - 1] + 1) * 10 + 1
	var pts: Array = []
	for lv in range(lo, hi + 1):
		pts.append([lv, stop_pos(G, lv) - Vector2(0, scroll)])
	for k in pts.size() - 1:
		var a: Vector2 = pts[k][1]
		var b: Vector2 = pts[k + 1][1]
		var lit: bool = pts[k + 1][0] <= cur
		var my := (a.y + b.y) * 0.5
		var gap := 14.0 * k_scale
		var steps := 40
		var prev := a
		var run := gap   # dots evenly spaced along the curve
		for s in steps + 1:
			var p := a.bezier_interpolate(Vector2(a.x, my), Vector2(b.x, my), b, float(s) / steps)
			run += p.distance_to(prev)
			prev = p
			if run < gap:
				continue
			run = 0.0
			if lit:
				Art.glow(self, p, 7.0 * k_scale, Color("#ffc83c"), 0.35)
				draw_circle(p, 3.0 * k_scale, Color(1, 0.85, 0.23, 0.9))
			else:
				draw_circle(p, 2.5 * k_scale, Color(0.78, 0.84, 1, 0.28))
	# chapter signs
	for i in vis:
		var T: Dictionary = Art.THEMES[i % Art.THEMES.size()]
		var c := Vector2(W * 0.5, band_top(G, i) - scroll + G.step * 10.0 + G.sign * 0.5)
		var w: float = min(W * 0.8, 330.0 * k_scale)
		var h: float = G.sign * 0.62
		var locked: bool = i > cur_ch
		var done: bool = i < cur_ch
		if not _banner.is_empty() and _banner.ch == i:
			var bl: float = max(0.0, 1.0 - (_now - _banner.t0) / 2.6)
			Art.glow(self, c, w * 0.8, Color(T.glow), 0.5 * bl)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.047, 0.055, 0.118, 0.82) if locked else Color(0.04, 0.055, 0.14, 0.78)
		sb.border_color = Color(0.63, 0.67, 0.78, 0.3) if locked else Color(Color(T.glow), 0.75)
		sb.set_border_width_all(int(max(2.0, 2.0 * k_scale)))
		sb.set_corner_radius_all(int(16 * k_scale))
		sb.anti_aliasing = true
		draw_style_box(sb, Rect2(c - Vector2(w, h) * 0.5, Vector2(w, h)))
		var fs1 := int(h * 0.2)
		var fs2 := int(h * 0.34)
		draw_string(NUM_FONT, Vector2(c.x - w * 0.5, c.y - h * 0.2 + fs1 * 0.35), I18n.up(I18n.t("Chapter {0}", [i + 1])), HORIZONTAL_ALIGNMENT_CENTER, w, fs1, Color(0.67, 0.7, 0.82, 0.55) if locked else Color(0.78, 0.82, 0.94, 0.85))
		draw_string(NAME_FONT, Vector2(c.x - w * 0.5, c.y + h * 0.17 + fs2 * 0.35), chapter_name(i), HORIZONTAL_ALIGNMENT_CENTER, w, fs2, Color(0.78, 0.8, 0.88, 0.5) if locked else Color("#fff6d0"))
		if locked:
			_lock(Vector2(c.x - w * 0.5 + h * 0.45, c.y), h * 0.38, Color(0.75, 0.78, 0.88, 0.6))
		if done:
			var cc := Vector2(c.x + w * 0.5 - h * 0.42, c.y)
			draw_circle(cc, h * 0.2, Color("#7dff6b"))
			draw_polyline(PackedVector2Array([cc + Vector2(-h * 0.08, 0), cc + Vector2(-h * 0.02, h * 0.07), cc + Vector2(h * 0.09, -h * 0.08)]), Color("#0a2a10"), max(2.0, 2.5 * k_scale))
	# the stones
	var r: float = G.r
	for e in pts:
		var lv: int = e[0]
		var p: Vector2 = e[1]
		if p.y < -r * 3.0 or p.y > H + r * 3.0:
			continue
		var T: Dictionary = Art.THEMES[((lv - 1) / 10) % Art.THEMES.size()]
		var hard := Puzzle.is_hard(lv)
		var ext := Puzzle.is_extreme(lv)
		var num_col: Color
		if lv < cur:
			Art.glow(self, p, r * 2.4, Color(T.glow), 0.3)
			draw_circle(p, r, Color("#ff6b4a") if ext else (Color("#ff8fc8") if hard else Color("#ffb830")))
			draw_circle(p - Vector2(r, r) * 0.12, r * 0.82, Color("#ffb39c") if ext else (Color("#ffc8e4") if hard else Color("#ffd36a")))
			draw_circle(p - Vector2(r, r) * 0.25, r * 0.45, Color(1, 0.97, 0.8, 0.6))
			num_col = Color("#3a2205")
		elif lv == cur:
			var pu := 0.5 + 0.5 * sin(t * 3.0)
			Art.glow(self, p, r * (3.0 + pu), Color("#ffd93b"), 0.55)
			draw_arc(p, r * (1.25 + 0.15 * pu), 0, TAU, 48, Color(1, 0.94, 0.7, 0.35 + 0.4 * pu), 3.0 * k_scale, true)
			draw_circle(p, r * 1.12, Color("#ff3b2e") if ext else (Color("#ff5ca8") if hard else Color("#ffd93b")))
			draw_circle(p - Vector2(r, r) * 0.15, r * 0.85, Color("#ff8a70") if ext else (Color("#ff9fcf") if hard else Color("#ffec8a")))
			draw_circle(p - Vector2(r, r) * 0.3, r * 0.42, Color(1, 1, 1, 0.75))
			num_col = Color("#3a2205")
		else:
			if ext:
				Art.glow(self, p, r * 1.8, Color("#ff3b2e"), 0.22 + 0.08 * sin(t * 2.0 + lv))
			draw_circle(p, r, Color(T.get("stone", "#101633e0")))
			draw_arc(p, r, 0, TAU, 40, Color(1, 0.35, 0.24, 0.7) if ext else (Color(1, 0.47, 0.75, 0.55) if hard else Color(0.78, 0.84, 1, 0.25)), (2.5 if ext else 2.0) * k_scale, true)
			num_col = Color(0.78, 0.82, 0.94, 0.6)
		var fs := int(r * (0.72 if lv >= 100 else 0.85))
		draw_string(NUM_FONT, Vector2(p.x - r * 1.5, p.y + fs * 0.36), str(lv), HORIZONTAL_ALIGNMENT_CENTER, r * 3.0, fs, num_col)
		if ext:   # a small gold crown marks each Extreme level (the chapter's last)
			var w := r * 0.8
			var h := w * 0.62
			var cy := p.y - r * 1.05
			# three soft points with a little glowing orb on each, sitting on a darker band (same as the web crown)
			var bh := h * 0.26
			var b := cy + h * 0.5
			var tips := [Vector2(p.x - w * 0.5, cy - h * 0.32), Vector2(p.x, cy - h * 0.54), Vector2(p.x + w * 0.5, cy - h * 0.32)]
			var crown := PackedVector2Array([Vector2(p.x - w * 0.46, b - bh), tips[0] + Vector2(w * 0.02, 0), Vector2(p.x - w * 0.22, cy + h * 0.04), tips[1],
				Vector2(p.x + w * 0.22, cy + h * 0.04), tips[2] - Vector2(w * 0.02, 0), Vector2(p.x + w * 0.46, b - bh)])
			var line := Color(0.43, 0.2, 0, 0.65)
			draw_colored_polygon(crown, Color("#ffcf3a"))
			crown.append(crown[0])
			draw_polyline(crown, line, 1.5 * k_scale, true)
			var band := Rect2(p.x - w * 0.5, b - bh, w, bh)
			draw_rect(band, Color("#e0961f"))
			draw_rect(band, line, false, 1.5 * k_scale)
			for tip in tips:
				draw_circle(tip, w * 0.07, Color("#fff8d0"))
		elif hard:
			var sc := p + Vector2(r, -r) * 0.85
			draw_colored_polygon(Art.star_points(sc, r * 0.42, r * 0.19), Color("#ff5ca8") if lv < cur else Color("#ff8fc8"))
		if lv == cur:
			Art.fly(self, p + Vector2(sin(t * 1.3) * r * 0.4, -r * 2.0 + sin(t * 2.1) * 4.0), r * 0.42, Art.COLORS[0], _flap, true, true, 7.0, _now)
			draw_set_transform(Vector2.ZERO)
	# sparkles when a new chapter opens
	for b in _burst:
		var a: float = 1.0 - b.life / b.max
		var bp: Vector2 = b.p - Vector2(0, scroll)
		Art.glow(self, bp, 10.0 * k_scale, b.c, 0.7 * a)
		draw_rect(Rect2(bp - Vector2(1.5, 1.5) * k_scale, Vector2(3, 3) * k_scale), Color(1, 1, 0.94, a))
	if not _banner.is_empty() and _now - _banner.t0 < 3.2:
		var e: float = _now - _banner.t0
		var a: float = clampf(min(e / 0.3, (3.2 - e) / 0.5), 0.0, 1.0)
		var fs := int(34 * k_scale)
		Art.glow(self, Vector2(W * 0.5, H * 0.3), fs * 3.0, Color("#ffc83c"), 0.25 * a)
		draw_string(NAME_FONT, Vector2(0, H * 0.3 + fs * 0.35), tr("New chapter!"), HORIZONTAL_ALIGNMENT_CENTER, W, fs, Color(1, 0.95, 0.77, a))
	for f in _flies:
		var p := Vector2((f.x + sin(t * 0.25 * f.s + f.a) * 0.1) * W, (f.y + cos(t * 0.2 * f.s + f.b) * 0.05) * H)
		var tw := 0.3 + 0.7 * absf(sin(t * 1.2 * f.s + f.a))
		Art.glow(self, p, 12.0 * k_scale, Art.COLORS[f.c], 0.3 * tw)
		draw_circle(p, 1.6 * k_scale, Color(1, 0.98, 0.78, 0.8 * tw))

func _lock(c: Vector2, s: float, col: Color) -> void:
	draw_arc(c + Vector2(0, -s * 0.2), s * 0.3, PI, TAU, 16, col, s * 0.16)
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(int(s * 0.12))
	draw_style_box(sb, Rect2(c.x - s * 0.45, c.y - s * 0.2, s * 0.9, s * 0.7))
