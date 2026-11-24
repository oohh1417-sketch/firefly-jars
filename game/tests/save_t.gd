extends Node
## Saving safety, hearts after a clock change, and a fresh first launch.
func _ready():
	var S = get_tree().root.get_node("Save")
	var bad := []
	# atomic save and reload
	S.level = 77; S.coins = 321; S.seen = {"map": true}; S.save_game()
	if FileAccess.file_exists(S.PATH + ".tmp"): bad.append("tmp left behind")
	S.level = 1; S.coins = 0; S.load_game()
	if S.level != 77 or S.coins != 321: bad.append("reload level=%d coins=%d" % [S.level, S.coins])
	# broken main file but a good side file
	DirAccess.copy_absolute(S.PATH, S.PATH + ".tmp")
	var f := FileAccess.open(S.PATH, FileAccess.WRITE); f.store_string("[progress\nlevel=garbage(("); f.close()
	S.level = 1; S.load_game()
	if S.level != 77: bad.append("fallback level=%d" % S.level)
	# wrong types in the file don't crash
	var cfg := ConfigFile.new(); cfg.set_value("progress", "level", 5); cfg.set_value("progress", "seen", "oops"); cfg.set_value("progress", "stats", 3); cfg.save(S.PATH)
	S.load_game(); S._fix_stats()
	if not (S.seen is Dictionary) or S.level != 5: bad.append("types")
	DirAccess.remove_absolute(S.PATH + ".tmp")
	# clock moved back a day: next heart within 20 minutes
	var now := Time.get_unix_time_from_system()
	S.lives = 2; S.lives_at = now + 86400
	var wait: float = S.next_life_in()
	if wait > S.LIFE_SECONDS + 1: bad.append("clock back wait=%d" % wait)
	# clock moved forward: refill but never above max
	S.lives = 1; S.lives_at = now - 10 * 86400
	if S.lives_now() != S.LIVES_MAX: bad.append("forward %d" % S.lives)
	# daily gift: claimed "tomorrow" then clock back -> can claim again but starts at day 1, no crash
	S.gift_last = "2099-01-01"; S.gift_day = 3
	var st: Dictionary = S.gift_state()
	if not st.ready or st.day != 0: bad.append("gift future %s" % st)
	S.gift_last = S.today(); S.gift_day = 7
	if S.gift_state().ready: bad.append("gift claimed today but ready")
	S.gift_last = S.yesterday(); S.gift_day = 7
	if S.gift_state().day != 0: bad.append("after day 7 should wrap %s" % S.gift_state())
	# fresh first launch: no save file at all
	DirAccess.remove_absolute(S.PATH)
	var fresh = load("res://scripts/save.gd").new()
	fresh.load_game()
	if fresh.level != 1 or fresh.lives != 5 or fresh.hints != 3 or fresh.ads_removed: bad.append("fresh defaults")
	fresh.free()
	print("SAVE bad=", bad)
	get_tree().quit()
