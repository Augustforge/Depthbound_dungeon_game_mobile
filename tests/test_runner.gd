extends Node
## Discovers res://tests/unit/test_*.gd, runs every test_* method, prints a summary and exits
## with code 1 if anything failed. Run: tools/run_tests.sh [filter]

const UNIT_DIR := "res://tests/unit"


func _ready() -> void:
	var filter := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--filter="):
			filter = a.trim_prefix("--filter=")
	var total := 0
	var failed: PackedStringArray = []
	var files := DirAccess.get_files_at(UNIT_DIR)
	for file in files:
		if not (file.begins_with("test_") and file.ends_with(".gd")):
			continue
		var script: GDScript = load(UNIT_DIR + "/" + file)
		if script == null or not script.can_instantiate():
			failed.append("%s: failed to load" % file)
			continue
		for m in script.get_script_method_list():
			var name: String = m["name"]
			if not name.begins_with("test_"):
				continue
			if not filter.is_empty() and not (file + ":" + name).contains(filter):
				continue
			var tc: TestCase = script.new()
			tc._current = "%s:%s" % [file.get_basename(), name]
			tc.before_each()
			tc.call(name)
			tc.cleanup()
			total += 1
			if tc.failures.is_empty():
				print("  ok   ", tc._current)
			else:
				for f in tc.failures:
					print("  FAIL ", f)
				failed.append_array(tc.failures)
	print("\n%d tests, %d failures" % [total, failed.size()])
	if total == 0:
		print("No tests found.")
	get_tree().quit(1 if not failed.is_empty() or total == 0 else 0)
