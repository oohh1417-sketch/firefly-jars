extends Control
## The loading screen: a jar fills with things from every world, its golden lid screws on, then the menu fades in.
## Same scene as the iPhone version. Emits `finished` when it has faded out.

signal finished

const TIPS := ["Tip: tap a jar, then tap another jar to pour", "Tip: a jar with a ribbon only takes that color",
	"Tip: lidded jars open after a few pours", "Tip: a new daily puzzle arrives every day"]
const FILL_TIME := 2.0
const ORBS := [Vector2(0.15, 0.33), Vector2(0.85, 0.33), Vector2(0.1, 0.52), Vector2(0.9, 0.52), Vector2(0.16, 0.71), Vector2(0.84, 0.71)]
const KINDS := ["fish", "flower", "candy", "planet"]

var logo_font: Font
var ui_font: Font
var _now := 0.0
var _ready_at := -1.0
var _stars: Array = []
var _tip := ""
var _leaving := false
var still := false   # true when drawing the still splash image (no flying firefly, no text)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 70:
		_stars.append([rng.randf(), rng.randf() * 0.8, rng.randf() * TAU, 1.0 + rng.randf() * 2.0])
	_tip = TIPS[randi() % TIPS.size()]

func _process(delta: float) -> void:
	_now += min(delta, 0.05)
	if _ready_at < 0.0 and _now >= FILL_TIME:
		_ready_at = _now
	if _ready_at >= 0.0 and not _leaving and _now - _ready_at > Art.CAP_TOTAL + 0.5:
		_leaving = true
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 0.5)
		tw.tween_callback(func():
			finished.emit()
			queue_free())
	queue_redraw()

func _draw() -> void:
	var W := size.x
	var H := size.y
	# Jar World: a twilight sky with a little bubble for each world, and mixed things filling the jar
	Regions.hub = true
	Regions.hub_sky(self, W, H, _now, H * 0.8)
	Regions.hub_land(self, W, H, H * 0.8)
	Regions.hub_orbs(self, W, H, _now, ORBS, min(W * 0.07, 60.0))
	# logo
	_text_center("Jar", logo_font, 150, H * 0.17, Color("#ffd93b"), Color("#ff9f43"))
	var pill := Rect2(W * 0.5 - 130, H * 0.17 + 92, 260, 64)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.07, 0.17, 0.45)
	sb.border_color = Color(0.72, 0.8, 1.0, 0.28)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(32)
	sb.anti_aliasing = true
	draw_style_box(sb, pill)
	_text_center("W O R L D", ui_font, 40, pill.get_center().y - 2, Color("#dfe7ff"))
	# the jar filling up
	var jw: float = min(W * 0.26, 200.0)
	var jh := jw * 2.5
	var r := Rect2(W * 0.5 - jw * 0.5, H * 0.52 - jh * 0.5, jw, jh)
	var n: int = min(4, int(_now / FILL_TIME * 4.999))
	Art.glow(self, Vector2(W * 0.5, r.position.y + jh * 0.55), jw * 2.2, Color("#ffcf4a"), 0.18 + 0.05 * n)
	Art.jar_back(self, r)
	var step := (r.size.y - r.size.x * 0.42) / 4.0
	var R := jw * 0.29
	for k in n:
		var p := Vector2(r.get_center().x + sin(_now * 2.0 + k) * 2.0, r.end.y - jw * 0.16 - step * (k + 0.5) + cos(_now * 2.4 + k) * 2.0)
		Regions.mix_fly(self, KINDS[k], p, R, Art.COLORS[k], _now * 8.0 + k, false, k * 3.0, _now)
	if n < 4 and not still:
		var t := fmod(_now / 0.4, 1.0)
		var target_y := r.end.y - jw * 0.16 - step * (n + 0.5)
		var from_y := r.position.y - jh * 0.6
		Regions.mix_fly(self, KINDS[n], Vector2(W * 0.5 + sin(t * 5.0 + n) * W * 0.25 * (1.0 - t), lerpf(from_y, target_y, t)), R, Art.COLORS[n], _now * 12.0, true, n * 3.0, _now)
	Art.jar_front(self, r, Art.jar_line(), max(2.0, R * 0.11))
	if _ready_at >= 0.0:
		Art.cap(self, r, _now - _ready_at)
	Regions.hub = false
	# status and tip
	if still:
		return
	_text_center(tr("Filling the jars…") if _ready_at < 0.0 else tr("Ready!"), logo_font, 44, H * 0.85, Color("#fff3c4"))
	_text_center(tr(_tip), ui_font, 28, H * 0.85 + 56, Color("#9aa6d6"))

func _text_center(t: String, f: Font, fs: int, y: float, col: Color, outline := Color(0, 0, 0, 0)) -> void:
	var w := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var pos := Vector2((size.x - w) * 0.5, y + f.get_ascent(fs) * 0.5)
	if outline.a > 0.0:
		draw_string_outline(f, pos, t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 10, outline)
	draw_string(f, pos, t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
