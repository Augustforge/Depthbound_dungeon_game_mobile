extends Control
## Main menu (GDD 17.2 #2): art «Дно Колодца» with living effects, logo and buttons in the left
## third: Continue, New game, Settings, Credits. Shop, gear and records live in the camp.

const ART := preload("res://assets/ui/main_menu.webp")

var _continue: Button


func _ready() -> void:
	var art := UiKit.cover_art(self, ART)
	var tw := create_tween().set_loops()
	art.pivot_offset = Vector2(960, 540)
	tw.tween_property(art, "scale", Vector2(1.04, 1.04), 18.0).set_trans(Tween.TRANS_SINE)
	tw.tween_property(art, "scale", Vector2(1.0, 1.0), 18.0).set_trans(Tween.TRANS_SINE)
	var fx := ArtEffects.new()
	add_child(fx)
	fx.setup(ART)
	fx.add_beam_dust(Vector2(0.6, 0.02), Vector2(0.6, 0.62), 0.12, 46)
	fx.add_drops(0.3, 0.85, 16)
	fx.add_glints(Rect2(0.56, 0.75, 0.33, 0.13), 26)
	for t: Vector2 in [Vector2(0.9, 0.445), Vector2(0.869, 0.573), Vector2(0.679, 0.59), Vector2(0.712, 0.69),
			Vector2(0.832, 0.676)]:
		fx.add_glow(t, 0.05, Color(1.0, 0.55, 0.2), 0.45)
	_shade_left()
	_build_panel()
	EventBus.language_changed.connect(func(_l: String) -> void: _build_panel())


## Darkens the left third so the logo and buttons read over the art.
func _shade_left() -> void:
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0.75))
	g.set_color(1, Color(0, 0, 0, 0.0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill_from = Vector2(0, 0)
	t.fill_to = Vector2(1, 0)
	var r := TextureRect.new()
	r.texture = t
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.anchor_bottom = 1.0
	r.anchor_right = 0.5
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)


func _build_panel() -> void:
	if has_node("Panel"):
		get_node("Panel").free()
	var box := VBoxContainer.new()
	box.name = "Panel"
	box.anchor_bottom = 1.0
	box.offset_left = 110
	box.offset_right = 760
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override(&"separation", 22)
	add_child(box)
	var title_text := tr("GAME_TITLE").to_upper()
	# Fit the logo into the left third whatever the language.
	var font_size := 130
	while font_size > 60 and UiKit.FONT_DISPLAY.get_string_size(title_text, HORIZONTAL_ALIGNMENT_LEFT, -1,
			font_size).x > 620.0:
		font_size -= 4
	var logo := UiKit.label(box, title_text, font_size, Color(0.93, 0.86, 0.72))
	logo.autowrap_mode = TextServer.AUTOWRAP_OFF
	logo.add_theme_font_override(&"font", UiKit.FONT_DISPLAY)
	logo.add_theme_color_override(&"font_shadow_color", Color(0, 0, 0, 0.8))
	logo.add_theme_constant_override(&"shadow_offset_y", 6)
	UiKit.label(box, tr("MENU_TAGLINE"), 30, Color(0.6, 0.85, 0.85))
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 30)
	box.add_child(spacer)
	_continue = _menu_button(box, tr("MENU_CONTINUE"), _on_continue)
	_continue.disabled = not GameState.profile.hero_chosen
	_menu_button(box, tr("MENU_NEW_GAME"), _on_new_game)
	_menu_button(box, tr("MENU_SETTINGS"), func() -> void: SettingsWindow.new().setup(self))
	_menu_button(box, tr("MENU_CREDITS"), func() -> void: CreditsWindow.new().setup(self))
	var ver := UiKit.label(box, "v%s" % ProjectSettings.get_setting("application/config/version", "0.5"), 20,
		Color(0.5, 0.5, 0.5))
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT


func _menu_button(parent: Node, text: String, cb: Callable) -> Button:
	var b := UiKit.button(parent, text, cb, 38)
	b.custom_minimum_size = Vector2(500, 84)
	return b


func _on_continue() -> void:
	if GameState.has_run():
		GameState.descend()
	else:
		GameState.to_camp()


func _on_new_game() -> void:
	if not GameState.profile.hero_chosen:
		GameState.goto(GameState.HERO_SELECT_SCENE)
		return
	ConfirmWindow.new().ask(self, tr("MENU_NEW_GAME"), tr("MENU_NEW_GAME_CONFIRM"),
		func() -> void: GameState.goto(GameState.HERO_SELECT_SCENE))
