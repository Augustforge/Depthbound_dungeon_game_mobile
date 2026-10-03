class_name Profile
extends RefCounted
## Everything that outlives a run (GDD 4, 11, 14): wallet, gear, records, merchant, hero look, and
## the run in progress with its phase. Saved as one json (GDD 19.6, SaveManager).

const VERSION := 1
const DUNGEON := "d01"

var gold: int = 0
var crystals: int = 0
var inventory: Array[Item] = []
## slot (StringName) -> Item
var equipped: Dictionary = {}
var hero_class: StringName = &"swordsman"
var hero_look: StringName = &"male"
## False until the player picked class and look on the first new game (GDD 3.4).
var hero_chosen: bool = false
var intro_seen: bool = false
## Deepest floor ever reached: the merchant's item level (GDD 14.3).
var best_floor: int = 1
## dungeon -> {"floors": {"3": {"time": float, "stars": int}}, "best_total": float, "best_tier": int,
## "completed": bool}
var records: Dictionary = {}
var merchant_stock: Array[Item] = []
var merchant_rolls: int = 0
var meta_seed: int = 0
var run: RunState = null
## &"floor": the run waits at the start of run.floor_index; &"reward": the floor is done and the
## summary / boss reward is shown (GDD 11.1 — closing the app there returns to the same choice).
var run_phase: StringName = &"floor"
var pending_result: Dictionary = {}


static func create(seed_value: int) -> Profile:
	var p := Profile.new()
	p.meta_seed = seed_value
	p.refresh_merchant()
	return p


# --- inventory and equipment ---

func inventory_size() -> int:
	return int(Item.cfg()["inventory_size"])


func inventory_full() -> bool:
	return inventory.size() >= inventory_size()


## Adds to the inventory; a full inventory sells the item to Ulm on the spot (returns false).
func add_item(it: Item) -> bool:
	if inventory_full():
		gold += it.sell_price()
		return false
	inventory.append(it)
	return true


func equipped_items() -> Array[Item]:
	var out: Array[Item] = []
	for slot: Variant in Item.cfg()["slots"]:
		var it: Item = equipped.get(StringName(slot))
		if it != null:
			out.append(it)
	return out


func equip(it: Item) -> void:
	var idx := inventory.find(it)
	if idx < 0:
		return
	inventory.remove_at(idx)
	var old: Item = equipped.get(it.slot)
	equipped[it.slot] = it
	if old != null:
		inventory.insert(idx, old)


func unequip(slot: StringName) -> bool:
	var it: Item = equipped.get(slot)
	if it == null or inventory_full():
		return false
	equipped.erase(slot)
	inventory.append(it)
	return true


func sell(it: Item) -> void:
	var idx := inventory.find(it)
	if idx < 0:
		return
	inventory.remove_at(idx)
	gold += it.sell_price()


## Gear stats for the hero (GDD 6.2 source "gear").
func apply_gear(hero: Hero) -> void:
	var b := Loot.gear_bonuses(equipped_items())
	hero.stats.set_source(&"gear", b[0], b[1])
	hero.refresh_stats()


# --- merchant (GDD 14.5) ---

func refresh_merchant() -> void:
	var rng := RngStreams.new(meta_seed).stream("merchant", merchant_rolls)
	merchant_rolls += 1
	merchant_stock.clear()
	for i in int(Item.cfg()["merchant"]["stock"]):
		merchant_stock.append(Loot.roll_item("merchant", best_floor, rng))


func can_buy(it: Item) -> bool:
	return merchant_stock.has(it) and gold >= it.price() and not inventory_full()


func buy(it: Item) -> bool:
	if not can_buy(it):
		return false
	gold -= it.price()
	merchant_stock.erase(it)
	inventory.append(it)
	return true


func paid_refresh() -> bool:
	var cost := int(Item.cfg()["merchant"]["refresh_crystals"])
	if crystals < cost:
		return false
	crystals -= cost
	refresh_merchant()
	return true


# --- records (GDD 11.5) ---

func dungeon_record(dungeon: String = DUNGEON) -> Dictionary:
	if not records.has(dungeon):
		records[dungeon] = {"floors": {}, "best_total": 0.0, "best_tier": -1, "completed": false}
	return records[dungeon]


func floor_record(index: int, dungeon: String = DUNGEON) -> Dictionary:
	return dungeon_record(dungeon)["floors"].get(str(index), {})


## Returns true if the time is a new best for the floor.
func record_floor(index: int, time: float, stars: int, dungeon: String = DUNGEON) -> bool:
	var floors: Dictionary = dungeon_record(dungeon)["floors"]
	var rec: Dictionary = floors.get(str(index), {})
	var best := rec.is_empty() or time < float(rec["time"])
	floors[str(index)] = {"time": time if best else float(rec["time"]),
		"stars": maxi(stars, int(rec.get("stars", 0)))}
	return best


func dungeon_completed(dungeon: String = DUNGEON) -> bool:
	return bool(dungeon_record(dungeon)["completed"])


# --- save ---

## Json turns every number into a float: restore the ints of the records.
static func _clean_records(src: Dictionary) -> Dictionary:
	var out := {}
	for dungeon: String in src:
		var r: Dictionary = src[dungeon]
		var floors := {}
		for k: String in r.get("floors", {}):
			var f: Dictionary = r["floors"][k]
			floors[k] = {"time": float(f.get("time", 0.0)), "stars": int(f.get("stars", 0))}
		out[dungeon] = {"floors": floors, "best_total": float(r.get("best_total", 0.0)),
			"best_tier": int(r.get("best_tier", -1)), "completed": bool(r.get("completed", false))}
	return out


func to_dict() -> Dictionary:
	var inv := []
	for it in inventory:
		inv.append(it.to_dict())
	var eq := {}
	for slot: StringName in equipped:
		eq[String(slot)] = (equipped[slot] as Item).to_dict()
	var stock := []
	for it in merchant_stock:
		stock.append(it.to_dict())
	var pending := pending_result.duplicate(true)
	if pending.has("loot"):
		var items := []
		for it: Variant in pending["loot"]:
			items.append(it.to_dict() if it is Item else it)
		pending["loot"] = items
	return {"version": VERSION, "gold": gold, "crystals": crystals, "inventory": inv, "equipped": eq,
		"hero_class": String(hero_class), "hero_look": String(hero_look), "hero_chosen": hero_chosen,
		"intro_seen": intro_seen, "best_floor": best_floor, "records": records, "merchant_stock": stock,
		"merchant_rolls": merchant_rolls, "meta_seed": meta_seed,
		"run": run.to_dict() if run != null else null, "run_phase": String(run_phase), "pending_result": pending}


static func from_dict(d: Dictionary) -> Profile:
	var p := Profile.new()
	p.gold = int(d.get("gold", 0))
	p.crystals = int(d.get("crystals", 0))
	for x: Dictionary in d.get("inventory", []):
		p.inventory.append(Item.from_dict(x))
	var eq: Dictionary = d.get("equipped", {})
	for slot: String in eq:
		p.equipped[StringName(slot)] = Item.from_dict(eq[slot])
	p.hero_class = StringName(d.get("hero_class", "swordsman"))
	p.hero_look = StringName(d.get("hero_look", "male"))
	p.hero_chosen = bool(d.get("hero_chosen", false))
	p.intro_seen = bool(d.get("intro_seen", false))
	p.best_floor = int(d.get("best_floor", 1))
	p.records = _clean_records(d.get("records", {}))
	for x: Dictionary in d.get("merchant_stock", []):
		p.merchant_stock.append(Item.from_dict(x))
	p.merchant_rolls = int(d.get("merchant_rolls", 0))
	p.meta_seed = int(d.get("meta_seed", 0))
	var r: Variant = d.get("run")
	p.run = RunState.from_dict(r) if r is Dictionary else null
	p.run_phase = StringName(d.get("run_phase", "floor"))
	p.pending_result = d.get("pending_result", {})
	if p.pending_result.has("loot"):
		var items: Array[Item] = []
		for x: Variant in p.pending_result["loot"]:
			if x is Dictionary:
				items.append(Item.from_dict(x))
		p.pending_result["loot"] = items
	return p
