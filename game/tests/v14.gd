extends Node
## v0.14: coins, win-card coins and double, offers (video or coins), cracked jar repair, Remove ads test store,
## trophies, analytics events, cloud-save merge.
var main
func shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/claude-0/shots/gd14_%s.png" % n)
func _ready():
	var S = get_tree().root.get_node("Save")
	S.level = 3; S.hints = 0; S.coins = 0; S.ach = {}; S.stats = {}; S._fix_stats(); S.ads_removed = false
	S.seen = {"color_jar": true, "lid": true, "daily": true, "hard": true, "extreme": true, "coins": true, "map": true, "lives": true, "tutorial": true}
	main = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main)
	await get_tree().create_timer(4.0).timeout
	await shot("menu")
	main._start_level(); await get_tree().create_timer(1.6).timeout
	print("V14 tip=", main.tip_layer.visible, " title=", main.tip_title.text, " extra=", main.board.extra_index(), " jars=", main.state.jars.size(), " rects=", main.board._rects.size())
	await shot("tip")
	main._show_next_tip(); await get_tree().create_timer(0.3).timeout
	await shot("cracked")
	# tap the cracked jar through real input
	var e := InputEventMouseButton.new(); e.button_index = MOUSE_BUTTON_LEFT; e.pressed = true
	e.position = main.board._rects[main.board.extra_index()].get_center()
	main.board._gui_input(e)
	await get_tree().create_timer(0.2).timeout
	print("V14 offer=", main.offer_layer.visible, " title=", main.offer_title.text, " coinbtn=", main.offer_coin_btn.text, " disabled=", main.offer_coin_btn.disabled)
	await shot("offer")
	main.offer_ad_btn.pressed.emit()
	await get_tree().create_timer(0.9).timeout
	await shot("repair1")
	await get_tree().create_timer(0.6).timeout
	await shot("repair2")
	await get_tree().create_timer(1.4).timeout
	print("V14 repaired state=", main.board.extra_state, " jars=", main.state.jars.size(), " flies=", main.board.flies.size(), " rects=", main.board._rects.size(), " repairs=", S.stats.repairs, " mend=", S.ach.has("mend"))
	await shot("fixed")
	# restart keeps the mended jar
	main._restart(); await get_tree().create_timer(1.0).timeout
	print("V14 restart jars=", main.state.jars.size(), " extra=", main.board.extra_state)
	# solve
	var p = Puzzle.solve(main.state)
	for m in p:
		main._on_jar_tapped(m[0]); main._on_jar_tapped(m[1]); await get_tree().create_timer(0.6).timeout
	await get_tree().create_timer(3.4).timeout
	print("V14 win=", main.win_layer.visible, " gain=", main.win_gain_label.text, " total=", main.win_total_label.text, " coins=", S.coins, " double=", main.double_btn.visible)
	await shot("win")
	main.double_btn.pressed.emit(); await get_tree().create_timer(1.4).timeout
	print("V14 doubled coins=", S.coins, " total=", main.win_total_label.text, " doublebtn=", main.double_btn.visible)
	await shot("win2")
	# hint offer with coins
	S.coins = 400; S.hints = 0
	main.next_btn.pressed.emit(); await get_tree().create_timer(1.8).timeout
	if main.tip_layer.visible: main._show_next_tip()
	main._on_hint_pressed(); await get_tree().create_timer(0.2).timeout
	print("V14 hint offer=", main.offer_layer.visible, " btn=", main.offer_coin_btn.text)
	await shot("hintoffer")
	main.offer_coin_btn.pressed.emit(); await get_tree().create_timer(0.3).timeout
	print("V14 bought hint coins=", S.coins, " hints=", S.hints, " hint=", main.board.hint_move)
	# undo offer with coins
	main.undos_left = 0
	var m2 = Puzzle.solve(main.state)[0]
	main._on_jar_tapped(m2[0]); main._on_jar_tapped(m2[1]); await get_tree().create_timer(0.8).timeout
	main._undo(); await get_tree().create_timer(0.2).timeout
	print("V14 undo offer=", main.offer_layer.visible, " title=", main.offer_title.text)
	main.offer_coin_btn.pressed.emit(); await get_tree().create_timer(0.8).timeout
	print("V14 after undo coins=", S.coins, " history=", main.history.size())
	# store
	main._show_menu(); await get_tree().create_timer(0.4).timeout
	main._show_settings(); await get_tree().create_timer(0.4).timeout
	await shot("settings")
	main.remove_ads_btn.pressed.emit(); await get_tree().create_timer(0.4).timeout
	print("V14 test store=", main.store_layer != null and main.store_layer.visible)
	await shot("store")
	Store.confirm_test_purchase(); await get_tree().create_timer(0.5).timeout
	print("V14 bought ads_removed=", S.ads_removed, " btn=", main.remove_ads_btn.text, " due=", Ads.interstitial_due(50))
	await shot("bought")
	main.settings_layer.hide()
	await get_tree().create_timer(2.5).timeout
	main._show_trophies(); await get_tree().create_timer(0.5).timeout
	print("V14 trophies ", main.trophy_count.text)
	await shot("trophies")
	main.trophies_layer.hide()
	# cloud merge
	var d: Dictionary = S.to_dict()
	d.level = S.level + 5; d.coins = 999; d.updated = S.updated + 100; d.ach = {"lv10": true}
	print("V14 merge changed=", S.merge_cloud(d), " level=", S.level, " coins=", S.coins, " lv10=", S.ach.has("lv10"))
	var names := []
	for ev in Analytics.recent:
		if not names.has(ev[0]): names.append(ev[0])
	print("V14 events ", ",".join(names))
	get_tree().quit()
