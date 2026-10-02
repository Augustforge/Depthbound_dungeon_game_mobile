extends Node3D
## Visual check for the torch flame (tools/screenshot.sh res://scenes/dev/flame_test.tscn out.png).


func _ready() -> void:
	var dark := Image.create(4, 4, false, Image.FORMAT_RGBAH)
	VisualGlobals.set_light_grid(ImageTexture.create_from_image(dark), Vector2.ZERO, Vector2.ONE)
	var t := TorchView.new()
	add_child(t)
	t.setup({"pos": Vector2(0, 0.62), "normal": Vector2(0, 1), "cell": Vector2i(0, 0)})
	var cam := Camera3D.new()
	add_child(cam)
	cam.position = Vector3(0, 2.4, 2.2)
	cam.look_at(Vector3(0, 1.9, 0.3))
	cam.current = true
