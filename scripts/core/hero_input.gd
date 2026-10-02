class_name HeroInput
extends RefCounted
## Intent from the player (joystick, buttons, keyboard) or from the test bot.
## Edge-triggered requests (dodge, skills, interact) are consumed by the hero each tick.

var move: Vector2 = Vector2.ZERO
var dodge_requested: bool = false
var skill_requested: Array[bool] = [false, false, false]
var interact_requested: bool = false


func consume_dodge() -> bool:
	var r := dodge_requested
	dodge_requested = false
	return r
