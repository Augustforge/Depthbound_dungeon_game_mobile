class_name Telegraph
extends RefCounted
## A telegraphed strike (GDD 12.1): the zone is shown for `total` seconds, then hits everyone of
## `target_team` inside it. Damage is reduced by the target's armour.

var id: StringName = &""
var shape: Dictionary = {}
var origin: Vector2
var dir: Vector2 = Vector2.DOWN
var total: float = 1.0
var left: float = 1.0
var source: Combatant
var target_team: Entity.Team = Entity.Team.HERO
var damage: float = 0.0
## {"stun": s, "root": s, "slow": [value, s], "pull": true, "knockback": m}
var effect: Dictionary = {}
var parryable: bool = true
## Traps hit every team (GDD 12.1: traps hit mobs too).
var hit_all: bool = false
var fired: bool = false


func progress() -> float:
	return 1.0 - left / total if total > 0.0 else 1.0
