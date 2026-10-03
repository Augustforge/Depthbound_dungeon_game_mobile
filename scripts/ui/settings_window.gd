class_name SettingsWindow
extends UiWindow
## Settings (GDD 17.2 #13): language, music, sounds, vibration, left-handed layout.


func setup(parent: Node) -> SettingsWindow:
	open(parent, tr("SETTINGS_TITLE"), Vector2(1100, 760), 70)
	_build()
	return self


func _build() -> void:
	clear_body()
	set_title(tr("SETTINGS_TITLE"))
	var langs := _row(tr("SETTINGS_LANGUAGE"))
	for loc in Settings.LOCALES:
		var b := UiKit.small_button(langs, tr("LANG_" + loc.to_upper()), func() -> void:
			Settings.set_locale(loc)
			_build(), 26)
		b.custom_minimum_size = Vector2(170, 64)
		if Settings.locale == loc:
			b.add_theme_color_override(&"font_color", UiKit.GOLD)
	_slider(tr("SETTINGS_MUSIC"), Settings.music_volume, func(v: float) -> void:
		Settings.music_volume = v
		Settings.save())
	_slider(tr("SETTINGS_SOUNDS"), Settings.sfx_volume, func(v: float) -> void:
		Settings.sfx_volume = v
		Settings.save())
	_toggle(tr("SETTINGS_VIBRATION"), Settings.vibration, func(on: bool) -> void:
		Settings.vibration = on
		Settings.save())
	_toggle(tr("SETTINGS_LEFT_HANDED"), Settings.left_handed, func(on: bool) -> void:
		Settings.left_handed = on
		Settings.save())


func _row(title_text: String) -> HBoxContainer:
	var r := HBoxContainer.new()
	r.add_theme_constant_override(&"separation", 16)
	body.add_child(r)
	var l := UiKit.label(r, title_text, 30)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.custom_minimum_size = Vector2(380, 0)
	return r


func _slider(title_text: String, value: float, cb: Callable) -> void:
	var r := _row(title_text)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = value
	s.custom_minimum_size = Vector2(500, 60)
	s.value_changed.connect(cb)
	r.add_child(s)


func _toggle(title_text: String, on: bool, cb: Callable) -> void:
	var r := _row(title_text)
	var c := CheckButton.new()
	c.button_pressed = on
	c.scale = Vector2(1.6, 1.6)
	c.toggled.connect(cb)
	r.add_child(c)
