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
