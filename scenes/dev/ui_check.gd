extends Control
## Dev: opens every meta screen and window once with sample data, so script errors in rarely
## reached UI paths show up in the log (tools/screenshot.sh fails on SCRIPT ERROR).
## Run: tools/screenshot.sh res://scenes/dev/ui_check.tscn out.png 120 [--step=N]


func _ready() -> void:
	var p := Profile.create(5)
	GameState.profile = p
	Progress.start_run(p, 77)
	var rng := RngStreams.new(3).stream("ui", 1)
	for i in 6:
		p.add_item(Loot.roll_item("relic", 3, rng))
	p.equip(p.inventory[0])
	var result := {"floor": 3, "time": 72.0, "stars": 2, "essence": 15.0, "essence_total": 23.0, "essence_fill": 0.65,
		"double_card": true, "gold": 120, "crystals": 1, "loot": [Loot.roll_item("iron", 3, rng)], "boss": ""}
	var r := Progress.complete_floor(p, result)
	var step := int(DevTools.arg("step", "0"))
	match step:
		0:
			var s := SummaryScreen.new()
			add_child(s)
			s.setup(p.run, r)
			s._show_cards(CardDeck.offer(p.run, 0.65, rng))
		1:
			var boss_res := result.duplicate()
			boss_res["floor"] = 5
			boss_res["boss"] = "warden_grum"
			var br := Progress.complete_floor(p, boss_res)
			var b := BossRewardScreen.new()
			add_child(b)
			b.setup(p.run, br)
			b._show_skills()
		2:
			EquipmentWindow.new().setup(self, p)._select(p.inventory[0])
		3:
			MerchantWindow.new().setup(self, p)
		4:
			RecordsWindow.new().setup(self, p)
			ReflectionWindow.new().setup(self, p)
		5:
			SettingsWindow.new().setup(self)
			CreditsWindow.new().setup(self)
		6:
			for i in range(1, 11):
				p.run.stars[str(i)] = 2
			p.run.floor_index = 11
			add_child(load("res://scenes/final.tscn").instantiate())
	print("UI_CHECK step %d ok" % step)
