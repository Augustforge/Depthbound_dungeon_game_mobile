extends Control
## Intro (GDD 3.3): four still frames with a line of text each; tap to go on, "Skip" to the camp.
## Frames slowly pan over the menu and camp art until the comic frames arrive (art track A5).

const WELL := preload("res://assets/ui/main_menu.webp")
const CAMP := preload("res://assets/ui/camp.webp")
const FRAMES := [
	{"art": "well", "key": "INTRO_1", "from": Vector2(0.0, 0.0), "zoom": 1.25},
	{"art": "well", "key": "INTRO_2", "from": Vector2(-0.15, -0.05), "zoom": 1.35},
	{"art": "well", "key": "INTRO_3", "from": Vector2(-0.1, -0.2), "zoom": 1.5},
	{"art": "camp", "key": "INTRO_4", "from": Vector2(-0.05, -0.05), "zoom": 1.2},
]

var _index: int = -1
var _art: TextureRect
var _text: Label
var _tween: Tween


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_art = UiKit.cover_art(self, WELL)
	_art.pivot_offset = Vector2(960, 540)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.35)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	_text = UiKit.label(self, "", 40, UiKit.TEXT)
	_text.add_theme_font_override(&"font", UiKit.FONT_BOLD)
	_text.add_theme_color_override(&"font_shadow_color", Color(0, 0, 0, 0.9))
	_text.add_theme_constant_override(&"shadow_offset_y", 4)
	_text.anchor_left = 0.1
	_text.anchor_right = 0.9
	_text.anchor_top = 0.72
	_text.anchor_bottom = 0.95
	var skip := UiKit.small_button(self, tr("BTN_SKIP"), _finish, 26)
	skip.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	skip.position = Vector2(size.x - 240, 30)
	skip.anchor_left = 1.0
	skip.offset_left = -240
	skip.offset_right = -30
	skip.offset_top = 30
	_next()


func _gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		_next()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.pressed and not event.is_echo():
		_next()


func _next() -> void:
	_index += 1
	if _index >= FRAMES.size():
		_finish()
		return
	var f: Dictionary = FRAMES[_index]
	_art.texture = WELL if f["art"] == "well" else CAMP
	_art.scale = Vector2.ONE * float(f["zoom"])
	_art.position = Vector2(f["from"]) * size
	_text.text = tr(String(f["key"]))
	_text.modulate.a = 0.0
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel()
	_tween.tween_property(_text, "modulate:a", 1.0, 0.8)
	_tween.tween_property(_art, "scale", Vector2.ONE * (float(f["zoom"]) - 0.12), 7.0)
	_tween.tween_property(_art, "position", Vector2(f["from"]) * size * 0.4, 7.0)


func _finish() -> void:
	GameState.profile.intro_seen = true
	GameState.to_camp()
