extends Node
## Skill streak: target on normal levels, kept / lost / bonus coins.
func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/claude-0/work/%s.png" % name)

func _solve(main) -> void:
	var p = Puzzle.shortest_path(main.state)
	for m in p:
		main._pour(m[0], m[1])
		await get_tree().create_timer(0.35).timeout

func _ready():
	var S = get_tree().root.get_node("Save")
	S.level = 3; S.coins = 0; S.hints = 3; S.lives = 5; S.skill = 2; S.ads_removed = true
	S.seen = {"cracked_jar": true, "color_jar": true, "lid": true, "daily": true, "hard": true, "extreme": true, "coins": true, "map": true, "tutorial": true, "tutorial_done": true}
	var main = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main)
	await get_tree().create_timer(6.0).timeout
	var bad := []
	main._start_level()
	await get_tree().create_timer(2.5).timeout
	if main.target <= 0: bad.append("no target")
	if not main.tip_layer.visible: bad.append("no streak tip")
	await _shot("gdstreaktip")
	main._show_next_tip()
	await _shot("gdstreakpill")
	await _solve(main)
	await get_tree().create_timer(5.0).timeout
	if S.skill != 3: bad.append("skill after win %d" % S.skill)
	if S.coins != 25: bad.append("coins %d (want 10 + 15 bonus)" % S.coins)
	await _shot("gdstreakwin")
	print("win text: ", main.win_text.text if "win_text" in main else "")
	# level 4: use a hint -> streak lost
	main._start_level()
	await get_tree().create_timer(2.5).timeout
	main._use_hint()
	await get_tree().create_timer(1.0).timeout
	await _shot("gdhint")
	await _solve(main)
	await get_tree().create_timer(5.0).timeout
	if S.skill != 0: bad.append("skill after hint %d" % S.skill)
	main._show_menu()
	await get_tree().create_timer(1.0).timeout
	if not main.side_streak.visible: bad.append("side streak hidden")
	await _shot("gdstreakmenu")
	print("STREAK ", "PASS" if bad.is_empty() else "FAIL " + str(bad))
	get_tree().quit()
