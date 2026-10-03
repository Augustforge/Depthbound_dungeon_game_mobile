extends Skill
## Fury (GDD 8.2 #12): +0.5..0.7 % damage per 1 % missing HP; level 3 also attack speed;
## level 5: below 30 % HP, +10 % lifesteal.


func stat_bonus() -> Dictionary:
	var missing := (1.0 - hero.hp / hero.max_hp) * 100.0 if hero.max_hp > 0.0 else 0.0
	var pct := {&"atk": missing * float(p("atk_per_pct")), &"attack_speed": missing * float(p("as_per_pct", 0.0))}
	var flat := {}
	if p("low_hp_lifesteal", 0.0) > 0.0 and hero.hp < hero.max_hp * float(p("low_hp")):
		flat[&"lifesteal"] = float(p("low_hp_lifesteal"))
	return {"flat": flat, "pct": pct}
