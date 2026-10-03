class_name Mob
extends Combatant
## Enemy with the basic state machine from GDD 12.1: idle -> aggro (whole pack) -> chase -> attack,
## leash back to spawn with full heal. Ranged mobs keep their distance. Abilities arrive in stage 2.

enum State { IDLE, CHASE, ATTACK, CAST, RETURN }

var data: Dictionary = {}
var state: State = State.IDLE
var pack_id: String = ""
var spawn_pos: Vector2
var move_speed: float = 3.0
var damage: float = 10.0
var attack_interval: float = 1.5
var attack_range: float = 1.2
var aggro_radius: float = 6.0
var ranged: bool = false
var elite: bool = false
var attack_cooldown: float = 0.0
var swing_left: float = 0.0
## Abilities from mobs.json with their cooldowns: [{"data": {...}, "cd": float}]
var abilities: Array[Dictionary] = []
var _cast: Telegraph
## Id of the ability being cast (views pick the animation).
var cast_id: StringName = &""
## Key holder modifier (GDD 12.2): x1.5 HP and a key icon.
var key_holder: bool = false
var floor_index: int = 1
var _path: PackedVector2Array = []
var _repath_left: float = 0.0


func setup(def: StringName, d: Dictionary, floor_number: int, at: Vector2) -> void:
	floor_index = floor_number
	def_id = def
	data = d
	team = Team.ENEMY
	pos = at
	spawn_pos = at
	radius = float(d.get("radius", 0.35))
	max_hp = Damage.mob_hp(float(d["hp"]), floor_number)
	hp = max_hp
	damage = Damage.mob_damage(float(d["damage"]), floor_number)
	armor = float(d.get("armor", 0))
	move_speed = float(d.get("move_speed", 3.0))
	attack_interval = float(d.get("attack_interval", 1.5))
	attack_range = float(d.get("attack_range", 1.2))
	aggro_radius = float(d.get("aggro_radius", 6.0))
	essence = int(d.get("essence", 1))
	ranged = bool(d.get("ranged", false))
	elite = bool(d.get("elite", false))
	for a: Dictionary in d.get("abilities", []):
		# First use comes after half a cooldown, staggered per ability.
		abilities.append({"data": a, "cd": float(a["cooldown"]) * (0.5 + 0.25 * abilities.size())})


func make_key_holder() -> void:
	key_holder = true
	# Elites are tough enough already: only common mobs get the key holder's extra health.
	if not elite:
		max_hp *= float(DataDB.table(&"combat").get("key_holder_hp_mult", 1.5))
	hp = max_hp


func aggro() -> void:
	if state == State.IDLE:
		state = State.CHASE
		_repath_left = 0.0


func _on_damaged(_source: Entity) -> void:
	world.aggro_pack(self)


func tick(dt: float) -> void:
	super.tick(dt)
	attack_cooldown = maxf(0.0, attack_cooldown - dt)
	swing_left = maxf(0.0, swing_left - dt)
	for a in abilities:
		a["cd"] = maxf(0.0, a["cd"] - dt)
	_water_regen(dt)
	if not statuses.can_act():
		anim_state = &"idle"
		_cancel_cast()
		return
	var hero := world.hero
	if state == State.CAST:
		_tick_cast()
		return
	match state:
		State.IDLE:
			anim_state = &"idle"
			if hero.alive and pos.distance_to(hero.pos) <= aggro_radius and world.grid.has_line_of_sight(pos, hero.pos):
				world.aggro_pack(self)
		State.CHASE, State.ATTACK:
			if pos.distance_to(spawn_pos) > float(DataDB.table(&"combat").get("leash_distance", 15.0)) or not hero.alive:
				state = State.RETURN
				_repath_left = 0.0
				return
			_fight(hero, dt)
		State.RETURN:
			if _move_towards(spawn_pos, dt) < 0.3:
				hp = max_hp
				state = State.IDLE


func _fight(hero: Hero, dt: float) -> void:
	var dist := pos.distance_to(hero.pos)
	var reach := attack_range + hero.radius
	var sees := world.grid.has_line_of_sight(pos, hero.pos)
	if sees and _try_ability(hero, dist):
		return
	if ranged and sees and dist < float(data.get("flee_distance", 3.0)):
		var away := pos + (pos - hero.pos).normalized() * 2.0
		pos = world.grid.move_circle(pos, radius, (away - pos).normalized() * move_speed * dt)
		anim_state = &"run"
		state = State.CHASE
		return
	if dist <= reach and sees:
		state = State.ATTACK
		facing = (hero.pos - pos).normalized()
		anim_state = &"attack" if swing_left > 0.0 else &"idle"
		if attack_cooldown <= 0.0:
			attack_cooldown = attack_interval
			swing_left = 0.4
			if ranged:
				_start_cast({"id": "shot", "telegraph": {"type": "line", "length": attack_range + 1.0, "width": 0.5,
					"time": float(data.get("aim_time", 0.8))}, "damage": float(data["damage"])}, hero)
			else:
				world.apply_strike(self, hero, damage, _melee_effect(), true, pos)
		return
	state = State.CHASE
	_move_towards(hero.pos, dt)


func _melee_effect() -> Dictionary:
	if data.has("grab_chance") and world.rng.stream("ai", floor_index).randf() < float(data["grab_chance"]):
		return {"root": float(data.get("grab_root", 1.0))}
	return {}


## Starts a ready ability if the hero is inside its reach (abilities alternate by cooldown order).
func _try_ability(hero: Hero, dist: float) -> bool:
	for a in abilities:
		if a["cd"] > 0.0:
			continue
		var ad: Dictionary = a["data"]
		var tg: Dictionary = ad["telegraph"]
		var reach := float(tg.get("radius", tg.get("length", 2.0)))
		if dist > reach + hero.radius:
			continue
		a["cd"] = float(ad["cooldown"])
		_start_cast(ad, hero)
		# Alternate: push the other abilities back a little so they do not chain instantly.
		for other in abilities:
			if other != a:
				other["cd"] = maxf(other["cd"], 2.0)
		return true
	return false


func _start_cast(ad: Dictionary, hero: Hero) -> void:
	var tg: Dictionary = ad["telegraph"]
	var t := Telegraph.new()
	t.id = StringName(ad["id"])
	t.shape = tg
	t.dir = (hero.pos - pos).normalized()
	facing = t.dir
	t.origin = pos if String(tg["type"]) != "circle" or not tg.get("at_target", false) else hero.pos
	t.total = float(tg["time"])
	t.source = self
	t.target_team = Team.HERO
	t.damage = Damage.mob_damage(float(ad["damage"]), floor_index)
	t.effect = ad.get("effect", {})
	t.parryable = not ad.get("unparryable", false)
	_cast = t
	cast_id = t.id
	state = State.CAST
	anim_state = &"cast"
	world.add_telegraph(t)


func _tick_cast() -> void:
	if _cast == null or _cast.fired or not world.telegraphs.has(_cast):
		_cast = null
		state = State.CHASE
		swing_left = 0.4
		anim_state = &"attack"


func _cancel_cast() -> void:
	if _cast != null:
		world.telegraphs.erase(_cast)
		_cast = null
		state = State.CHASE


## Drowned regenerate in knee-deep water (GDD 12.2).
func _water_regen(dt: float) -> void:
	if data.has("water_regen_pct") and world.timer.phase() >= FloorTimer.Phase.KNEE:
		heal(max_hp * float(data["water_regen_pct"]) * dt)


## Steps along a grid path to the target; returns the remaining straight distance.
func _move_towards(target: Vector2, dt: float) -> float:
	_repath_left -= dt
	if _repath_left <= 0.0 or _path.is_empty():
		_repath_left = float(DataDB.table(&"combat").get("repath_interval", 0.4))
		_path = world.find_path(pos, target)
	var goal := target
	while _path.size() > 1 and pos.distance_to(_path[0]) < 0.35:
		_path.remove_at(0)
	if _path.size() > 1:
		goal = _path[0]
	var to_goal := goal - pos
	if to_goal.length() > 0.05:
		facing = to_goal.normalized()
		if statuses.can_move():
			var spd := move_speed * statuses.speed_multiplier() * world.mob_speed_factor(self)
			pos = world.grid.move_circle(pos, radius, facing * minf(spd * dt, to_goal.length()))
		anim_state = &"run"
	return pos.distance_to(target)
