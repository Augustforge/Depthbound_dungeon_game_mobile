class_name Bot
extends RefCounted
## Test bot (GDD 19.8): plays a floor through HeroInput, faster than real time.
## RUSH: shortest way to the stairs, fights only what blocks it, does the floor goal.
## CLEAR: kills every pack and opens every chest, then leaves.

enum Mode { RUSH, CLEAR }

var world: World
var mode: Mode = Mode.RUSH
var _path: PackedVector2Array = []
var _repath: float = 0.0
var _target_pos: Vector2
var _stuck_time: float = 0.0
var _last_pos: Vector2


func _init(w: World, m: Mode) -> void:
	world = w
	mode = m
	world.hero.auto_mode = true


## Runs until the floor ends or max_seconds pass. Returns metrics.
func run(max_seconds: float) -> Dictionary:
	var t := 0.0
	while t < max_seconds and not world.completed and not world.failed:
		tick(World.TICK)
		world.step(World.TICK)
		t += World.TICK
	return {"completed": world.completed, "failed": world.failed, "time": world.timer.elapsed,
		"limit": world.timer.limit, "essence": world.essence, "essence_total": world.essence_total,
		"hp": world.hero.hp, "gold": world.gold_collected}


func tick(dt: float) -> void:
	var hero := world.hero
	var input := hero.input
	input.move = Vector2.ZERO
	if not hero.alive:
		return
	if _dodge_telegraphs():
		return
	if hero.interact_target != null:
		return
	var fight := _threat()
	if fight != null:
		var d := hero.pos.distance_to(fight.pos)
		if d > hero.stats.get_stat(&"attack_range") + fight.radius - 0.1:
			_go(fight.pos, dt)
		return
	var obj := _next_object()
	if obj != null:
		if hero.pos.distance_to(obj.pos) <= float(DataDB.table(&"floor")["interact_radius"]) - 0.2:
			input.interact_requested = true
		else:
			_go(obj.pos, dt)
		return
	_go(_goal_target(), dt)


## Steps out of any telegraph about to hit the hero.
func _dodge_telegraphs() -> bool:
	var hero := world.hero
	for t in world.telegraphs:
		if t.target_team != Entity.Team.HERO and not t.hit_all:
			continue
		if t.left > 0.45 or not Shapes.contains(t.shape, t.origin, t.dir, hero.pos, hero.radius):
			continue
		var away := (hero.pos - t.origin)
		if t.shape.get("type") == "line":
			away = Vector2(-t.dir.y, t.dir.x)
			if away.dot(hero.pos - t.origin) < 0.0:
				away = -away
		hero.input.move = away.normalized()
		if hero.dodge_charges > 0:
			hero.input.dodge_requested = true
		return true
	return false


## The enemy to fight now: anything already fighting us nearby, or (CLEAR) the closest mob.
func _threat() -> Mob:
	var hero := world.hero
	var best: Mob = null
	var best_d := INF
	for e in world.entities:
		if not (e is Mob) or not e.alive:
			continue
		var d := hero.pos.distance_to(e.pos)
		var engaged: bool = e.state != Mob.State.IDLE and e.state != Mob.State.RETURN and d < 6.0
		var wanted: bool = mode == Mode.CLEAR or engaged or (world.goal_type == &"key_holder" and e.key_holder)
		if wanted and d < best_d and _reachable(e.pos):
			best_d = d
			best = e
	return best


func _next_object() -> FloorObject:
	var hero := world.hero
	var best: FloorObject = null
	var best_d := INF
	for e in world.entities:
		if not (e is FloorObject) or not e.can_interact():
			continue
		var want := false
		match e.kind:
			FloorObject.Kind.VALVE:
				want = world.goal_type == &"seals" and not world.goal_done()
			FloorObject.Kind.CHEST, FloorObject.Kind.SPRING:
				want = mode == Mode.CLEAR or (e.kind == FloorObject.Kind.SPRING and hero.hp < hero.max_hp * 0.5)
			FloorObject.Kind.LEVER:
				want = not _reachable(FloorGrid.cell_center(world.grid.exit))
		if want and _reachable(e.pos):
			var d := hero.pos.distance_to(e.pos)
			if d < best_d:
				best_d = d
				best = e
	return best


func _goal_target() -> Vector2:
	return FloorGrid.cell_center(world.grid.exit)


func _reachable(p: Vector2) -> bool:
	var path := world.find_path(world.hero.pos, p)
	return path.size() > 0 and (path.size() > 1 or world.hero.pos.distance_to(p) < 2.0) \
			and world.grid.is_walkable(FloorGrid.to_cell(path[path.size() - 1]))


func _go(target: Vector2, dt: float) -> void:
	var hero := world.hero
	_repath -= dt
	if _repath <= 0.0 or target.distance_to(_target_pos) > 0.5:
		_repath = 0.3
		_target_pos = target
		_path = world.find_path(hero.pos, target)
	while _path.size() > 1 and hero.pos.distance_to(_path[0]) < 0.4:
		_path.remove_at(0)
	var next := _path[0] if _path.size() > 0 else target
	var dir := next - hero.pos
	hero.input.move = dir.normalized() if dir.length() > 0.05 else Vector2.ZERO
	# Unstick: if not moving for a while, dodge in the move direction.
	if hero.pos.distance_to(_last_pos) < 0.01 and hero.input.move != Vector2.ZERO:
		_stuck_time += dt
		if _stuck_time > 1.0:
			hero.input.dodge_requested = true
			_stuck_time = 0.0
	else:
		_stuck_time = 0.0
	_last_pos = hero.pos
