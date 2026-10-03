class_name CardText
extends RefCounted
## Localised title and description of a card (GDD 9.3).


static func title(card: Dictionary) -> String:
	var cfg: Dictionary = DataDB.table(&"cards")
	match card["kind"]:
		&"stat":
			return TranslationServer.translate(cfg["stats"][String(card["id"])]["name_key"])
		&"time":
			return TranslationServer.translate(cfg["time"][String(card["id"])]["name_key"])
		&"dodge":
			return TranslationServer.translate(cfg["dodge"][String(card["id"])]["name_key"])
		&"skill":
			var skill_name := TranslationServer.translate(DataDB.table(&"skills")[String(card["skill"])]["name_key"])
			return TranslationServer.translate("CARD_SKILL_UP") % skill_name
	return String(card["id"])


static func description(card: Dictionary, run: RunState) -> String:
	var cfg: Dictionary = DataDB.table(&"cards")
	var r: int = card["rarity"]
	match card["kind"]:
		&"stat":
			var c: Dictionary = cfg["stats"][String(card["id"])]
			var stat: String = c.get("pct", c.get("flat", ""))
			var v := float(c["values"][r])
			var shown := ("%d%%" % roundi(v * 100.0)) if (c.has("pct") or v < 1.0) else str(v)
			if stat == "armor":
				shown = str(roundi(v))
			return TranslationServer.translate("STAT_" + stat) % shown
		&"time":
			var t := float(cfg["time"][String(card["id"])]["time_pct"][r])
			return TranslationServer.translate("CARD_RESPITE_DESC") % ("%d%%" % roundi(t * 100.0))
		&"dodge":
			return TranslationServer.translate(String(cfg["dodge"][String(card["id"])]["name_key"]) + "_DESC")
		&"skill":
			var lvl := int(run.skill_entry(card["skill"]).get("level", 1))
			var add := int(cfg["skill_upgrade"]["levels"][r])
			var key := "CARD_SKILL_UP_RARE" if r == 1 else "CARD_SKILL_UP_DESC"
			return TranslationServer.translate(key) % [lvl, mini(5, lvl + add)]
	return ""


static func rarity_color(r: int) -> Color:
	return [Color(0.62, 0.62, 0.62), Color(0.3, 0.55, 1.0), Color(0.72, 0.35, 1.0)][clampi(r, 0, 2)]
