class_name Minimap
extends Control
## Mini-map with fog of war (GDD 5, P1): cells within 8 m of the hero open up; the stairs are
## marked once they have been seen. One small image, updated only where new cells open.

const REVEAL_RADIUS := 8.0
const MAX_SIZE := Vector2(220, 150)
const FLOOR_COL := Color(0.55, 0.6, 0.62, 0.85)
const WALL_COL := Color(0.16, 0.17, 0.19, 0.85)
const BARS_COL := Color(0.35, 0.33, 0.3, 0.9)

var world: World
var _img: Image
var _tex: ImageTexture
var _seen: PackedByteArray = PackedByteArray()
var _stairs_seen: bool = false
var _scale: float = 4.0
var _accum: float = 0.0


func setup(w: World) -> void:
	world = w
	var g := w.grid
	_scale = minf(MAX_SIZE.x / g.width, MAX_SIZE.y / g.height)
	custom_minimum_size = Vector2(g.width, g.height) * _scale
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_img = Image.create(g.width, g.height, false, Image.FORMAT_RGBA8)
	_img.fill(Color(0, 0, 0, 0))
	_tex = ImageTexture.create_from_image(_img)
	_seen.resize(g.width * g.height)
	_reveal()


func _process(delta: float) -> void:
	_accum += delta
	if _accum >= 0.15:
		_accum = 0.0
		_reveal()
	queue_redraw()


func _reveal() -> void:
	var g := world.grid
	var hp := world.hero.pos
	var changed := false
	var r := ceili(REVEAL_RADIUS)
	var hc := FloorGrid.to_cell(hp)
	for y in range(maxi(0, hc.y - r), mini(g.height, hc.y + r + 1)):
		for x in range(maxi(0, hc.x - r), mini(g.width, hc.x + r + 1)):
			var i := y * g.width + x
			if _seen[i] == 1 or FloorGrid.cell_center(Vector2i(x, y)).distance_to(hp) > REVEAL_RADIUS:
				continue
			_seen[i] = 1
			changed = true
			var c := Vector2i(x, y)
			_img.set_pixel(x, y, WALL_COL if g.is_wall(c) else (BARS_COL if g.is_bars(c) else FLOOR_COL))
			if c == g.exit:
				_stairs_seen = true
	if changed:
		_tex.update(_img)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.35))
	draw_texture_rect(_tex, Rect2(Vector2.ZERO, size), false)
	if _stairs_seen:
		draw_circle((Vector2(world.grid.exit) + Vector2(0.5, 0.5)) * _scale, maxf(3.0, _scale * 0.9),
			Color(0.3, 0.95, 0.85))
	draw_circle(world.hero.pos * _scale, maxf(3.0, _scale * 0.8), Color(1, 0.95, 0.8))
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.78, 0.62, 0.4, 0.8), false, 2.0)
