extends Node
## Save files (GDD 19.6): user://save.json holds the Profile (meta progress + the run in progress)
## with a version field. Writes are atomic: write to .tmp, then rename.

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := Profile.VERSION


func has_save(path: String = SAVE_PATH) -> bool:
	return FileAccess.file_exists(path)


func save_profile(p: Profile, path: String = SAVE_PATH) -> bool:
	return write_json(path, p.to_dict())


## Returns null when there is no save or it cannot be read.
func load_profile(path: String = SAVE_PATH) -> Profile:
	var d := read_json(path)
	if d.is_empty():
		return null
	# TODO(design): migrations when SAVE_VERSION grows; version 1 is the first format.
	return Profile.from_dict(d)


func delete_save(path: String = SAVE_PATH) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func write_json(path: String, data: Dictionary) -> bool:
	var tmp_path := path + ".tmp"
	var f := FileAccess.open(tmp_path, FileAccess.WRITE)
	if f == null:
		push_error("SaveManager: cannot write %s" % tmp_path)
		return false
	f.store_string(JSON.stringify(data, "\t", true, true))
	f.close()
	# Write-then-rename so a crash mid-write never corrupts the previous save.
	return DirAccess.rename_absolute(tmp_path, path) == OK


func read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
