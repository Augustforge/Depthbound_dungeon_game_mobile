class_name Boss
extends Mob
## Boss (GDD 15): always fighting, skills from data/bosses.json with telegraphs, HP thresholds
## (phases, buffs), enrage (+50 % damage, +30 % attack speed). Skill kinds:
##   telegraph — one telegraphed strike; double — two strikes, the second re-aimed;
##   charge — telegraphed rectangle, then a dash along it; summon — calls mobs from the cages;
##   spin — telegraph, then a damaging spin that slowly follows the hero.

signal line_said(key: String)

var boss_data: Dictionary = {}
var phase: int = 1
var enraged: bool = false
var invulnerable_left: float = 0.0
var cooldown_cut: float = 0.0
var attack_speed_bonus: float = 0.0
## Cage cells to summon from (arena json "cages").
var cages: Array[Vector2] = []
var _skills: Array[Dictionary] = []
var _thresholds_done: Dictionary = {}
var _charge: Dictionary = {}
var _spin: Dictionary = {}
var _pending: Array[Dictionary] = []


func setup_boss(id: StringName, at: Vector2) -> void:
	boss_data = DataDB.table(&"bosses")[String(id)]
	def_id = id
	data = boss_data
	team = Team.ENEMY
	pos = at
	spawn_pos = at
	radius = float(boss_data.get("radius", 0.7))
	max_hp = float(boss_data["hp"])
	hp = max_hp
	damage = float(boss_data["damage"])
	armor = float(boss_data["armor"])
	move_speed = float(boss_data["move_speed"])
	attack_interval = float(boss_data["attack_interval"])
	attack_range = float(boss_data["attack_range"])
	elite = true
	essence = 0
	for s: Dictionary in boss_data["skills"]:
		_skills.append({"data": s, "cd": float(s.get("first", s["cooldown"]))})
	state = State.CHASE


func is_invulnerable() -> bool:
	return invulnerable_left > 0.0


func aggro() -> void:
	state = State.CHASE


func tick(dt: float) -> void:
	since_hit += dt
	statuses.tick(self, dt)
	invulnerable_left = maxf(0.0, invulnerable_left - dt)
	attack_cooldown = maxf(0.0, attack_cooldown - dt)
	swing_left = maxf(0.0, swing_left - dt)
	_check_enrage()
	_check_thresholds()
	_tick_pending(dt)
	for s in _skills:
		s["cd"] = maxf(0.0, s["cd"] - dt)
	if not _spin.is_empty():
		_tick_spin(dt)
		return
	if not _charge.is_empty():
		_tick_charge(dt)
		return
	if not statuses.can_act() or invulnerable_left > 0.0:
		anim_state = &"idle"
		return
	if state == State.CAST:
		_tick_cast()
		return
	var hero := world.hero
	if not hero.alive:
		anim_state = &"idle"
		return
	if _try_boss_skill(hero):
		return
	var dist := pos.distance_to(hero.pos)
	if dist <= attack_range + hero.radius:
		facing = (hero.pos - pos).normalized()
		anim_state = &"attack" if swing_left > 0.0 else &"idle"
		if attack_cooldown <= 0.0:
			var speed := 1.0 + attack_speed_bonus + (_enrage_cfg("attack_speed_pct") if enraged else 0.0)
			attack_cooldown = attack_interval / speed
			swing_left = 0.5
			world.apply_strike(self, hero, _scaled(damage), {}, true, pos)
		return
	_move_towards(hero.pos, dt)


func _scaled(base: float) -> float:
	return base * (1.0 + (_enrage_cfg("damage_pct") if enraged else 0.0))


func _enrage_cfg(key: String) -> float:
	return float(DataDB.table(&"bosses")["enrage"][key])


func _check_enrage() -> void:
	if not enraged and world.timer.enraged():
		enraged = true
		world.boss_enraged.emit(self)


func _check_thresholds() -> void:
	for i in boss_data.get("thresholds", []).size():
		var th: Dictionary = boss_data["thresholds"][i]
		if _thresholds_done.has(i) or hp / max_hp > float(th["hp"]):
			continue
		_thresholds_done[i] = true
		attack_speed_bonus += float(th.get("attack_speed_pct", 0.0))
		cooldown_cut += float(th.get("cooldown_cut", 0.0))
		if th.has("phase"):
			phase = int(th["phase"])
			_cancel_cast()
			_spin.clear()
			_charge.clear()
		invulnerable_left = maxf(invulnerable_left, float(th.get("invulnerable", 0.0)))
		if th.has("puddles"):
			world.spawn_puddles(int(th["puddles"]), float(th["puddle_diameter"]), float(th["puddle_slow"]))
		if th.has("line"):
			line_said.emit(String(th["line"]))
			world.boss_line.emit(String(th["line"]))


func _try_boss_skill(hero: Hero) -> bool:
	for s in _skills:
		var sd: Dictionary = s["data"]
		if s["cd"] > 0.0 or int(sd.get("phase", phase)) != phase:
			continue
		var kind := String(sd["kind"])
		var reach := 99.0
		if sd.has("telegraph") and kind == "telegraph":
			var tg: Dictionary = sd["telegraph"]
			reach = float(tg.get("radius", tg.get("length", 3.0))) + 1.0
		elif kind == "double":
			reach = float(sd["telegraph"]["radius"]) + 1.0
		elif kind == "spin":
			reach = 5.0
		if pos.distance_to(hero.pos) > reach:
			continue
		s["cd"] = float(sd["cooldown"]) * (1.0 - cooldown_cut)
		match kind:
			"summon":
				_summon(sd)
			"charge":
				_start_charge(sd, hero)
			"spin":
				_start_spin(sd, hero)
			"double":
				_start_cast(_strike_data(sd), hero)
				_pending.append({"delay": float(sd["telegraph"]["time"]) + float(sd["second_delay"]), "sd": sd})
			_:
				_start_cast(_strike_data(sd), hero)
		return true
	return false


func _strike_data(sd: Dictionary) -> Dictionary:
	var d := sd.duplicate()
	d["damage"] = _scaled(float(sd["damage"]))
	return d


## Mob._start_cast scales damage by floor; bosses use absolute numbers, so undo it here.
func _start_cast(ad: Dictionary, hero: Hero) -> void:
	super._start_cast(ad, hero)
	if _cast != null:
		_cast.damage = float(ad["damage"])


## Second strike of Double Execution, re-aimed at the hero's new position.
func _tick_pending(dt: float) -> void:
	for p in _pending.duplicate():
		p["delay"] -= dt
		if p["delay"] <= 0.0:
			_pending.erase(p)
			if alive and phase == 2:
				_start_cast(_strike_data(p["sd"]), world.hero)


func _summon(sd: Dictionary) -> void:
	anim_state = &"cast"
	cast_id = StringName(sd["id"])
	swing_left = 0.8
	var spots := cages if not cages.is_empty() else [pos + Vector2(2, 0), pos - Vector2(2, 0)]
	var i := 0
	for group: Dictionary in sd["summon"]:
		for n in int(group.get("count", 1)):
			var m := Mob.new()
			var at: Vector2 = spots[i % spots.size()]
			m.setup(StringName(group["mob"]), DataDB.table(&"mobs")[String(group["mob"])], world.floor_index, at)
			m.essence = 0
			world.add_entity(m)
			m.aggro()
			i += 1
	world.boss_summoned.emit(self)


func _start_charge(sd: Dictionary, hero: Hero) -> void:
	_start_cast(_strike_data(sd), hero)
	if _cast != null:
		# The charge itself deals the damage, not the telegraph.
		_cast.damage = 0.0
		_charge = {"sd": sd, "dir": _cast.dir, "wait": float(sd["telegraph"]["time"]), "left": 0.0, "hit": false}


func _tick_charge(dt: float) -> void:
	if _charge["wait"] > 0.0:
		_charge["wait"] -= dt
		if _charge["wait"] <= 0.0:
			_charge["left"] = float(_charge["sd"]["telegraph"]["length"]) / 16.0
			state = State.CHASE
		return
	var step := minf(dt, _charge["left"])
	_charge["left"] -= step
	anim_state = &"charge"
	var dir: Vector2 = _charge["dir"]
	pos = world.grid.move_circle(pos, radius, dir * 16.0 * step)
	var hero := world.hero
	if not _charge["hit"] and pos.distance_to(hero.pos) <= radius + hero.radius + 0.3:
		_charge["hit"] = true
		var sd: Dictionary = _charge["sd"]
		world.apply_strike(self, hero, _scaled(float(sd["damage"])), sd.get("effect", {}), true, pos)
	if _charge["left"] <= 0.0:
		_charge.clear()


func _start_spin(sd: Dictionary, hero: Hero) -> void:
	_start_cast(_strike_data(sd), hero)
	if _cast != null:
		_cast.damage = 0.0
		_spin = {"sd": sd, "wait": float(sd["telegraph"]["time"]), "left": float(sd["duration"]), "tick": 0.0}


func _tick_spin(dt: float) -> void:
	if _spin["wait"] > 0.0:
		_spin["wait"] -= dt
		return
	var sd: Dictionary = _spin["sd"]
	_spin["left"] -= dt
	_spin["tick"] -= dt
	anim_state = &"spin"
	state = State.CHASE
	var hero := world.hero
	var to_hero := hero.pos - pos
	if to_hero.length() > 0.5:
		pos = world.grid.move_circle(pos, radius, to_hero.normalized() * float(sd["spin_speed"]) * dt)
	if _spin["tick"] <= 0.0:
		_spin["tick"] += float(sd["tick"])
		var shape := {"type": "circle", "radius": float(sd["telegraph"]["radius"])}
		if Shapes.contains(shape, pos, facing, hero.pos, hero.radius):
			world.apply_strike(self, hero, _scaled(float(sd["damage"])), {}, false, pos)
	if _spin["left"] <= 0.0:
		_spin.clear()


## Radius of an ongoing damaging spin (0 when not spinning) — for the test bot and views.
func spin_radius() -> float:
	if _spin.is_empty() or _spin["wait"] > 0.0:
		return 0.0
	return float(_spin["sd"]["telegraph"]["radius"])


func die(killer: Entity) -> void:
	super.die(killer)
	var defeat: String = boss_data.get("lines", {}).get("defeat", "")
	if not defeat.is_empty():
		world.boss_line.emit(defeat)
