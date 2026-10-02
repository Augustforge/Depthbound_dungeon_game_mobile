extends Node3D
## Stage 0 tech spike: a room from an ASCII map, placeholder hero on the joystick, fixed 3/4 camera,
## rising water and baked torch light. Debug keys: T — water time x10, R — restart.

const MAP := "res://levels/test/spike_room"

var world: World
var hud: Hud
var water: WaterView
var time_scale: float = 1.0


func _ready() -> void:
	var grid := FloorGrid.load_floor(MAP)
	world = World.new()
	add_child(world)
	world.setup(grid, GameState.rng, 1, float(grid.data.get("time_limit", 120)))
	world.running = true
	var start_progress := float(DevTools.arg("water", "0"))
	world.timer.elapsed = world.timer.limit * start_progress

	var torches := LightGrid.place_torches(grid)
	var img := LightGrid.bake(grid, torches)
	VisualGlobals.set_light_grid(ImageTexture.create_from_image(img), Vector2.ZERO, Vector2(grid.width, grid.height))

	var floor_view := FloorView.new()
	add_child(floor_view)
	floor_view.build(grid, torches)
	water = WaterView.new()
	add_child(water)
	water.setup(grid)

	var hero_view := HeroView.new()
	add_child(hero_view)
	hero_view.setup(world.hero)
	var cam := CameraRig.new()
	add_child(cam)
	cam.target = hero_view
	hero_view._process(0.0)
	cam.snap()

	_add_environment()
	hud = Hud.new()
	add_child(hud)
	hud.setup(world)
	hud.controls.dodge_pressed.connect(func() -> void: world.hero.input.dodge_requested = true)


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


func _physics_process(_delta: float) -> void:
	var keys := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var input := world.hero.input
	input.move = keys if keys.length() > 0.0 else hud.controls.joystick
	if Input.is_action_just_pressed(&"dodge"):
		input.dodge_requested = true
	if time_scale > 1.0:
		world.timer.tick(get_physics_process_delta_time() * (time_scale - 1.0))


func _process(_delta: float) -> void:
	water.set_level(world.timer.water_height())


func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	if k.physical_keycode == KEY_T:
		time_scale = 10.0 if time_scale == 1.0 else 1.0
	elif k.physical_keycode == KEY_R:
		get_tree().reload_current_scene()
