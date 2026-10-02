extends Node
## Loads JSON balance configs from res://data (GDD 19.4). Access: DataDB.table(&"hero_swordsman").

const TABLES: Array[String] = ["hero_swordsman"]

var _tables: Dictionary = {}
var load_errors: PackedStringArray = []


func _ready() -> void:
	reload()


func reload() -> void:
	_tables.clear()
	load_errors.clear()
	for name in TABLES:
		var path := "res://data/%s.json" % name
		var parsed: Variant = load_json(path)
		if parsed == null:
			load_errors.append(path)
			continue
		_tables[StringName(name)] = parsed


func table(name: StringName) -> Dictionary:
	return _tables.get(name, {})


static func load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("DataDB: missing %s" % path)
		return null
	var json := JSON.new()
	var err := json.parse(FileAccess.get_file_as_string(path))
	if err != OK:
		push_error("DataDB: %s:%d %s" % [path, json.get_error_line(), json.get_error_message()])
		return null
	return json.data
