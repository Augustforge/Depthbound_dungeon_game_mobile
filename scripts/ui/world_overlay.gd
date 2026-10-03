class_name WorldOverlay
extends Control
## Draws in screen space over the 3D world: enemy HP bars and floating damage numbers (GDD 17.3).
## White = normal, big yellow = crit, red = damage to the hero.

const NUMBER_LIFE := 0.9

var world: World
var camera: Camera3D
## Debug: draw aggro radii (yellow) and attack reach (red).
var show_radii: bool = false
var _numbers: Array[Dictionary] = []


func setup(w: World, cam: Camera3D) -> void:
	world = w
	camera = cam
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	world.damage_dealt.connect(_on_damage)


func _on_damage(target: Combatant, amount: float, crit: bool, _source: Entity) -> void:
	var color := Color(1, 0.3, 0.25) if target == world.hero else (Color(1, 0.85, 0.2) if crit else Color(1, 1, 1))
	_numbers.append({
		"pos": Vector3(target.pos.x, 2.0, target.pos.y), "text": str(roundi(amount)), "color": color,
		"size": 54 if crit else 38, "t": 0.0, "dx": randf_range(-30.0, 30.0),
	})


func _process(delta: float) -> void:
	for n in _numbers:
		n["t"] += delta
	_numbers = _numbers.filter(func(n: Dictionary) -> bool: return n["t"] < NUMBER_LIFE)
	queue_redraw()


func _circle(c: Vector2, r: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 33:
		var a := TAU * i / 32.0
		var p := Vector3(c.x + cos(a) * r, 0.05, c.y + sin(a) * r)
		if camera.is_position_behind(p):
			return
		pts.append(camera.unproject_position(p))
	draw_polyline(pts, color, 2.0)


func _draw() -> void:
	if world == null or camera == null:
		return
	var font := get_theme_default_font()
	if show_radii:
		for e in world.entities:
			if e is Mob and e.alive:
				_circle(e.pos, e.aggro_radius, Color(1, 0.85, 0.2, 0.6))
				_circle(e.pos, e.attack_range + world.hero.radius, Color(1, 0.3, 0.2, 0.7))
		_circle(world.hero.pos, world.hero.stats.get_stat(&"attack_range"), Color(0.4, 1, 0.5, 0.7))
	for e in world.entities:
		if e is Mob and e.alive and (e.hp < e.max_hp or e.state != Mob.State.IDLE):
			var p := Vector3(e.pos.x, 2.3 if e.def_id != &"rat" else 1.0, e.pos.y)
			if camera.is_position_behind(p):
				continue
			var s := camera.unproject_position(p)
			var w := 110.0 if e.elite else 76.0
			var r := Rect2(s - Vector2(w * 0.5, 0), Vector2(w, 10))
			draw_rect(r.grow(2), Color(0, 0, 0, 0.75))
			draw_rect(Rect2(r.position, Vector2(w * e.hp / e.max_hp, 10)), Color(0.85, 0.18, 0.15))
	# Key icon over the key holder (GDD 10.3) and the interaction progress over the hero (GDD 5).
	for e in world.entities:
		if e is Mob and e.alive and e.key_holder:
			var kp := Vector3(e.pos.x, 2.9, e.pos.y)
			if not camera.is_position_behind(kp):
				var ks := camera.unproject_position(kp)
				draw_circle(ks, 22.0, Color(0.1, 0.08, 0.02, 0.85))
				draw_string(font, ks + Vector2(-12, 11), "⚿", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color(1, 0.85, 0.3))
	var hero := world.hero
	if hero.interact_target != null:
		var hp3 := Vector3(hero.pos.x, 2.3, hero.pos.y)
		var hs := camera.unproject_position(hp3)
		var k := 1.0 - hero.interact_left / maxf(hero.interact_total, 0.01)
		draw_rect(Rect2(hs - Vector2(60, 0), Vector2(120, 12)).grow(2), Color(0, 0, 0, 0.8))
		draw_rect(Rect2(hs - Vector2(60, 0), Vector2(120 * k, 12)), Color(0.95, 0.85, 0.4))
	for n in _numbers:
		var p: Vector3 = n["pos"]
		if camera.is_position_behind(p):
			continue
		var k: float = n["t"] / NUMBER_LIFE
		var s := camera.unproject_position(p) + Vector2(n["dx"], -90.0 * k)
		var c: Color = n["color"]
		c.a = 1.0 - k * k
		var text: String = n["text"]
		var size: int = n["size"]
		var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		draw_string_outline(font, s - Vector2(tw * 0.5, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 8, Color(0, 0, 0, c.a))
		draw_string(font, s - Vector2(tw * 0.5, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, c)
