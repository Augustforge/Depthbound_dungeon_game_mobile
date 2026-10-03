class_name ReflectionWindow
extends UiWindow
## «Отражение» — the puddle by the fire: change the hero's look (GDD 3.4, 17.1).

const PORTRAITS := {&"male": preload("res://assets/ui/portrait_male.webp"),
	&"female": preload("res://assets/ui/portrait_female.webp")}

var profile: Profile


func setup(parent: Node, p: Profile) -> ReflectionWindow:
	profile = p
	open(parent, tr("REFLECTION_TITLE"), Vector2(1100, 900))
	_build()
	return self


func _build() -> void:
	clear_body()
	UiKit.label(body, tr("REFLECTION_HINT"), 26, UiKit.DIM_TEXT)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", 40)
	body.add_child(row)
	for look: StringName in [&"male", &"female"]:
		LookCard.make(row, look, PORTRAITS[look], profile.hero_look == look, _pick.bind(look))


func _pick(look: StringName) -> void:
	profile.hero_look = look
	GameState.save()
	_build()
