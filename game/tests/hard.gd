extends Node
## Hard levels: banner, pink header, +1 hint on winning, back to normal afterwards.
func _ready():
	var S = get_tree().root.get_node("Save")
	S.level = 10; S.hints = 0; S.seen = {"cracked_jar": true, "color_jar": true, "lid": true, "daily": true, "hard": true, "extreme": true, "coins": true, "map": true, "lives": true, "tutorial": true}
	var main = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main)
	await get_tree().create_timer(4.0).timeout
	print("HARD menu sub=", main.play_sub.text, " tint=", main.hard_tint.visible)
	main._start_level(); await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/claude-0/shots/gd_hard1.png")
	await get_tree().create_timer(2.5).timeout
	print("HARD label=", main.chapter_label.text, " jars=", main.state.jars.size(), " tint=", main.hard_tint.visible, " banner=", main.hard_banner.visible)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/claude-0/shots/gd_hard2.png")
	for m in Puzzle.shortest_path(main.state):
		main._on_jar_tapped(m[0]); main._on_jar_tapped(m[1]); await get_tree().create_timer(0.65).timeout
	await get_tree().create_timer(4.0).timeout
	print("HARD win=", main.win_title.text, " | ", main.win_label.text.replace("\n", " / "), " hints=", S.hints, " level=", S.level, " tint=", main.hard_tint.visible)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/claude-0/shots/gd_hard3.png")
	main._start_level(); await get_tree().create_timer(1.0).timeout
	print("HARD L11 label=", main.chapter_label.text, " tint=", main.hard_tint.visible)
	main._show_menu(); print("HARD menu tint=", main.hard_tint.visible, " sub=", main.play_sub.text)
	get_tree().quit()
