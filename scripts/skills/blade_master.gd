extends Skill
## Blade Master (GDD 8.2 #8): every 3rd auto-attack is a guaranteed crit (+20/40 % crit damage at
## levels 2/4), hits in a 120° cone at level 3, reduces active cooldowns by 0.5 s at level 5.

var _count: int = 0


func on_auto_attack(ctx: Dictionary) -> void:
	_count += 1
	if _count % int(p("every")) != 0:
		return
	ctx["force_crit"] = true
	ctx["crit_bonus"] = float(ctx.get("crit_bonus", 0.0)) + float(p("crit_bonus"))
	if p("cone", 0) > 0:
		ctx["cone"] = float(p("cone"))
	if p("cdr_seconds", 0.0) > 0.0:
		for s in hero.actives:
			if s != null:
				s.reduce_cooldown(float(p("cdr_seconds")))
