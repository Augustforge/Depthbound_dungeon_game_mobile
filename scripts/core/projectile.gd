class_name Projectile
extends Entity
## Hero projectile (Throwing Blade, Cleave wave): flies straight, hits each enemy once,
## pierces up to `pierce` enemies, stops at walls, can fly back to the hero.

var dir: Vector2 = Vector2.DOWN
var speed: float = 16.0
var max_range: float = 8.0
var width: float = 0.5
var coef: float = 1.0
var pierce: int = 3
var returns: bool = false
## Throwing blades break harpoon walls / pull levers (stage 3); waves do not.
var kind: StringName = &"blade"
var _travelled: float = 0.0
var _hit: Dictionary = {}
var _returning: bool = false
var _hits_left: int = 3


func _init() -> void:
	team = Team.HERO
	radius = 0.1


func launch() -> void:
	_hits_left = pierce
	facing = dir


func tick(dt: float) -> void:
	var step := speed * dt
	var from := pos
	if _returning:
		var to_hero := world.hero.pos - pos
		if to_hero.length() <= step:
			alive = false
			world.remove_entity(self)
			return
		dir = to_hero.normalized()
		pos += dir * step
	else:
		var next := pos + dir * step
		if not world.grid.has_line_of_sight(pos, next) or _travelled + step >= max_range:
			_finish_outbound()
			return
		pos = next
		_travelled += step
	facing = dir
	_hit_along(from, pos)


func _seg_dist(a: Vector2, seg: Vector2, p: Vector2) -> float:
	var t := clampf((p - a).dot(seg) / maxf(seg.length_squared(), 1e-6), 0.0, 1.0)
	return (a + seg * t).distance_to(p)


func _finish_outbound() -> void:
	if returns and not _returning:
		_returning = true
		_hit.clear()
		_hits_left = pierce
	else:
		alive = false
		world.remove_entity(self)


func _hit_along(a: Vector2, b: Vector2) -> void:
	var seg := b - a
	if kind == &"blade":
		# Throwing blades pull levers and break harpoon walls from afar (GDD 8.2 #5).
		for o in world.entities:
			if o is FloorObject and o.kind == FloorObject.Kind.LEVER and o.can_interact() \
					and _seg_dist(a, seg, o.pos) <= 0.6:
				o.activate()
			elif o is HarpoonWall and o.alive and not _hit.has(o.id) and _seg_dist(a, seg, o.pos) <= 0.7:
				_hit[o.id] = true
				world.hero.deal_damage(o, coef, {"skill": kind})
	for e in world.entities:
		if not (e is Mob) or not e.alive or _hit.has(e.id) or _hits_left <= 0:
			continue
		var t := clampf((e.pos - a).dot(seg) / maxf(seg.length_squared(), 1e-6), 0.0, 1.0)
		if (a + seg * t).distance_to(e.pos) <= e.radius + width * 0.5:
			_hit[e.id] = true
			_hits_left -= 1
			world.hero.deal_damage(e, coef, {"skill": kind})
	if _hits_left <= 0 and not _returning:
		_finish_outbound()
