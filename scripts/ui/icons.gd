class_name Icons
extends RefCounted
## Painted icons (art track A5): skills by id, gear by slot. Null when an icon is missing.

const DIR := "res://assets/ui/icons/%s.webp"

static var _cache: Dictionary = {}


static func skill(id: StringName) -> Texture2D:
	return _icon(String(id))


static func slot(slot_id: StringName) -> Texture2D:
	return _icon("slot_" + String(slot_id))


static func _icon(name: String) -> Texture2D:
	if not _cache.has(name):
		_cache[name] = load(DIR % name) if ResourceLoader.exists(DIR % name) else null
	return _cache[name]
