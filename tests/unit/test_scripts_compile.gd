extends TestCase
## Every script in the project must load and compile (catches parse errors early).

const SKIP_DIRS := ["res://.godot", "res://addons"]


func test_all_scripts_compile() -> void:
	var bad: PackedStringArray = []
	for path in _collect("res://"):
		var s: Script = load(path)
		if s == null or not s.can_instantiate():
			bad.append(path)
	assert_true(bad.is_empty(), "scripts failed to compile: %s" % [bad])


func _collect(dir: String) -> PackedStringArray:
	var out: PackedStringArray = []
	for d in DirAccess.get_directories_at(dir):
		var sub := dir.path_join(d)
		if sub in SKIP_DIRS or FileAccess.file_exists(sub.path_join(".gdignore")):
			continue
		out.append_array(_collect(sub))
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	return out
