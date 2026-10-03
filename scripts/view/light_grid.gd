class_name LightGrid
extends RefCounted
## Bakes torch light into a texture covering the floor (decision D4).
## Light does not pass through walls: every texel checks line of sight to the torch.

const TEXELS_PER_METRE := 4
const STORE_SCALE := 0.25 # matches LIGHT_SCALE = 4.0 in shaders/common.gdshaderinc
const TORCH_COLOR := Color(1.0, 0.56, 0.22)
const TORCH_RADIUS := 6.0
const TORCH_INTENSITY := 0.95
const TORCH_HEIGHT := 1.75
const MIN_SPACING := 5.0


## Torch = {"pos": Vector2 (floor plane, just in front of the wall), "normal": Vector2, "cell": Vector2i}.
## Placement is deterministic: walls whose south side is floor (they face the camera) and some
## east/west faces, filtered by a hash of the cell and a minimum spacing (decision D5).
static func place_torches(grid: FloorGrid, density: float = 0.55) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var dirs := [Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0)]
	for y in grid.height:
		for x in grid.width:
			var c := Vector2i(x, y)
			if not grid.is_wall(c):
				continue
			for d: Vector2i in dirs:
				var front := c + d
				if not grid.in_bounds(front) or grid.is_wall(front) or grid.is_bars(front):
					continue
				var h := RngStreams.fnv1a32("torch%d,%d,%d" % [x, y, d.x], 2166136261) % 1000
				var chance := density if d.y == 1 else density * 0.35
				if h >= int(chance * 1000.0):
					continue
				var pos := Vector2(x + 0.5, y + 0.5) + Vector2(d) * 0.62
				var too_close := false
				for t in result:
					if t["pos"].distance_to(pos) < MIN_SPACING:
						too_close = true
						break
				if not too_close:
					result.append({"pos": pos, "normal": Vector2(d), "cell": c})
				break
	return result


## Pale light falling from holes in the vault (the well above): fills the dark middles of big
## rooms, greedily at the open cell farthest from any light, until none is darker than `dark_dist`.
static func place_shafts(grid: FloorGrid, lights: Array[Dictionary], color: Color, dark_dist: float = 4.8,
		) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var points: Array[Vector2] = []
	for t in lights:
		points.append(t["pos"])
	var open: Array[Vector2] = []
	for y in range(1, grid.height - 1):
		for x in range(1, grid.width - 1):
			if _open_area(grid, Vector2i(x, y)):
				open.append(Vector2(x + 0.5, y + 0.5))
	while result.size() < 24:
		var best := Vector2.ZERO
		var best_d := dark_dist
		for p in open:
			var d := INF
			for q in points:
				d = minf(d, p.distance_to(q))
			if d > best_d:
				best_d = d
				best = p
		if best == Vector2.ZERO:
			break
		points.append(best)
		result.append({"pos": best, "intensity": 0.8, "color": color, "shaft": true})
	return result


## A cell in the middle of a room: it and its 8 neighbours are floor (not walls or bars).
static func _open_area(grid: FloorGrid, c: Vector2i) -> bool:
	for oy in range(-1, 2):
		for ox in range(-1, 2):
			var n := c + Vector2i(ox, oy)
			if grid.is_wall(n) or grid.is_bars(n):
				return false
	return true


static func bake(grid: FloorGrid, torches: Array[Dictionary], color: Color = TORCH_COLOR) -> Image:
	var w := grid.width * TEXELS_PER_METRE
	var h := grid.height * TEXELS_PER_METRE
	var light := PackedVector3Array()
	light.resize(w * h)
	var step := 1.0 / TEXELS_PER_METRE
	for t in torches:
		var tp: Vector2 = t["pos"]
		var intensity := TORCH_INTENSITY * float(t.get("intensity", 1.0))
		var c: Color = t.get("color", color)
		var x0 := maxi(0, floori((tp.x - TORCH_RADIUS) * TEXELS_PER_METRE))
		var x1 := mini(w - 1, ceili((tp.x + TORCH_RADIUS) * TEXELS_PER_METRE))
		var y0 := maxi(0, floori((tp.y - TORCH_RADIUS) * TEXELS_PER_METRE))
		var y1 := mini(h - 1, ceili((tp.y + TORCH_RADIUS) * TEXELS_PER_METRE))
		for ty in range(y0, y1 + 1):
			for tx in range(x0, x1 + 1):
				var p := Vector2((tx + 0.5) * step, (ty + 0.5) * step)
				var dist := sqrt(p.distance_squared_to(tp) + TORCH_HEIGHT * TORCH_HEIGHT * 0.35)
				if dist >= TORCH_RADIUS:
					continue
				if grid.is_wall(FloorGrid.to_cell(p)) or not grid.has_line_of_sight(tp, p):
					continue
				var k := 1.0 - dist / TORCH_RADIUS
				var v := k * k * k * intensity * 1.6
				light[ty * w + tx] += Vector3(c.r, c.g, c.b) * v
	# Alpha: 0 inside walls, 0.5 on floor, 1 in decorative water basins (~). The water shader uses it
	# as a mask; while the floor is dry, water shows only in basins (and never through mesh seams).
	var basins := {}
	for c in grid.marker_cells("~"):
		basins[c] = true
	var img := Image.create(w, h, false, Image.FORMAT_RGBAH)
	for ty in h:
		for tx in w:
			var v := _blurred(light, w, h, tx, ty) * STORE_SCALE
			var cell := Vector2i(tx / TEXELS_PER_METRE, ty / TEXELS_PER_METRE)
			var mask := 0.0 if grid.is_wall(cell) else (1.0 if basins.has(cell) else 0.5)
			img.set_pixel(tx, ty, Color(v.x, v.y, v.z, mask))
	return img


static func _blurred(light: PackedVector3Array, w: int, h: int, x: int, y: int) -> Vector3:
	var sum := Vector3.ZERO
	var n := 0
	for oy in range(-1, 2):
		for ox in range(-1, 2):
			var sx := x + ox
			var sy := y + oy
			if sx >= 0 and sy >= 0 and sx < w and sy < h:
				sum += light[sy * w + sx]
				n += 1
	return sum / n
