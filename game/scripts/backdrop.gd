extends Control
## The night scene behind the jars. Each chapter (10 levels) has its own theme,
## and the daily puzzle uses the starfall sky. Same scenes as the iPhone test version.

var theme_index := 0:
	set(v):
		theme_index = v
		queue_redraw()

var _now := 0.0
var _stars: Array = []
var _flies: Array = []
# Living sky: a shooting star every few seconds (more often in the Starfall sky), slow clouds, swaying grass.
var _meteor_state := {"list": [], "next": 0.0}
var _clouds: Array = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	for i in 80:
		_stars.append([rng.randf(), rng.randf() * 0.55, rng.randf() * TAU, 0.6 + rng.randf() * 1.2])
	for i in 3:
		_clouds.append({"x": rng.randf(), "y": 0.06 + rng.randf() * 0.22, "s": 0.5 + rng.randf() * 0.7, "v": 0.004 + rng.randf() * 0.006, "w": 0.3 + rng.randf() * 0.25})
	for i in 10:
		_flies.append({"x": rng.randf(), "y": 0.25 + rng.randf() * 0.6, "a": rng.randf() * TAU, "b": rng.randf() * TAU, "s": 0.4 + rng.randf() * 0.6, "c": i % 5})

func _process(delta: float) -> void:
	_now += delta
	queue_redraw()

func _draw() -> void:
	var T: Dictionary = Art.THEMES[theme_index % Art.THEMES.size()]
	var W := size.x
	var H := size.y
	var hills: Array = T.hills
	var t := _now
	if T.has("custom"):   # Jar World regions: their own scene, no night sky extras
		Scenes.sky(self, T, W, H)
		Scenes.live(self, T, W, H, t, "sky")
		Scenes.land(self, T, W, H)
		Scenes.live(self, T, W, H, t, "ground")
		var c0 := Color(0, 0, 0, 0)
		var c1 := Color(0, 0, 0, 0.16 if T.get("day", false) else 0.35)
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(W, 0), Vector2(W, H * 0.12), Vector2(0, H * 0.12)]), PackedColorArray([c1, c1, c0, c0]))
		draw_polygon(PackedVector2Array([Vector2(0, H * 0.85), Vector2(W, H * 0.85), Vector2(W, H), Vector2(0, H)]), PackedColorArray([c0, c0, c1, c1]))
		return
	Scenes.sky(self, T, W, H, true)
	for s in _stars:
		var a := 0.2 + 0.5 * absf(sin(t * 0.5 * s[3] + s[2]))
		draw_rect(Rect2(s[0] * W, s[1] * H, s[3] * 1.5, s[3] * 1.5), Color(1, 0.98, 0.9, a))
	Scenes.live(self, T, W, H, t, "sky")
	Art.glow(self, Vector2(W * 0.8, H * 0.13), min(W, H) * 0.045 * 4.0, Color("#dfe8ff"), 0.05 + 0.04 * sin(t * 0.8))   # the moon's halo breathes
	_sky_life(T, t, W, H)
	Scenes.land(self, T, W, H)
	for i in 60:   # grass and reeds sway in the night breeze
		var x := i / 60.0 * W + (i % 3) * 3
		var h := 18.0 + (i * 37 % 26)
		var sw := sin(t * 1.1 + i * 0.45) * 3.0 + sin(t * 0.37 + i) * 1.5
		draw_polyline(PackedVector2Array([Vector2(x, H + 2), Vector2(x + 3 + sw * 0.4, H - h * 0.6), Vector2(x + (7 if i % 2 else -5) + sw, H - h)]), Color(hills[2]), 2.0)
	Scenes.live(self, T, W, H, t, "ground")
	# soft dark edges so the jars stay the brightest thing
	var clear := Color(0, 0, 0, 0)
	var dark := Color(0, 0, 0, 0.4)
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(W, 0), Vector2(W, H * 0.12), Vector2(0, H * 0.12)]), PackedColorArray([dark, dark, clear, clear]))
	draw_polygon(PackedVector2Array([Vector2(0, H * 0.85), Vector2(W, H * 0.85), Vector2(W, H), Vector2(0, H)]), PackedColorArray([clear, clear, dark, dark]))
	for f in _flies:
		var p := Vector2((f.x + sin(t * 0.25 * f.s + f.a) * 0.1) * W, (f.y + cos(t * 0.2 * f.s + f.b) * 0.05) * H)
		var tw := 0.3 + 0.7 * absf(sin(t * 1.2 * f.s + f.a))
		Art.glow(self, p, 12, Art.COLORS[f.c], 0.3 * tw)
		draw_circle(p, 1.6, Color(1, 0.98, 0.78, 0.8 * tw))

func _sky_life(T: Dictionary, t: float, W: float, H: float) -> void:
	# clouds: a few soft puffs drifting slowly sideways, sometimes across the moon
	var cc := Color(T.sky[2])
	for c in _clouds:
		var x: float = (fmod(c.x + t * c.v, 1.6) - 0.3) * W
		var y: float = c.y * H
		var w: float = c.w * W
		for k in 5:
			Art.glow(self, Vector2(x + (k - 2) * w * 0.22, y + sin(k * 1.7) * w * 0.05), w * (0.28 + (k % 2) * 0.08) * c.s, cc, 0.2)
	Art.meteors(self, _meteor_state, t, W, H, T.name == "starfall")
