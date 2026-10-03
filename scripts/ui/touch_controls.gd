class_name TouchControls
extends Control
## Multi-touch controls (GDD 5): floating joystick on the left half, round buttons bottom-right.
## Mouse works as a finger on PC (input_devices/pointing/emulate_touch_from_mouse).

signal dodge_pressed
signal action_pressed
signal skill_pressed(index: int)
signal auto_toggled
## A tap on the right half of the screen outside the buttons (used to pick a priority target).
signal world_tapped(screen_pos: Vector2)

const JOY_RADIUS := 120.0
const DEAD_ZONE := 0.15

var joystick: Vector2 = Vector2.ZERO
## 0..1, 1 = ready. Set by the HUD every frame.
var dodge_ready: float = 1.0
var dodge_charges: int = 1
## Per slot: {"ready": 0..1, "level": int, "label": String, "seconds": float} or {} when empty.
var skills: Array[Dictionary] = [{}, {}, {}]
var auto_on: bool = false
var action_visible: bool = false
var action_progress: float = 0.0
const SKILL_OFFSETS: Array[Vector2] = [Vector2(-235, 30), Vector2(-175, -160), Vector2(0, -235)]
const SKILL_RADIUS := 68.0

var _joy_finger: int = -1
var _joy_origin: Vector2
var _joy_knob: Vector2


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Left-handed layout (GDD 17.2 #13): everything mirrored, the joystick on the right.
func _m(p: Vector2) -> Vector2:
	return Vector2(size.x - p.x, p.y) if Settings.left_handed else p


func _rh_dodge() -> Vector2:
	return Vector2(size.x - 210.0, size.y - 190.0)


func _dodge_center() -> Vector2:
	return _m(_rh_dodge())


func _skill_center(i: int) -> Vector2:
	return _m(_rh_dodge() + SKILL_OFFSETS[i])


func _action_center() -> Vector2:
	return _m(_rh_dodge() + Vector2(-420, 30))


func _auto_center() -> Vector2:
	return _m(_rh_dodge() + Vector2(150, -330))


func _joy_rest() -> Vector2:
	return _m(Vector2(260.0, size.y - 250.0))


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			if t.position.distance_to(_dodge_center()) < 110.0:
				dodge_pressed.emit()
				get_viewport().set_input_as_handled()
				return
			for i in 3:
				if not skills[i].is_empty() and t.position.distance_to(_skill_center(i)) < SKILL_RADIUS + 12.0:
					skill_pressed.emit(i)
					get_viewport().set_input_as_handled()
					return
			if action_visible and t.position.distance_to(_action_center()) < 80.0:
				action_pressed.emit()
				get_viewport().set_input_as_handled()
				return
			if t.position.distance_to(_auto_center()) < 55.0:
				auto_toggled.emit()
				get_viewport().set_input_as_handled()
			elif (t.position.x >= size.x * 0.5) != Settings.left_handed:
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
	for i in 3:
		_draw_skill(i, font)
	if action_visible:
		var xc := _action_center()
		draw_circle(xc, 72.0, Color(0.1, 0.18, 0.12, 0.9))
		draw_arc(xc, 72.0, 0, TAU, 48, Color(0.6, 0.95, 0.6), 4.0, true)
		if action_progress > 0.0:
			draw_arc(xc, 64.0, -PI / 2.0, -PI / 2.0 + TAU * action_progress, 48, Color(0.95, 0.95, 0.6), 9.0, true)
		var at2 := tr("BTN_ACTION")
		var aw2 := font.get_string_size(at2, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
		draw_string(font, xc + Vector2(-aw2 * 0.5, 9), at2, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.9, 1, 0.9))
	var ac := _auto_center()
	draw_circle(ac, 48.0, Color(0.85, 0.55, 0.15, 0.9) if auto_on else Color(0.06, 0.07, 0.08, 0.75))
	draw_arc(ac, 48.0, 0, TAU, 48, Color(0.95, 0.85, 0.6), 3.0, true)
	var at := "AUTO"
	var aw := font.get_string_size(at, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
	draw_string(font, ac + Vector2(-aw * 0.5, 8), at, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
	var label := tr("BTN_DODGE")
	var fs := 30
	var tw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(font, c + Vector2(-tw * 0.5, 10), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ready_col)


func _draw_skill(i: int, font: Font) -> void:
	var s: Dictionary = skills[i]
	var c := _skill_center(i)
	if s.is_empty():
		draw_arc(c, SKILL_RADIUS, 0, TAU, 48, Color(0.5, 0.45, 0.38, 0.35), 2.0, true)
		return
	var ready: float = s["ready"]
	draw_circle(c, SKILL_RADIUS, Color(0.12, 0.05, 0.04, 0.85) if ready >= 1.0 else Color(0.05, 0.05, 0.06, 0.85))
	if ready < 1.0:
		draw_arc(c, SKILL_RADIUS - 5.0, -PI / 2.0, -PI / 2.0 + TAU * ready, 48, Color(0.95, 0.4, 0.2, 0.9), 8.0, true)
		var secs := "%d" % ceili(s["seconds"])
		var sw := font.get_string_size(secs, HORIZONTAL_ALIGNMENT_LEFT, -1, 34).x
		draw_string(font, c + Vector2(-sw * 0.5, 12), secs, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color.WHITE)
	else:
		draw_arc(c, SKILL_RADIUS, 0, TAU, 48, Color(0.95, 0.55, 0.25), 4.0, true)
		var text: String = s["label"]
		var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
		draw_string(font, c + Vector2(-tw * 0.5, 8), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 0.9, 0.75))
	# Level dots under the button (GDD 8.4).
	var lvl: int = s["level"]
	for d in 5:
		var dp := c + Vector2((d - 2) * 16.0, SKILL_RADIUS + 14.0)
		draw_circle(dp, 5.0, Color(1, 0.8, 0.3) if d < lvl else Color(0.3, 0.28, 0.25))
