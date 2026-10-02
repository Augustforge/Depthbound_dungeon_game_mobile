class_name World
extends Node
## Owns the floor simulation (decision D2). Advance it with step(dt); the live game calls it from
## _physics_process, tests and the bot call it in a loop faster than real time.

signal entity_added(entity: Entity)
signal entity_removed(entity: Entity)
signal damage_dealt(target: Combatant, amount: float, crit: bool, source: Entity)
signal entity_died(entity: Entity)
signal hero_attacked(target: Combatant)

const TICK := 1.0 / 60.0

var grid: FloorGrid
var timer: FloorTimer
var rng: RngStreams
var floor_index: int = 1
var hero: Hero
var entities: Array[Entity] = []
var time: float = 0.0
## Live mode: _physics_process drives step(). Off in tests.
var running: bool = false
var _next_id: int = 1
var _astar: AStarGrid2D


func setup(floor_grid: FloorGrid, run_rng: RngStreams, index: int, time_limit: float) -> void:
	grid = floor_grid
	rng = run_rng
	floor_index = index
	timer = FloorTimer.new(time_limit)
	hero = Hero.new()
	hero.apply_data(DataDB.table(&"hero_swordsman"))
	hero.pos = FloorGrid.cell_center(grid.start)
	add_entity(hero)
	_build_navigation()
	_spawn_packs()


## Spawns packs from the floor json: "packs": {"a": [{"mob": "rat", "count": 3}, ...]} (GDD 19.5).
## Mobs are placed on free cells around the pack letter, deterministically.
func _spawn_packs() -> void:
	var packs: Dictionary = grid.data.get("packs", {})
	var mobs_db: Dictionary = DataDB.table(&"mobs")
	for letter: String in packs:
		var centres: Array = grid.marker_cells(letter)
		if centres.is_empty():
			push_warning("World: pack %s has no letter on the map" % letter)
			continue
		var spots := _spawn_spots(centres[0], 12)
		var i := 0
		for group: Dictionary in packs[letter]:
			var def := StringName(group["mob"])
			for n in int(group.get("count", 1)):
				var m := Mob.new()
				m.setup(def, mobs_db[String(def)], floor_index, spots[i % spots.size()])
				m.pack_id = letter
				add_entity(m)
				i += 1


func _spawn_spots(centre: Vector2i, max_count: int) -> Array[Vector2]:
	var result: Array[Vector2] = [FloorGrid.cell_center(centre)]
	var offsets := [Vector2(0.7, 0), Vector2(-0.7, 0), Vector2(0, 0.7), Vector2(0, -0.7),
		Vector2(0.7, 0.7), Vector2(-0.7, 0.7), Vector2(0.7, -0.7), Vector2(-0.7, -0.7),
		Vector2(1.4, 0), Vector2(-1.4, 0), Vector2(0, 1.4), Vector2(0, -1.4)]
	for o: Vector2 in offsets:
		var p: Vector2 = result[0] + o
		if grid.circle_free(p, 0.3) and result.size() < max_count:
			result.append(p)
	return result


func _build_navigation() -> void:
	_astar = AStarGrid2D.new()
	_astar.region = Rect2i(0, 0, grid.width, grid.height)
	_astar.cell_size = Vector2.ONE
	_astar.offset = Vector2(0.5, 0.5)
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_astar.update()
	for y in grid.height:
		for x in grid.width:
			_astar.set_point_solid(Vector2i(x, y), not grid.is_walkable(Vector2i(x, y)))


## Call after a gate opens or closes.
func refresh_navigation_cell(c: Vector2i) -> void:
	_astar.set_point_solid(c, not grid.is_walkable(c))


func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var a := FloorGrid.to_cell(from)
	var b := FloorGrid.to_cell(to)
	if not grid.is_walkable(a) or not grid.is_walkable(b):
		return PackedVector2Array([to])
	var path := _astar.get_point_path(a, b, true)
	if path.size() > 0:
		path[path.size() - 1] = to
	return path


func aggro_pack(m: Mob) -> void:
	for e in entities:
		if e is Mob and e.alive and (e == m or (not m.pack_id.is_empty() and e.pack_id == m.pack_id)):
			e.aggro()


func nearest_enemy(from: Vector2, reach: float, of: Entity) -> Combatant:
	var best: Combatant = null
	var best_d := INF
	for e in entities:
		if e.alive and e != of and e.team != of.team and e.team != Entity.Team.NEUTRAL and e is Combatant:
			var d := from.distance_to(e.pos) - e.radius
			if d <= reach and d < best_d:
				best_d = d
				best = e
	return best


func living_enemies() -> int:
	var n := 0
	for e in entities:
		if e.alive and e.team == Entity.Team.ENEMY:
			n += 1
	return n


func add_entity(e: Entity) -> void:
	e.id = _next_id
	_next_id += 1
	e.world = self
	entities.append(e)
	entity_added.emit(e)


func remove_entity(e: Entity) -> void:
	entities.erase(e)
	entity_removed.emit(e)


func _physics_process(delta: float) -> void:
	if running:
		step(delta)


func step(dt: float) -> void:
	time += dt
	timer.tick(dt)
	hero.speed_factor = 1.0
	if timer.phase() >= FloorTimer.Phase.KNEE:
		hero.speed_factor = 1.0 - float(DataDB.table(&"hero_swordsman").get("water", {}).get("knee_deep_slow", 0.15))
	for e in entities.duplicate():
		if e.alive:
			e.tick(dt)
	_separate()


## Pushes overlapping bodies apart. The hero passes through enemies while dodging (GDD 7).
func _separate() -> void:
	var n := entities.size()
	for i in n:
		var a := entities[i]
		if not a.alive:
			continue
		for j in range(i + 1, n):
			var b := entities[j]
			if not b.alive:
				continue
			if (a == hero and hero.is_dodging()) or (b == hero and hero.is_dodging()):
				continue
			var d := b.pos - a.pos
			var min_d := a.radius + b.radius
			var dist_sq := d.length_squared()
			if dist_sq >= min_d * min_d or dist_sq < 1e-8:
				continue
			var dist := sqrt(dist_sq)
			var push := d / dist * (min_d - dist)
			# The hero is light: enemies push it, it barely pushes them (body blocking in corridors).
			var wa := 0.9 if a == hero else 0.5
			var wb := 0.9 if b == hero else 0.5
			if a == hero or b == hero:
				wa = 0.9 if a == hero else 0.1
				wb = 0.9 if b == hero else 0.1
			a.pos = grid.move_circle(a.pos, a.radius, -push * wa)
			b.pos = grid.move_circle(b.pos, b.radius, push * wb)
