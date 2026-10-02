class_name World
extends Node
## Owns the floor simulation (decision D2). Advance it with step(dt); the live game calls it from
## _physics_process, tests and the bot call it in a loop faster than real time.

signal entity_added(entity: Entity)
signal entity_removed(entity: Entity)

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


func setup(floor_grid: FloorGrid, run_rng: RngStreams, index: int, time_limit: float) -> void:
	grid = floor_grid
	rng = run_rng
	floor_index = index
	timer = FloorTimer.new(time_limit)
	hero = Hero.new()
	hero.apply_data(DataDB.table(&"hero_swordsman"))
	hero.pos = FloorGrid.cell_center(grid.start)
	add_entity(hero)


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
