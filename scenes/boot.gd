extends Node
## Entry point. Stage 0: goes straight to the tech spike; the main menu replaces it in stage 5.

const FIRST_SCENE := "res://scenes/dev/spike.tscn"


func _ready() -> void:
	get_tree().change_scene_to_file.call_deferred(FIRST_SCENE)
