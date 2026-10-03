class_name Combatant
extends Entity
## An entity with health and armour that can deal and take damage.

var max_hp: float = 100.0
var hp: float = 100.0
var armor: float = 0.0
var essence: int = 0
## Seconds since the last hit taken (views flash on hit).
var since_hit: float = 99.0
var statuses: StatusEffects = StatusEffects.new()
## Multiplier for incoming damage (e.g. Whirlwind level 5 = 0.6).
var damage_taken_mult: float = 1.0


func is_invulnerable() -> bool:
	return false


## Applies damage that was already computed by Damage.roll. Returns the amount actually taken.
## is_dot = damage over time (bleed): does not trigger on-hit reactions.
func take_damage(amount: float, crit: bool, source: Entity, is_dot: bool = false) -> float:
	if not alive or is_invulnerable():
		return 0.0
	amount *= damage_taken_mult
	amount = statuses.absorb(amount)
	if amount <= 0.0:
		return 0.0
	var taken := minf(amount, hp)
	hp -= taken
	since_hit = 0.0
	world.damage_dealt.emit(self, amount, crit, source)
	if source is Combatant and source != self:
		(source as Combatant).on_dealt_damage(self, taken)
	if not is_dot:
		_on_damaged(source)
	if hp <= 0.0:
		die(source)
	return taken


func heal(amount: float) -> void:
	hp = minf(max_hp, hp + amount)


func die(_killer: Entity) -> void:
	alive = false
	hp = 0.0
	anim_state = &"death"
	world.entity_died.emit(self)


func _on_damaged(_source: Entity) -> void:
	pass


## Called on the attacker after it damaged someone (lifesteal etc.).
func on_dealt_damage(_target: Combatant, _amount: float) -> void:
	pass


func tick(dt: float) -> void:
	since_hit += dt
	statuses.tick(self, dt)
