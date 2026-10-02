extends Node
## Save files (GDD 19.6): user://save.json with a version field. Snapshot logic arrives in stage 5.

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 1


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func write_json(path: String, data: Dictionary) -> bool:
	var tmp_path := path + ".tmp"
	var f := FileAccess.open(tmp_path, FileAccess.WRITE)
	if f == null:
		push_error("SaveManager: cannot write %s" % tmp_path)
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	# Write-then-rename so a crash mid-write never corrupts the previous save.
	return DirAccess.rename_absolute(tmp_path, path) == OK


func read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
