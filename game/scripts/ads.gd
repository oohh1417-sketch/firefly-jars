extends Node
## Ads for Firefly Jars.
##
## Two kinds of ads:
##   * Rewarded video: the player chooses to watch one for +1 hint or +1 undo.
##   * Interstitial: a short full-screen ad between levels, every few levels,
##     never in the first levels, and never if the player bought "Remove ads".
##
## It uses the Poing Studios AdMob plugin (addons/admob, needs Godot 4.5+) when
## the plugin is installed and the game runs on a phone. Anywhere else (the
## editor, a computer, or before the plugin is installed) it falls back to a
## stand-in that gives the reward at once, so the game is always playable.
##
## Until Hatem's own AdMob IDs are filled in below, Google's official TEST ads
## are used. Test ads are safe to tap. Never tap your own REAL ads.

signal reward_granted(kind: String)
signal reward_unavailable(kind: String)   # no ad could load (offline, no fill)

# ---------------- Hatem's AdMob IDs (all filled in 2026-11-23) ----------------
# The App IDs (with a ~) go in Project Settings > Admob > General, Android and iOS sections.
# Android App ID (goes in Project Settings > Admob > General > Android): ca-app-pub-4638827077517403~9720732794
# iOS App ID (Project Settings > Admob > General > iOS): ca-app-pub-4638827077517403~5345092257
const REAL_IDS := {
	"Android": {"rewarded": "ca-app-pub-4638827077517403/8046231035", "interstitial": "ca-app-pub-4638827077517403/5424983308"},
	"iOS": {"rewarded": "ca-app-pub-4638827077517403/2718928914", "interstitial": "ca-app-pub-4638827077517403/9677334916"},
}
# Google's public test units: https://developers.google.com/admob/android/test-ads
const TEST_IDS := {
	"Android": {"rewarded": "ca-app-pub-3940256099942544/5224354917", "interstitial": "ca-app-pub-3940256099942544/1033173712"},
	"iOS": {"rewarded": "ca-app-pub-3940256099942544/1712485313", "interstitial": "ca-app-pub-3940256099942544/4411468910"},
}

# ---------------- how often between-level ads appear ----------------
# GUESS: gentle settings for a calm puzzle game. Easy to tune later.
const FIRST_AD_LEVEL := 6        # no between-level ads before this level
const LEVELS_BETWEEN_ADS := 3    # at most one every 3 finished levels
const MIN_SECONDS_BETWEEN := 90  # and at least 90 seconds apart

var backend := "stub"            # "admob" when the plugin is present on a phone
var _rewarded = null             # RewardedAd from the plugin
var _interstitial = null         # InterstitialAd from the plugin
var _levels_since_ad := 0
var _last_ad_time := -1000.0
var _pending_kind := ""
var _earned := false
var _after_interstitial := Callable()
var _classes := {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.get_name() in ["Android", "iOS"] and _find_plugin():
		backend = "admob"
		_gather_consent_then_start()

# ---------------- what the game calls ----------------

func ads_removed() -> bool:
	return Save.ads_removed

## Called when the $2.99 "Remove ads" purchase succeeds (the store hookup comes later).
## It turns off between-level ads. Rewarded videos stay available because players choose them.
func set_ads_removed(on: bool) -> void:
	Save.ads_removed = on
	Save.save_game()

func is_rewarded_ready() -> bool:
	return backend == "stub" or _rewarded != null

## Show a rewarded video. reward_granted(kind) fires only if the player watched it to the end.
func show_rewarded(kind: String) -> void:
	if backend == "stub" or _rewarded != null:
		Analytics.log_event("ad_impression", {"ad_format": "rewarded", "reward": kind, "level": Save.level})
	if backend == "stub":
		reward_granted.emit(kind)
		return
	if _rewarded == null:
		reward_unavailable.emit(kind)
		_load_rewarded()
		return
	_pending_kind = kind
	_earned = false
	_pause_game_audio(true)
	var listener = _cls("OnUserEarnedRewardListener").new()
	listener.on_user_earned_reward = func(_item) -> void:
		_earned = true
	_rewarded.show(listener)

## True when the next finished level would show a between-level ad.
func interstitial_due(level: int) -> bool:
	var now := Time.get_ticks_msec() / 1000.0
	return not ads_removed() and level >= FIRST_AD_LEVEL \
		and _levels_since_ad + 1 >= LEVELS_BETWEEN_ADS and now - _last_ad_time >= MIN_SECONDS_BETWEEN

## Call after each finished level (not the daily puzzle). Runs `then` right away,
## or after a between-level ad closes if one is due.
func after_level(level: int, then: Callable) -> void:
	var due := interstitial_due(level)
	_levels_since_ad += 1
	if not due:
		then.call()
		return
	_levels_since_ad = 0
	_last_ad_time = Time.get_ticks_msec() / 1000.0
	Analytics.log_event("ad_impression", {"ad_format": "interstitial", "level": level})
	if backend == "stub" or _interstitial == null:
		if backend == "admob":
			_load_interstitial()
		then.call()
		return
	_after_interstitial = then
	_pause_game_audio(true)
	_interstitial.show()

# ---------------- AdMob plugin plumbing ----------------

func _unit(kind: String) -> String:
	var os := OS.get_name()
	var real: String = REAL_IDS.get(os, {}).get(kind, "")
	return real if real != "" and not OS.is_debug_build() and not _is_test_install() else TEST_IDS[os][kind]

## True for iPhone builds that did not come from the App Store (TestFlight or a
## developer install). Those always get Google's TEST ads, so Hatem and his
## testers can tap ads freely without risk to the AdMob account. Apple puts a
## "sandboxReceipt" next to the app for TestFlight and a "receipt" for real
## App Store downloads; with no App Store receipt we stay on test ads.
var _test_install = null
func _is_test_install() -> bool:
	if _test_install == null:
		_test_install = false
		if OS.get_name() == "iOS":
			var dir := OS.get_executable_path().get_base_dir().path_join("StoreKit")
			_test_install = FileAccess.file_exists(dir.path_join("sandboxReceipt")) \
				or not FileAccess.file_exists(dir.path_join("receipt"))
	return _test_install

func _find_plugin() -> bool:
	for c in ProjectSettings.get_global_class_list():
		_classes[c["class"]] = c["path"]
	for need in ["MobileAds", "RewardedAdLoader", "InterstitialAdLoader", "AdRequest"]:
		if not _classes.has(need):
			return false
	return true

func _cls(name: String):
	return load(_classes[name])

func _callbacks(on_closed: Callable):
	var cb = _cls("FullScreenContentCallback").new()
	cb.on_ad_dismissed_full_screen_content = func() -> void:
		_pause_game_audio(false)
		on_closed.call()
	cb.on_ad_failed_to_show_full_screen_content = func(_err) -> void:
		_pause_game_audio(false)
		on_closed.call()
	return cb

func _load_rewarded() -> void:
	if _rewarded:
		_rewarded.destroy()
		_rewarded = null
	var load_cb = _cls("RewardedAdLoadCallback").new()
	load_cb.on_ad_failed_to_load = func(err) -> void:
		push_warning("Rewarded ad failed to load: %s" % err.message)
		_retry_later(_load_rewarded)
	load_cb.on_ad_loaded = func(ad) -> void:
		_retry_wait = 30.0
		_rewarded = ad
		_rewarded.full_screen_content_callback = _callbacks(_on_rewarded_closed)
	_cls("RewardedAdLoader").new().load(_unit("rewarded"), _cls("AdRequest").new(), load_cb)

func _on_rewarded_closed() -> void:
	var kind := _pending_kind
	_pending_kind = ""
	if _earned:
		reward_granted.emit(kind)
	_load_rewarded()   # get the next one ready

func _load_interstitial() -> void:
	if _interstitial:
		_interstitial.destroy()
		_interstitial = null
	var load_cb = _cls("InterstitialAdLoadCallback").new()
	load_cb.on_ad_failed_to_load = func(err) -> void:
		push_warning("Interstitial failed to load: %s" % err.message)
	load_cb.on_ad_loaded = func(ad) -> void:
		_interstitial = ad
		_interstitial.full_screen_content_callback = _callbacks(_on_interstitial_closed)
	_cls("InterstitialAdLoader").new().load(_unit("interstitial"), _cls("AdRequest").new(), load_cb)

func _on_interstitial_closed() -> void:
	var then := _after_interstitial
	_after_interstitial = Callable()
	_load_interstitial()
	if then.is_valid():
		then.call()

## No ad (offline, no fill): try again later, waiting longer each time (30 s up to 5 min),
## so videos come back by themselves when the phone is online again.
var _retry_wait := 30.0
var _retry_queued := {}
func _retry_later(f: Callable) -> void:
	var key := f.get_method()
	if _retry_queued.get(key, false):
		return
	_retry_queued[key] = true
	var wait := _retry_wait
	_retry_wait = minf(_retry_wait * 2.0, 300.0)
	get_tree().create_timer(wait, true).timeout.connect(func() -> void:
		_retry_queued[key] = false
		if key == "_load_rewarded" and _rewarded != null:
			return
		f.call())

## Called when the player asks for a video and none is ready: start loading one now.
func reload_rewarded() -> void:
	if backend == "admob" and _started and _rewarded == null:
		_load_rewarded()

## Game sound is muted while an ad plays, as AdMob recommends.
func _pause_game_audio(paused: bool) -> void:
	AudioServer.set_bus_mute(0, paused)

# ---------------- consent (GDPR in Europe/UK, Apple's tracking prompt on iPhone) ----------------
## Before any ad loads, ask Google's User Messaging Platform whether this player
## must see a consent message. On iPhone the same flow shows Apple's
## "Allow tracking?" prompt (needs the IDFA message published in AdMob >
## Privacy & messaging, and NSUserTrackingUsageDescription in the iOS export).
## Any error simply carries on, so ads (non-personalized if needed) still work.
var _started := false
var _form_open := false
signal privacy_changed   # the consent answer is known, so Settings can show "Privacy choices"

func _gather_consent_then_start() -> void:
	if not (_classes.has("UserMessagingPlatform") and _classes.has("ConsentRequestParameters")):
		_start_ads()
		return
	var ump = _cls("UserMessagingPlatform")
	var params = _cls("ConsentRequestParameters").new()
	params.tag_for_under_age_of_consent = false
	ump.consent_information.update(params,
		func() -> void: _consent_info_ready(),
		func(_err) -> void: _start_ads())
	# safety net: never wait more than 8 seconds for the consent service,
	# but never start ads while the player is still reading the consent message
	get_tree().create_timer(8.0, true).timeout.connect(func() -> void:
		if not _form_open:
			_start_ads())

func _consent_info_ready() -> void:
	var ump = _cls("UserMessagingPlatform")
	var info = ump.consent_information
	# ConsentStatus.REQUIRED == 2
	if info.get_is_consent_form_available() and info.get_consent_status() == 2:
		_form_open = true
		ump.load_consent_form(func(form) -> void: form.show(_consent_done), _consent_done)
	else:
		_start_ads()

## The consent message was answered (or could not be shown): ads can start now.
func _consent_done(_err = null) -> void:
	_form_open = false
	_start_ads()

func _start_ads() -> void:
	if _started:
		return
	_started = true
	privacy_changed.emit()
	_cls("MobileAds").initialize()
	_load_rewarded()
	_load_interstitial()

## True when the player should get a "Privacy choices" button in Settings
## (only in places like Europe where Google says it is required).
func privacy_options_required() -> bool:
	if backend != "admob" or not _classes.has("UserMessagingPlatform"):
		return false
	# PrivacyOptionsRequirementStatus.REQUIRED == 2
	return _cls("UserMessagingPlatform").consent_information.get_privacy_options_requirement_status() == 2

func show_privacy_options() -> void:
	if privacy_options_required():
		_cls("UserMessagingPlatform").show_privacy_options_form(func(_err) -> void: pass)
