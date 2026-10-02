extends Node3D
## Renders an imported character for visual checks:
## tools/screenshot.sh res://scenes/dev/model_preview.tscn out.png 30 --model=res://... --clip=Name --t=0.5


func _ready() -> void:
	var img := Image.create(4, 4, false, Image.FORMAT_RGBAH)
	img.fill(Color(0.25, 0.2, 0.15, 1))
	VisualGlobals.set_light_grid(ImageTexture.create_from_image(img), Vector2(-50, -50), Vector2(100, 100))
	VisualGlobals.set_water_height(-5.0)
	var hv := HeroView.new()
	add_child(hv)
	var h := Hero.new()
	hv.setup(h)
	hv.set_process(false)
	var model := hv.model
	if DevTools.arg("sword_rot") != "":
		var r := DevTools.arg("sword_rot").split(",")
		hv.sword.rotation_degrees = Vector3(float(r[0]), float(r[1]), float(r[2]))
	print("skeleton scale: ", model.skeleton.global_transform.basis.get_scale())
	var clip := DevTools.arg("clip")
	if model.player:
		print("clips: ", model.player.get_animation_list())
		if not clip.is_empty():
			model.player.play(clip)
			model.player.seek(model.player.current_animation_length * float(DevTools.arg("t", "0.5")), true)
			model.player.pause()
	var aabb := AABB()
	for mi in RiggedModel._all_meshes(model):
		aabb = aabb.merge(mi.global_transform * mi.get_aabb())
	print("aabb: ", aabb)
	var cam := Camera3D.new()
	add_child(cam)
	var pitch := deg_to_rad(float(DevTools.arg("pitch", "15")))
	var dist := float(DevTools.arg("dist", "4"))
	cam.position = Vector3(0, 1.0 + sin(pitch) * dist, cos(pitch) * dist)
	cam.look_at(Vector3(0, 0.9, 0))
	cam.fov = 40
	cam.current = true
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.3, 0.32, 0.34)
	add_child(env)
