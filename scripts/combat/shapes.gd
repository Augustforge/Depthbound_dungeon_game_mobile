class_name Shapes
extends RefCounted
## Hit shapes in the floor plane (GDD 12.1 telegraphs, 8.2 skills).
## shape = {"type": "circle"|"cone"|"line"|"rect", "radius", "angle" (deg), "length", "width"}
## origin = shape anchor, dir = unit facing. Lines/rects start at origin and extend along dir.


static func contains(shape: Dictionary, origin: Vector2, dir: Vector2, p: Vector2, p_radius: float = 0.0) -> bool:
	var d := p - origin
	match String(shape.get("type", "circle")):
		"circle":
			return d.length() <= float(shape["radius"]) + p_radius
		"cone":
			var r := float(shape["radius"])
			if d.length() > r + p_radius:
				return false
			if d.length() <= p_radius + 0.05:
				return true
			var half := deg_to_rad(float(shape["angle"]) * 0.5)
			var ang := absf(dir.angle_to(d))
			# Allow the target's body radius to poke into the cone edge.
			return ang <= half + asin(clampf(p_radius / d.length(), 0.0, 1.0))
		"line", "rect":
			var length := float(shape.get("length", 1.0))
			var width := float(shape.get("width", 1.0))
			var along := d.dot(dir)
			var side := absf(d.dot(Vector2(-dir.y, dir.x)))
			return along >= -p_radius and along <= length + p_radius and side <= width * 0.5 + p_radius
	return false


## Entities of the given team inside a shape.
static func query(world: World, shape: Dictionary, origin: Vector2, dir: Vector2,
		team: Entity.Team) -> Array[Combatant]:
	var out: Array[Combatant] = []
	for e in world.entities:
		if e.alive and e.team == team and e is Combatant and contains(shape, origin, dir, e.pos, e.radius):
			out.append(e)
	return out
