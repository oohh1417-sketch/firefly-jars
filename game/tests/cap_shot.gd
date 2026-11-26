extends Node2D
## Close-up of a full jar with its lid on, in each of the 6 worlds (for checking the lid sits right).
## Run: xvfb-run godot --path game res://tests/run_cap_shot.tscn --resolution 1080x1920  (OUT env = folder)
const NAMES := ["Bubble Reef", "Sunpetal Meadow", "Lantern Grove", "Firefly Night", "Candy Clouds", "Starlight Space"]

func _ready():
	await get_tree().create_timer(0.5).timeout
	queue_redraw()
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_environment("OUT") + "/caps.png")
	get_tree().quit()

func _draw():
	draw_rect(Rect2(0, 0, 720, 1280), Color("#f4d9b8"))
	var font := ThemeDB.fallback_font
	for i in 6:
		Art.region = i
		var r := Rect2(45 + (i % 3) * 235, 150 + (i / 3) * 560, 160, 400)
		Art.jar_back(self, r)
		Regions.corked = true
		Art.jar_front(self, r, Color("#ffffffcc"), 4.0)
		Regions.corked = false
		Art.cap(self, r, 5.0)
		draw_string(font, Vector2(r.position.x - 30, r.end.y + 50), NAMES[i], HORIZONTAL_ALIGNMENT_CENTER, 220, 22, Color("#3a2716"))
