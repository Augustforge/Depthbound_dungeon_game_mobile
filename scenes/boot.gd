extends Node
## Entry point. Stage 3: goes straight into floor 1 of a new run; the main menu replaces it in stage 5.

const FIRST_SCENE := "res://scenes/floor.tscn"


func _ready() -> void:
	get_tree().change_scene_to_file.call_deferred(FIRST_SCENE)
