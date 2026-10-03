class_name SimBuild
extends RefCounted
## A typical hero arriving at floor N, for the test bot (and later the debug menu): one card per
## cleared floor, the boss skill after floor 5, and common gear of item level N - 1 in weapon,
## helmet and armour (GDD 14.3) until the loot system lands.

const CARDS: Array[Dictionary] = [
	{"id": &"sharpness", "kind": &"stat", "rarity": 1},
	{"id": &"vitality", "kind": &"stat", "rarity": 1},
	{"id": &"skill_up", "kind": &"skill", "skill": &"cleave", "rarity": 0},
	{"id": &"quick_hand", "kind": &"stat", "rarity": 0},
	{"id": &"bloodthirst", "kind": &"stat", "rarity": 1},
	{"id": &"skill_up", "kind": &"skill", "skill": &"bleed", "rarity": 0},
	{"id": &"sharpness", "kind": &"stat", "rarity": 0},
	{"id": &"tempering", "kind": &"stat", "rarity": 0},
	{"id": &"skill_up", "kind": &"skill", "skill": &"cleave", "rarity": 1},
]


static func make_run(seed_value: int, floor_index: int) -> RunState:
	var run := RunState.new_run(seed_value)
	run.floor_index = floor_index
	if floor_index > 5:
		run.add_skill(&"whirlwind")
	for i in mini(floor_index - 1, CARDS.size()):
		run.take_card(CARDS[i])
	return run


static func apply_gear(hero: Hero, ilvl: int) -> void:
	if ilvl <= 0:
		return
	hero.stats.set_source(&"gear_sim", {&"atk": 6.0 + 1.0 * ilvl, &"max_hp": 70.0 + 14.0 * ilvl,
		&"armor": 4.0 + 0.8 * ilvl})
	hero.refresh_stats()
	hero.hp = hero.max_hp
