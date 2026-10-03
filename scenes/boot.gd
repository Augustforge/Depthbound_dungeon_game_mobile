extends Node
## Entry point: the main menu, or straight into a floor for development (--map=... or --floor=N).

const MENU := "res://scenes/main_menu.tscn"
const FLOOR := "res://scenes/floor.tscn"


func _ready() -> void:
	var floor_arg := DevTools.arg("floor")
	if not floor_arg.is_empty() or not DevTools.arg("map").is_empty():
		if GameState.run == null:
			GameState.new_run()
		if not floor_arg.is_empty():
			GameState.run.floor_index = int(floor_arg)
		get_tree().change_scene_to_file.call_deferred(FLOOR)
		return
	var scene := DevTools.arg("scene")
	get_tree().change_scene_to_file.call_deferred(scene if not scene.is_empty() else MENU)
