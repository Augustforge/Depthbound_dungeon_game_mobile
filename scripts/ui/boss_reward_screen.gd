class_name BossRewardScreen
extends CanvasLayer
## Boss reward (GDD 15): chest (gold, items, crystals) -> new skill (1 of 3 of the boss's type) ->
## Reforge: drop 1 (weak boss) or 2 (medium boss) taken cards, pick 1 of 3 new for each.

signal finished

var run: RunState
var reward: Dictionary
var result: Dictionary
var _root: Control
var _rng: RandomNumberGenerator
var _reforge_left: int = 0


func setup(r: RunState, res: Dictionary) -> void:
	run = r
	result = res
	layer = 40
	reward = DataDB.table(&"bosses")[String(res["boss"])]["reward"]
	_rng = RngStreams.new(run.run_seed).stream("boss_reward", int(res["floor"]))
	_reforge_left = int(reward.get("reforge", 0))
	_show_chest()


func _clear() -> void:
	if _root:
		_root.queue_free()
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	UiKit.dimmer(_root, 0.75)


func _show_chest() -> void:
	_clear()
	var box := UiKit.centered_box(_root)
	UiKit.label(box, tr("BOSS_DEFEATED"), 52, UiKit.BRONZE)
	UiKit.label(box, "★".repeat(int(result["stars"])) + "☆".repeat(3 - int(result["stars"])), 72, Color(1, 0.8, 0.3))
	var gained := UiKit.wallet(box, int(result.get("gold_total", 0)), int(result.get("crystals_total", 0)), 34)
	gained.alignment = BoxContainer.ALIGNMENT_CENTER
	SummaryScreen.loot_row(box, result)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", 24)
	box.add_child(row)
	UiKit.button(row, tr("EQUIP_TITLE"), func() -> void: EquipmentWindow.new().setup(self, GameState.profile))
	UiKit.button(row, tr("BTN_NEXT"), _show_skills)


func _show_skills() -> void:
	var pool := run.missing_skills(String(reward["skill_type"]))
	if pool.is_empty():
		_show_reforge()
		return
	# Deterministic pick of up to 3.
	for i in range(pool.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var t := pool[i]
		pool[i] = pool[j]
		pool[j] = t
	_clear()
	var outer := _column(tr("CHOOSE_SKILL"))
	var row := _row(outer)
	for id in pool.slice(0, 3):
		var sd: Dictionary = DataDB.table(&"skills")[String(id)]
		_option(row, tr(String(sd["name_key"])), tr(String(sd["desc_key"])), Color(1.0, 0.65, 0.25), func() -> void:
			run.add_skill(id)
			_show_reforge())


func _show_reforge() -> void:
	if _reforge_left <= 0 or run.cards.is_empty():
		_finish()
		return
	_clear()
	var outer := _column(tr("REFORGE_TITLE") % _reforge_left)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override(&"h_separation", 18)
	grid.add_theme_constant_override(&"v_separation", 18)
	outer.add_child(grid)
	for i in run.cards.size():
		var c: Dictionary = run.cards[i]
		var b := UiKit.button(grid, "%s\n%s" % [CardText.title(c), tr("RARITY_%d" % int(c["rarity"]))],
				_reforge_card.bind(i), 24)
		b.custom_minimum_size = Vector2(330, 110)
		b.add_theme_color_override(&"font_color", CardText.rarity_color(int(c["rarity"])))
	UiKit.button(outer, tr("BTN_SKIP"), _finish)


func _reforge_card(index: int) -> void:
	run.remove_card(index)
	_reforge_left -= 1
	_clear()
	var outer := _column(tr("CHOOSE_CARD"))
	var row := _row(outer)
	for card in CardDeck.offer(run, 0.5, _rng):
		_option(row, CardText.title(card), CardText.description(card, run), CardText.rarity_color(int(card["rarity"])),
				func() -> void:
					run.take_card(card)
					_show_reforge())


func _finish() -> void:
	_clear()
	var box := UiKit.centered_box(_root, 700)
	UiKit.button(box, tr("BTN_DESCEND"), func() -> void: finished.emit())


func _column(title: String) -> VBoxContainer:
	var outer := VBoxContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.alignment = BoxContainer.ALIGNMENT_CENTER
	outer.add_theme_constant_override(&"separation", 30)
	_root.add_child(outer)
	UiKit.label(outer, title, 48, UiKit.BRONZE)
	return outer


func _row(parent: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", 36)
	parent.add_child(row)
	return row


func _option(parent: Control, title: String, desc: String, col: Color, cb: Callable) -> void:
	var b := Button.new()
	b.custom_minimum_size = Vector2(440, 500)
	var sb := UiKit.panel_style(col)
	sb.set_border_width_all(6)
	b.add_theme_stylebox_override(&"normal", sb)
	var hov := sb.duplicate() as StyleBoxFlat
	hov.bg_color = Color(0.12, 0.1, 0.1, 0.96)
	b.add_theme_stylebox_override(&"hover", hov)
	b.add_theme_stylebox_override(&"pressed", hov)
	b.add_theme_stylebox_override(&"focus", sb)
	b.pressed.connect(cb)
	parent.add_child(b)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 24
	box.offset_right = -24
	box.offset_top = 30
	box.add_theme_constant_override(&"separation", 24)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(box)
	for l in [UiKit.label(box, title, 38, col), UiKit.label(box, desc, 28, Color(0.85, 0.85, 0.8))]:
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
