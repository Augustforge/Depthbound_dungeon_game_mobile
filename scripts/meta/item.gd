class_name Item
extends RefCounted
## A piece of gear (GDD 14.3): slot, rarity, item level, main stats and extra properties.
## Values are rolled once (Loot) and stored, so an item never changes after it drops.

var uid: int = 0
var slot: StringName = &"weapon"
## 0 common .. 4 legendary
var rarity: int = 0
var ilvl: int = 1
## stat -> value (rarity multiplier already applied)
var main: Dictionary = {}
## [{"stat": StringName, "value": float}]
var affixes: Array[Dictionary] = []


static func cfg() -> Dictionary:
	return DataDB.table(&"gear")


## All stats of the item: stat -> value.
func stats() -> Dictionary:
	var out := main.duplicate()
	for a in affixes:
		out[a["stat"]] = float(out.get(a["stat"], 0.0)) + float(a["value"])
	return out


static func is_pct(stat: StringName) -> bool:
	return String(stat) in cfg()["pct_stats"]


## Merchant price (GDD 14.5); legendaries are never sold by Ulm but can be sold to him.
func price() -> int:
	var base := float(cfg()["prices"][rarity])
	return roundi(base * (1.0 + float(cfg()["price_ilvl_scale"]) * ilvl))


func sell_price() -> int:
	return maxi(1, roundi(price() * float(cfg()["sell_share"])))


## Rough power for sorting and the "better" hint: sum of stats in comparable units.
func score() -> float:
	var weights := {&"atk": 4.0, &"max_hp": 0.5, &"armor": 2.0, &"attack_speed": 400.0, &"move_speed": 300.0,
		&"crit_chance": 500.0, &"crit_damage": 120.0, &"lifesteal": 900.0, &"cdr": 400.0, &"floor_time": 600.0}
	var s := 0.0
	var all := stats()
	for k: StringName in all:
		s += float(all[k]) * float(weights.get(k, 1.0))
	return s


func to_dict() -> Dictionary:
	var ax := []
	for a in affixes:
		ax.append({"stat": String(a["stat"]), "value": a["value"]})
	var m := {}
	for k: StringName in main:
		m[String(k)] = main[k]
	return {"uid": uid, "slot": String(slot), "rarity": rarity, "ilvl": ilvl, "main": m, "affixes": ax}


static func from_dict(d: Dictionary) -> Item:
	var it := Item.new()
	it.uid = int(d.get("uid", 0))
	it.slot = StringName(d.get("slot", "weapon"))
	it.rarity = int(d.get("rarity", 0))
	it.ilvl = int(d.get("ilvl", 1))
	var m: Dictionary = d.get("main", {})
	for k: String in m:
		it.main[StringName(k)] = float(m[k])
	for a: Dictionary in d.get("affixes", []):
		it.affixes.append({"stat": StringName(a["stat"]), "value": float(a["value"])})
	return it
