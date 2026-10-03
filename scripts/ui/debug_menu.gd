class_name DebugMenu
extends CanvasLayer
## Developer menu (GDD 19.8). Opens with F3 or the small "DBG" button in the top right corner.
## Shown only in dev builds (project setting depthbound/dev_build).

var world: World
var overlay: WorldOverlay
var freeze_timer: bool = false
var _panel: PanelContainer
var _box: VBoxContainer


static func enabled() -> bool:
	return OS.is_debug_build() or bool(ProjectSettings.get_setting("depthbound/dev_build", false))


func setup(w: World, ov: WorldOverlay) -> void:
	world = w
	overlay = ov
	layer = 50
	var toggle := Button.new()
	toggle.text = "DBG"
	toggle.add_theme_font_size_override(&"font_size", 26)
	toggle.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	toggle.position += Vector2(-130, 20)
	toggle.custom_minimum_size = Vector2(100, 60)
	toggle.pressed.connect(func() -> void: _panel.visible = not _panel.visible)
	add_child(toggle)
	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_panel.position += Vector2(-480, 100)
	_panel.visible = false
	add_child(_panel)
	_box = VBoxContainer.new()
	_panel.add_child(_box)
	_check("Immortal (I)", func(on: bool) -> void: world.hero.immortal = on)
	_check("Freeze timer", func(on: bool) -> void: freeze_timer = on; world.timer.paused = on)
	_check("Show radii", func(on: bool) -> void: overlay.show_radii = on)
	_button("Kill all enemies (K)", kill_all)
	_button("Water +10%", func() -> void: world.timer.elapsed += world.timer.limit * 0.1)
	_button("Heal hero", func() -> void: world.hero.hp = world.hero.max_hp)
	_button("Give all skills", func() -> void:
		for id in SkillDB.actives() + SkillDB.passives():
			if world.hero.find_skill(id) == null:
				world.hero.add_skill(id))
	_button("All skills +1 level", func() -> void:
		for sk in world.hero.all_skills():
			sk.set_level(sk.level + 1))
	_button("Restart floor (R)", func() -> void: get_tree().reload_current_scene())
	_button("Complete floor", complete_floor)
	_button("Floor +1", func() -> void: _jump(1))
	_button("Floor -1", func() -> void: _jump(-1))
	_button("+1000 gold, +10 crystals", func() -> void:
		GameState.profile.gold += 1000
		GameState.profile.crystals += 10)
	_button("Give a random item", func() -> void:
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		GameState.profile.add_item(Loot.roll_item("relic", world.floor_index, rng)))
	_button("Typical build of this floor", func() -> void:
		var run := GameState.run
		var sim := SimBuild.make_run(run.run_seed, world.floor_index)
		run.skills = sim.skills
		run.cards = sim.cards
		get_tree().reload_current_scene())


## Finishes the floor as if the goal were done and the stairs reached (or the boss killed).
func complete_floor() -> void:
	world.has_key = true
	world.seals_done = world.seals_needed
	if world.boss != null and world.boss.alive:
		world.boss.take_damage(world.boss.hp + 1.0, false, world.hero)
	elif world.grid.in_bounds(world.grid.exit):
		world.hero.pos = FloorGrid.cell_center(world.grid.exit)


func _jump(delta: int) -> void:
	var run := GameState.run
	run.floor_index = clampi(run.floor_index + delta, 1, GameState.LAST_FLOOR)
	GameState.profile.run_phase = &"floor"
	GameState.profile.pending_result = {}
	get_tree().reload_current_scene()


func kill_all() -> void:
	for e in world.entities:
		if e is Mob and e.alive:
			e.take_damage(e.hp, false, world.hero)


func _check(label: String, cb: Callable) -> void:
	var c := CheckButton.new()
	c.text = label
	c.add_theme_font_size_override(&"font_size", 26)
	c.toggled.connect(cb)
	_box.add_child(c)


func _button(label: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = label
	b.add_theme_font_size_override(&"font_size", 26)
	b.custom_minimum_size = Vector2(380, 56)
	b.pressed.connect(cb)
	_box.add_child(b)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"debug_menu"):
		_panel.visible = not _panel.visible
