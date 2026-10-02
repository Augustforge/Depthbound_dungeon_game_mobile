extends Node
## Plays sounds by id (GDD 18.4). Sounds arrive in stage 6; until then calls are no-ops.

var _known: Dictionary = {}


func play(sound_id: StringName, _position: Vector3 = Vector3.INF) -> void:
	if not _known.has(sound_id):
		return
