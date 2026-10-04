class_name DecorView
extends MeshInstance3D
## Static dressing of a floor in one mesh (vertex colours, one draw call): prison bars (|) and the
## accent's decor set (data/accents.json) along the walls. Purely visual — nothing here blocks.
## Placement is a stable hash of the floor id and the cell, so a floor always looks the same.
## Placeholder primitives until the environment art (A4).

const CHAR_SHADER := preload("res://shaders/character.gdshader")
const IRON := Color(0.2, 0.19, 0.18)
const WOOD := Color(0.42, 0.28, 0.16)
const WOOD_DARK := Color(0.28, 0.19, 0.11)
const BONE := Color(0.74, 0.7, 0.6)
const STRAW := Color(0.24, 0.19, 0.1)
## Emissive parts store alpha < 1 (the shader turns 1 - alpha into glow).
const EMBER := Color(1.0, 0.45, 0.12, 0.25)
const FLAME := Color(1.0, 0.8, 0.45, 0.2)
## Tall props are only put against walls the camera looks at (north, east, west).
const TALL := ["chains", "weapon_rack", "cage"]
## Props that may also lie in the open, away from the walls.
const SCATTER := ["bones", "skull", "moss", "grate"]
const MIN_SPACING := 1.8
## _wall_dir result for a corridor cell (walls on two opposite sides): no decor there.
const CORRIDOR := Vector2i(0, 99)

## Extra light sources baked into the light grid like torches (braziers, candles):
## {"pos": Vector2, "intensity": float}.
var lights: Array[Dictionary] = []
var _st: SurfaceTool
var _origin := Vector3.ZERO
var _basis := Basis.IDENTITY
var _count: int = 0
## Decor kinds drawn with Meshy models (A4): kind -> Array[Transform3D], one MultiMesh each.
var _model_xforms: Dictionary = {}
var _prim_vertices: int = 0


func build(grid: FloorGrid, accent: Dictionary, torches: Array[Dictionary]) -> void:
	_st = SurfaceTool.new()
	_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for c: Vector2i in grid.marker_cells(FloorGrid.BARS_CHAR):
		_add_bars(grid, c)
	_place_decor(grid, accent, torches)
	for kind: String in _model_xforms:
		_add_multimesh(kind, _model_xforms[kind])
	if _prim_vertices == 0:
		return
	mesh = _st.commit()
	var mat := ShaderMaterial.new()
	mat.shader = CHAR_SHADER
	mat.set_shader_parameter(&"albedo", Color.WHITE)
	mat.set_shader_parameter(&"vertex_color_mix", 1.0)
	material_override = mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Number of decor props placed (for tests).
func decor_count() -> int:
	return _count


func _add_bars(grid: FloorGrid, c: Vector2i) -> void:
	var along_x := grid.grille_along_x(c)
	_at(Vector3(c.x + 0.5, 0.0, c.y + 0.5), 0.0 if along_x else PI * 0.5)
	for i in 5:
		_box(Vector3(-0.4 + i * 0.2, 1.05, 0.0), Vector3(0.06, 2.1, 0.06), IRON)
	for y in [0.12, 1.15, 2.05]:
		_box(Vector3(0.0, y, 0.0), Vector3(1.0, 0.06, 0.09), IRON.darkened(0.15))


func _place_decor(grid: FloorGrid, accent: Dictionary, torches: Array[Dictionary]) -> void:
	var weights: Dictionary = accent.get("decor", {})
	var density := float(accent.get("decor_density", 0.0))
	if weights.is_empty() or density <= 0.0:
		return
	var busy := _busy_cells(grid, torches)
	var salt := String(grid.data.get("id", "floor"))
	var placed: Array[Vector2] = []
	for y in grid.height:
		for x in grid.width:
			var c := Vector2i(x, y)
			if busy.has(c) or not grid.is_walkable(c):
				continue
			var wall := _wall_dir(grid, c)
			if wall == CORRIDOR:
				continue
			var h := RngStreams.fnv1a32("decor%s%d,%d" % [salt, x, y], 2166136261)
			var chance := density if wall != Vector2i.ZERO else density * 0.2
			if float(h % 10000) / 10000.0 >= chance:
				continue
			var kind := _pick(weights, h / 10000, wall)
			if kind.is_empty():
				continue
			var anchor := Vector2(x + 0.5, y + 0.5) + Vector2(wall) * (0.18 if kind in TALL else 0.12)
			var too_close := false
			for p in placed:
				if p.distance_to(anchor) < MIN_SPACING:
					too_close = true
					break
			if too_close:
				continue
			placed.append(anchor)
			# Local +Z looks into the room, away from the wall.
			var yaw := atan2(-float(wall.x), -float(wall.y)) if wall != Vector2i.ZERO else float(h % 628) / 100.0
			_at(Vector3(anchor.x, 0.0, anchor.y), yaw)
			if PropModels.has(kind):
				var t := Transform3D(_basis, _origin + _basis.z * (0.12 if kind in TALL else 0.25))
				if kind == "skull":
					# A skull reads by its face: turn it to the camera (south), with a little jitter.
					t.basis = Basis(Vector3.UP, float(h % 140) / 100.0 - 0.7)
				if not _model_xforms.has(kind):
					_model_xforms[kind] = []
				_model_xforms[kind].append(t)
			else:
				_build_prop(kind, h)
			if kind == "brazier" or kind == "candles":
				var at := Vector2(_origin.x, _origin.z) + Vector2(_basis.z.x, _basis.z.z) * 0.25
				lights.append({"pos": at, "intensity": 0.9 if kind == "brazier" else 0.45})
			_count += 1


## Cells too close to gameplay things: markers (objects, packs, start, exit), torches, bars.
func _busy_cells(grid: FloorGrid, torches: Array[Dictionary]) -> Dictionary:
	var busy := {}
	var centres: Array[Vector2i] = []
	for ch: String in grid.markers:
		if ch == "~":
			continue
		centres.append_array(grid.markers[ch])
	for t in torches:
		centres.append(FloorGrid.to_cell(t["pos"]))
	for c in centres:
		for oy in range(-1, 2):
			for ox in range(-1, 2):
				busy[c + Vector2i(ox, oy)] = true
	return busy


## Direction from the cell to an adjacent wall (zero if none, or if it is a corridor between two walls).
func _wall_dir(grid: FloorGrid, c: Vector2i) -> Vector2i:
	var left := grid.is_wall(c + Vector2i(-1, 0))
	var right := grid.is_wall(c + Vector2i(1, 0))
	var up := grid.is_wall(c + Vector2i(0, -1))
	var down := grid.is_wall(c + Vector2i(0, 1))
	if (left and right) or (up and down):
		return CORRIDOR
	if up:
		return Vector2i(0, -1)
	if left:
		return Vector2i(-1, 0)
	if right:
		return Vector2i(1, 0)
	if down:
		return Vector2i(0, 1)
	return Vector2i.ZERO


func _pick(weights: Dictionary, h: int, wall: Vector2i) -> String:
	var options: Array[String] = []
	var total := 0
	for kind: String in weights:
		if wall == Vector2i.ZERO and not kind in SCATTER:
			continue
		if wall == Vector2i(0, 1) and kind in TALL:
			continue
		options.append(kind)
		total += int(weights[kind])
	if total <= 0:
		return ""
	var roll := h % total
	for kind in options:
		roll -= int(weights[kind])
		if roll < 0:
			return kind
	return ""


func _build_prop(kind: String, h: int) -> void:
	var v := float(h % 97) / 97.0
	match kind:
		"barrel":
			_cyl(Vector3(0, 0, 0.1), 0.3, 0.78, WOOD)
			_cyl(Vector3(0, 0.14, 0.1), 0.315, 0.06, IRON)
			_cyl(Vector3(0, 0.6, 0.1), 0.315, 0.06, IRON)
			if v > 0.5:
				_cyl(Vector3(0.62, 0, 0.0), 0.26, 0.66, WOOD.darkened(0.1))
		"crate":
			_box(Vector3(0, 0.3, 0.1), Vector3(0.62, 0.6, 0.62), WOOD.lightened(0.08))
			_box(Vector3(0, 0.3, 0.42), Vector3(0.64, 0.08, 0.02), WOOD_DARK)
			if v > 0.45:
				_box(Vector3(0.1, 0.8, 0.05), Vector3(0.42, 0.4, 0.42), WOOD)
		"bucket":
			_cyl(Vector3(0, 0, 0.15), 0.17, 0.32, WOOD_DARK)
			_cyl(Vector3(0, 0.24, 0.15), 0.18, 0.04, IRON)
		"straw":
			_box(Vector3(0, 0.05, 0.25), Vector3(1.1, 0.1, 0.7), STRAW)
			_box(Vector3(0.15, 0.09, 0.3), Vector3(0.7, 0.08, 0.5), STRAW.lightened(0.12), 0.3)
		"bones":
			for i in 4:
				var a := v * 6.0 + i * 1.7
				_box(Vector3(cos(a) * 0.25, 0.03, sin(a) * 0.25 + 0.2), Vector3(0.36, 0.05, 0.05), BONE, a)
		"skull":
			_box(Vector3(0, 0.09, 0.2), Vector3(0.2, 0.18, 0.22), BONE)
			_box(Vector3(-0.05, 0.11, 0.31), Vector3(0.05, 0.05, 0.01), Color(0.05, 0.05, 0.05))
			_box(Vector3(0.05, 0.11, 0.31), Vector3(0.05, 0.05, 0.01), Color(0.05, 0.05, 0.05))
		"chains":
			for side in [-0.3, 0.3]:
				var length := 5 + int(v * 4.0) if side < 0 else 7 - int(v * 3.0)
				for i in length:
					_box(Vector3(side, 2.05 - i * 0.16, -0.32), Vector3(0.05, 0.14, 0.05 if i % 2 == 0 else 0.1), IRON)
				_box(Vector3(side, 2.0 - length * 0.16, -0.32), Vector3(0.16, 0.08, 0.12), IRON.lightened(0.1))
		"table":
			_box(Vector3(0, 0.75, 0.2), Vector3(1.2, 0.08, 0.62), WOOD)
			for lx in [-0.52, 0.52]:
				for lz in [-0.05, 0.45]:
					_box(Vector3(lx, 0.36, lz), Vector3(0.07, 0.72, 0.07), WOOD_DARK)
			_cyl(Vector3(0.75, 0, 0.6), 0.18, 0.45, WOOD_DARK)
			_cyl(Vector3(-0.2, 0.79, 0.2), 0.07, 0.14, Color(0.5, 0.48, 0.45))
		"weapon_rack":
			for px in [-0.55, 0.55]:
				_box(Vector3(px, 0.7, -0.3), Vector3(0.08, 1.4, 0.08), WOOD_DARK)
			_box(Vector3(0, 1.25, -0.3), Vector3(1.2, 0.07, 0.07), WOOD_DARK)
			_box(Vector3(0, 0.25, -0.3), Vector3(1.2, 0.07, 0.07), WOOD_DARK)
			for i in 3:
				var sx := -0.32 + i * 0.32
				_box(Vector3(sx, 0.85, -0.22), Vector3(0.04, 1.7, 0.04), WOOD)
				_box(Vector3(sx, 1.76, -0.22), Vector3(0.07, 0.16, 0.02), Color(0.55, 0.55, 0.58))
		"rack":
			_box(Vector3(0, 0.6, 0.45), Vector3(0.75, 0.1, 1.7), WOOD)
			for lz in [-0.3, 1.2]:
				for lx in [-0.32, 0.32]:
					_box(Vector3(lx, 0.3, lz), Vector3(0.08, 0.6, 0.08), WOOD_DARK)
				_box(Vector3(0, 0.72, lz), Vector3(0.9, 0.12, 0.12), WOOD_DARK)
			_box(Vector3(-0.15, 0.68, 0.45), Vector3(0.02, 0.02, 1.4), Color(0.5, 0.42, 0.3))
			_box(Vector3(0.15, 0.68, 0.45), Vector3(0.02, 0.02, 1.4), Color(0.5, 0.42, 0.3))
		"brazier":
			for i in 3:
				var a := TAU * i / 3.0
				_box(Vector3(cos(a) * 0.22, 0.3, sin(a) * 0.22 + 0.3), Vector3(0.05, 0.6, 0.05), IRON, a)
			_cyl(Vector3(0, 0.55, 0.3), 0.34, 0.16, IRON)
			_cyl(Vector3(0, 0.68, 0.3), 0.28, 0.06, EMBER)
		"cage":
			var top := 2.0
			_box(Vector3(0, top + 0.2, 0.3), Vector3(0.04, 0.4, 0.04), IRON)
			_cyl(Vector3(0, top - 0.05, 0.3), 0.42, 0.06, IRON)
			_cyl(Vector3(0, top - 1.1, 0.3), 0.42, 0.06, IRON)
			for i in 8:
				var a := TAU * i / 8.0
				_box(Vector3(cos(a) * 0.4, top - 0.55, sin(a) * 0.4 + 0.3), Vector3(0.035, 1.05, 0.035), IRON)
			if v > 0.5:
				_box(Vector3(0, top - 0.95, 0.3), Vector3(0.22, 0.2, 0.25), BONE)
		"pipe":
			_prism_x(Vector3(0, 0.55, -0.28), 0.2, 1.4, Color(0.3, 0.27, 0.22))
			for px in [-0.45, 0.45]:
				_prism_x(Vector3(px, 0.55, -0.28), 0.25, 0.08, IRON)
			if v > 0.6:
				_cyl(Vector3(0, 0, 0.15), 0.3, 0.02, Color(0.12, 0.3, 0.3))
		"grate":
			_box(Vector3(0, 0.012, 0.2), Vector3(0.8, 0.02, 0.8), Color(0.03, 0.03, 0.035))
			for i in 4:
				_box(Vector3(-0.3 + i * 0.2, 0.03, 0.2), Vector3(0.05, 0.03, 0.8), IRON.lightened(0.1))
		"moss":
			_box(Vector3(0, 0.012, 0.18), Vector3(1.0, 0.02, 0.5), Color(0.14, 0.24, 0.11), v)
			_box(Vector3(0.25, 0.015, 0.3), Vector3(0.5, 0.02, 0.4), Color(0.18, 0.3, 0.13), v + 0.6)
		"candles":
			_cyl(Vector3(0, 0, 0.2), 0.22, 0.02, Color(0.8, 0.76, 0.62))
			for i in 3:
				var a := v * 6.0 + i * 2.1
				var hgt := 0.14 + 0.08 * i
				var p := Vector3(cos(a) * 0.1, 0, sin(a) * 0.1 + 0.2)
				_cyl(p, 0.035, hgt, Color(0.85, 0.82, 0.7))
				_box(p + Vector3(0, hgt + 0.035, 0), Vector3(0.03, 0.06, 0.03), FLAME)


func _at(origin: Vector3, yaw: float) -> void:
	_origin = origin
	_basis = Basis(Vector3.UP, yaw)


## Axis-aligned box in prop space, optionally turned around Y by `yaw`.
func _box(center: Vector3, size: Vector3, col: Color, yaw: float = 0.0) -> void:
	var b := Basis(Vector3.UP, yaw)
	var hs := size * 0.5
	var faces := [
		[Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1)],
		[Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, -1)],
		[Vector3(0, 1, 0), Vector3(0, 0, 1), Vector3(1, 0, 0)],
		[Vector3(0, -1, 0), Vector3(0, 0, -1), Vector3(1, 0, 0)],
		[Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 1, 0)],
		[Vector3(0, 0, -1), Vector3(-1, 0, 0), Vector3(0, 1, 0)],
	]
	for f in faces:
		var n: Vector3 = f[0]
		var u: Vector3 = f[1]
		var w: Vector3 = f[2]
		var c := n * hs
		var du := u * hs
		var dw := w * hs
		_quad([c - du - dw, c - du + dw, c + du + dw, c + du - dw], n, col, center, b)


## Vertical 8-sided prism standing on `base`.
func _cyl(base: Vector3, r: float, height: float, col: Color) -> void:
	var seg := 8
	for i in seg:
		var a0 := TAU * i / seg
		var a1 := TAU * (i + 1) / seg
		var p0 := Vector3(cos(a0) * r, 0, sin(a0) * r)
		var p1 := Vector3(cos(a1) * r, 0, sin(a1) * r)
		var n := Vector3(cos((a0 + a1) * 0.5), 0, sin((a0 + a1) * 0.5))
		var up := Vector3(0, height, 0)
		_quad([p0, p0 + up, p1 + up, p1], n, col, base, Basis.IDENTITY)
		_tri([up, p1 + up, p0 + up], Vector3.UP, col, base)


## Horizontal 8-sided prism along local X.
func _prism_x(center: Vector3, r: float, length: float, col: Color) -> void:
	var seg := 8
	var hx := Vector3(length * 0.5, 0, 0)
	for i in seg:
		var a0 := TAU * i / seg
		var a1 := TAU * (i + 1) / seg
		var p0 := Vector3(0, cos(a0) * r, sin(a0) * r)
		var p1 := Vector3(0, cos(a1) * r, sin(a1) * r)
		var n := Vector3(0, cos((a0 + a1) * 0.5), sin((a0 + a1) * 0.5))
		_quad([p0 - hx, p0 + hx, p1 + hx, p1 - hx], n, col, center, Basis.IDENTITY)


func _quad(pts: Array, n: Vector3, col: Color, offset: Vector3, b: Basis) -> void:
	var order := [0, 1, 2, 0, 2, 3]
	# Keep Godot's clockwise front faces: flip the winding if it faces away from the normal.
	var face_n: Vector3 = (pts[1] - pts[0]).cross(pts[2] - pts[0])
	if face_n.dot(n) > 0.0:
		order = [0, 2, 1, 0, 3, 2]
	for i in order:
		_vertex(b * pts[i] + offset, b * n, col)


func _tri(pts: Array, n: Vector3, col: Color, offset: Vector3) -> void:
	var order := [0, 1, 2]
	var face_n: Vector3 = (pts[1] - pts[0]).cross(pts[2] - pts[0])
	if face_n.dot(n) > 0.0:
		order = [0, 2, 1]
	for i in order:
		_vertex(pts[i] + offset, n, col)


func _vertex(local: Vector3, n: Vector3, col: Color) -> void:
	_prim_vertices += 1
	_st.set_color(col)
	_st.set_normal(_basis * n)
	_st.add_vertex(_basis * local + _origin)


func _add_multimesh(kind: String, xforms: Array) -> void:
	var d := PropModels.mesh_data(kind)
	if d.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = d["mesh"]
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, (xforms[i] as Transform3D) * (d["xform"] as Transform3D))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = d["material"]
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
