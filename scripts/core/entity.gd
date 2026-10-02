class_name Entity
extends RefCounted
## Base logic object living in the floor plane (decision D2). Views read its state.

enum Team { HERO, ENEMY, NEUTRAL }

var id: int = 0
var def_id: StringName = &""
var team: Team = Team.NEUTRAL
var pos: Vector2 = Vector2.ZERO
var facing: Vector2 = Vector2.DOWN
var radius: float = 0.35
var alive: bool = true
## Free-form animation state for views: &"idle", &"run", &"dodge", &"attack" ...
var anim_state: StringName = &"idle"
var world: World


func tick(_dt: float) -> void:
	pass
