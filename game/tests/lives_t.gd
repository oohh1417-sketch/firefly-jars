extends Node
## Hearts, daily rewards and the menu's side buttons.
func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/claude-0/work/%s.png" % name)

func _ready():
	var S = get_tree().root.get_node("Save")
	S.level = 15; S.coins = 150; S.hints = 0; S.lives = 5; S.gift_day = 0; S.gift_last = ""; S.ads_removed = false
	S.seen = {"cracked_jar": true, "color_jar": true, "lid": true, "daily": true, "hard": true, "extreme": true, "coins": true, "map": true, "tutorial": true}
	var main = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main)
	await get_tree().create_timer(7.0).timeout
	var bad := []
	if not main.side_gift.get_meta("badge"): bad.append("no gift badge")
	if not main.side_noads.visible: bad.append("no-ads hidden")
	await _shot("gdmenu")
	# claim day 1
	main.side_gift.pressed.emit()
	await get_tree().create_timer(0.5).timeout
	await _shot("gdgifts")
	main._claim_gift()
	if S.coins != 170: bad.append("gift coins %d" % S.coins)
	if main.side_gift.get_meta("badge"): bad.append("badge stays after claim")
	main._claim_gift()
	if S.coins != 170: bad.append("claimed twice")
	# yesterday's claim -> day 2; missed day -> day 1
	S.gift_last = S.yesterday(); S.gift_day = 1
	if S.gift_state().day != 1: bad.append("day2 %s" % S.gift_state())
	S.gift_last = "2000-01-01"
	if S.gift_state().day != 0: bad.append("reset %s" % S.gift_state())
	main.gifts_layer.hide()
	# Hard level 15: restart after moves asks first and costs a heart
	main._start_level()
	await get_tree().create_timer(1.5).timeout
	if main.tip_layer.visible: main._show_next_tip()
	main.moves = 2
	main._restart()
	if not main.leave_layer.visible: bad.append("no leave card")
	await _shot("gdleave")
	main.leave_yes.pressed.emit()
	if S.lives != 4: bad.append("lives after restart %d" % S.lives)
	await get_tree().create_timer(0.8).timeout
	if not main.tip_layer.visible: bad.append("no hearts tip")
	await _shot("gdhearttip")
	main._show_next_tip()
	# leave to menu after moves, keep playing first
	main.moves = 3
	main._confirm_leave("menu", main._show_menu)
	main.leave_layer.hide()
	if S.lives != 4 or main.menu_layer.visible: bad.append("keep playing cost a heart")
	# no hearts: blocked with the out-of-hearts card, coins buy one
	S.lives = 0; S.lives_at = Time.get_unix_time_from_system()
	main._start_level()
	await get_tree().create_timer(0.5).timeout
	if not main.nolives_layer.visible: bad.append("no out-of-hearts card")
	await _shot("gdnolives")
	main.nolives_coin_btn.pressed.emit()
	if S.lives != 1 or S.coins != 70: bad.append("buy heart lives=%d coins=%d" % [S.lives, S.coins])
	# refill over time
	S.lives = 2; S.lives_at = Time.get_unix_time_from_system() - 41 * 60
	if S.lives_now() != 4: bad.append("refill %d" % S.lives)
	# normal levels never need a heart
	S.lives = 0
	if main._needs_life(16): bad.append("normal level needs heart")
	# no ads bought -> button hides
	S.ads_removed = true; main._refresh_side()
	if main.side_noads.visible: bad.append("no-ads still shown")
	print("LIVES bad=", bad)
	get_tree().quit()
