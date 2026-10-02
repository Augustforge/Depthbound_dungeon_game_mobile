class_name RngStreams
extends RefCounted
## Deterministic random streams (decision D7): one generator per (purpose, floor).
## The same run seed always produces the same loot, cards and rolls on a floor.

var run_seed: int
var _streams: Dictionary = {}


func _init(seed_value: int) -> void:
	run_seed = seed_value


func stream(purpose: String, floor_index: int = 0) -> RandomNumberGenerator:
	var key := "%s:%d" % [purpose, floor_index]
	if not _streams.has(key):
		var rng := RandomNumberGenerator.new()
		rng.seed = derive_seed(run_seed, key)
		_streams[key] = rng
	return _streams[key]


## Forgets a stream so the next call restarts it from its seed (used when a floor restarts).
func reset(purpose: String, floor_index: int = 0) -> void:
	_streams.erase("%s:%d" % [purpose, floor_index])


## Stable across platforms and engine versions: two 32-bit FNV-1a hashes combined.
static func derive_seed(seed_value: int, key: String) -> int:
	var text := "%d|%s" % [seed_value, key]
	return (fnv1a32(text, 2166136261) << 31) ^ fnv1a32(text, 84696351)


static func fnv1a32(text: String, offset: int) -> int:
	var h := offset
	for b in text.to_utf8_buffer():
		h = ((h ^ b) * 16777619) & 0xFFFFFFFF
	return h
