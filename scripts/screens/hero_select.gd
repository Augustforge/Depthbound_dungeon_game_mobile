extends Control
## Hero select (GDD 3.4, 17.2 #3): class — only the Swordsman in the MVP, the others "Coming
## soon" — and the look, man or woman. Changing the look later: the Reflection in the camp.

const ART := preload("res://assets/ui/main_menu.webp")
const CLASSES: Array[StringName] = [&"swordsman", &"guardian", &"hunter", &"assassin"]

var _look: StringName = &"male"
var _box: VBoxContainer


func _ready() -> void:
	AudioManager.play_music(&"camp")
	UiKit.cover_art(self, ART)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	_look = GameState.profile.hero_look
	_build()


func _build() -> void:
	if _box:
		_box.queue_free()
	_box = VBoxContainer.new()
	_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_box.add_theme_constant_override(&"separation", 20)
	add_child(_box)
	UiKit.title(_box, tr("SELECT_TITLE"), 52)
	var classes := HBoxContainer.new()
	classes.alignment = BoxContainer.ALIGNMENT_CENTER
	classes.add_theme_constant_override(&"separation", 20)
	_box.add_child(classes)
	for id in CLASSES:
		_class_card(classes, id)
	var looks := HBoxContainer.new()
	looks.alignment = BoxContainer.ALIGNMENT_CENTER
	looks.add_theme_constant_override(&"separation", 40)
	_box.add_child(looks)
	for look: StringName in [&"male", &"female"]:
		var card := LookCard.make(looks, look, ReflectionWindow.PORTRAITS[look], _look == look, func() -> void:
			_look = look
			_build())
		card.custom_minimum_size = Vector2(300, 470)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", 30)
	_box.add_child(row)
	UiKit.button(row, tr("BTN_BACK"), func() -> void: GameState.goto(GameState.MENU_SCENE))
	UiKit.button(row, tr("SELECT_START"), _start)


func _class_card(parent: Node, id: StringName) -> void:
	var locked := id != &"swordsman"
	var p := UiKit.panel(parent, UiKit.GOLD if not locked else Color(0.3, 0.28, 0.25))
	p.custom_minimum_size = Vector2(300, 120)
	if locked:
		p.modulate = Color(1, 1, 1, 0.6)
	var b := VBoxContainer.new()
	p.add_child(b)
	UiKit.title(b, tr("CLASS_" + String(id).to_upper()), 32, UiKit.TEXT if not locked else UiKit.DIM_TEXT)
	UiKit.label(b, tr("CLASS_SOON") if locked else tr("CLASS_SWORDSMAN_DESC"), 22,
		UiKit.DIM_TEXT if locked else Color(0.8, 0.78, 0.7))


func _start() -> void:
	GameState.new_game(&"swordsman", _look)
	GameState.goto(GameState.INTRO_SCENE)
