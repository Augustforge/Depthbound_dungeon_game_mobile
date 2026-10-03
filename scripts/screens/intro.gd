extends Control
## Intro (GDD 3.3): four still frames with a line of text each; tap to go on, "Skip" to the camp.
## Painted frames (art track A5) with a slow pan and zoom.

const WELL := preload("res://assets/ui/main_menu.webp")
const FRAMES := [
	{"art": "res://assets/ui/intro/frame1.webp", "key": "INTRO_1", "from": Vector2(0.0, 0.0), "zoom": 1.15},
	{"art": "res://assets/ui/intro/frame2.webp", "key": "INTRO_2", "from": Vector2(-0.06, -0.02), "zoom": 1.2},
	{"art": "res://assets/ui/intro/frame3.webp", "key": "INTRO_3", "from": Vector2(-0.04, -0.08), "zoom": 1.25},
	{"art": "res://assets/ui/intro/frame4.webp", "key": "INTRO_4", "from": Vector2(-0.03, -0.03), "zoom": 1.15},
]

var _index: int = -1
var _art: TextureRect
var _text: Label
var _tween: Tween


func _ready() -> void:
	AudioManager.play_music(&"camp")
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_art = UiKit.cover_art(self, WELL)
	_art.pivot_offset = Vector2(960, 540)
	# A dark band under the text so it reads over any frame.
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0.0))
	g.set_color(1, Color(0, 0, 0, 0.8))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	var shade := TextureRect.new()
	shade.texture = gt
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.anchor_right = 1.0
	shade.anchor_top = 0.55
	shade.anchor_bottom = 1.0
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
	_art.texture = load(String(f["art"])) if ResourceLoader.exists(String(f["art"])) else WELL
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
