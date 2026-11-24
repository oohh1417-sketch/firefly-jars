extends Button
## A glass button with a drawn line icon, an optional label and an optional gold badge.
## Icons are drawn with code (Art.icon), so they look the same on every phone.

var icon_name := "home":
	set(v):
		icon_name = v
		queue_redraw()
var label := "":
	set(v):
		label = v
		queue_redraw()
var badge := "":
	set(v):
		badge = v
		queue_redraw()
var round_shape := true
var badge_color := Color("#ffc23d")
var badge_text_color := Color("#3a2400")
var dim := false:
	set(v):
		dim = v
		queue_redraw()
var icon_color := Color("#e8eeff")
var font: Font

func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_NONE
	for st in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
		add_theme_stylebox_override(st, StyleBoxEmpty.new())
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.16, 0.2, 0.39, 0.75) if is_pressed() else Color(0.05, 0.07, 0.17, 0.88)
	sb.border_color = Color(0.72, 0.8, 1.0, 0.28)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(int(size.y * 0.5) if round_shape else 34)
	sb.anti_aliasing = true
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 6)
	draw_style_box(sb, r)
	var a := 0.4 if (disabled or dim) else 1.0
	var col := Color(icon_color, a)
	if label == "":
		Art.icon(self, icon_name, size * 0.5, size.y * 0.5, col)
		return
	var fs := 40
	var tw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var bw := 0.0
	if badge != "":
		bw = max(52.0, font.get_string_size(badge, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x + 28.0) + 16.0
	var isz := size.y * 0.42
	var total := isz + 18.0 + tw + bw
	var x := (size.x - total) * 0.5
	var ic := col
	if icon_name == "bulb":
		ic = Color(Color("#ffd93b"), a)
	Art.icon(self, icon_name, Vector2(x + isz * 0.5, size.y * 0.5), isz, ic)
	x += isz + 18.0
	draw_string(font, Vector2(x, size.y * 0.5 + font.get_ascent(fs) * 0.5 - fs * 0.12), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(Color("#f3f5ff"), a))
	if badge != "":
		var br := Rect2(x + tw + 16.0, size.y * 0.5 - 26.0, bw - 16.0, 52.0)
		var bs := StyleBoxFlat.new()
		bs.bg_color = badge_color
		bs.set_corner_radius_all(26)
		bs.anti_aliasing = true
		draw_style_box(bs, br)
		var bt := font.get_string_size(badge, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
		draw_string(font, Vector2(br.get_center().x - bt * 0.5, br.get_center().y + font.get_ascent(30) * 0.5 - 4), badge, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, badge_text_color)
