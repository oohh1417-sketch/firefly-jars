extends Node
## Plays the background music and sound effects.
## All audio was composed in code by tools/make_audio.py, so there is nothing to license.

## Each world (region) can bring its own music and its own versions of these sounds,
## made by tools/make_region_audio.py into res://audio/<region>/.
const REGION_SFX := ["select", "drop", "pour", "twinkle", "jar_done", "win"]

const SFX := ["select", "drop", "pour", "nope", "jar_done", "win", "hint", "whoosh", "unlock", "daily", "tick", "lock", "twinkle", "coin", "repair"]

var _streams := {}
var _base := {}            # the original (firefly night) streams
var _region_cache := {}    # region name -> {"music": stream, sfx name -> stream}
var _region := ""
var _music: AudioStreamPlayer
var _pool: Array[AudioStreamPlayer] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for name in SFX:
		_streams[name] = load("res://audio/sfx_%s.wav" % name)
	_base = _streams.duplicate()
	_music = AudioStreamPlayer.new()
	_base["music"] = _looped(load("res://audio/music.wav"))
	_music.stream = _base["music"]
	_music.volume_db = -5.0
	add_child(_music)
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	apply_settings()

func _looped(music: AudioStreamWAV) -> AudioStreamWAV:
	if music:
		music.loop_mode = AudioStreamWAV.LOOP_FORWARD
		music.loop_begin = 0
		music.loop_end = int(music.get_length() * music.mix_rate)
	return music

func _process(_delta: float) -> void:
	var name: String = Art.THEMES[clampi(Art.region, 0, Art.THEMES.size() - 1)].name
	if name != _region:
		set_region(name)

## Swaps to a world's music and sounds. Worlds without their own folder use the originals.
func set_region(name: String) -> void:
	_region = name
	var set: Dictionary = _base
	if ResourceLoader.exists("res://audio/%s/music.wav" % name):
		if not _region_cache.has(name):
			var d := _base.duplicate()
			d["music"] = _looped(load("res://audio/%s/music.wav" % name))
			for s in REGION_SFX:
				var path := "res://audio/%s/sfx_%s.wav" % [name, s]
				if ResourceLoader.exists(path):
					d[s] = load(path)
			_region_cache[name] = d
		set = _region_cache[name]
	for s in SFX:
		_streams[s] = set[s]
	if _music.stream != set["music"]:
		var was := _music.playing
		_music.stream = set["music"]
		if was:
			_music.play()

func apply_settings() -> void:
	if Save.music_on and not _music.playing:
		_music.play()
	elif not Save.music_on and _music.playing:
		_music.stop()

func play(name: String, pitch := 1.0, volume_db := 0.0) -> void:
	if not Save.sfx_on or not _streams.has(name):
		return
	for p in _pool:
		if not p.playing:
			p.stream = _streams[name]
			p.pitch_scale = pitch
			p.volume_db = volume_db
			p.play()
			return
