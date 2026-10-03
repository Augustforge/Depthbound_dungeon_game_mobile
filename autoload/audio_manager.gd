extends Node
## Sounds and music by id (GDD 18.4, data/audio.json). Buses: Music and SFX, volumes from
## Settings. Sound effects use a small pool of players; music crossfades between two players.
## Vibration (GDD 18.4) also goes through here so the setting is respected in one place.

const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"
const POOL := 12
const FADE := 1.2

var _cfg: Dictionary = {}
var _cache: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _next: int = 0
var _music: Array[AudioStreamPlayer] = []
var _music_id: StringName = &""
var _loops: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _last_played: Dictionary = {}


func _ready() -> void:
	_rng.randomize()
	_cfg = DataDB.load_json("res://data/audio.json") as Dictionary
	for bus in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, &"Master")
	for i in POOL:
		var p := AudioStreamPlayer.new()
		p.bus = &"SFX"
		add_child(p)
		_pool.append(p)
	for i in 2:
		var m := AudioStreamPlayer.new()
		m.bus = &"Music"
		m.volume_db = -80.0
		add_child(m)
		_music.append(m)
	apply_volumes()
	EventBus.settings_changed.connect(apply_volumes)


func apply_volumes() -> void:
	_set_bus(&"Music", Settings.music_volume)
	_set_bus(&"SFX", Settings.sfx_volume)


func _set_bus(bus: StringName, v: float) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i < 0:
		return
	AudioServer.set_bus_mute(i, v <= 0.001)
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(v, 0.001)))


## Plays a sound effect; the same id is not repeated more often than every 50 ms.
func play(sound_id: StringName, volume_offset_db: float = 0.0) -> void:
	var sd: Dictionary = _cfg.get("sfx", {}).get(String(sound_id), {})
	if sd.is_empty():
		return
	var now := Time.get_ticks_msec()
	if now - int(_last_played.get(sound_id, -1000)) < 50:
		return
	_last_played[sound_id] = now
	var files: Array = sd["files"]
	var stream := _load(SFX_DIR + String(files[_rng.randi_range(0, files.size() - 1)]))
	if stream == null:
		return
	var p := _pool[_next]
	_next = (_next + 1) % POOL
	p.stream = stream
	p.volume_db = float(sd.get("volume_db", 0.0)) + volume_offset_db
	var pr: Array = sd.get("pitch", [1.0, 1.0])
	p.pitch_scale = _rng.randf_range(float(pr[0]), float(pr[1]))
	p.play()


## Music with a crossfade; the same id keeps playing.
func play_music(music_id: StringName) -> void:
	if music_id == _music_id:
		return
	_music_id = music_id
	var md: Dictionary = _cfg.get("music", {}).get(String(music_id), {})
	var old := _music[0]
	var new := _music[1]
	_music = [new, old]
	var tw := create_tween().set_parallel()
	tw.tween_property(old, "volume_db", -80.0, FADE)
	if md.is_empty():
		return
	var stream := _load(MUSIC_DIR + String(md["file"]))
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	new.stream = stream
	new.volume_db = -40.0
	new.play()
	tw.tween_property(new, "volume_db", float(md.get("volume_db", 0.0)), FADE)


## A looping layer (rising water, flood) at a 0..1 level; 0 stops it.
func set_loop(loop_id: StringName, level: float) -> void:
	var ld: Dictionary = _cfg.get("loops", {}).get(String(loop_id), {})
	if ld.is_empty():
		return
	var p: AudioStreamPlayer = _loops.get(loop_id)
	if level <= 0.001:
		if p != null:
			p.stop()
		return
	if p == null:
		p = AudioStreamPlayer.new()
		p.bus = &"SFX"
		var stream := _load(SFX_DIR + String(ld["file"]))
		if stream is AudioStreamOggVorbis:
			(stream as AudioStreamOggVorbis).loop = true
		p.stream = stream
		add_child(p)
		_loops[loop_id] = p
	p.volume_db = float(ld.get("volume_db", 0.0)) + linear_to_db(clampf(level, 0.001, 1.0))
	if not p.playing:
		p.play()


func stop_loops() -> void:
	for p: AudioStreamPlayer in _loops.values():
		p.stop()


## Short vibration on phones (GDD 18.4), if enabled in the settings.
func vibrate(ms: int = 40) -> void:
	if Settings.vibration:
		Input.vibrate_handheld(ms)


func _load(path: String) -> AudioStream:
	if not _cache.has(path):
		_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return _cache[path]
