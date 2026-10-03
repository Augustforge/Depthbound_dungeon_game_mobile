class_name Accent
extends RefCounted
## Per-floor visual accent (data/accents.json, GDD 16.1): the named accent merged over "default".


static func resolve(accent_name: String) -> Dictionary:
	var table := DataDB.table(&"accents")
	var result: Dictionary = (table.get("default", {}) as Dictionary).duplicate()
	result.merge(table.get(accent_name, {}), true)
	return result


static func color(accent: Dictionary, key: String) -> Color:
	var c: Array = accent.get(key, [1.0, 1.0, 1.0])
	return Color(float(c[0]), float(c[1]), float(c[2]))


## Torch density: the floor json wins over the accent.
static func torch_density(grid: FloorGrid, accent: Dictionary) -> float:
	return float(grid.data.get("torch_density", accent.get("torch_density", 0.55)))
