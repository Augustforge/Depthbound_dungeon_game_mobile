class_name Hero
extends Combatant
## The player character: joystick movement, auto-attack while standing, dodge (GDD 5, 6, 7).

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


## Re-reads derived values after stat sources changed (gear, cards, buffs).
func refresh_stats() -> void:
	var ratio := hp / max_hp if max_hp > 0.0 else 1.0
	max_hp = stats.get_stat(&"max_hp")
	hp = max_hp * ratio
	armor = stats.get_stat(&"armor")
	move_speed = stats.get_stat(&"move_speed")


func is_dodging() -> bool:
	return _dodge_left > 0.0


func is_invulnerable() -> bool:
	return immortal or _invulnerable_left > 0.0


## 0..1 progress of the current dodge cooldown, 1 when a charge is ready (for the HUD).
func dodge_ready_ratio() -> float:
	if dodge_charges > 0:
		return 1.0
	return 1.0 - dodge_recharge / dodge_cooldown


func tick(dt: float) -> void:
	super.tick(dt)
	attack_cooldown = maxf(0.0, attack_cooldown - dt)
	swing_left = maxf(0.0, swing_left - dt)
	_tick_dodge_cooldown(dt)
	_invulnerable_left = maxf(0.0, _invulnerable_left - dt)
	if input.consume_dodge():
		try_dodge()
	if _dodge_left > 0.0:
		var step := minf(dt, _dodge_left)
		_dodge_left -= step
		pos = world.grid.move_circle(pos, radius, _dodge_dir * (dodge_distance / dodge_duration) * step)
		anim_state = &"dodge"
		return
	var move := input.move.limit_length(1.0)
	velocity = move * move_speed * speed_factor
	if move.length() > 0.1:
		facing = move.normalized()
		pos = world.grid.move_circle(pos, radius, velocity * dt)
		anim_state = &"run"
	else:
		velocity = Vector2.ZERO
		_auto_attack()
		anim_state = &"attack" if swing_left > 0.0 else &"idle"


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
	var rng := world.rng.stream("combat", world.floor_index)
	var d := Damage.roll(stats.get_stat(&"atk"), 1.0, stats.get_stat(&"crit_chance"), stats.get_stat(&"crit_damage"),
			current_target.armor, rng)
	world.hero_attacked.emit(current_target)
	current_target.take_damage(d.amount, d.crit, self)


func _in_reach(e: Entity, reach: float) -> bool:
	return pos.distance_to(e.pos) <= reach + e.radius


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
	_invulnerable_left = dodge_invulnerable
	return true


func _tick_dodge_cooldown(dt: float) -> void:
	if dodge_charges >= dodge_max_charges:
		dodge_recharge = 0.0
		return
	dodge_recharge -= dt
	if dodge_recharge <= 0.0:
		dodge_charges += 1
		dodge_recharge = dodge_cooldown if dodge_charges < dodge_max_charges else 0.0


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
