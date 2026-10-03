class_name HarpoonWall
extends Combatant
## Harpoon wall (GDD 13.1): every 3 s shoots along an 8 m line with a 0.6 s telegraph; hits
## everyone, mobs too. Disabled by its lever or destroyed (150 HP; Throwing Blade reaches it).

var cell: Vector2i
var dir: Vector2 = Vector2.DOWN
var disabled: bool = false
var _timer: float = 0.0


func _init() -> void:
	team = Team.NEUTRAL
	radius = 0.5


func cfg() -> Dictionary:
	return DataDB.table(&"floor")["harpoon"]


func setup_wall(c: Vector2i, d: Vector2, phase: float) -> void:
	cell = c
	dir = d
	pos = FloorGrid.cell_center(c) + d * 0.5
	facing = d
	max_hp = float(cfg()["hp"])
	hp = max_hp
	_timer = phase


func tick(dt: float) -> void:
	super.tick(dt)
	if disabled:
		return
	_timer -= dt
	if _timer > float(cfg()["telegraph"]):
		return
	if _timer <= float(cfg()["telegraph"]) and _timer + dt > float(cfg()["telegraph"]):
		var t := Telegraph.new()
		t.id = &"harpoon"
		t.shape = {"type": "line", "length": float(cfg()["length"]), "width": float(cfg()["width"])}
		t.origin = pos
		t.dir = dir
		t.total = float(cfg()["telegraph"])
		t.source = self
		t.hit_all = true
		t.parryable = false
		t.damage = Damage.mob_damage(float(cfg()["damage"]), world.floor_index)
		world.add_telegraph(t)
	if _timer <= 0.0:
		_timer += float(cfg()["interval"])


func disable() -> void:
	disabled = true
	world.object_changed.emit(self)


func die(killer: Entity) -> void:
	disabled = true
	super.die(killer)
