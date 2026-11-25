extends Node
## Jar World: screenshots of the menu, map and a level in each of the 6 regions.
## Run: xvfb-run godot --path game res://tests/run_regions_shot.tscn  (OUT env = folder for the pictures)
func _shot(name: String) -> void:
	await get_tree().create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	var out := OS.get_environment("OUT")
	get_viewport().get_texture().get_image().save_png(out + "/" + name + ".png")

func _ready():
	var S = get_tree().root.get_node("Save")
	S.coins = 120
	S.seen = {"cracked_jar": true, "color_jar": true, "lid": true, "daily": true, "hard": true, "extreme": true, "coins": true, "map": true, "lives": true, "tutorial": true, "streak": true}
	var main = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main)
	await get_tree().create_timer(4.0).timeout
	var only := OS.get_environment("REGIONS")
	for i in 6:
		if only != "" and not str(i) in only:
			continue
		S.level = i * 10 + 3
		S.map_ch = i + 1
		main._show_menu()
		await _shot("r%d-1menu" % i)
		main._show_map("menu")
		await get_tree().create_timer(1.6).timeout
		await _shot("r%d-2map" % i)
		main.map_layer.hide()
		main._start_level()
		await get_tree().create_timer(1.4).timeout
		await _shot("r%d-3level" % i)
	print("REGION SHOTS done")
	get_tree().quit()
