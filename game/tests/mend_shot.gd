extends Node
## Jar World: the cracked-jar helpers mid-repair in each of the 6 regions.
## Run: xvfb-run godot --path game res://tests/run_mend_shot.tscn  (OUT env = folder for the pictures)
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
	await get_tree().create_timer(1.0).timeout
	await get_tree().create_timer(3.0).timeout
	for i in 6:
		S.level = i * 10 + 5
		S.map_ch = i + 1
		main.map_layer.hide()
		main.menu_layer.hide()
		main._start_level()
		await get_tree().create_timer(1.4).timeout
		main._start_repair()
		await get_tree().create_timer(0.7).timeout
		await _shot("mend%d" % i)
		await get_tree().create_timer(2.5).timeout
	print("MEND SHOTS done")
	get_tree().quit()
