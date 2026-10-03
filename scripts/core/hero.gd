class_name Hero
extends Combatant
## The player character (GDD 5–8): joystick movement, auto-attack while standing, dodge, up to
## 3 active and 3 passive skills, AUTO mode.

const MAX_ACTIVES := 3
const MAX_PASSIVES := 3

var input: HeroInput = HeroInput.new()
var stats: StatBlock
var move_speed: float = 4.0
var velocity: Vector2 = Vector2.ZERO
## Priority target chosen by tapping an enemy (GDD 5).
var priority_target: Combatant
var current_target: Combatant
var attack_cooldown: float = 0.0
## Remaining time of the current swing animation (views only).
var swing_left: float = 0.0
## Debug: ignore all damage.
var immortal: bool = false
## AUTO toggle (GDD 5, 8.3).
var auto_mode: bool = false
var actives: Array[Skill] = []
var passives: Array[Skill] = []
## Skill animation request for views: {"id": StringName, "left": float}
var skill_anim: StringName = &""
var skill_anim_left: float = 0.0

var dodge_cooldown: float = 6.0
var dodge_distance: float = 3.0
var dodge_duration: float = 0.25
var dodge_invulnerable: float = 0.35
var dodge_max_charges: int = 1
var dodge_charges: int = 1
## Time until the next charge is restored.
var dodge_recharge: float = 0.0
var _dodge_left: float = 0.0
var _dodge_dir: Vector2 = Vector2.DOWN
var _invulnerable_left: float = 0.0
## Multiplier from knee-deep water etc. Set by the floor each tick.
var speed_factor: float = 1.0
## Dash Strike in progress.
var _dash_left: float = 0.0
var _dash_speed: float = 0.0
var _dash_dir: Vector2
var _dash_skill: Skill


func _init() -> void:
	team = Team.HERO
	def_id = &"swordsman"


func apply_data(d: Dictionary) -> void:
	radius = float(d.get("radius", radius))
	stats = StatBlock.new(d.get("stats", {}), d.get("stat_caps", {}))
	refresh_stats()
	hp = max_hp
	var dodge: Dictionary = d.get("dodge", {})
	dodge_cooldown = float(dodge.get("cooldown", dodge_cooldown))
	dodge_distance = float(dodge.get("distance", dodge_distance))
	dodge_duration = float(dodge.get("duration", dodge_duration))
	dodge_invulnerable = float(dodge.get("invulnerable", dodge_invulnerable))
	dodge_max_charges = int(dodge.get("charges", dodge_max_charges))
	dodge_charges = dodge_max_charges
	actives.resize(MAX_ACTIVES)
	for id: String in DataDB.table(&"skills"):
		var sd: Variant = DataDB.table(&"skills")[id]
		if sd is Dictionary and sd.get("start", false):
			add_skill(StringName(id))


## Adds a skill into the first free slot of its type. Returns false if there is no room.
func add_skill(skill_id: StringName, level: int = 1) -> bool:
	var s := SkillDB.create(skill_id, self, level)
	if s.is_active():
		for i in MAX_ACTIVES:
			if actives[i] == null:
				actives[i] = s
				return true
		return false
	if passives.size() >= MAX_PASSIVES:
		return false
	passives.append(s)
	return true


func all_skills() -> Array[Skill]:
	var out: Array[Skill] = []
	for s in actives:
		if s != null:
			out.append(s)
	out.append_array(passives)
	return out


func find_skill(skill_id: StringName) -> Skill:
	for s in all_skills():
		if s.id == skill_id:
			return s
	return null


## Re-reads derived values after stat sources changed (gear, cards, buffs).
func refresh_stats() -> void:
	var ratio := hp / max_hp if max_hp > 0.0 else 1.0
	max_hp = stats.get_stat(&"max_hp")
	hp = minf(max_hp * ratio, max_hp)
	armor = stats.get_stat(&"armor")
	move_speed = stats.get_stat(&"move_speed")


func is_dodging() -> bool:
	return _dodge_left > 0.0 or _dash_left > 0.0


func is_invulnerable() -> bool:
	return immortal or _invulnerable_left > 0.0 or _dash_left > 0.0


func grant_invulnerability(seconds: float) -> void:
	_invulnerable_left = maxf(_invulnerable_left, seconds)


func parrying() -> bool:
	var p := find_skill(&"parry")
	return p != null and p.active_stance()


func spinning() -> bool:
	var w := find_skill(&"whirlwind")
	return w != null and w.spinning()


## 0..1 progress of the current dodge cooldown, 1 when a charge is ready (for the HUD).
func dodge_ready_ratio() -> float:
	if dodge_charges > 0:
		return 1.0
	return 1.0 - dodge_recharge / dodge_cooldown


func play_skill_anim(anim_id: StringName, time: float) -> void:
	skill_anim = anim_id
	skill_anim_left = time


func tick(dt: float) -> void:
	super.tick(dt)
	_update_dynamic_stats()
	attack_cooldown = maxf(0.0, attack_cooldown - dt)
	swing_left = maxf(0.0, swing_left - dt)
	skill_anim_left = maxf(0.0, skill_anim_left - dt)
	_tick_dodge_cooldown(dt)
	_invulnerable_left = maxf(0.0, _invulnerable_left - dt)
	for s in all_skills():
		s.tick(dt)
	if _dash_left > 0.0:
		_tick_dash(dt)
		return
	var dodge := input.consume_dodge()
	var requested := input.skill_requested.duplicate()
	input.skill_requested = [false, false, false]
	if not statuses.can_act():
		anim_state = &"stunned"
		return
	if dodge:
		try_dodge()
	if _dodge_left > 0.0:
		var step := minf(dt, _dodge_left)
		_dodge_left -= step
		pos = world.grid.move_circle(pos, radius, _dodge_dir * (dodge_distance / dodge_duration) * step)
		anim_state = &"dodge"
		return
	for i in MAX_ACTIVES:
		if actives[i] != null and (requested[i] or (auto_mode and actives[i].ready() and actives[i].auto_wants())):
			actives[i].try_cast()
	if _dash_left > 0.0:
		return
	var move := input.move.limit_length(1.0)
	var spin := spinning()
	if move.length() > 0.1 and statuses.can_move():
		var spd := move_speed * speed_factor * statuses.speed_multiplier()
		if spin:
			spd *= float(find_skill(&"whirlwind").p("move_mult", 0.7))
		velocity = move * spd
		facing = move.normalized()
		pos = world.grid.move_circle(pos, radius, velocity * dt)
		anim_state = &"run"
	else:
		velocity = Vector2.ZERO
		if not spin:
			_auto_attack()
		anim_state = &"attack" if swing_left > 0.0 else &"idle"
	if spin:
		anim_state = &"whirlwind"


func _update_dynamic_stats() -> void:
	for s in all_skills():
		var b := s.stat_bonus()
		if b.is_empty():
			stats.sources.erase(StringName("skill_" + String(s.id)))
		else:
			stats.sources[StringName("skill_" + String(s.id))] = {"flat": b.get("flat", {}), "pct": b.get("pct", {})}
	stats.recompute()
	var ratio := hp / max_hp if max_hp > 0.0 else 1.0
	var new_max := stats.get_stat(&"max_hp")
	if not is_equal_approx(new_max, max_hp):
		max_hp = new_max
		hp = max_hp * ratio
	armor = stats.get_stat(&"armor")
	move_speed = stats.get_stat(&"move_speed")


## Attacks only while standing (GDD 5): the tapped target if it is in range, else the nearest enemy.
func _auto_attack() -> void:
	current_target = null
	var reach := stats.get_stat(&"attack_range")
	if priority_target != null and priority_target.alive and _in_reach(priority_target, reach):
		current_target = priority_target
	else:
		current_target = world.nearest_enemy(pos, reach, self)
	if current_target == null:
		return
	facing = (current_target.pos - pos).normalized()
	if attack_cooldown > 0.0:
		return
	attack_cooldown = stats.attack_interval()
	swing_left = minf(0.35, attack_cooldown)
	var ctx := {"auto": true}
	for s in passives:
		s.on_auto_attack(ctx)
	world.hero_attacked.emit(current_target)
	if ctx.has("cone"):
		var shape := {"type": "cone", "angle": float(ctx["cone"]), "radius": reach}
		for e in Shapes.query(world, shape, pos, facing, Team.ENEMY):
			deal_damage(e, 1.0, ctx)
	else:
		deal_damage(current_target, 1.0, ctx)


## All hero damage goes through here (GDD 6.3): crit, spread, armour, passives, lifesteal.
func deal_damage(target: Combatant, coef: float, ctx: Dictionary = {}) -> float:
	if target == null or not target.alive:
		return 0.0
	var rng := world.rng.stream("combat", world.floor_index)
	var crit_chance := 1.0 if ctx.get("force_crit", false) else stats.get_stat(&"crit_chance")
	var crit_damage := stats.get_stat(&"crit_damage") + float(ctx.get("crit_bonus", 0.0))
	var d := Damage.roll(stats.get_stat(&"atk"), coef, crit_chance, crit_damage, target.armor, rng)
	var was_alive := target.alive
	var taken := target.take_damage(d.amount, d.crit, self)
	if taken > 0.0:
		for s in passives:
			s.on_hit(target, taken, ctx)
	if was_alive and not target.alive:
		for s in all_skills():
			s.on_kill(target)
	return taken


## Lifesteal (GDD 6.3): heals a share of the damage actually dealt; overheal may become a shield.
func on_dealt_damage(_target: Combatant, amount: float) -> void:
	var ls := stats.get_stat(&"lifesteal")
	if ls <= 0.0:
		return
	var heal_amount := amount * ls
	var missing := max_hp - hp
	heal(heal_amount)
	var over := heal_amount - missing
	if over > 0.0:
		var lsp := find_skill(&"lifesteal_passive")
		if lsp != null and lsp.overheal_shield_cap() > 0.0:
			var cap := max_hp * lsp.overheal_shield_cap()
			statuses.add_shield(minf(over, maxf(0.0, cap - statuses.shield_amount())),
					float(lsp.p("shield_time", 5.0)))


func take_damage(amount: float, crit: bool, source: Entity, is_dot: bool = false) -> float:
	if not alive or is_invulnerable():
		return 0.0
	var scaled := statuses.shield_amount()
	if amount * damage_taken_mult - scaled >= hp:
		for s in passives:
			if s.on_lethal():
				world.damage_dealt.emit(self, 0.0, false, source)
				return 0.0
	var taken := super.take_damage(amount, crit, source, is_dot)
	if taken > 0.0 and alive and not is_dot:
		for s in passives:
			s.on_hero_damaged(source, taken)
	return taken


## Parry stance check, called by World.apply_strike before damage.
func try_parry(source: Combatant, parryable: bool) -> bool:
	var p := find_skill(&"parry")
	return p != null and p.parried(source, parryable)


func start_dash(dir: Vector2, distance: float, duration: float, skill: Skill) -> void:
	_dash_dir = dir.normalized() if dir.length() > 0.01 else facing
	facing = _dash_dir
	_dash_left = duration
	_dash_speed = distance / duration
	_dash_skill = skill
	anim_state = &"dash"


func _tick_dash(dt: float) -> void:
	var step := minf(dt, _dash_left)
	_dash_left -= step
	var from := pos
	pos = world.grid.move_circle(pos, radius, _dash_dir * _dash_speed * step)
	anim_state = &"dash"
	if _dash_skill != null:
		_dash_skill.dash_step(from, pos)


func try_dodge() -> bool:
	if dodge_charges <= 0 or is_dodging():
		return false
	var dir := input.move
	if dir.length() < 0.1:
		dir = _away_from_nearest_enemy()
	_dodge_dir = dir.normalized()
	facing = _dodge_dir
	dodge_charges -= 1
	if dodge_recharge <= 0.0:
		dodge_recharge = dodge_cooldown
	_dodge_left = dodge_duration
	_invulnerable_left = maxf(_invulnerable_left, dodge_invulnerable)
	return true


func _tick_dodge_cooldown(dt: float) -> void:
	if dodge_charges >= dodge_max_charges:
		dodge_recharge = 0.0
		return
	dodge_recharge -= dt
	if dodge_recharge <= 0.0:
		dodge_charges += 1
		dodge_recharge = dodge_cooldown if dodge_charges < dodge_max_charges else 0.0


func _in_reach(e: Entity, reach: float) -> bool:
	return pos.distance_to(e.pos) <= reach + e.radius


func _away_from_nearest_enemy() -> Vector2:
	var best: Entity = null
	var best_d := INF
	for e in world.entities:
		if e.team == Team.ENEMY and e.alive:
			var d := pos.distance_squared_to(e.pos)
			if d < best_d:
				best_d = d
				best = e
	if best == null or best.pos.is_equal_approx(pos):
		return -facing if facing != Vector2.ZERO else Vector2.DOWN
	return (pos - best.pos).normalized()
