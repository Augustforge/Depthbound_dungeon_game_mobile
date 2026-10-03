extends Skill
## Lifesteal passive (GDD 8.2 #9): +6..12 % lifesteal; level 3 turns overheal into a shield
## (up to 10 % max HP, 5 s); level 5 heals 3 % max HP per kill.


func stat_bonus() -> Dictionary:
	return {"flat": {&"lifesteal": float(p("lifesteal"))}, "pct": {}}


func overheal_shield_cap() -> float:
	return float(p("overheal_shield", 0.0))


func on_kill(_target: Combatant) -> void:
	if p("kill_heal", 0.0) > 0.0:
		hero.heal(hero.max_hp * float(p("kill_heal")))
