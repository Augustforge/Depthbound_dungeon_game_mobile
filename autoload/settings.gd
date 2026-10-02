extends Node
## Player settings (GDD 17.2 #13), input actions and localization loading.

const SETTINGS_PATH := "user://settings.json"
const STRINGS_PATH := "res://localization/strings.csv"
const LOCALES: Array[String] = ["en", "ru", "es"]

var locale: String = ""
var music_volume: float = 0.8
var sfx_volume: float = 1.0
var vibration: bool = true
var left_handed: bool = false
## Blood effects are disabled in the MVP (GDD 18.1, decision D10).
var gore_enabled: bool = false


func _ready() -> void:
	_register_input_actions()
	load_translations()
	_load()
	if locale.is_empty():
		locale = detect_locale(OS.get_locale_language())
	TranslationServer.set_locale(locale)


static func detect_locale(system_language: String) -> String:
	return system_language if system_language in LOCALES else "en"


func set_locale(new_locale: String) -> void:
	if new_locale not in LOCALES:
		return
	locale = new_locale
	TranslationServer.set_locale(locale)
	save()
	EventBus.language_changed.emit(locale)


func save() -> void:
	SaveManager.write_json(SETTINGS_PATH, {
		"locale": locale,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"vibration": vibration,
		"left_handed": left_handed,
	})
	EventBus.settings_changed.emit()


func _load() -> void:
	var d: Dictionary = SaveManager.read_json(SETTINGS_PATH)
	locale = str(d.get("locale", ""))
	music_volume = float(d.get("music_volume", music_volume))
	sfx_volume = float(d.get("sfx_volume", sfx_volume))
	vibration = bool(d.get("vibration", vibration))
	left_handed = bool(d.get("left_handed", left_handed))


## Loads strings.csv (key,en,ru,es) into TranslationServer. Returns the number of keys.
static func load_translations() -> int:
	var f := FileAccess.open(STRINGS_PATH, FileAccess.READ)
	if f == null:
		push_error("Settings: missing %s" % STRINGS_PATH)
		return 0
	var header := f.get_csv_line()
	var translations: Array[Translation] = []
	for i in range(1, header.size()):
		var t := Translation.new()
		t.locale = header[i].strip_edges()
		translations.append(t)
	var count := 0
	while not f.eof_reached():
		var row := f.get_csv_line()
		if row.size() < 2 or row[0].strip_edges().is_empty() or row[0].begins_with("#"):
			continue
		count += 1
		for i in range(1, mini(row.size(), header.size())):
			translations[i - 1].add_message(row[0].strip_edges(), row[i])
	for t in translations:
		TranslationServer.add_translation(t)
	return count


func _register_input_actions() -> void:
	var keys := {
		&"move_up": [KEY_W, KEY_UP],
		&"move_down": [KEY_S, KEY_DOWN],
		&"move_left": [KEY_A, KEY_LEFT],
		&"move_right": [KEY_D, KEY_RIGHT],
		&"dodge": [KEY_SPACE],
		&"skill_1": [KEY_1],
		&"skill_2": [KEY_2],
		&"skill_3": [KEY_3],
		&"interact": [KEY_E],
		&"pause": [KEY_ESCAPE],
		&"debug_menu": [KEY_F3],
	}
	for action: StringName in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for code: Key in keys[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = code
			InputMap.action_add_event(action, ev)
