class_name UiKit
extends RefCounted
## Shared look for placeholder UI (until art track A5): dark stone panels, bronze borders.

const BRONZE := Color(0.78, 0.62, 0.4)
const TEXT := Color(0.95, 0.9, 0.8)


static func panel_style(border: Color = BRONZE) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.06, 0.07, 0.94)
	sb.border_color = border
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(24)
	return sb


static func panel(parent: Node, border: Color = BRONZE) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override(&"panel", panel_style(border))
	parent.add_child(p)
	return p


static func label(parent: Node, text: String, size: int = 32, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override(&"font_size", size)
	l.add_theme_color_override(&"font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(l)
	return l


static func button(parent: Node, text: String, cb: Callable, size: int = 34) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override(&"font_size", size)
	b.custom_minimum_size = Vector2(360, 84)
	var normal := panel_style()
	normal.bg_color = Color(0.16, 0.1, 0.07, 0.95)
	normal.set_content_margin_all(12)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.3, 0.17, 0.08, 0.95)
	b.add_theme_stylebox_override(&"normal", normal)
	b.add_theme_stylebox_override(&"hover", hover)
	b.add_theme_stylebox_override(&"pressed", hover)
	b.add_theme_stylebox_override(&"focus", normal)
	b.add_theme_stylebox_override(&"disabled", normal)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


## Full-screen dimmer that blocks touches to the game below.
static func dimmer(parent: Node, alpha: float = 0.7) -> ColorRect:
	var c := ColorRect.new()
	c.color = Color(0, 0, 0, alpha)
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(c)
	return c


static func centered_box(parent: Control, min_width: float = 900.0) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(center)
	var p := panel(center)
	p.custom_minimum_size = Vector2(min_width, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 18)
	p.add_child(box)
	return box
