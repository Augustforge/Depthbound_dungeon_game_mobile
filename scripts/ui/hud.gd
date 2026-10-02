class_name Hud
extends CanvasLayer
## In-floor HUD (GDD 17.3), placeholder look: floor and timer on top, water gauge on the right edge.

var world: World
var controls: TouchControls
var _title: Label
var _timer_label: Label
var _hint: Label
var _fps: Label
var _gauge: WaterGauge
var _hp_bar: HpBar
var overlay: WorldOverlay


func setup(w: World) -> void:
	world = w
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_title = _label(root, 34, Color(0.9, 0.84, 0.72))
	_title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_title.position.y = 24
	_timer_label = _label(root, 54, Color(0.95, 0.92, 0.85))
	_timer_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_timer_label.position.y = 66
	_hint = _label(root, 26, Color(0.8, 0.85, 0.85, 0.8))
	_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_hint.position.y -= 60
	_fps = _label(root, 22, Color(0.6, 0.7, 0.7))
	_fps.position = Vector2(40, 16)
	_gauge = WaterGauge.new()
	_gauge.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	_gauge.custom_minimum_size = Vector2(46, 420)
	_gauge.size = Vector2(46, 420)
	_gauge.position = Vector2(-140, -260)
	root.add_child(_gauge)
	_hp_bar = HpBar.new()
	_hp_bar.position = Vector2(40, 70)
	_hp_bar.size = Vector2(420, 34)
	root.add_child(_hp_bar)
	overlay = WorldOverlay.new()
	root.add_child(overlay)
	root.move_child(overlay, 0)
	controls = TouchControls.new()
	root.add_child(controls)


func _label(parent: Control, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override(&"font_size", font_size)
	l.add_theme_color_override(&"font_color", color)
	l.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override(&"outline_size", 8)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.grow_horizontal = Control.GROW_DIRECTION_BOTH
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func _process(_delta: float) -> void:
	if world == null:
		return
	var t := world.timer
	_title.text = tr("HUD_FLOOR") % [world.floor_index, 25]
	var rem := ceili(t.remaining())
	_timer_label.text = "%d:%02d" % [rem / 60, rem % 60]
	var alarm := t.remaining() <= 30.0
	_timer_label.add_theme_color_override(&"font_color", Color(1, 0.35, 0.3) if alarm else Color(0.95, 0.92, 0.85))
	_hint.text = tr("SPIKE_HINT")
	_fps.text = "%d FPS" % Engine.get_frames_per_second()
	_gauge.ratio = clampf(t.progress(), 0.0, 1.0)
	controls.dodge_ready = world.hero.dodge_ready_ratio()
	_hp_bar.hp = world.hero.hp
	_hp_bar.max_hp = world.hero.max_hp


class HpBar:
	extends Control
	var hp: float = 1.0
	var max_hp: float = 1.0

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r.grow(3), Color(0, 0, 0, 0.8))
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * clampf(hp / max_hp, 0, 1), size.y)), Color(0.75, 0.12, 0.1))
		draw_rect(r, Color(0.7, 0.62, 0.48), false, 2.0)
		var font := get_theme_default_font()
		var text := "%d / %d" % [ceili(hp), roundi(max_hp)]
		var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
		draw_string(font, Vector2((size.x - tw) * 0.5, size.y - 8), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)


class WaterGauge:
	extends Control
	var ratio: float = 0.0

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Color(0.03, 0.05, 0.06, 0.8))
		var h := size.y * ratio
		draw_rect(Rect2(0, size.y - h, size.x, h), Color(0.15, 0.75, 0.72, 0.9))
		for mark: float in [0.5, 0.8]:
			var y := size.y * (1.0 - mark)
			draw_line(Vector2(-6, y), Vector2(size.x + 6, y), Color(0.9, 0.85, 0.7, 0.8), 2.0)
		draw_rect(r, Color(0.7, 0.62, 0.48), false, 3.0)
