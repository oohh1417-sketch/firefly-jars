extends Node
## The cracked jar's "Mend the jar?" popup must not close by itself (Khalid's report, and again in the daily puzzle):
## the popup opens only when the finger lifts, and ignores taps for a moment after it opens.
## Run: xvfb-run godot --path game res://tests/run_popup_tap.tscn
var fails := 0

func _check(ok: bool, what: String) -> void:
	print(("PASS " if ok else "FAIL ") + what)
	if not ok:
		fails += 1

func _tap(p: Vector2, down: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = down
	ev.position = p
	ev.global_position = p
	get_viewport().push_input(ev, true)
	await get_tree().process_frame

func _jar_spot(main) -> Vector2:
	var b = main.board
	var r: Rect2 = b._rects[b.extra_index()]
	return b.get_global_transform_with_canvas() * r.get_center()

func _run(main, label: String) -> void:
	await get_tree().create_timer(1.4).timeout
	_check(main.board.extra_state == "cracked", label + ": cracked jar is there")
	var p := _jar_spot(main)
	await _tap(p, true)
	_check(not main.offer_layer.visible, label + ": popup waits while the finger is down")
	await _tap(p, false)
	_check(main.offer_layer.visible, label + ": popup opens when the finger lifts")
	# a stray second touch at the same spot right away must not close it
	await _tap(p, true)
	await _tap(p, false)
	_check(main.offer_layer.visible, label + ": popup stays open after a quick second touch")
	await get_tree().create_timer(0.5).timeout
	var not_now: Button = null
	for n in main.offer_layer.find_children("*", "Button", true, false):
		if n.text == "Not now":
			not_now = n
	var q := not_now.get_global_rect().get_center()
	await _tap(q, true)
	await _tap(q, false)
	_check(not main.offer_layer.visible, label + ": a real tap on Not now still closes it")
	# a press on the jar, dragged away before lifting, opens nothing
	await _tap(p, true)
	await _tap(p + Vector2(0, 600), false)
	_check(not main.offer_layer.visible, label + ": no popup when the finger slides off the jar")

func _ready():
	var S = get_tree().root.get_node("Save")
	S.coins = 120
	S.seen = {"cracked_jar": true, "color_jar": true, "lid": true, "daily": true, "hard": true, "extreme": true, "coins": true, "map": true, "lives": true, "tutorial": true, "streak": true}
	var main = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main)
	await get_tree().create_timer(4.0).timeout
	main.map_layer.hide()
	main.menu_layer.hide()
	main._start_daily()
	await _run(main, "daily")
	S.level = 4
	main.mode = "level"
	main._start_level()
	await _run(main, "level 4")
	print("POPUP TAP: %s" % ("ALL PASS" if fails == 0 else "%d FAILED" % fails))
	get_tree().quit(1 if fails else 0)
