extends Node
func _ready():
	var S = get_tree().root.get_node("Save")
	S.level = 41; S.seen = {"cracked_jar": true, "color_jar": true, "lid": true, "daily": true, "hard": true, "extreme": true, "coins": true, "map": true, "lives": true, "tutorial": true}
	var main = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main)
	await get_tree().create_timer(4.0).timeout
	main._start_level()
	var got := 0
	for k in 120:
		await get_tree().create_timer(0.1).timeout
		var live: bool = main.backdrop._meteor_state.list.any(func(m): var u: float = (main.backdrop._now - m.t0) / m.dur; return u > 0.3 and u < 0.8)
		if live and got < 2:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("/tmp/claude-0/shots/gdsky%d.png" % got)
			got += 1
			await get_tree().create_timer(1.5).timeout
	print("SKY shots=", got)
	get_tree().quit()
