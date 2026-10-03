class_name CameraRig
extends Camera3D
## Fixed 3/4 camera (decision D8): looks north and down, follows the target with a little inertia.

@export var pitch_degrees: float = 50.0
@export var distance: float = 15.5
@export var follow_speed: float = 6.0

var target: Node3D
## Floor bounds in the xz plane: the camera does not show much of the void past the walls.
var bounds: Rect2 = Rect2()
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
		_focus = _clamped(target.global_position)
		_apply()


func _process(delta: float) -> void:
	if target == null:
		return
	_focus = _focus.lerp(_clamped(target.global_position), minf(1.0, delta * follow_speed))
	_apply()


## Keeps the view over the floor: margins are a bit less than half the visible area, so the
## target always stays on screen.
func _clamped(p: Vector3) -> Vector3:
	if bounds.size == Vector2.ZERO:
		return p
	var half_w := 7.0
	var q := p
	if bounds.size.x > half_w * 2.0:
		q.x = clampf(p.x, bounds.position.x + half_w, bounds.end.x - half_w)
	else:
		q.x = bounds.get_center().x
	var z_lo := bounds.position.y + 4.5
	var z_hi := bounds.end.y - 3.0
	q.z = clampf(p.z, z_lo, z_hi) if z_hi > z_lo else bounds.get_center().y
	return q


func _apply() -> void:
	var p := deg_to_rad(pitch_degrees)
	global_position = _focus + Vector3(0, sin(p) * distance, cos(p) * distance)
