extends Control
## Draws the Jar World launch picture (the first screen the iPhone shows) from the loading screen's own art,
## so the picture flows straight into the loading animation.
## Run:  godot --resolution 1290x2796 res://tools/make_splash.tscn
## Writes: splash.png (1290x2796, tall like a modern iPhone).
## The picture is shown "cover" (fills the whole screen, edges trimmed on shorter phones),
## so the logo and jar sit well inside the middle.

const LoadingScript := preload("res://scripts/loading.gd")

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var loading: Control = LoadingScript.new()
	loading.logo_font = preload("res://fonts/Fredoka-Bold.woff2")
	loading.ui_font = preload("res://fonts/Baloo2-ExtraBold.woff2")
	loading.still = true
	loading.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(loading)
	loading.set_process(false)   # freeze at the very first frame of the loading screen
	await get_tree().process_frame
	loading.queue_redraw()
	for i in 3:
		await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	img.save_png(ProjectSettings.globalize_path("res://splash.png"))
	print("splash saved ", img.get_size())
	get_tree().quit()
