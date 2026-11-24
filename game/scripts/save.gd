extends Node
## Stores the player's progress on the device. Works fully offline.

const PATH := "user://save.cfg"

var level: int = 1          # next level to play
var best_level: int = 1     # highest level reached
var hints: int = 3          # free hints in the bank
var ads_removed: bool = false
var music_on: bool = true
var sfx_on: bool = true
var vibrate_on: bool = true
var color_blind: bool = false   # draw a shape on every firefly color
var language: String = ""     # "" = the phone's language, else a code like "ar" (see i18n.gd)
var seen: Dictionary = {}     # which new-twist explainer cards were shown
var daily_done: String = ""  # date of the last solved daily puzzle
var streak: int = 0
var coins: int = 0            # earned by solving puzzles, spent on hints, undos, moves and mending jars
var ach: Dictionary = {}      # trophy id -> true
var stats: Dictionary = {}    # hard, pure, daily, best_streak, repairs, earned
var lives: int = 5            # hearts for Hard and Extreme levels
var lives_at: float = 0.0     # unix time the next heart started refilling
var gift_day: int = 0         # daily rewards: days claimed in the current run (0-7)
var gift_last: String = ""    # date of the last claimed daily gift
var map_ch: int = 0          # highest chapter whose opening was celebrated on the map (0 = not set yet)
var updated: int = 0          # unix time of the last save, used to merge with the cloud copy

signal saved

const STAT_KEYS := ["hard", "extreme", "pure", "daily", "best_streak", "repairs", "earned"]

func _ready() -> void:
	load_game()
	_fix_stats()

func load_game() -> void:
	var cfg := ConfigFile.new()
	# the save is written to a side file first and then swapped in; if the phone died in between,
	# the side file still holds the latest progress
	if cfg.load(PATH) != OK:
		cfg = ConfigFile.new()
		if cfg.load(PATH + ".tmp") != OK:
			return
	level = int(cfg.get_value("progress", "level", 1))
	best_level = int(cfg.get_value("progress", "best_level", level))
	hints = int(cfg.get_value("progress", "hints", 3))
	ads_removed = bool(cfg.get_value("shop", "ads_removed", false))
	music_on = bool(cfg.get_value("settings", "music", true))
	sfx_on = bool(cfg.get_value("settings", "sfx", true))
	vibrate_on = bool(cfg.get_value("settings", "vibrate", true))
	color_blind = bool(cfg.get_value("settings", "color_blind", false))
	language = str(cfg.get_value("settings", "language", ""))
	seen = _dict(cfg.get_value("progress", "seen", {}))
	daily_done = str(cfg.get_value("daily", "done", ""))
	streak = int(cfg.get_value("daily", "streak", 0))
	coins = maxi(0, int(cfg.get_value("progress", "coins", 0)))
	map_ch = int(cfg.get_value("progress", "map_ch", 0))
	lives = clampi(int(cfg.get_value("progress", "lives", LIVES_MAX)), 0, LIVES_MAX)
	lives_at = float(cfg.get_value("progress", "lives_at", 0.0))
	gift_day = int(cfg.get_value("progress", "gift_day", 0))
	gift_last = str(cfg.get_value("progress", "gift_last", ""))
	ach = _dict(cfg.get_value("progress", "ach", {}))
	stats = _dict(cfg.get_value("progress", "stats", {}))
	updated = int(cfg.get_value("progress", "updated", 0))
	_fix_stats()

static func _dict(v) -> Dictionary:
	return v if v is Dictionary else {}

func _fix_stats() -> void:
	for k in STAT_KEYS:
		stats[k] = int(stats.get(k, 0))

## Phone vibration, if the player has it turned on.
func buzz(ms: int) -> void:
	if vibrate_on:
		Input.vibrate_handheld(ms)

func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "level", level)
	cfg.set_value("progress", "best_level", best_level)
	cfg.set_value("progress", "hints", hints)
	cfg.set_value("shop", "ads_removed", ads_removed)
	cfg.set_value("settings", "music", music_on)
	cfg.set_value("settings", "sfx", sfx_on)
	cfg.set_value("settings", "vibrate", vibrate_on)
	cfg.set_value("settings", "color_blind", color_blind)
	cfg.set_value("settings", "language", language)
	cfg.set_value("progress", "seen", seen)
	cfg.set_value("daily", "done", daily_done)
	cfg.set_value("daily", "streak", streak)
	cfg.set_value("progress", "coins", coins)
	cfg.set_value("progress", "map_ch", map_ch)
	cfg.set_value("progress", "lives", lives)
	cfg.set_value("progress", "lives_at", lives_at)
	cfg.set_value("progress", "gift_day", gift_day)
	cfg.set_value("progress", "gift_last", gift_last)
	cfg.set_value("progress", "ach", ach)
	cfg.set_value("progress", "stats", stats)
	updated = int(Time.get_unix_time_from_system())
	cfg.set_value("progress", "updated", updated)
	# write a side file, then swap it in, so a crash mid-save never leaves a broken save
	if cfg.save(PATH + ".tmp") == OK and DirAccess.rename_absolute(PATH + ".tmp", PATH) == OK:
		pass
	else:
		cfg.save(PATH)
	saved.emit()

## Progress as plain data, for the cloud copy (Game Center / Play Games). Settings stay on the phone.
func to_dict() -> Dictionary:
	return {"v": 1, "level": level, "best_level": best_level, "hints": hints, "coins": coins, "ads_removed": ads_removed,
		"seen": seen, "daily_done": daily_done, "streak": streak, "ach": ach, "stats": stats, "updated": updated}

## Combine a cloud copy with this phone's progress, so nothing is lost when a player changes phones
## or plays on two. Progress counters take the higher value; coins and hints come from the newer copy.
func merge_cloud(d: Dictionary) -> bool:
	if d.is_empty() or int(d.get("v", 0)) < 1:
		return false
	var before := JSON.stringify(to_dict())
	var newer := int(d.get("updated", 0)) > updated
	level = maxi(level, int(d.get("level", 1)))
	best_level = maxi(best_level, int(d.get("best_level", 1)))
	if newer:
		hints = int(d.get("hints", hints))
		coins = maxi(0, int(d.get("coins", coins)))
		daily_done = str(d.get("daily_done", daily_done))
		streak = int(d.get("streak", streak))
	ads_removed = ads_removed or bool(d.get("ads_removed", false))
	for k in d.get("seen", {}):
		seen[k] = true
	for k in d.get("ach", {}):
		ach[k] = true
	var st: Dictionary = d.get("stats", {})
	for k in STAT_KEYS:
		stats[k] = maxi(int(stats.get(k, 0)), int(st.get(k, 0)))
	if JSON.stringify(to_dict()) == before:
		return false
	save_game()
	return true

func complete_level() -> void:
	var was_hard := Puzzle.is_hard(level)
	var was_extreme := Puzzle.is_extreme(level)
	level += 1
	best_level = max(best_level, level)
	# GUESS: +1 hint for beating each Hard or Extreme level (every 5th), and two early gifts (after levels 4 and 9).
	if was_hard or (level < 10 and level % 5 == 0):
		hints += 1
	if was_hard:
		stats.hard = int(stats.get("hard", 0)) + 1
		if was_extreme:
			stats.extreme = int(stats.get("extreme", 0)) + 1
	save_game()

static func today() -> String:
	return Time.get_date_string_from_system()

static func yesterday() -> String:
	return Time.get_date_string_from_unix_time(int(Time.get_unix_time_from_system()) - 86400 + int(Time.get_time_zone_from_system().bias) * 60)

func complete_daily(date_str: String) -> void:
	if daily_done == date_str:
		return
	streak = streak + 1 if daily_done == yesterday() else 1
	stats.daily = int(stats.get("daily", 0)) + 1
	stats.best_streak = maxi(int(stats.get("best_streak", 0)), streak)
	daily_done = date_str
	hints += 1
	save_game()

# ---------- hearts (lives) ----------
# Only Hard and Extreme levels use hearts: you lose one when you give up on one ("Try again" after running out
# of moves, Restart, or leaving after making moves). 5 at most, one comes back every 20 minutes.
const LIVES_MAX := 5
const LIFE_SECONDS := 20 * 60

func lives_now() -> int:
	# if the phone's clock was moved back, don't make the player wait for hours
	var now := Time.get_unix_time_from_system()
	if lives_at > now:
		lives_at = now
	if lives >= LIVES_MAX:
		lives = LIVES_MAX
		return lives
	var n := int(floor((Time.get_unix_time_from_system() - lives_at) / LIFE_SECONDS))
	if n > 0:
		lives = mini(LIVES_MAX, lives + n)
		lives_at += n * LIFE_SECONDS
		save_game()
	return lives

## Seconds until the next heart comes back (0 when full).
func next_life_in() -> float:
	if lives_now() >= LIVES_MAX:
		return 0.0
	return maxf(0.0, lives_at + LIFE_SECONDS - Time.get_unix_time_from_system())

func add_life(n := 1) -> void:
	lives_now()
	lives = mini(LIVES_MAX, lives + n)
	save_game()

func lose_life() -> void:
	if lives_now() >= LIVES_MAX:
		lives_at = Time.get_unix_time_from_system()
	lives = maxi(0, lives - 1)
	save_game()

# ---------- daily rewards: a 7-day calendar ----------
# Come back each day for the next gift. Missing a day starts again from day 1.
const DAILY_GIFTS := [{"coins": 20}, {"coins": 30}, {"hints": 1}, {"coins": 50}, {"lives": 5}, {"hints": 2}, {"coins": 100}]

## {"day": index of the gift to claim next (0-6), "ready": can it be claimed today}
func gift_state() -> Dictionary:
	if gift_last == today():
		return {"day": gift_day, "ready": false}
	return {"day": gift_day % 7 if gift_last == yesterday() else 0, "ready": true}
