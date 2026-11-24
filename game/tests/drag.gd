extends Node
## Drag and drop: drag pours, drop in the air puts them back, tap-tap still works, tutorial drag demo.
var main
func ev_btn(pos: Vector2, down: bool) -> void:
	var e := InputEventMouseButton.new(); e.button_index = MOUSE_BUTTON_LEFT; e.pressed = down; e.position = pos
	main.board._gui_input(e)
func ev_move(pos: Vector2) -> void:
	var e := InputEventMouseMotion.new(); e.position = pos
	main.board._gui_input(e)
func center(i: int) -> Vector2:
	return main.board._rects[i].get_center()
func do_drag(a: int, b: int, shot := "") -> void:
	var p0 := center(a); var p1 := center(b)
	ev_btn(p0, true); await get_tree().create_timer(0.25).timeout
	for k in range(1, 21):
		ev_move(p0.lerp(p1, k / 20.0) + Vector2(sin(k / 3.0) * 50.0, -sin(k / 20.0 * PI) * 200.0))
		await get_tree().process_frame; await get_tree().process_frame
	if shot != "":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(shot)
	ev_btn(p1, false); await get_tree().create_timer(0.8).timeout
func _ready():
	var S = get_tree().root.get_node("Save")
	S.level = 3; S.seen = {"cracked_jar": true, "color_jar": true, "lid": true, "daily": true, "hard": true, "extreme": true, "coins": true, "map": true, "lives": true, "tutorial": true, "streak": true}
	main = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main)
	await get_tree().create_timer(4.0).timeout
	main._start_level(); await get_tree().create_timer(1.6).timeout
	var p = Puzzle.solve(main.state)
	await do_drag(p[0][0], p[0][1], "/tmp/claude-0/shots/gd_drag.png")
	print("DRAG pour ok=", main.history.size() == 1, " selected=", main.board.selected)
	p = Puzzle.solve(main.state)
	var a := center(p[0][0])
	ev_btn(a, true); for k in 10: ev_move(a + Vector2(6 * k, -30 * k))
	ev_btn(a + Vector2(60, -300), false); await get_tree().create_timer(0.8).timeout
	print("DRAG air history=", main.history.size(), " selected=", main.board.selected)
	ev_btn(center(p[0][0]), true); ev_btn(center(p[0][0]), false); await get_tree().create_timer(0.3).timeout
	var s1: int = main.board.selected
	ev_btn(center(p[0][1]), true); ev_btn(center(p[0][1]), false); await get_tree().create_timer(0.8).timeout
	print("DRAG tap-tap selected_after_first=", s1, " history=", main.history.size())
	var q = Puzzle.solve(main.state)
	ev_btn(center(q[0][0]), true); ev_btn(center(q[0][0]), false); await get_tree().create_timer(0.3).timeout
	var s2: int = main.board.selected
	ev_btn(center(q[0][0]), true); ev_btn(center(q[0][0]), false); await get_tree().create_timer(0.3).timeout
	print("DRAG select/unselect ", s2, " ", main.board.selected)
	for n in 60:
		q = Puzzle.solve(main.state)
		if q == null or q.is_empty(): break
		await do_drag(q[0][0], q[0][1])
	await get_tree().create_timer(4.0).timeout
	print("DRAG won=", main.win_layer.visible, " level=", S.level)
	# tutorial: second pour shows the drag demo, then a real drag finishes it
	main.win_layer.hide(); S.level = 1; S.seen.erase("tutorial")
	main._start_level(); await get_tree().create_timer(1.6).timeout
	for k in 2:
		var t: int = main._tut_target(); ev_btn(center(t), true); ev_btn(center(t), false); await get_tree().create_timer(0.4).timeout
	await get_tree().create_timer(0.9).timeout
	var t2: int = main._tut_target(); ev_btn(center(t2), true); ev_btn(center(t2), false); await get_tree().create_timer(1.1).timeout
	print("DRAG tut msg='", main.info_label.text, "' demo_from=", main.board.tut_drag_from)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/claude-0/shots/gd_tutdrag.png")
	await do_drag(main.tut.step[0], main._tut_target())
	print("DRAG tut after history=", main.history.size(), " tut=", main.tut, " msg='", main.info_label.text, "'")
	get_tree().quit()
