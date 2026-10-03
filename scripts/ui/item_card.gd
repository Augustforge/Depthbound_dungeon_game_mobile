class_name ItemCard
extends PanelContainer
## Item details: name, rarity and level, stats, the difference against the equipped item
## (green / red arrows, GDD 14.3), and action buttons.


static func make(parent: Node, it: Item, compare_to: Item = null, show_compare: bool = true) -> ItemCard:
	var c := ItemCard.new()
	c.add_theme_stylebox_override(&"panel", UiKit.panel_style(ItemText.color(it)))
	c.custom_minimum_size = Vector2(470, 0)
	parent.add_child(c)
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 8)
	c.add_child(box)
	var t := UiKit.title(box, ItemText.title(it), 36, ItemText.color(it))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_left(UiKit.label(box, ItemText.subtitle(it), 24, UiKit.DIM_TEXT))
	for line in ItemText.lines(it):
		_left(UiKit.label(box, String(line["text"]), 28 if line["main"] else 25,
			UiKit.TEXT if line["main"] else Color(0.75, 0.8, 0.95)))
	if show_compare:
		var diff := ItemText.compare(it, compare_to)
		if not diff.is_empty():
			_left(UiKit.label(box, TranslationServer.translate("ITEM_COMPARE"), 22, UiKit.DIM_TEXT))
			for d in diff:
				_left(UiKit.label(box, String(d["text"]), 24,
					Color(0.45, 0.9, 0.4) if float(d["delta"]) > 0.0 else Color(0.95, 0.4, 0.35)))
	c.set_meta(&"box", box)
	return c


## Adds a row of action buttons under the stats.
func add_actions(actions: Array[Dictionary]) -> void:
	var box: VBoxContainer = get_meta(&"box")
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 12)
	box.add_child(row)
	for a in actions:
		var b := UiKit.small_button(row, String(a["text"]), a["cb"], 24)
		b.disabled = bool(a.get("disabled", false))


static func _left(l: Label) -> void:
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
