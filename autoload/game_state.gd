extends Node
## The player's Profile and the run in progress (GDD 19.2), plus scene flow between the menu,
## camp and floors. Saves at the moments GDD 11.1 / 19.6 name: entering a floor, finishing it,
## the camp, and when the app goes to the background.

const DUNGEON := "d01"
## MVP: floors 1–10 (GDD 20.1).
const LAST_FLOOR := 10
const MENU_SCENE := "res://scenes/main_menu.tscn"
const CAMP_SCENE := "res://scenes/camp.tscn"
const FLOOR_SCENE := "res://scenes/floor.tscn"
const HERO_SELECT_SCENE := "res://scenes/hero_select.tscn"
const INTRO_SCENE := "res://scenes/intro.tscn"
const FINAL_SCENE := "res://scenes/final.tscn"

var profile: Profile
## The run in progress (null between runs).
var run: RunState:
	get:
		return profile.run if profile != null else null
var hero_look: StringName:
	get:
		return profile.hero_look if profile != null else &"male"
## Saving is off for tests and dev scenes started directly (--nosave).
var saving_enabled: bool = true


func _ready() -> void:
	saving_enabled = DevTools.arg("nosave") == ""
	var loaded: Profile = SaveManager.load_profile() if saving_enabled else null
	profile = loaded if loaded != null else Profile.create(int(Time.get_unix_time_from_system()))


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		save()


func save() -> void:
	if saving_enabled and profile != null:
		SaveManager.save_profile(profile)


func has_run() -> bool:
	return run != null


## Starts a fresh run of the dungeon (keeps gear, gold and records).
func new_run(seed_value: int = 0) -> void:
	Progress.start_run(profile, seed_value if seed_value != 0 else int(Time.get_unix_time_from_system()))


## A new game from the menu: a clean profile with the chosen class and look (GDD 3.4).
func new_game(hero_class: StringName, look: StringName) -> void:
	profile = Profile.create(int(Time.get_unix_time_from_system()))
	profile.hero_class = hero_class
	profile.hero_look = look
	profile.hero_chosen = true
	save()


static func floor_path(index: int) -> String:
	return "res://levels/%s/floor_%02d" % [DUNGEON, index]


static func floor_exists(index: int) -> bool:
	return FileAccess.file_exists(floor_path(index) + ".txt")


# --- scene flow ---

func goto(scene: String) -> void:
	get_tree().change_scene_to_file.call_deferred(scene)


## «Спуск» from the camp: continue the run (its current floor or pending reward) or start one.
func descend() -> void:
	if run == null:
		new_run()
	save()
	goto(FLOOR_SCENE)


func to_camp() -> void:
	save()
	goto(CAMP_SCENE)


func to_menu() -> void:
	save()
	goto(MENU_SCENE)
