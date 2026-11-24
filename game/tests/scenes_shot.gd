extends Node
func _ready():
	var S = get_tree().root.get_node("Save")
	S.level = 81; S.seen = {"cracked_jar": true, "color_jar": true, "lid": true, "daily": true, "hard": true, "extreme": true, "coins": true, "map": true, "lives": true, "tutorial": true}
	var main = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main)
	await get_tree().create_timer(3.0).timeout
	main._start_level()
	await get_tree().create_timer(1.0).timeout
	for i in range(8, 20):
		main.backdrop.theme_index = i
		await get_tree().create_timer(0.4).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("/tmp/claude-0/work/gd%d.png" % i)
	print("SCENES done")
	get_tree().quit()
