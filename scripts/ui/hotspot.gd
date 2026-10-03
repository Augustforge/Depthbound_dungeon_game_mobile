class_name Hotspot
extends Control
## A glowing ring with a caption over a background art: a place you can tap in the camp.

signal pressed

const RING := 112.0

var _button: Button
var _label: Label
var _time: float = 0.0


static func make(parent: Node, caption: String, cb: Callable) -> Hotspot:
	var h := Hotspot.new()
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.size = Vector2(RING, RING)
	parent.add_child(h)
	h._button = Button.new()
	h._button.size = Vector2(RING, RING)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.07, 0.04, 0.35)
	sb.border_color = UiKit.GOLD
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(int(RING * 0.5))
	var hov := sb.duplicate() as StyleBoxFlat
	hov.bg_color = Color(0.5, 0.3, 0.1, 0.45)
	for st in [&"normal", &"focus", &"disabled"]:
		h._button.add_theme_stylebox_override(st, sb)
	h._button.add_theme_stylebox_override(&"hover", hov)
	h._button.add_theme_stylebox_override(&"pressed", hov)
	h._button.pressed.connect(cb)
	h._button.pressed.connect(func() -> void: h.pressed.emit())
	h.add_child(h._button)
	h._label = UiKit.label(h, caption, 30, Color(1.0, 0.92, 0.75))
	h._label.add_theme_font_override(&"font", UiKit.FONT_BOLD)
	h._label.add_theme_color_override(&"font_shadow_color", Color(0, 0, 0, 0.95))
	h._label.add_theme_constant_override(&"shadow_offset_y", 3)
	h._label.add_theme_constant_override(&"shadow_outline_size", 8)
	h._label.autowrap_mode = TextServer.AUTOWRAP_OFF
	h._label.position = Vector2(-150, RING + 4)
	h._label.size = Vector2(RING + 300, 40)
	return h


func set_caption(text: String) -> void:
	_label.text = text


## Places the ring's centre at a screen point.
func place(center: Vector2) -> void:
	position = center - Vector2(RING, RING) * 0.5


func _process(delta: float) -> void:
	_time += delta
	var k := 0.75 + 0.25 * sin(_time * 2.4 + position.x * 0.01)
	_button.modulate = Color(1, 1, 1, k)
