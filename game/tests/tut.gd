extends Node
## First-level tutorial: the hand guides 2 pours, wrong jars are ignored, and it is not shown again.
func _ready():
	var S = get_tree().root.get_node("Save")
	S.level = 1; S.seen = {}
	var main = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main)
	await get_tree().create_timer(4.0).timeout   # loading screen
	main._start_level(); await get_tree().create_timer(1.6).timeout
	var out := []
	var st := func(tag): out.append("%s tut=%s jar=%d msg='%s'" % [tag, main.tut, main.board.tut_jar, main.info_label.text])
	st.call("start")
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/claude-0/shots/gd_tut1.png")
	var t0: int = main._tut_target()
	main._on_jar_tapped((t0 + 1) % main.state.jars.size()); st.call("wrong")
	main._on_jar_tapped(main._tut_target()); st.call("picked")
	await get_tree().create_timer(0.9).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/claude-0/shots/gd_tut2.png")
	main._on_jar_tapped(main._tut_target()); await get_tree().create_timer(0.9).timeout; st.call("pour1")
	main._undo(); await get_tree().create_timer(0.9).timeout; st.call("undo")
	for k in 2:
		main._on_jar_tapped(main._tut_target()); main._on_jar_tapped(main._tut_target()); await get_tree().create_timer(0.9).timeout
	st.call("pour2")
	for m in Puzzle.solve(main.state):
		main._on_jar_tapped(m[0]); main._on_jar_tapped(m[1]); await get_tree().create_timer(0.9).timeout
	await get_tree().create_timer(4.0).timeout
	out.append("won level=%d seen=%s win=%s" % [S.level, S.seen.has("tutorial"), main.win_layer.visible])
	main._start_level(); await get_tree().create_timer(1.0).timeout; st.call("level2")
	for l in out: print("TUT ", l)
	get_tree().quit()
