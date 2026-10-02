extends Node
## Current run state (GDD 19.2). Filled by stage 3–5; kept minimal for now.

var run_seed: int = 0
var floor_index: int = 1
var hero_class: StringName = &"swordsman"
var hero_look: StringName = &"male"
var rng: RngStreams


func _ready() -> void:
	new_run(int(Time.get_unix_time_from_system()))


func new_run(seed_value: int) -> void:
	run_seed = seed_value
	floor_index = 1
	rng = RngStreams.new(run_seed)
