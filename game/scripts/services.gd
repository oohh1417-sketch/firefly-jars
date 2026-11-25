extends Node
## Trophies, leaderboards and the cloud copy of the player's progress.
##
## Trophies are kept on the phone (Save.ach) and shown on the Trophies card, so they work fully
## offline and without any sign-in. When the player is signed in, they are also sent to:
##   * iPhone:  Apple Game Center (singleton "GameCenter"), progress copy in iCloud (singleton "ICloud")
##   * Android: Google Play Games Services (singleton "GodotPlayGameServices"), progress copy in Saved Games
## The plugins are added in the final store build step. Without them nothing is sent anywhere.
##
## Hatem creates the achievements and leaderboards in App Store Connect and Play Console.
## iPhone IDs are the names below (type them exactly the same in App Store Connect).
## Android IDs are made by Play Console (they look like "CgkI..."); paste them into ANDROID_IDS.

signal changed   # a cloud copy was merged in: refresh the screens

## [id, name, how to get it]. The check itself is in trophy_earned().
const TROPHIES := [
	["first", "First glow", "Finish level 1"],
	["lv10", "Night walker", "Reach level 10"],
	["lv25", "Lantern keeper", "Reach level 25"],
	["lv50", "Starlight", "Reach level 50"],
	["lv100", "Jar master", "Reach level 100"],
	["hard1", "Brave heart", "Beat a hard level"],
	["hard10", "Unshakable", "Beat 10 hard levels"],
	["extreme1", "Fearless", "Beat an Extreme level"],
	["pure", "Pure skill", "Beat a hard level without a hint"],
	["daily1", "Early bird", "Solve a daily puzzle"],
	["streak7", "Week of light", "Reach a 7-day daily streak"],
	["mend", "Jar mender", "Mend a cracked jar"],
	["rich", "Treasure jar", "Hold 500 coins at once"],
]
## Leaderboards: highest level reached, hard levels beaten, best daily streak.
const BOARDS := ["highest_level", "hard_beaten", "best_streak"]

const IOS_PREFIX := "fireflyjars."   # App Store Connect IDs: fireflyjars.first, fireflyjars.highest_level, ...
const ANDROID_IDS := {
	# "first": "CgkI...",   <- fill in from Play Console > Play Games Services > Achievements / Leaderboards
}
const SAVE_NAME := "firefly_jars_progress"

var backend := "none"   # "apple", "play" or "none"
var signed_in := false
var _gc = null
var _icloud = null
var _pgs = null
var _upload_pending := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.get_name() == "iOS" and Engine.has_singleton("GameCenter"):
		backend = "apple"
		_gc = Engine.get_singleton("GameCenter")
		if Engine.has_singleton("ICloud"):
			_icloud = Engine.get_singleton("ICloud")
		_gc.authenticate()
	elif OS.get_name() == "Android" and Engine.has_singleton("GodotPlayGameServices"):
		backend = "play"
		_pgs = Engine.get_singleton("GodotPlayGameServices")
		for sig in [["userAuthenticated", _on_play_auth], ["gameLoaded", _on_play_loaded]]:
			if _pgs.has_signal(sig[0]):
				_pgs.connect(sig[0], sig[1])
		_call(_pgs, "initialize")
		_call(_pgs, "isAuthenticated")
	Save.saved.connect(func(): _upload_pending = true)

static func trophy_earned(id: String) -> bool:
	var st: Dictionary = Save.stats
	match id:
		"first": return Save.level > 1
		"lv10": return Save.level >= 10
		"lv25": return Save.level >= 25
		"lv50": return Save.level >= 50
		"lv100": return Save.level >= 100
		"hard1": return int(st.get("hard", 0)) >= 1
		"hard10": return int(st.get("hard", 0)) >= 10
		"extreme1": return int(st.get("extreme", 0)) >= 1
		"pure": return int(st.get("pure", 0)) >= 1
		"daily1": return int(st.get("daily", 0)) >= 1
		"streak7": return int(st.get("best_streak", 0)) >= 7
		"mend": return int(st.get("repairs", 0)) >= 1
		"rich": return Save.coins >= 500
	return false

## Unlocks any trophies the player has earned. Returns the names of the new ones (for the toast).
func check_trophies() -> Array:
	var fresh := []
	for t in TROPHIES:
		if not Save.ach.has(t[0]) and trophy_earned(t[0]):
			Save.ach[t[0]] = true
			fresh.append(t[1])
			Analytics.log_event("unlock_achievement", {"achievement_id": t[0]})
			_send_trophy(t[0])
	if not fresh.is_empty():
		Save.save_game()
	return fresh

## Sends scores after a level; the stores keep only the best one.
func submit_scores() -> void:
	_send_score("highest_level", Save.best_level - 1)
	_send_score("hard_beaten", int(Save.stats.get("hard", 0)))
	_send_score("best_streak", int(Save.stats.get("best_streak", 0)))

func show_leaderboards() -> void:
	if backend == "apple":
		_gc.show_game_center({"view": "leaderboards"})
	elif backend == "play":
		_call(_pgs, "showAllLeaderboards")

func can_show_boards() -> bool:
	return backend != "none" and signed_in

# ---------------- sending ----------------

func _id(key: String) -> String:
	return IOS_PREFIX + key if backend == "apple" else str(ANDROID_IDS.get(key, ""))

func _send_trophy(key: String) -> void:
	if not signed_in or _id(key) == "":
		return
	if backend == "apple":
		_gc.award_achievement({"name": _id(key), "progress": 100.0, "show_completion_banner": true})
	elif backend == "play":
		_call(_pgs, "unlockAchievement", [_id(key)])

func _send_score(key: String, value: int) -> void:
	if not signed_in or _id(key) == "" or value <= 0:
		return
	if backend == "apple":
		_gc.post_score({"score": value, "category": _id(key)})
	elif backend == "play":
		_call(_pgs, "submitScore", [_id(key), value])

# ---------------- cloud copy of progress ----------------
# Uploaded a few seconds after progress changes; merged in when the game starts (see Save.merge_cloud).

var _since := 0.0
func _process(delta: float) -> void:
	if _gc != null:
		while _gc.get_pending_event_count() > 0:
			var e: Dictionary = _gc.pop_pending_event()
			if e.get("type", "") == "authentication":
				signed_in = e.get("result", "") == "ok"
				if signed_in:
					_after_sign_in()
	_since += delta
	if _upload_pending and _since > 5.0:
		_since = 0.0
		_upload_pending = false
		_upload()

func _after_sign_in() -> void:
	_download()
	for t in TROPHIES:   # trophies earned while offline or before signing in
		if Save.ach.has(t[0]):
			_send_trophy(t[0])
	submit_scores()

func _upload() -> void:
	if not signed_in:
		return
	var data := JSON.stringify(Save.to_dict())
	if backend == "apple" and _icloud != null:
		_icloud.set_key_values({SAVE_NAME: data})
		_call(_icloud, "synchronize_key_values")
	elif backend == "play":
		_call(_pgs, "saveGame", [SAVE_NAME, "Level %d" % Save.level, data, 0, Save.level])

func _download() -> void:
	if backend == "apple" and _icloud != null:
		_call(_icloud, "synchronize_key_values")
		var all = _icloud.get_all_key_values()
		if all is Dictionary and all.has(SAVE_NAME):
			_merge(str(all[SAVE_NAME]))
	elif backend == "play":
		_call(_pgs, "loadGame", [SAVE_NAME, true])

func _merge(text: String) -> void:
	var d = JSON.parse_string(text)
	if d is Dictionary and Save.merge_cloud(d):
		changed.emit()

func _on_play_auth(ok: bool) -> void:
	signed_in = ok
	if ok:
		_after_sign_in()

func _on_play_loaded(snapshot) -> void:
	var d = JSON.parse_string(str(snapshot)) if snapshot is String else snapshot
	if d is Dictionary:
		var content = d.get("content", d.get("data", ""))
		if content is String and content != "":
			_merge(content)

func _call(obj, method: String, args := []) -> void:
	if obj != null and obj.has_method(method):
		obj.callv(method, args)
