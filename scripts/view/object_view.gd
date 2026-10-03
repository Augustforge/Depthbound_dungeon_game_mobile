class_name ObjectView
extends Node3D
## Placeholder 3D look for floor objects and traps (until art track A4).

const CHAR_SHADER := preload("res://shaders/character.gdshader")
const TIER_COLORS := {
	&"wood": Color(0.45, 0.3, 0.17), &"iron": Color(0.35, 0.35, 0.38), &"relic": Color(0.75, 0.6, 0.25),
}

var ent: Entity
var _parts: Dictionary = {}
var _time: float = 0.0


func setup(e: Entity) -> void:
	ent = e
	position = Vector3(e.pos.x, 0.0, e.pos.y)
	if e is SpikeZone:
		for c: Vector2i in e.cells:
			var plate := _box(Vector3(0.95, 0.06, 0.95), Color(0.25, 0.24, 0.23))
			plate.position = Vector3(c.x + 0.5 - e.pos.x, 0.03, c.y + 0.5 - e.pos.y)
			for i in 4:
				var spike := _cone(0.08, 0.5, Color(0.55, 0.55, 0.58))
				spike.position = plate.position + Vector3((i % 2 - 0.5) * 0.45, -0.3, (i / 2 - 0.5) * 0.45)
				_parts[spike] = spike.position.y
		return
	if e is HarpoonWall:
		var slot := _box(Vector3(0.7, 0.5, 0.15), Color(0.2, 0.18, 0.16))
		slot.position = Vector3(0, 1.0, 0)
		rotation.y = atan2(e.dir.x, e.dir.y)
		_parts["harpoon"] = _box(Vector3(0.08, 0.08, 0.6), Color(0.5, 0.45, 0.4))
		_parts["harpoon"].position = Vector3(0, 1.0, 0.2)
		return
	if e is Coin:
		var coin := _cylinder(0.12, 0.03, Color(1.0, 0.8, 0.25), 1.2)
		coin.position.y = 0.3
		_parts["coin"] = coin
		return
	var o := e as FloorObject
	match o.kind:
		FloorObject.Kind.STAIRS:
			var hole := _box(Vector3(1.6, 0.02, 1.6), Color(0.02, 0.02, 0.03))
			hole.position.y = 0.04
			for i in 3:
				var step := _box(Vector3(1.4, 0.08, 0.35), Color(0.3, 0.3, 0.32))
				step.position = Vector3(0, 0.05 - i * 0.12, -0.5 + i * 0.4)
			_parts["glow"] = _box(Vector3(1.0, 0.02, 1.0), Color(0.3, 0.9, 0.85), 0.8)
			_parts["glow"].position.y = 0.06
		FloorObject.Kind.CHEST:
			var col: Color = TIER_COLORS.get(o.tier, Color.BROWN)
			_box(Vector3(0.9, 0.5, 0.6), col).position.y = 0.25
			var lid := _box(Vector3(0.92, 0.18, 0.62), col.lightened(0.15))
			lid.position.y = 0.6
			_parts["lid"] = lid
		FloorObject.Kind.LEVER:
			_box(Vector3(0.3, 0.6, 0.3), Color(0.3, 0.28, 0.26)).position.y = 0.3
			var handle := _box(Vector3(0.08, 0.7, 0.08), Color(0.6, 0.4, 0.2))
			handle.position.y = 0.8
			_parts["handle"] = handle
		FloorObject.Kind.GATE, FloorObject.Kind.LOCK_GATE:
			var bars := Node3D.new()
			add_child(bars)
			for i in 5:
				var bar := _box(Vector3(0.07, 2.1, 0.07), Color(0.28, 0.25, 0.23), 0.0, bars)
				bar.position = Vector3(-0.4 + i * 0.2, 1.05, 0)
			_parts["bars"] = bars
		FloorObject.Kind.VALVE, FloorObject.Kind.FLOOD_VALVE:
			_box(Vector3(0.25, 0.8, 0.25), Color(0.3, 0.3, 0.32)).position.y = 0.4
			var wheel_col := Color(0.55, 0.25, 0.15) if o.kind == FloorObject.Kind.VALVE else Color(0.2, 0.4, 0.6)
			var wheel := _cylinder(0.32, 0.06, wheel_col)
			wheel.position.y = 0.85
			_parts["wheel"] = wheel
		FloorObject.Kind.SPRING:
			_cylinder(0.6, 0.35, Color(0.4, 0.4, 0.42)).position.y = 0.17
			_parts["water"] = _cylinder(0.5, 0.05, Color(0.3, 0.9, 1.0), 1.5)
			_parts["water"].position.y = 0.36
		FloorObject.Kind.NOTE:
			_parts["note"] = _box(Vector3(0.3, 0.02, 0.4), Color(0.85, 0.8, 0.65), 0.4)
			_parts["note"].position.y = 0.05
		FloorObject.Kind.BEAR_TRAP:
			_cylinder(0.32, 0.04, Color(0.35, 0.33, 0.3)).position.y = 0.03
			for i in 6:
				var tooth := _cone(0.04, 0.15, Color(0.6, 0.6, 0.62))
				var a := TAU * i / 6.0
				tooth.position = Vector3(cos(a) * 0.25, 0.1, sin(a) * 0.25)
			_parts["glint"] = _box(Vector3(0.1, 0.02, 0.1), Color(1, 1, 0.9), 2.0)
			_parts["glint"].position.y = 0.08


func _process(delta: float) -> void:
	_time += delta
	if ent == null:
		return
	if ent is Coin:
		if not ent.alive:
			queue_free()
			return
		position = Vector3(ent.pos.x, 0.0, ent.pos.y)
		_parts["coin"].rotation.y += delta * 4.0
		return
	if ent is SpikeZone:
		var z := ent as SpikeZone
		var up := 0.0 if not z.extended() else 1.0
		var shake := 0.03 * sin(_time * 60.0) if z.trembling() else 0.0
		for spike: Node3D in _parts:
			spike.position.y = lerpf(spike.position.y, -0.3 + up * 0.55 + shake, minf(1.0, delta * 25.0))
		return
	if ent is HarpoonWall:
		visible = ent.alive
		return
	var o := ent as FloorObject
	match o.kind:
		FloorObject.Kind.CHEST:
			_parts["lid"].rotation.x = lerpf(_parts["lid"].rotation.x, -1.2 if o.used else 0.0, minf(1.0, delta * 6.0))
		FloorObject.Kind.LEVER:
			_parts["handle"].rotation.z = lerpf(_parts["handle"].rotation.z, 0.8 if o.used else -0.8, minf(1.0, delta * 8.0))
		FloorObject.Kind.GATE, FloorObject.Kind.LOCK_GATE:
			var target := 0.0 if o.closed else (2.0 if o.kind == FloorObject.Kind.GATE else -2.2)
			_parts["bars"].position.y = lerpf(_parts["bars"].position.y, target, minf(1.0, delta * 6.0))
		FloorObject.Kind.VALVE, FloorObject.Kind.FLOOD_VALVE:
			if ent.world.hero.interact_target == o or o.used:
				_parts["wheel"].rotation.y += delta * (4.0 if not o.used else 0.0)
		FloorObject.Kind.SPRING:
			_parts["water"].visible = not o.used
		FloorObject.Kind.NOTE:
			visible = not o.used
		FloorObject.Kind.BEAR_TRAP:
			_parts["glint"].visible = o.armed and fmod(_time, 1.6) < 0.25


func _material(color: Color, emission: float) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = CHAR_SHADER
	mat.set_shader_parameter(&"albedo", color)
	mat.set_shader_parameter(&"emission", emission)
	return mat


func _box(size: Vector3, color: Color, emission: float = 0.0, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.material_override = _material(color, emission)
	(parent if parent else self).add_child(mi)
	return mi


func _cylinder(r: float, h: float, color: Color, emission: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = r
	c.bottom_radius = r
	c.height = h
	c.radial_segments = 16
	mi.mesh = c
	mi.material_override = _material(color, emission)
	add_child(mi)
	return mi


func _cone(r: float, h: float, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.0
	c.bottom_radius = r
	c.height = h
	c.radial_segments = 6
	mi.mesh = c
	mi.material_override = _material(color, 0.0)
	add_child(mi)
	return mi
