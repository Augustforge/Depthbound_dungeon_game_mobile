class_name ArtEffects
extends Control
## Living effects over a cover-stretched art (GDD 17.2): dust in a light beam, falling drops, water
## glints and flickering warm glows. Points are given in art coordinates (0..1) and follow resizes.

var art_size: Vector2
var _items: Array[Dictionary] = []
var _time: float = 0.0


func setup(art: Texture2D) -> ArtEffects:
	art_size = art.get_size()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_layout)
	return self


## Dust motes drifting in a beam: `top` and `bottom` are art points of the beam's axis.
func add_beam_dust(top: Vector2, bottom: Vector2, width: float, amount: int = 40) -> void:
	var p := CPUParticles2D.new()
	p.amount = amount
	p.lifetime = 7.0
	p.preprocess = 7.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.direction = Vector2(0.2, 1.0)
	p.spread = 40.0
	p.gravity = Vector2(0, 4)
	p.initial_velocity_min = 4.0
	p.initial_velocity_max = 14.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.6
	p.color = Color(0.75, 0.88, 1.0, 0.55)
	p.color_ramp = _fade_ramp(Color(0.75, 0.88, 1.0, 0.6))
	_add(p, {"kind": "rect", "a": top, "b": bottom, "w": width})


## Drops falling from the top edge over an art band [x0, x1].
func add_drops(x0: float, x1: float, amount: int = 14) -> void:
	var p := CPUParticles2D.new()
	p.amount = amount
	p.lifetime = 1.6
	p.preprocess = 2.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.direction = Vector2.DOWN
	p.spread = 2.0
	p.gravity = Vector2(0, 900)
	p.initial_velocity_min = 50.0
	p.initial_velocity_max = 120.0
	p.scale_amount_min = 1.2
	p.scale_amount_max = 2.0
	p.color_ramp = _fade_ramp(Color(0.7, 0.9, 1.0, 0.7))
	_add(p, {"kind": "rect", "a": Vector2((x0 + x1) * 0.5, 0.0), "b": Vector2((x0 + x1) * 0.5, 0.0), "w": x1 - x0})


## Sparkles on water in an art rectangle.
func add_glints(rect: Rect2, amount: int = 24, color: Color = Color(0.6, 1.0, 0.95)) -> void:
	var p := CPUParticles2D.new()
	p.amount = amount
	p.lifetime = 1.4
	p.preprocess = 1.4
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 0.0
	p.initial_velocity_max = 6.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.5
	p.color_ramp = _pulse_ramp(color)
	_add(p, {"kind": "area", "rect": rect})


## A warm flickering glow (torch, fire, lantern) at an art point.
func add_glow(at: Vector2, radius: float, color: Color = Color(1.0, 0.55, 0.2), strength: float = 0.5) -> void:
	var g := TextureRect.new()
	g.texture = _radial_texture()
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g.modulate = Color(color.r, color.g, color.b, strength)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	g.material = mat
	g.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	add_child(g)
	_items.append({"node": g, "kind": "glow", "at": at, "r": radius, "base": strength, "seed": randf() * 10.0})
	_layout()


## Embers rising from a fire at an art point.
func add_embers(at: Vector2, amount: int = 18) -> void:
	var p := CPUParticles2D.new()
	p.amount = amount
	p.lifetime = 2.2
	p.preprocess = 2.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.direction = Vector2.UP
	p.spread = 25.0
	p.gravity = Vector2(0, -20)
	p.initial_velocity_min = 30.0
	p.initial_velocity_max = 80.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.0
	p.color_ramp = _fade_ramp(Color(1.0, 0.6, 0.2, 1.0))
	_add(p, {"kind": "rect", "a": at, "b": at, "w": 0.03})


func _add(p: CPUParticles2D, info: Dictionary) -> void:
	add_child(p)
	info["node"] = p
	_items.append(info)
	_layout()


func _process(delta: float) -> void:
	_time += delta
	for it in _items:
		if it["kind"] == "glow":
			var flick := 0.8 + 0.12 * sin(_time * 9.0 + float(it["seed"])) + 0.08 * sin(_time * 23.0 + float(it["seed"]) * 3.0)
			(it["node"] as CanvasItem).modulate.a = float(it["base"]) * flick


func _layout() -> void:
	var screen := size
	if screen == Vector2.ZERO:
		return
	var s := maxf(screen.x / art_size.x, screen.y / art_size.y)
	for it in _items:
		match String(it["kind"]):
			"rect":
				var a := UiKit.art_point(screen, art_size, it["a"])
				var b := UiKit.art_point(screen, art_size, it["b"])
				var p: CPUParticles2D = it["node"]
				p.position = (a + b) * 0.5
				p.emission_rect_extents = Vector2(float(it["w"]) * art_size.x * s * 0.5, maxf(4.0, absf(b.y - a.y) * 0.5))
			"area":
				var r: Rect2 = it["rect"]
				var p: CPUParticles2D = it["node"]
				p.position = UiKit.art_point(screen, art_size, r.get_center())
				p.emission_rect_extents = r.size * art_size * s * 0.5
			"glow":
				var g: TextureRect = it["node"]
				var rad := float(it["r"]) * art_size.x * s
				g.size = Vector2(rad, rad) * 2.0
				g.position = UiKit.art_point(screen, art_size, it["at"]) - g.size * 0.5


static func _fade_ramp(c: Color) -> Gradient:
	var g := Gradient.new()
	g.set_color(0, Color(c.r, c.g, c.b, 0.0))
	g.set_color(1, Color(c.r, c.g, c.b, 0.0))
	g.add_point(0.2, c)
	g.add_point(0.8, c)
	return g


static func _pulse_ramp(c: Color) -> Gradient:
	var g := Gradient.new()
	g.set_color(0, Color(c.r, c.g, c.b, 0.0))
	g.set_color(1, Color(c.r, c.g, c.b, 0.0))
	g.add_point(0.5, c)
	return g


static func _radial_texture() -> GradientTexture2D:
	var t := GradientTexture2D.new()
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 128
	t.height = 128
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	t.gradient = g
	return t
