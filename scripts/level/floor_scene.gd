class_name FloorScene
extends Node3D
## One floor of the dungeon: builds the World from the current run (GameState.run) and the 3D view,
## drives input, tutorial hints, notes, and the summary / death screens (GDD 4, 10, 11).
## Dev args: --map=res://levels/... --hero_at=x,y --water=0..1 --skills=all --auto=1 --immortal=1
## Debug keys: T — water time x10, R — restart, I — immortal, K — kill all enemies.

const SCENE := "res://scenes/floor.tscn"

## Overrides the floor file (without extension); empty = the run's current floor.
var map_path: String = ""
var world: World
var hud: Hud
var water: WaterView
var cam: CameraRig
var time_scale: float = 1.0
var _shown_hints: Dictionary = {}
var _hint_pause_left: float = 0.0
var _modal_open: bool = false


func _ready() -> void:
	if GameState.run == null:
		# Started directly (dev): a fresh run.
		GameState.new_run()
	var run := GameState.run
	var path := map_path if not map_path.is_empty() else DevTools.arg("map", GameState.floor_path(run.floor_index))
	var grid := FloorGrid.load_floor(path)
	world = World.new()
	add_child(world)
	# A fresh RngStreams per attempt: retrying a floor replays the same loot and cards (GDD 11.1).
	world.setup(grid, RngStreams.new(run.run_seed), run.floor_index, float(grid.data.get("time_limit", 150)), run,
		GameState.profile.equipped_items())
	world.running = true
	_apply_dev_args()
	_build_view(grid)
	_build_ui()
	world.floor_completed.connect(_on_completed)
	world.floor_failed.connect(_on_failed)
	world.note_found.connect(_on_note)
	world.spring_chooser = _choose_spring
	world.boss_line.connect(func(key: String) -> void: hud.show_boss_line(key))
	var sound := SoundDirector.new()
	add_child(sound)
	sound.setup(world)
	EventBus.floor_started.emit(run.floor_index)
	if GameState.profile.run_phase == &"reward" and not GameState.profile.pending_result.is_empty():
		# The app was closed on the summary of this floor: back to the same choice (GDD 11.1).
		world.running = false
		_modal_open = true
		_show_reward.call_deferred(GameState.profile.pending_result)
	else:
		# Floor-start snapshot (GDD 11.1).
		GameState.save()


func _apply_dev_args() -> void:
	var hero_at := DevTools.arg("hero_at")
	if not hero_at.is_empty():
		var xy := hero_at.split(",")
		world.hero.pos = Vector2(float(xy[0]), float(xy[1]))
	if DevTools.arg("skills") == "all":
		for id in [&"whirlwind", &"throwing_blade", &"blade_master", &"fury"]:
			world.hero.add_skill(id)
	world.hero.auto_mode = DevTools.arg("auto") == "1"
	world.hero.immortal = DevTools.arg("immortal") == "1"
	world.timer.elapsed = world.timer.limit * float(DevTools.arg("water", "0"))


func _build_view(grid: FloorGrid) -> void:
	var accent := Accent.resolve(String(grid.data.get("accent", "default")))
	var torches := LightGrid.place_torches(grid, Accent.torch_density(grid, accent))
	var decor := DecorView.new()
	add_child(decor)
	decor.build(grid, accent, torches)
	var lights := torches.duplicate()
	lights.append_array(decor.lights)
	var shafts := LightGrid.place_shafts(grid, lights, Accent.color(accent, "shaft"))
	lights.append_array(shafts)
	for s in shafts:
		var shaft := ShaftView.new()
		add_child(shaft)
		shaft.setup(s)
	var img := LightGrid.bake(grid, lights, Accent.color(accent, "torch"))
	VisualGlobals.set_light_grid(ImageTexture.create_from_image(img), Vector2.ZERO, Vector2(grid.width, grid.height))
	var floor_view := FloorView.new()
	add_child(floor_view)
	floor_view.build(grid, torches, accent)
	water = WaterView.new()
	add_child(water)
	water.setup(grid, accent)
	water.visible = DevTools.arg("nowater") == ""
	var hero_view := HeroView.new()
	add_child(hero_view)
	hero_view.setup(world.hero, StringName(DevTools.arg("look", String(GameState.hero_look))))
	for e in world.entities:
		_add_view(e)
	world.entity_added.connect(_add_view)
	world.telegraph_started.connect(_add_telegraph_view)
	cam = CameraRig.new()
	add_child(cam)
	cam.target = hero_view
	cam.bounds = Rect2(0, 0, grid.width, grid.height)
	hero_view._process(0.0)
	cam.snap()
	_add_environment()


func _build_ui() -> void:
	hud = Hud.new()
	add_child(hud)
	hud.setup(world)
	hud.controls.dodge_pressed.connect(func() -> void: world.hero.input.dodge_requested = true)
	hud.controls.action_pressed.connect(func() -> void: world.hero.input.interact_requested = true)
	hud.controls.world_tapped.connect(_on_world_tapped)
	hud.controls.skill_pressed.connect(func(i: int) -> void: world.hero.input.skill_requested[i] = true)
	hud.controls.auto_toggled.connect(func() -> void: world.hero.auto_mode = not world.hero.auto_mode)
	hud.pause_pressed.connect(_open_pause)
	hud.overlay.setup(world, cam)
	if DebugMenu.enabled():
		var dbg := DebugMenu.new()
		add_child(dbg)
		dbg.setup(world, hud.overlay)


func _add_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.01, 0.015, 0.02)
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 0.9
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.08
	env.adjustment_saturation = 1.1
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


func _add_telegraph_view(t: Telegraph) -> void:
	var v := TelegraphView.new()
	add_child(v)
	v.setup(t)


func _add_view(e: Entity) -> void:
	if e is Projectile:
		var pv := ProjectileView.new()
		add_child(pv)
		pv.setup(e)
	elif e is Mob:
		var v := MobView.new()
		add_child(v)
		v.setup(e)
	elif e is FloorObject or e is SpikeZone or e is HarpoonWall or e is Coin:
		var ov := ObjectView.new()
		add_child(ov)
		ov.setup(e)


## Tap on an enemy = priority target (GDD 5): the closest living enemy to the tap on screen.
func _on_world_tapped(screen_pos: Vector2) -> void:
	var best: Combatant = null
	var best_d := 110.0
	for e in world.entities:
		if (e is Mob or e is HarpoonWall) and e.alive:
			var s := cam.unproject_position(Vector3(e.pos.x, 0.8, e.pos.y))
			var d := s.distance_to(screen_pos)
			if d < best_d:
				best_d = d
				best = e
	world.hero.priority_target = best


func _physics_process(delta: float) -> void:
	var input := world.hero.input
	if _modal_open:
		input.move = Vector2.ZERO
		return
	var keys := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	input.move = keys if keys.length() > 0.0 else hud.controls.joystick
	if Input.is_action_just_pressed(&"dodge"):
		input.dodge_requested = true
	if Input.is_action_just_pressed(&"interact"):
		input.interact_requested = true
	for i in 3:
		if Input.is_action_just_pressed(StringName("skill_%d" % (i + 1))):
			input.skill_requested[i] = true
	if time_scale > 1.0 and world.running:
		world.timer.tick(delta * (time_scale - 1.0))
	_tick_hints(delta)


## Tutorial hints (GDD 16.3 floor 1): shown once when the hero enters their zone; the timer
## stops while a hint is on screen (GDD 10.1).
func _tick_hints(delta: float) -> void:
	if _hint_pause_left > 0.0:
		_hint_pause_left -= delta
		if _hint_pause_left <= 0.0:
			world.timer.paused = false
	if not world.grid.data.get("tutorial", false):
		return
	for h: Dictionary in world.grid.data.get("hints", []):
		var key: String = h["key"]
		if _shown_hints.has(key):
			continue
		var at := FloorGrid.cell_center(Vector2i(int(h["at"][0]), int(h["at"][1])))
		if world.hero.pos.distance_to(at) <= float(h.get("radius", 2.0)):
			_shown_hints[key] = true
			hud.show_hint(tr(key), 3.0)
			world.timer.paused = true
			_hint_pause_left = 3.0


func _process(_delta: float) -> void:
	water.set_level(world.timer.water_height())


## Spring choice (GDD 13.2, P1): drink (heal) or wash the blade (+15 % damage for this floor).
func _choose_spring(o: FloorObject) -> void:
	_modal_open = true
	world.running = false
	var w := UiWindow.new().open(self, tr("SPRING_TITLE"), Vector2(1000, 0), 45)
	var done := func(choice: StringName) -> void:
		world.use_spring(o, choice)
		_modal_open = false
		world.running = true
		w.queue_free()
	UiKit.label(w.body, tr("SPRING_HINT"), 28, UiKit.DIM_TEXT)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", 30)
	w.body.add_child(row)
	UiKit.button(row, tr("SPRING_DRINK"), done.bind(&"drink"), 30).custom_minimum_size = Vector2(420, 110)
	UiKit.button(row, tr("SPRING_BLADE"), done.bind(&"blade"), 30).custom_minimum_size = Vector2(420, 110)
	# Closing without a choice drinks.
	w.closed.connect(func() -> void:
		if _modal_open:
			done.call(&"drink"))


func _on_note(key: String) -> void:
	_modal_open = true
	world.running = false
	var w := NoteWindow.new()
	add_child(w)
	w.setup(key)
	w.closed.connect(func() -> void:
		_modal_open = false
		world.running = true)


func _on_completed(result: Dictionary) -> void:
	_modal_open = true
	var r := Progress.complete_floor(GameState.profile, result)
	GameState.save()
	_show_reward(r)


func _show_reward(r: Dictionary) -> void:
	_modal_open = true
	if not String(r.get("boss", "")).is_empty():
		var b := BossRewardScreen.new()
		add_child(b)
		b.setup(GameState.run, r)
		b.finished.connect(_next_floor)
		return
	var s := SummaryScreen.new()
	add_child(s)
	s.setup(GameState.run, r)
	s.finished.connect(_next_floor)


func _next_floor() -> void:
	var done := Progress.next_floor(GameState.profile, GameState.LAST_FLOOR)
	GameState.save()
	if done:
		GameState.goto(GameState.FINAL_SCENE)
		return
	if not GameState.floor_exists(GameState.run.floor_index):
		_show_demo_end()
		return
	get_tree().change_scene_to_file(SCENE)


func _show_demo_end() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 60
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)
	UiKit.dimmer(root, 0.85)
	var box := UiKit.centered_box(root, 900)
	UiKit.label(box, tr("DEMO_END"), 40)
	UiKit.button(box, tr("BTN_NEW_RUN"), _restart_run)


func _on_failed(cause: StringName) -> void:
	_modal_open = true
	var d := DeathScreen.new()
	add_child(d)
	d.setup(cause)
	d.retry.connect(func() -> void:
		# GDD 11.3: each death adds 20 s to the dungeon time.
		Progress.retry_floor(GameState.profile)
		GameState.save()
		get_tree().reload_current_scene())
	d.to_camp.connect(func() -> void:
		Progress.retry_floor(GameState.profile)
		GameState.to_camp())


func _restart_run() -> void:
	GameState.new_run()
	get_tree().change_scene_to_file(SCENE)


## Pause (GDD 17.2 #7): Continue, Equipment, Settings, To camp. The timer stops.
func _open_pause() -> void:
	if _modal_open or world.completed or world.failed:
		return
	_modal_open = true
	world.running = false
	var w := UiWindow.new().open(self, tr("PAUSE_TITLE"), Vector2(700, 0), 45)
	var resume := func() -> void:
		_modal_open = false
		world.running = true
	w.closed.connect(resume)
	UiKit.button(w.body, tr("PAUSE_CONTINUE"), w.close)
	UiKit.button(w.body, tr("EQUIP_TITLE"), func() -> void:
		var eq := EquipmentWindow.new().setup(self, GameState.profile)
		eq.layer = 55
		eq.gear_changed.connect(func() -> void: GameState.profile.apply_gear(world.hero))
		eq.closed.connect(GameState.save))
	UiKit.button(w.body, tr("MENU_SETTINGS"), func() -> void: SettingsWindow.new().setup(self))
	UiKit.button(w.body, tr("BTN_TO_CAMP"), func() -> void:
		ConfirmWindow.new().ask(self, tr("BTN_TO_CAMP"), tr("PAUSE_LEAVE_CONFIRM"), GameState.to_camp))


## Leaving the app mid-floor (a call, the home button) opens the pause, so the water waits.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		if world != null and world.running and not _modal_open and DevTools.arg("screenshot").is_empty():
			_open_pause()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause") and not _modal_open:
		get_viewport().set_input_as_handled()
		_open_pause()


func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	if k.physical_keycode == KEY_T:
		time_scale = 10.0 if time_scale == 1.0 else 1.0
	elif k.physical_keycode == KEY_R:
		get_tree().reload_current_scene()
	elif k.physical_keycode == KEY_I:
		world.hero.immortal = not world.hero.immortal
	elif k.physical_keycode == KEY_K:
		for e in world.entities:
			if e is Mob and e.alive:
				e.take_damage(e.hp, false, world.hero)
