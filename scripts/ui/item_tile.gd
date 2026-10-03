class_name ItemTile
extends Button
## A square tile for one item (or an empty slot): slot name, level, rarity-coloured frame.
## Item icons replace the text in the art track (A5).

const SIZE := Vector2(150, 118)

var item: Item


static func make(parent: Node, it: Item, cb: Callable, empty_text: String = "", selected: bool = false,
		tile_size: Vector2 = SIZE, empty_slot: StringName = &"") -> ItemTile:
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
	var icon := Icons.slot(it.slot) if it != null else (Icons.slot(empty_slot) if empty_slot != &"" else null)
	if icon != null and it == null:
		# An empty equipment slot: its icon, faded.
		var ghost := TextureRect.new()
		ghost.texture = icon
		ghost.modulate = Color(1, 1, 1, 0.25)
		ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ghost.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ghost.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ghost.offset_left = 12
		ghost.offset_top = 12
		ghost.offset_right = -12
		ghost.offset_bottom = -12
		ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
		t.add_child(ghost)
	elif icon != null:
		var pic := TextureRect.new()
		pic.texture = icon
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		pic.offset_left = 8
		pic.offset_top = 8
		pic.offset_right = -8
		pic.offset_bottom = -8
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		t.add_child(pic)
		var lvl := Label.new()
		lvl.text = str(it.ilvl)
		lvl.add_theme_font_size_override(&"font_size", 22)
		lvl.add_theme_color_override(&"font_color", col)
		lvl.add_theme_color_override(&"font_outline_color", Color.BLACK)
		lvl.add_theme_constant_override(&"outline_size", 6)
		lvl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		lvl.offset_left = -34
		lvl.offset_top = -32
		lvl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		t.add_child(lvl)
	elif it != null:
		t.text = "%s\n%s" % [ItemText.title(it), TranslationServer.translate("ITEM_LEVEL") % it.ilvl]
	else:
		t.text = empty_text
	t.pressed.connect(cb)
	parent.add_child(t)
	return t
