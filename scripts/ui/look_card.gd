class_name LookCard
extends Button
## A portrait button for the hero's look (hero select and the Reflection).


static func make(parent: Node, look: StringName, portrait: Texture2D, selected: bool, cb: Callable) -> LookCard:
	var b := LookCard.new()
	b.custom_minimum_size = Vector2(400, 620)
	var sb := UiKit.panel_style(UiKit.GOLD if selected else Color(0.35, 0.3, 0.25))
	sb.set_border_width_all(6 if selected else 3)
	sb.set_content_margin_all(10)
	var hov := sb.duplicate() as StyleBoxFlat
	hov.bg_color = Color(0.15, 0.11, 0.08, 0.97)
	for st in [&"normal", &"focus", &"disabled"]:
		b.add_theme_stylebox_override(st, sb)
	b.add_theme_stylebox_override(&"hover", hov)
	b.add_theme_stylebox_override(&"pressed", hov)
	b.pressed.connect(cb)
	parent.add_child(b)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 12
	box.offset_right = -12
	box.offset_top = 12
	box.offset_bottom = -12
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(box)
	var pic := TextureRect.new()
	pic.texture = portrait
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(pic)
	var l := UiKit.title(box, TranslationServer.translate("LOOK_" + String(look).to_upper()), 32,
		UiKit.GOLD if selected else UiKit.TEXT)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b
