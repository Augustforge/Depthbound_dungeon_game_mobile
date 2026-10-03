class_name TelegraphView
extends MeshInstance3D
## Draws one telegraph on the floor and follows its fill progress.

const SHADER := preload("res://shaders/telegraph.gdshader")

var tel: Telegraph
var _mat: ShaderMaterial


func setup(t: Telegraph) -> void:
	tel = t
	var plane := PlaneMesh.new()
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	var type := String(t.shape.get("type", "circle"))
	var yaw := atan2(t.dir.x, t.dir.y) + PI
	match type:
		"circle":
			var r := float(t.shape["radius"])
			plane.size = Vector2(r * 2.0, r * 2.0)
			position = Vector3(t.origin.x, 0.06, t.origin.y)
		"cone":
			var r := float(t.shape["radius"])
			plane.size = Vector2(r * 2.0, r * 2.0)
			position = Vector3(t.origin.x, 0.06, t.origin.y)
			rotation.y = yaw
			_mat.set_shader_parameter(&"shape_type", 1)
			_mat.set_shader_parameter(&"half_angle", deg_to_rad(float(t.shape["angle"]) * 0.5))
		_:
			var length := float(t.shape.get("length", 1.0))
			var width := float(t.shape.get("width", 1.0))
			plane.size = Vector2(width, length)
			var mid := t.origin + t.dir * length * 0.5
			position = Vector3(mid.x, 0.06, mid.y)
			rotation.y = yaw
			_mat.set_shader_parameter(&"shape_type", 2)
	mesh = plane
	material_override = _mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _process(_delta: float) -> void:
	if tel == null or tel.fired or tel.left <= 0.0 or (tel.source != null and not tel.source.alive):
		queue_free()
		return
	_mat.set_shader_parameter(&"progress", tel.progress())
