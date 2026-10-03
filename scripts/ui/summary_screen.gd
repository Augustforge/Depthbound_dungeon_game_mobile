class_name SummaryScreen
extends CanvasLayer
## Floor summary (GDD 10.7) and card choice (9.1): once, or twice when the essence threshold is
## reached; one reroll per floor for crystals (9.5). Emits `finished` when the player descends.

signal finished

var run: RunState
var result: Dictionary
var _root: Control
var _picks_left: int = 1
var _rng: RandomNumberGenerator
var _reroll_rng: RandomNumberGenerator


func setup(r: RunState, res: Dictionary) -> void:
	run = r
	result = res
	layer = 40
	_picks_left = 2 if res["double_card"] else 1
	var streams := RngStreams.new(run.run_seed)
	_rng = streams.stream("cards", int(res["floor"]))
	_reroll_rng = streams.stream("reroll", int(res["floor"]))
	if DevTools.arg("show_cards") == "1":
		_show_cards(CardDeck.offer(run, float(res["essence_fill"]), _rng))
	else:
		_show_stats()


func _clear() -> void:
	if _root:
		_root.queue_free()
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	UiKit.dimmer(_root)


func _show_stats() -> void:
	_clear()
	var box := UiKit.centered_box(_root)
	UiKit.label(box, tr("SUMMARY_TITLE") % int(result["floor"]), 48, UiKit.BRONZE)
	UiKit.label(box, "★".repeat(int(result["stars"])) + "☆".repeat(3 - int(result["stars"])), 72, Color(1, 0.8, 0.3))
	var t := int(result["time"])
	UiKit.label(box, "%s: %d:%02d" % [tr("SUMMARY_TIME"), t / 60, t % 60], 34)
	var pct := roundi(100.0 * float(result["essence"]) / maxf(float(result["essence_total"]), 1.0))
	if result.get("new_best", false):
		UiKit.label(box, tr("SUMMARY_NEW_BEST"), 28, Color(0.5, 0.95, 0.5))
	elif result.has("best_time"):
		UiKit.label(box, tr("SUMMARY_BEST") % UiKit.time_text(float(result["best_time"])), 28, UiKit.DIM_TEXT)
	UiKit.label(box, "%s: %d%%" % [tr("SUMMARY_ESSENCE"), pct], 34)
	var gained := UiKit.wallet(box, int(result.get("gold_total", result["gold"])), int(result.get("crystals_total", 0)),
		34)
	gained.alignment = BoxContainer.ALIGNMENT_CENTER
	SummaryScreen.loot_row(box, result)
	if result["double_card"]:
		UiKit.label(box, tr("SUMMARY_DOUBLE"), 30, Color(0.75, 0.55, 1.0))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", 24)
	box.add_child(row)
	UiKit.button(row, tr("EQUIP_TITLE"), func() -> void: EquipmentWindow.new().setup(self, GameState.profile))
	UiKit.button(row, tr("CHOOSE_CARD"), _show_cards.bind(CardDeck.offer(run, float(result["essence_fill"]), _rng)))


## Items found on the floor (and sold for lack of room) as a row of tiles.
static func loot_row(parent: Control, res: Dictionary) -> void:
	var items: Array = res.get("loot", [])
	if items.is_empty():
		return
	UiKit.label(parent, TranslationServer.translate("SUMMARY_LOOT"), 28, UiKit.DIM_TEXT)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", 12)
	parent.add_child(row)
	for it: Variant in items:
		if it is Item:
			ItemTile.make(row, it, func() -> void: pass)
	if int(res.get("auto_sold", 0)) > 0:
		UiKit.label(parent, TranslationServer.translate("SUMMARY_SOLD") % int(res["auto_sold"]), 24,
			Color(0.95, 0.6, 0.4))


func _show_cards(offer: Array[Dictionary]) -> void:
	_clear()
	var outer := VBoxContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.alignment = BoxContainer.ALIGNMENT_CENTER
	outer.add_theme_constant_override(&"separation", 30)
	_root.add_child(outer)
	UiKit.label(outer, tr("CHOOSE_CARD"), 52, UiKit.BRONZE)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", 36)
	outer.add_child(row)
	for card in offer:
		_card_widget(row, card)
	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	outer.add_child(bottom)
	var cost := int(DataDB.table(&"cards")["reroll_cost"])
	var reroll := UiKit.button(bottom, tr("BTN_REROLL") % cost, func() -> void:
		GameState.profile.crystals -= cost
		run.rerolls_used_on_floor += 1
		_show_cards(CardDeck.offer(run, float(result["essence_fill"]), _reroll_rng)))
	reroll.disabled = GameState.profile.crystals < cost or run.rerolls_used_on_floor >= 1


func _card_widget(parent: Control, card: Dictionary) -> void:
	var col := CardText.rarity_color(int(card["rarity"]))
	var b := Button.new()
	b.custom_minimum_size = Vector2(420, 520)
	var sb := UiKit.panel_style(col)
	sb.set_border_width_all(6)
	b.add_theme_stylebox_override(&"normal", sb)
	var hov := sb.duplicate() as StyleBoxFlat
	hov.bg_color = Color(0.12, 0.1, 0.1, 0.96)
	b.add_theme_stylebox_override(&"hover", hov)
	b.add_theme_stylebox_override(&"pressed", hov)
	b.add_theme_stylebox_override(&"focus", sb)
	b.pressed.connect(_pick.bind(card))
	parent.add_child(b)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 24
	box.offset_right = -24
	box.offset_top = 30
	box.alignment = BoxContainer.ALIGNMENT_BEGIN
	box.add_theme_constant_override(&"separation", 26)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(box)
	if card["kind"] == &"skill" and Icons.skill(card["skill"]) != null:
		var pic := TextureRect.new()
		pic.texture = Icons.skill(card["skill"])
		pic.custom_minimum_size = Vector2(120, 120)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(pic)
	for l in [UiKit.label(box, tr("RARITY_%d" % int(card["rarity"])), 26, col),
			UiKit.label(box, CardText.title(card), 40, UiKit.TEXT),
			UiKit.label(box, CardText.description(card, run), 32, Color(0.85, 0.85, 0.8))]:
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _pick(card: Dictionary) -> void:
	AudioManager.play(&"card_pick")
	run.take_card(card)
	_picks_left -= 1
	if _picks_left > 0:
		_show_cards(CardDeck.offer(run, float(result["essence_fill"]), _rng))
		return
	_clear()
	var box := UiKit.centered_box(_root, 700)
	UiKit.label(box, CardText.title(card), 40, CardText.rarity_color(int(card["rarity"])))
	UiKit.button(box, tr("BTN_DESCEND"), func() -> void: finished.emit())
