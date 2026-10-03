class_name ItemTile
extends Button
## A square tile for one item (or an empty slot): slot name, level, rarity-coloured frame.
## Item icons replace the text in the art track (A5).

const SIZE := Vector2(150, 118)

var item: Item


static func make(parent: Node, it: Item, cb: Callable, empty_text: String = "", selected: bool = false,
		tile_size: Vector2 = SIZE) -> ItemTile:
	var t := ItemTile.new()
	t.item = it
	t.custom_minimum_size = tile_size
	t.clip_text = true
	t.add_theme_font_size_override(&"font_size", 22)
	var col := ItemText.color(it) if it != null else Color(0.35, 0.33, 0.3)
	var sb := UiKit.panel_style(col)
	sb.set_content_margin_all(6)
	sb.bg_color = Color(0.09, 0.08, 0.08, 0.95) if it != null else Color(0.05, 0.05, 0.05, 0.8)
	sb.set_border_width_all(5 if selected else 3)
	if selected:
		sb.bg_color = Color(0.2, 0.15, 0.1, 0.98)
	var hov := sb.duplicate() as StyleBoxFlat
	hov.bg_color = Color(0.22, 0.16, 0.1, 0.98)
	for st in [&"normal", &"focus", &"disabled"]:
		t.add_theme_stylebox_override(st, sb)
	t.add_theme_stylebox_override(&"hover", hov)
	t.add_theme_stylebox_override(&"pressed", hov)
	t.add_theme_color_override(&"font_color", col if it != null else UiKit.DIM_TEXT)
	t.add_theme_color_override(&"font_hover_color", col if it != null else UiKit.DIM_TEXT)
	if it != null:
		t.text = "%s\n%s" % [ItemText.title(it), TranslationServer.translate("ITEM_LEVEL") % it.ilvl]
	else:
		t.text = empty_text
	t.pressed.connect(cb)
	parent.add_child(t)
	return t
