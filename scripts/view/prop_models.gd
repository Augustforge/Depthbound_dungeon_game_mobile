class_name PropModels
extends RefCounted
## Meshy prop models (art track A4) for objects and decor: loaded once, re-materialled with the
## game's character shader (lit by the baked torch grid) and normalised to a size in metres.
## A missing file simply means the primitive placeholder stays.

const CHAR_SHADER := preload("res://shaders/character.gdshader")
const DIR := "res://assets/models/props/%s.glb"
## id -> {"width": max horizontal size} or {"height": height} in metres, plus a turn in degrees.
const SIZES := {
	"chest_wood": {"width": 0.95}, "chest_iron": {"width": 1.0}, "chest_relic": {"width": 1.05},
	"valve": {"height": 0.95}, "spring": {"width": 1.3}, "bear_trap": {"width": 0.75},
	"lever": {"height": 1.1}, "barrel": {"height": 0.85}, "crate": {"height": 0.65},
	"rack": {"width": 1.9}, "cage": {"height": 1.2}, "weapon_rack": {"height": 1.7}, "table": {"width": 1.3},
}

static var _cache: Dictionary = {}


static func has(id: String) -> bool:
	return ResourceLoader.exists(DIR % id)


## A ready node: the model on the floor, centred, at its size. `tint` multiplies the texture.
static func instance(id: String, tint: Color = Color.WHITE) -> Node3D:
	var d := mesh_data(id)
	if d.is_empty():
		return null
	var holder := Node3D.new()
	var mi := MeshInstance3D.new()
	mi.mesh = d["mesh"]
	mi.transform = d["xform"]
	var mat: ShaderMaterial = (d["material"] as ShaderMaterial).duplicate() if tint != Color.WHITE else d["material"]
	if tint != Color.WHITE:
		mat.set_shader_parameter(&"albedo", tint)
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(mi)
	return holder


## {"mesh", "material", "xform"} — one mesh with the normalising transform (for MultiMesh too).
static func mesh_data(id: String) -> Dictionary:
	if _cache.has(id):
		return _cache[id]
	var out := {}
	if has(id):
		var inst: Node3D = (load(DIR % id) as PackedScene).instantiate()
		var meshes := RiggedModel._all_meshes(inst)
		if not meshes.is_empty():
			var mi: MeshInstance3D = meshes[0]
			var local := _global_xform(mi, inst)
			var aabb := local * mi.get_aabb()
			var size: Dictionary = SIZES.get(id, {"height": 1.0})
			var k := 1.0
			if size.has("height"):
				k = float(size["height"]) / maxf(aabb.size.y, 0.001)
			else:
				k = float(size["width"]) / maxf(maxf(aabb.size.x, aabb.size.z), 0.001)
			var fit := Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * k),
				-Vector3(aabb.get_center().x, aabb.position.y, aabb.get_center().z) * k)
			var src := mi.get_active_material(0) as BaseMaterial3D
			var mat := ShaderMaterial.new()
			mat.shader = CHAR_SHADER
			mat.set_shader_parameter(&"albedo", Color.WHITE)
			if src and src.albedo_texture:
				mat.set_shader_parameter(&"albedo_tex", src.albedo_texture)
			out = {"mesh": mi.mesh, "material": mat, "xform": fit * local}
		inst.free()
	_cache[id] = out
	return out


static func _global_xform(node: Node3D, root: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var n: Node = node
	while n != null and n != root:
		if n is Node3D:
			t = (n as Node3D).transform * t
		n = n.get_parent()
	return t


## Height of the normalised model's top (to put things on it, e.g. the spring's water).
static func top(id: String) -> float:
	var d := mesh_data(id)
	if d.is_empty():
		return 0.0
	var aabb: AABB = (d["xform"] as Transform3D) * (d["mesh"] as Mesh).get_aabb()
	return aabb.end.y
