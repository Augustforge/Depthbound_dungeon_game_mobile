extends Node
## Current run (GDD 19.2): RunState for the dungeon in progress plus helpers to move between floors.

const DUNGEON := "d01"
## MVP: floors 1–10 (GDD 20.1).
const LAST_FLOOR := 10

var run: RunState
var hero_class: StringName = &"swordsman"
var hero_look: StringName = &"male"
var rng: RngStreams


func _ready() -> void:
	if run == null:
		new_run(int(Time.get_unix_time_from_system()))


func new_run(seed_value: int) -> void:
	run = RunState.new_run(seed_value)
	rng = RngStreams.new(seed_value)


static func floor_path(index: int) -> String:
	return "res://levels/%s/floor_%02d" % [DUNGEON, index]


static func floor_exists(index: int) -> bool:
	return FileAccess.file_exists(floor_path(index) + ".txt")
