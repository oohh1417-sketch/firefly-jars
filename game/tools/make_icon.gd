extends Control
## Draws the app icon with the game's own art and saves it as PNG files.
## NOTE: this draws the OLD Firefly Jars icon. The current Jar World icon is made by tools/icon/jar_world_icons.js (repo root).
## Run:  godot --resolution 1024x1024 res://tools/make_icon.tscn
## Writes: icon.png (1024, full square for iOS and the stores),
##         icon_fg.png and icon_bg.png (Android adaptive icon layers, 432x432 scaled from 1024).

var mode := "full"   # "full", "fg" (jar only, transparent), "bg" (sky only)

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	get_viewport().transparent_bg = true
	await get_tree().process_frame
	for m in ["full", "fg", "bg"]:
		mode = m
		queue_redraw()
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		var name: String = {"full": "icon.png", "fg": "icon_fg.png", "bg": "icon_bg.png"}[m]
		if m == "full":
			img.convert(Image.FORMAT_RGB8)   # the App Store wants no transparency
		img.save_png(ProjectSettings.globalize_path("res://" + name))
	get_tree().quit()

func _draw() -> void:
	var S := size.x
	if mode != "fg":
		Art.vgradient(self, Rect2(0, 0, S, S), Color("#060a22"), Color("#14205a"), Color("#2a3a7a"), 0.55)
		var rng := RandomNumberGenerator.new()
		rng.seed = 3
		for i in 60:
			var p := Vector2(rng.randf() * S, rng.randf() * S * 0.75)
			draw_circle(p, 1.5 + rng.randf() * 3.0, Color(1, 0.97, 0.85, 0.3 + rng.randf() * 0.5))
		# soft hill at the bottom
		Art.hill(self, Vector2(S, S), S * 0.86, S * 0.02, 3.0, 0.8, Color("#0b1438"))
		Art.glow(self, Vector2(S * 0.5, S * 0.55), S * 0.55, Color("#ffcf4a"), 0.35)
	if mode == "bg":
		return
	# the jar: in Android's safe zone (center 66%) so no launcher crops it
	var jw := S * 0.4
	var jh := jw * 1.5
	var r := Rect2(S * 0.5 - jw * 0.5, S * 0.53 - jh * 0.45, jw, jh)
	Art.glow(self, Vector2(S * 0.5, r.position.y + jh * 0.6), jw * 1.3, Color("#ffd93b"), 0.5)
	Art.jar_back(self, r, Color(1.0, 0.85, 0.3, 0.08))
	var R := jw * 0.24
	var spots := [Vector2(-0.17, 0.76), Vector2(0.19, 0.7), Vector2(-0.12, 0.47), Vector2(0.17, 0.42)]
	var cols := [0, 2, 1, 3]
	for k in spots.size():
		var p := Vector2(r.get_center().x + spots[k].x * jw, r.position.y + spots[k].y * jh)
		Art.fly(self, p, R, Art.COLORS[cols[k]], 1.2 + k, true, false, k * 2.0, 0.6)
	Art.jar_front(self, r, Color(0.86, 0.93, 1.0, 0.85), max(6.0, jw * 0.035))
	Art.cap(self, r, 10.0)
	# one firefly escaping above the lid
	Art.fly(self, Vector2(S * 0.63, r.position.y - jw * 0.3), R * 0.75, Art.COLORS[0], 0.9, true, true, 1.0, 0.6)
