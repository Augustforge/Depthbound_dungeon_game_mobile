class_name CreditsWindow
extends UiWindow
## Authors and licences (GDD 17.2 #2).


func setup(parent: Node) -> CreditsWindow:
	open(parent, tr("CREDITS_TITLE"), Vector2(1200, 800), 70)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(1140, 640)
	body.add_child(scroll)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(1100, 0)
	box.add_theme_constant_override(&"separation", 16)
	scroll.add_child(box)
	for key in ["CREDITS_GAME", "CREDITS_ART", "CREDITS_AUDIO", "CREDITS_FONTS", "CREDITS_ENGINE"]:
		var l := UiKit.label(box, tr(key), 28)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return self
