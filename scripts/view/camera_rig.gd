class_name CameraRig
extends Camera3D
## Fixed 3/4 camera (decision D8): looks north and down, follows the target with a little inertia.

@export var pitch_degrees: float = 50.0
@export var distance: float = 15.5
@export var follow_speed: float = 6.0

var target: Node3D
var _focus: Vector3


func _ready() -> void:
	pitch_degrees = float(DevTools.arg("cam_pitch", str(pitch_degrees)))
	distance = float(DevTools.arg("cam_dist", str(distance)))
	fov = 34.0
	near = 1.0
	far = 80.0
	rotation_degrees = Vector3(-pitch_degrees, 0, 0)
	current = true


func snap() -> void:
	if target:
		_focus = target.global_position
		_apply()


func _process(delta: float) -> void:
	if target == null:
		return
	_focus = _focus.lerp(target.global_position, minf(1.0, delta * follow_speed))
	_apply()


func _apply() -> void:
	var p := deg_to_rad(pitch_degrees)
	global_position = _focus + Vector3(0, sin(p) * distance, cos(p) * distance)
