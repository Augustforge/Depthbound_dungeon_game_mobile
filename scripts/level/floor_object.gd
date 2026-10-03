class_name FloorObject
extends Entity
## Interactive objects on a floor (GDD 13.2): stairs, chests, lever, gate, lock gate, valve,
## flood valve, spring, note, bear trap. Behaviour is selected by `kind`.

enum Kind { STAIRS, CHEST, LEVER, GATE, LOCK_GATE, VALVE, FLOOD_VALVE, SPRING, NOTE, BEAR_TRAP }

var kind: Kind
var cell: Vector2i
var used: bool = false
## Chest tier: &"wood", &"iron", &"relic".
var tier: StringName = &""
## Gate/lock gate: closed blocks the cell.
var closed: bool = false
## Lever / flood valve links: gate cells, harpoon cells, flood rect.
var links: Array = []
var flood_rect: Rect2i
## Lock gate: pack letter it locks for.
var pack: String = ""
## Note localisation key.
var note_key: String = ""
## Bear trap: sprung or disarmed traps do nothing.
var armed: bool = true


func _init() -> void:
	team = Team.NEUTRAL


const INTERACT_KEYS := {
	Kind.LEVER: "lever", Kind.VALVE: "valve", Kind.FLOOD_VALVE: "flood_valve",
	Kind.CHEST: "chest", Kind.SPRING: "spring", Kind.BEAR_TRAP: "bear_trap",
}


func interact_time() -> float:
	if not INTERACT_KEYS.has(kind):
		return 0.0
	return float(DataDB.table(&"floor")["interact_times"][INTERACT_KEYS[kind]])


func can_interact() -> bool:
	match kind:
		Kind.CHEST, Kind.SPRING, Kind.VALVE, Kind.FLOOD_VALVE:
			return not used
		Kind.LEVER:
			return not used
		Kind.BEAR_TRAP:
			return armed
	return false


## Finished interaction (or a throwing blade hit a lever).
func activate() -> void:
	if not can_interact():
		return
	match kind:
		Kind.LEVER:
			used = true
			world.pull_lever(self)
		Kind.VALVE:
			used = true
			world.seal_activated(self)
		Kind.FLOOD_VALVE:
			used = true
			world.start_flood(self)
		Kind.CHEST:
			used = true
			world.open_chest(self)
		Kind.SPRING:
			used = true
			world.offer_spring(self)
		Kind.BEAR_TRAP:
			armed = false
	world.object_changed.emit(self)


func set_closed(value: bool) -> void:
	if closed == value:
		return
	closed = value
	world.grid.set_blocked(cell, closed)
	world.refresh_navigation_cell(cell)
	world.object_changed.emit(self)


func tick(_dt: float) -> void:
	match kind:
		Kind.BEAR_TRAP:
			if not armed:
				return
			var r := float(DataDB.table(&"floor")["bear_trap"]["trigger_radius"])
			for e in world.entities:
				if e is Combatant and e.alive and e.team != Team.NEUTRAL and e.pos.distance_to(pos) < r + e.radius * 0.5:
					if e == world.hero and world.hero.is_dodging():
						continue
					_spring_on(e)
					return
		Kind.NOTE:
			if not used and world.hero.pos.distance_to(pos) < 1.0:
				used = true
				world.note_found.emit(note_key)
				world.object_changed.emit(self)


func _spring_on(e: Combatant) -> void:
	armed = false
	var cfg: Dictionary = DataDB.table(&"floor")["bear_trap"]
	e.take_damage(Damage.mob_damage(float(cfg["damage"]), world.floor_index) * Damage.armor_factor(e.armor), false, self)
	e.statuses.apply(&"root", float(cfg["root"]))
	world.object_changed.emit(self)
