extends TestCase


func test_every_key_has_all_languages() -> void:
	var f := FileAccess.open(Settings.STRINGS_PATH, FileAccess.READ)
	var header := f.get_csv_line()
	assert_eq(Array(header), ["key", "en", "ru", "es"])
	var line := 1
	while not f.eof_reached():
		var row := f.get_csv_line()
		line += 1
		if row.size() < 2 or row[0].is_empty():
			continue
		assert_eq(row.size(), 4, "line %d columns" % line)
		for i in range(1, row.size()):
			assert_false(row[i].strip_edges().is_empty(), "line %d (%s) empty %s" % [line, row[0], header[i]])


func test_detect_locale() -> void:
	assert_eq(Settings.detect_locale("ru"), "ru")
	assert_eq(Settings.detect_locale("zh"), "en")


## Every literal key used in code and data exists in strings.csv (GDD 19.7: no text in code).
func test_all_used_keys_exist() -> void:
	var keys := {}
	var f := FileAccess.open(Settings.STRINGS_PATH, FileAccess.READ)
	f.get_csv_line()
	while not f.eof_reached():
		var row := f.get_csv_line()
		if row.size() > 0 and not row[0].is_empty():
			keys[row[0]] = true
	var re := RegEx.create_from_string("(?:\\btr|TranslationServer\\.translate)\\(\"([A-Z][A-Z0-9_]+)\"")
	var missing: Array[String] = []
	for dir in ["res://scripts", "res://scenes", "res://autoload"]:
		for path in _gd_files(dir):
			for m in re.search_all(FileAccess.get_file_as_string(path)):
				# A key ending with "_" is a prefix completed at run time (e.g. "SLOT_" + slot).
				if not keys.has(m.get_string(1)) and not m.get_string(1).ends_with("_"):
					missing.append("%s: %s" % [path.get_file(), m.get_string(1)])
	# Keys referenced from the data tables.
	var fields := "name_key|desc_key|line|intro|rage|win|defeat|hero_death"
	var key_re := RegEx.create_from_string("\"(?:" + fields + ")\"\\s*:\\s*\"([A-Z][A-Z0-9_]+)\"")
	for path in ["res://data/skills.json", "res://data/bosses.json", "res://data/cards.json", "res://data/mobs.json"]:
		for m in key_re.search_all(FileAccess.get_file_as_string(path)):
			if not keys.has(m.get_string(1)):
				missing.append("%s: %s" % [path.get_file(), m.get_string(1)])
	for i in range(1, GameState.LAST_FLOOR + 1):
		var g := FloorGrid.load_floor(GameState.floor_path(i))
		for k in [String(g.data.get("name_key", ""))] + g.data.get("notes", {}).values():
			if not String(k).is_empty() and not keys.has(String(k)):
				missing.append("floor %d: %s" % [i, k])
	assert_eq(missing, [] as Array[String], "missing keys")


func _gd_files(dir: String) -> Array[String]:
	var out: Array[String] = []
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		out.append_array(_gd_files(dir.path_join(d)))
	return out
