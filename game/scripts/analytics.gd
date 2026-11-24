extends Node
## Game statistics for Hatem: how many people play each day and come back, the level where
## players stop, coins earned and spent, video-or-coins choices, ads seen and purchases.
##
## It sends events to Google Firebase Analytics when a Firebase plugin is in the phone build
## (added in the final store build step, together with google-services.json for Android and
## GoogleService-Info.plist for iPhone, both downloaded from Hatem's Firebase project).
## Daily players, returning players and ad revenue per player come from Firebase and AdMob
## automatically once AdMob is linked to the Firebase project.
##
## Without the plugin (computer, editor, test builds) nothing is sent anywhere: events are only
## kept in `recent` so the tests can check them.

var recent: Array = []           # last events: [name, params]
var _fb = null                   # the Firebase plugin, when there is one

# Singleton names used by the common Godot Firebase plugins. GUESS: confirmed when the plugin is
# chosen in the final build step; the first one found is used.
const PLUGIN_NAMES := ["GodotFirebaseAnalytics", "FirebaseAnalytics", "GodotFirebaseAndroid", "Firebase"]

func _ready() -> void:
	for n in PLUGIN_NAMES:
		if Engine.has_singleton(n):
			_fb = Engine.get_singleton(n)
			break

func log_event(name: String, params := {}) -> void:
	recent.append([name, params])
	if recent.size() > 300:
		recent.pop_front()
	if _fb == null:
		return
	# Firebase wants short snake_case names and plain values
	var clean := {}
	for k in params:
		var v = params[k]
		clean[str(k)] = v if (v is int or v is float or v is String) else (1 if v == true else (0 if v == false else str(v)))
	for m in ["log_event", "logEvent"]:
		if _fb.has_method(m):
			_fb.call(m, name, clean)
			return

func has(name: String) -> bool:
	return recent.any(func(e): return e[0] == name)
