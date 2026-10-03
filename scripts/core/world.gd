class_name World
extends Node
## Owns the floor simulation (decision D2). Advance it with step(dt); the live game calls it from
## _physics_process, tests and the bot call it in a loop faster than real time.

signal entity_added(entity: Entity)
signal entity_removed(entity: Entity)
signal damage_dealt(target: Combatant, amount: float, crit: bool, source: Entity)
signal entity_died(entity: Entity)
signal hero_attacked(target: Combatant)
signal telegraph_started(t: Telegraph)
signal telegraph_fired(t: Telegraph)
signal parried(attacker: Combatant)
signal bleed_exploded(at: Vector2)
signal second_wind
signal object_changed(obj: Entity)
signal note_found(key: String)
signal spring_used(obj: FloorObject)
signal chest_opened(obj: FloorObject, loot: Dictionary)
signal gold_changed(total: int)
signal key_dropped(at: Vector2)
signal seals_changed(done: int, needed: int)
signal flood_started(rect: Rect2i)
signal floor_completed(result: Dictionary)
signal floor_failed(cause: StringName)
signal boss_enraged(boss: Boss)
signal boss_summoned(boss: Boss)
signal boss_line(key: String)

const TICK := 1.0 / 60.0

var grid: FloorGrid
var timer: FloorTimer
var rng: RngStreams
var floor_index: int = 1
var hero: Hero
var entities: Array[Entity] = []
var telegraphs: Array[Telegraph] = []
var time: float = 0.0
## Live mode: _physics_process drives step(). Off in tests.
var running: bool = false
var _next_id: int = 1
var _astar: AStarGrid2D
## Floor goal (GDD 10.3): &"breakthrough", &"key_holder", &"seals", &"boss".
var goal_type: StringName = &"breakthrough"
var has_key: bool = false
var seals_done: int = 0
var seals_needed: int = 0
## Essence (GDD 10.5).
var essence: float = 0.0
var essence_total: float = 0.0
var gold_collected: int = 0
var crystals_collected: int = 0
## Loot found on the floor this attempt: [{"type": "gear", "source": tier}, ...] (items arrive in stage 5).
var loot: Array[Dictionary] = []
var completed: bool = false
var failed: bool = false
var run: RunState
## Active floods: [{"rect": Rect2i, "left": float}]
var floods: Array[Dictionary] = []
var boss: Boss
## Slowing puddles (Morten phase 2): [{"pos": Vector2, "radius": float, "slow": float}]
var puddles: Array[Dictionary] = []
var _flooded_ids: Dictionary = {}


func setup(floor_grid: FloorGrid, run_rng: RngStreams, index: int, time_limit: float,
		run_state: RunState = null) -> void:
	grid = floor_grid
	rng = run_rng
	floor_index = index
	run = run_state
	var limit := time_limit * (1.0 + (run.time_bonus() if run else 0.0))
	timer = FloorTimer.new(limit)
	hero = Hero.new()
	hero.apply_data(DataDB.table(&"hero_swordsman"))
	if run:
		run.apply_to_hero(hero)
	hero.pos = FloorGrid.cell_center(grid.start)
	add_entity(hero)
	FloorPopulator.populate(self)
	_build_navigation()
	_spawn_packs()
	_setup_goal()
	for e in entities:
		if e is Mob:
			essence_total += e.essence
	entity_died.connect(_on_entity_died)
	for s in hero.all_skills():
		s.on_floor_start()


func _setup_goal() -> void:
	var goal: Dictionary = grid.data.get("goal", {"type": "breakthrough"})
	goal_type = StringName(goal.get("type", "breakthrough"))
	match goal_type:
		&"key_holder":
			var holder := _strongest_in_pack(str(goal.get("pack", "")))
			if holder:
				holder.make_key_holder()
			else:
				push_warning("World: key holder pack not found")
		&"seals":
			seals_needed = int(goal.get("count", grid.marker_cells("V").size()))
		&"boss":
			_setup_boss(goal)


func _setup_boss(goal: Dictionary) -> void:
	var id := StringName(goal["boss"])
	var bd: Dictionary = DataDB.table(&"bosses")[String(id)]
	timer.boss_mode = true
	timer.limit = float(bd["enrage"])
	timer.flood_after = float(bd["flood_after"])
	boss = Boss.new()
	var at: Array = goal.get("boss_at", [grid.width / 2, grid.height / 2])
	boss.setup_boss(id, FloorGrid.cell_center(Vector2i(int(at[0]), int(at[1]))))
	for c: Array in grid.data.get("cages", []):
		boss.cages.append(FloorGrid.cell_center(Vector2i(int(c[0]), int(c[1]))))
	add_entity(boss)
	var intro: String = bd.get("lines", {}).get("intro", "")
	if not intro.is_empty():
		boss_line.emit.call_deferred(intro)


func spawn_puddles(count: int, diameter: float, slow: float) -> void:
	var r := rng.stream("ai", floor_index)
	for i in count:
		for attempt in 20:
			var p := Vector2(r.randf_range(2.0, grid.width - 2.0), r.randf_range(2.0, grid.height - 2.0))
			if grid.circle_free(p, diameter * 0.5):
				puddles.append({"pos": p, "radius": diameter * 0.5, "slow": slow})
				break


func _strongest_in_pack(letter: String) -> Mob:
	var best: Mob = null
	for e in entities:
		if e is Mob and e.pack_id == letter and (best == null or e.max_hp > best.max_hp):
			best = e
	return best


## Threshold for the double card choice (GDD 10.5).
func essence_threshold() -> float:
	return ceilf(float(DataDB.table(&"floor")["essence_threshold"]) * essence_total)


func essence_fill() -> float:
	var t := essence_threshold()
	return clampf(essence / t, 0.0, 1.0) if t > 0.0 else 0.0


func goal_done() -> bool:
	match goal_type:
		&"key_holder":
			return has_key
		&"seals":
			return seals_done >= seals_needed
		&"boss":
			return boss != null and not boss.alive
	return true


## Stars by remaining time (GDD 10.6).
func stars() -> int:
	if timer.boss_mode:
		var bcfg: Dictionary = DataDB.table(&"bosses")["stars"]
		var used := timer.elapsed / timer.limit
		if used <= float(bcfg["three"]):
			return 3
		if used <= float(bcfg["two"]):
			return 2
		return 1
	var cfg: Dictionary = DataDB.table(&"floor")["stars"]
	var left := timer.remaining() / timer.limit
	if left >= float(cfg["three"]):
		return 3
	if left >= float(cfg["two"]):
		return 2
	return 1


func result() -> Dictionary:
	return {"floor": floor_index, "time": timer.elapsed, "stars": stars(), "essence": essence,
		"essence_total": essence_total, "essence_fill": essence_fill(),
		"double_card": essence >= essence_threshold() and essence_total > 0.0,
		"gold": gold_collected, "crystals": crystals_collected, "loot": loot,
		"boss": String(boss.def_id) if boss != null else ""}


func _on_entity_died(e: Entity) -> void:
	if not (e is Mob):
		return
	var m := e as Mob
	var mult := float(DataDB.table(&"floor")["flooded_essence_mult"]) if _flooded_ids.has(m.id) else 1.0
	essence += m.essence * mult
	if m.key_holder:
		has_key = true
		key_dropped.emit(m.pos)
	_drop_coins(m)
	_update_lock_gates()


func _drop_coins(m: Mob) -> void:
	var cfg: Dictionary = DataDB.table(&"floor")["coins"]
	var r := rng.stream("loot", floor_index)
	var n := r.randi_range(int(cfg["per_mob"][0]), int(cfg["per_mob"][1]))
	if m.elite:
		n *= int(cfg["elite_mult"])
	var value := 1.0 + float(cfg["floor_growth"]) * (floor_index - 1)
	value *= 1.0 + (run.gold_bonus() if run else 0.0)
	for i in mini(n, 12):
		var c := Coin.new()
		c.pos = m.pos + Vector2(r.randf_range(-0.6, 0.6), r.randf_range(-0.6, 0.6))
		c.value = maxi(1, roundi(value * n / mini(n, 12)))
		add_entity(c)


func collect_gold(v: int) -> void:
	gold_collected += v
	gold_changed.emit(gold_collected)


func open_chest(o: FloorObject) -> void:
	var cfg: Dictionary = DataDB.table(&"floor")["chests"][String(o.tier)]
	var r := rng.stream("loot", floor_index)
	var gold := r.randi_range(int(cfg["gold"][0]), int(cfg["gold"][1]))
	gold = roundi(gold * (1.0 + 0.1 * (floor_index - 1)) * (1.0 + (run.gold_bonus() if run else 0.0)))
	var found := {"gold": gold, "crystals": 0, "gear": r.randf() < float(cfg["gear_chance"])}
	if cfg.has("crystal_chance") and r.randf() < float(cfg["crystal_chance"]):
		found["crystals"] = r.randi_range(int(cfg["crystals"][0]), int(cfg["crystals"][1]))
	collect_gold(gold)
	crystals_collected += int(found["crystals"])
	if found["gear"]:
		loot.append({"type": "gear", "source": String(o.tier), "floor": floor_index})
	chest_opened.emit(o, found)


func pull_lever(o: FloorObject) -> void:
	for link: Dictionary in o.links:
		if link.has("gate_at"):
			var c := Vector2i(int(link["gate_at"][0]), int(link["gate_at"][1]))
			for e in entities:
				if e is FloorObject and e.kind == FloorObject.Kind.GATE and e.cell == c:
					e.set_closed(false)
		if link.has("harpoon_at"):
			var c := Vector2i(int(link["harpoon_at"][0]), int(link["harpoon_at"][1]))
			for e in entities:
				if e is HarpoonWall and e.cell == c:
					e.disable()


func seal_activated(_o: FloorObject) -> void:
	seals_done += 1
	seals_changed.emit(seals_done, seals_needed)
	if seals_done < seals_needed:
		return
	# All seals turned: the sluice gates to the stairs open (floor json "seal_gates").
	for cell: Array in grid.data.get("seal_gates", []):
		var c := Vector2i(int(cell[0]), int(cell[1]))
		for e in entities:
			if e is FloorObject and e.kind == FloorObject.Kind.GATE and e.cell == c:
				e.set_closed(false)


## Flood valve (GDD 13.2): the hall drowns for 6 s; mobs inside die for half essence.
func start_flood(o: FloorObject) -> void:
	if o.flood_rect.size == Vector2i.ZERO:
		return
	floods.append({"rect": o.flood_rect, "left": float(DataDB.table(&"floor")["flood_valve"]["duration"])})
	flood_started.emit(o.flood_rect)


func _tick_floods(dt: float) -> void:
	for f in floods.duplicate():
		f["left"] -= dt
		var rect: Rect2i = f["rect"]
		for e in entities:
			if not (e is Combatant) or not e.alive or e.team == Entity.Team.NEUTRAL:
				continue
			if not rect.has_point(FloorGrid.to_cell(e.pos)):
				continue
			if e is Mob:
				_flooded_ids[e.id] = true
				e.take_damage(e.hp + 1.0, false, null)
			elif e == hero:
				hero.take_damage(float(DataDB.table(&"floor")["flood_valve"]["hero_dps"]) * dt, false, null, true)
		if f["left"] <= 0.0:
			floods.erase(f)


## Lock gates (GDD 10.4): close while their pack fights, open for good when it is dead.
func _update_lock_gates() -> void:
	for e in entities:
		if not (e is FloorObject) or e.kind != FloorObject.Kind.LOCK_GATE:
			continue
		var alive := 0
		var fighting := false
		for m in entities:
			if m is Mob and m.alive and m.pack_id == e.pack:
				alive += 1
				if m.state in [Mob.State.CHASE, Mob.State.ATTACK, Mob.State.CAST]:
					fighting = true
		var want_closed := alive > 0 and fighting
		if want_closed and not e.closed and hero.pos.distance_to(e.pos) < 0.5 + hero.radius:
			continue
		e.set_closed(want_closed)


func interactable_near(p: Vector2) -> FloorObject:
	var best: FloorObject = null
	var best_d := float(DataDB.table(&"floor")["interact_radius"])
	for e in entities:
		if e is FloorObject and e.can_interact():
			var d := p.distance_to(e.pos)
			if d <= best_d:
				best_d = d
				best = e
	return best


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
	# The first point is the centre of the cell we stand in: walking back to it makes units jitter.
	if path.size() > 1:
		path.remove_at(0)
	return path


## True if a walkable route exists between the two points (closed gates count as walls).
func is_reachable(from: Vector2, to: Vector2) -> bool:
	var a := FloorGrid.to_cell(from)
	var b := FloorGrid.to_cell(to)
	if not grid.is_walkable(a) or not grid.is_walkable(b):
		return false
	return a == b or not _astar.get_id_path(a, b, false).is_empty()


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
	_tick_telegraphs(dt)
	_tick_floods(dt)
	for pd in puddles:
		for e in entities:
			if e is Combatant and e.alive and e.team != Entity.Team.NEUTRAL and e.pos.distance_to(pd["pos"]) < pd["radius"]:
				e.statuses.apply(&"slow", 0.1, float(pd["slow"]))
	_separate()
	_update_lock_gates()
	_check_end()


func _check_end() -> void:
	if completed or failed:
		return
	if timer.drowned():
		hero.immortal = false
		if hero.alive:
			hero.die(null)
		failed = true
		running = false
		floor_failed.emit(&"drowned")
		return
	if not hero.alive:
		failed = true
		running = false
		if boss != null and boss.alive:
			var win: String = boss.boss_data.get("lines", {}).get("hero_death", "")
			if not win.is_empty():
				boss_line.emit(win)
		floor_failed.emit(&"fell")
		return
	if goal_type == &"boss":
		if boss != null and not boss.alive:
			completed = true
			running = false
			timer.paused = true
			floor_completed.emit(result())
		return
	if hero.pos.distance_to(FloorGrid.cell_center(grid.exit)) <= float(DataDB.table(&"floor")["stairs_radius"]):
		if goal_done():
			completed = true
			running = false
			timer.paused = true
			floor_completed.emit(result())


## Knee-deep water slows everyone by 15 %, drowned move 15 % faster (GDD 10.2).
func mob_speed_factor(m: Mob) -> float:
	if timer.phase() < FloorTimer.Phase.KNEE:
		return 1.0
	return 1.15 if m.def_id == &"drowned" else 0.85


func add_telegraph(t: Telegraph) -> void:
	t.left = t.total
	telegraphs.append(t)
	telegraph_started.emit(t)


func _tick_telegraphs(dt: float) -> void:
	for t in telegraphs.duplicate():
		if t.source != null and not t.source.alive:
			telegraphs.erase(t)
			continue
		t.left -= dt
		if t.left > 0.0:
			continue
		telegraphs.erase(t)
		t.fired = true
		telegraph_fired.emit(t)
		var targets := Shapes.query(self, t.shape, t.origin, t.dir, t.target_team)
		if t.hit_all:
			targets.append_array(Shapes.query(self, t.shape, t.origin, t.dir, Entity.Team.ENEMY))
		for target in targets:
			apply_strike(t.source, target, t.damage, t.effect, t.parryable, t.origin)


## A hit from a mob ability or attack on a target, with armour, parry and effects (GDD 6.3, 8.2).
func apply_strike(src: Combatant, target: Combatant, damage: float, effect: Dictionary,
		parryable: bool, from: Vector2) -> void:
	if target == hero and hero.try_parry(src, parryable):
		return
	var taken := target.take_damage(damage * Damage.armor_factor(target.armor), false, src)
	if taken <= 0.0 and target.is_invulnerable():
		return
	if effect.has("stun"):
		target.statuses.apply(&"stun", float(effect["stun"]))
	if effect.has("root"):
		target.statuses.apply(&"root", float(effect["root"]))
	if effect.has("slow"):
		target.statuses.apply(&"slow", float(effect["slow"][1]), float(effect["slow"][0]))
	if effect.get("pull", false) and src != null:
		var to_src := src.pos - target.pos
		var dist := maxf(0.0, to_src.length() - src.radius - target.radius - 0.2)
		target.statuses.push(to_src.normalized() * dist / 0.25, 0.25)
	if effect.has("knockback"):
		var away := (target.pos - from).normalized()
		target.statuses.push(away * float(effect["knockback"]) / 0.3, 0.3)


## Pushes overlapping bodies apart. The hero passes through enemies while dodging (GDD 7).
func _separate() -> void:
	var n := entities.size()
	for i in n:
		var a := entities[i]
		if not a.alive or not (a is Combatant) or a.team == Entity.Team.NEUTRAL:
			continue
		for j in range(i + 1, n):
			var b := entities[j]
			if not b.alive or not (b is Combatant) or b.team == Entity.Team.NEUTRAL:
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
