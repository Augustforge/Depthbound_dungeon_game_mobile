class_name StatusEffects
extends RefCounted
## Timed effects on a combatant (GDD 19.2): bleed, stun, slow, root, knockback, pull, shield.

## type -> {"time": float, "value": float, "stacks": int, ...}
## The owner is passed to tick() instead of stored, to avoid a reference cycle.
var effects: Dictionary = {}


func has(type: StringName) -> bool:
	return effects.has(type)


func apply(type: StringName, time: float, value: float = 0.0) -> void:
	if effects.has(type):
		var e: Dictionary = effects[type]
		e["time"] = maxf(e["time"], time)
		e["value"] = maxf(e["value"], value)
	else:
		effects[type] = {"time": time, "value": value, "stacks": 1}


## Bleed: damage per second per stack, stacks up to max_stacks, a new stack refreshes the duration.
func apply_bleed(dps: float, time: float, max_stacks: int, source: Entity) -> void:
	if effects.has(&"bleed"):
		var e: Dictionary = effects[&"bleed"]
		e["stacks"] = mini(int(e["stacks"]) + 1, max_stacks)
		e["time"] = time
		e["value"] = maxf(e["value"], dps)
		e["source"] = source
	else:
		effects[&"bleed"] = {"time": time, "value": dps, "stacks": 1, "source": source, "tick": 0.0}


## Forced movement (knockback away, pull towards): velocity in m/s for `time` seconds.
func push(velocity: Vector2, time: float) -> void:
	effects[&"forced"] = {"time": time, "value": 0.0, "stacks": 1, "velocity": velocity}


func add_shield(amount: float, time: float) -> void:
	var cur := shield_amount()
	effects[&"shield"] = {"time": time, "value": cur + amount, "stacks": 1}


func shield_amount() -> float:
	return float(effects[&"shield"]["value"]) if effects.has(&"shield") else 0.0


## Absorbs damage with the shield; returns what is left.
func absorb(amount: float) -> float:
	if not effects.has(&"shield"):
		return amount
	var e: Dictionary = effects[&"shield"]
	var take := minf(e["value"], amount)
	e["value"] -= take
	if e["value"] <= 0.0:
		effects.erase(&"shield")
	return amount - take


func can_move() -> bool:
	return not (has(&"stun") or has(&"root") or has(&"forced"))


func can_act() -> bool:
	return not (has(&"stun") or has(&"forced"))


func speed_multiplier() -> float:
	return 1.0 - (float(effects[&"slow"]["value"]) if effects.has(&"slow") else 0.0)


func tick(owner: Combatant, dt: float) -> void:
	for type: StringName in effects.keys():
		var e: Dictionary = effects[type]
		if type == &"bleed":
			e["tick"] += dt
			while e["tick"] >= 1.0 and owner.alive:
				e["tick"] -= 1.0
				# Bleed never crits and ignores armour (GDD 6.3).
				owner.take_damage(e["value"] * e["stacks"], false, e.get("source"), true)
		elif type == &"forced" and owner.alive:
			owner.pos = owner.world.grid.move_circle(owner.pos, owner.radius, e["velocity"] * dt)
		e["time"] -= dt
		if e["time"] <= 0.0:
			effects.erase(type)
