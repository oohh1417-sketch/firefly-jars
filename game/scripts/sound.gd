extends Node
## Plays the background music and sound effects.
## All audio was composed in code by tools/make_audio.py, so there is nothing to license.

const SFX := ["select", "drop", "pour", "nope", "jar_done", "win", "hint", "whoosh", "unlock", "daily", "tick", "lock", "twinkle", "coin", "repair"]

var _streams := {}
var _music: AudioStreamPlayer
var _pool: Array[AudioStreamPlayer] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for name in SFX:
		_streams[name] = load("res://audio/sfx_%s.wav" % name)
	_music = AudioStreamPlayer.new()
	var music: AudioStreamWAV = load("res://audio/music.wav")
	if music:
		music.loop_mode = AudioStreamWAV.LOOP_FORWARD
		music.loop_begin = 0
		music.loop_end = int(music.get_length() * music.mix_rate)
		_music.stream = music
	_music.volume_db = -5.0
	add_child(_music)
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	apply_settings()

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
