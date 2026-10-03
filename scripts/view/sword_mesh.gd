class_name SwordMesh
extends RefCounted
## The hero's rusty longsword built from boxes (cheaper than a generated model, reads fine at game scale).
## Local +Y runs from the grip to the tip; the grip is at the origin.

const CHAR_SHADER := preload("res://shaders/character.gdshader")


static func build() -> Node3D:
	var root := Node3D.new()
	_box(root, Vector3(0.035, 0.2, 0.035), Vector3(0, 0.0, 0), Color(0.22, 0.14, 0.09)) # grip
	_box(root, Vector3(0.05, 0.05, 0.05), Vector3(0, -0.12, 0), Color(0.4, 0.33, 0.25)) # pommel
	_box(root, Vector3(0.24, 0.035, 0.05), Vector3(0, 0.11, 0), Color(0.42, 0.35, 0.28)) # crossguard
	_box(root, Vector3(0.055, 0.86, 0.012), Vector3(0, 0.56, 0), Color(0.5, 0.5, 0.49), 0.05) # blade
	return root


## Spiked wooden club (jailer). +Y from grip to head.
static func build_club() -> Node3D:
	var root := Node3D.new()
	_box(root, Vector3(0.05, 0.35, 0.05), Vector3(0, 0.05, 0), Color(0.25, 0.16, 0.1))
	_box(root, Vector3(0.12, 0.4, 0.12), Vector3(0, 0.42, 0), Color(0.35, 0.22, 0.14))
	for i in 4:
		_box(root, Vector3(0.18, 0.03, 0.03), Vector3(0, 0.3 + i * 0.1, 0), Color(0.3, 0.28, 0.26))
	return root


## Tall wooden tower shield (jailer).
static func build_shield() -> Node3D:
	var root := Node3D.new()
	_box(root, Vector3(0.62, 1.05, 0.06), Vector3.ZERO, Color(0.36, 0.25, 0.16))
	for y in [-0.38, 0.0, 0.38]:
		_box(root, Vector3(0.66, 0.06, 0.08), Vector3(0, y, 0), Color(0.25, 0.22, 0.2))
	return root


## Crossbow (crossbowman). Stock along +Y.
static func build_crossbow() -> Node3D:
	var root := Node3D.new()
	_box(root, Vector3(0.06, 0.6, 0.07), Vector3(0, 0.2, 0), Color(0.35, 0.23, 0.13))
	_box(root, Vector3(0.6, 0.04, 0.04), Vector3(0, 0.42, 0), Color(0.3, 0.28, 0.26))
	return root


## Chain with a hooked iron weight (Chain Brute). Hangs along -Y from the hand.
static func build_chain_hook() -> Node3D:
	var root := Node3D.new()
	for i in 8:
		var link := Vector3(0.07, 0.11, 0.03) if i % 2 == 0 else Vector3(0.03, 0.11, 0.07)
		_box(root, link, Vector3(0, -0.1 * i, 0), Color(0.32, 0.2, 0.12))
	_box(root, Vector3(0.18, 0.28, 0.18), Vector3(0, -0.95, 0), Color(0.3, 0.22, 0.16))
	_box(root, Vector3(0.06, 0.3, 0.06), Vector3(0.1, -1.15, 0), Color(0.38, 0.3, 0.24))
	return root


## Merchant's staff with a glowing lantern (Ulm).
static func build_lantern_staff() -> Node3D:
	var root := Node3D.new()
	_box(root, Vector3(0.05, 1.7, 0.05), Vector3(0, 0.2, 0), Color(0.3, 0.2, 0.12))
	_box(root, Vector3(0.16, 0.22, 0.16), Vector3(0.12, 1.0, 0), Color(1.0, 0.65, 0.3), 2.0)
	return root


static func _box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, emission: float = 0.0) -> void:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.position = pos
	var mat := ShaderMaterial.new()
	mat.shader = CHAR_SHADER
	mat.set_shader_parameter(&"albedo", color)
	mat.set_shader_parameter(&"emission", emission)
	mi.material_override = mat
	parent.add_child(mi)
