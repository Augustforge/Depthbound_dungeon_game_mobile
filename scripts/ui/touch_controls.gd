class_name TouchControls
extends Control
## Multi-touch controls (GDD 5): floating joystick on the left half, round buttons bottom-right.
## Mouse works as a finger on PC (input_devices/pointing/emulate_touch_from_mouse).

signal dodge_pressed
signal action_pressed
## A tap on the right half of the screen outside the buttons (used to pick a priority target).
signal world_tapped(screen_pos: Vector2)

const JOY_RADIUS := 120.0
const DEAD_ZONE := 0.15

var joystick: Vector2 = Vector2.ZERO
## 0..1, 1 = ready. Set by the HUD every frame.
var dodge_ready: float = 1.0
var dodge_charges: int = 1

var _joy_finger: int = -1
var _joy_origin: Vector2
var _joy_knob: Vector2


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _dodge_center() -> Vector2:
	return Vector2(size.x - 210.0, size.y - 190.0)


func _joy_rest() -> Vector2:
	return Vector2(260.0, size.y - 250.0)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			if t.position.distance_to(_dodge_center()) < 110.0:
				dodge_pressed.emit()
				get_viewport().set_input_as_handled()
			elif t.position.x >= size.x * 0.5:
				world_tapped.emit(t.position)
			elif _joy_finger == -1:
				_joy_finger = t.index
				_joy_origin = t.position
				_joy_knob = t.position
				_update_joystick()
				get_viewport().set_input_as_handled()
		elif t.index == _joy_finger:
			_joy_finger = -1
			joystick = Vector2.ZERO
			queue_redraw()
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index == _joy_finger:
			_joy_knob = d.position
			_update_joystick()
			get_viewport().set_input_as_handled()


func _update_joystick() -> void:
	var off := (_joy_knob - _joy_origin).limit_length(JOY_RADIUS)
	_joy_knob = _joy_origin + off
	var v := off / JOY_RADIUS
	joystick = v if v.length() > DEAD_ZONE else Vector2.ZERO
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var origin := _joy_origin if _joy_finger != -1 else _joy_rest()
	var knob := _joy_knob if _joy_finger != -1 else origin
	var alpha := 0.55 if _joy_finger != -1 else 0.22
	draw_circle(origin, JOY_RADIUS, Color(0.05, 0.08, 0.09, alpha * 0.6))
	draw_arc(origin, JOY_RADIUS, 0, TAU, 64, Color(0.75, 0.68, 0.55, alpha), 3.0, true)
	draw_circle(knob, 46.0, Color(0.85, 0.78, 0.62, alpha + 0.15))
	var c := _dodge_center()
	draw_circle(c, 92.0, Color(0.06, 0.07, 0.08, 0.75))
	var ready_col := Color(0.95, 0.85, 0.6) if dodge_ready >= 1.0 else Color(0.5, 0.45, 0.38)
	draw_arc(c, 92.0, -PI / 2.0, -PI / 2.0 + TAU * dodge_ready, 64, ready_col, 6.0, true)
	var font := get_theme_default_font()
	var label := tr("BTN_DODGE")
	var fs := 30
	var tw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(font, c + Vector2(-tw * 0.5, 10), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ready_col)
