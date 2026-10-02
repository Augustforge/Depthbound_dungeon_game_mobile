class_name FloorGrid
extends RefCounted
## A floor parsed from an ASCII map (GDD 19.5). 1 character = 1 cell = 1 metre.
## Cell (cx, cy) covers world plane [cx, cx+1) x [cy, cy+1); its centre is (cx+0.5, cy+0.5).

enum Cell { FLOOR, WALL }

const WALL_CHARS := "#H"
## Characters that are floor cells but also mark something (start, exit, objects, packs).
const MARKER_CHARS := "SECGR^TLDVWFNB~"

var width: int = 0
var height: int = 0
var cells: PackedByteArray = PackedByteArray()
## char -> Array[Vector2i] for every marker and pack letter.
var markers: Dictionary = {}
var start: Vector2i = Vector2i(-1, -1)
var exit: Vector2i = Vector2i(-1, -1)
var data: Dictionary = {}
## Cells that block movement besides walls (closed gates etc.), toggled at runtime.
var _blocked: Dictionary = {}


static func from_text(text: String, params: Dictionary = {}) -> FloorGrid:
	var g := FloorGrid.new()
	g.data = params
	var lines: PackedStringArray = []
	for raw in text.split("\n"):
		var line := raw.trim_suffix("\r")
		if not line.strip_edges().is_empty():
			lines.append(line)
	g.height = lines.size()
	for line in lines:
		g.width = maxi(g.width, line.length())
	g.cells.resize(g.width * g.height)
	g.cells.fill(Cell.WALL)
	for y in g.height:
		var line: String = lines[y]
		for x in line.length():
			var ch := line[x]
			if ch == " " or WALL_CHARS.contains(ch):
				if ch == "H":
					g._add_marker(ch, Vector2i(x, y))
				continue
			g.cells[y * g.width + x] = Cell.FLOOR
			if ch == ".":
				continue
			g._add_marker(ch, Vector2i(x, y))
			if ch == "S":
				g.start = Vector2i(x, y)
			elif ch == "E":
				g.exit = Vector2i(x, y)
			elif ch == "D" or ch == "B":
				g._blocked[Vector2i(x, y)] = true
	return g


static func load_floor(base_path: String) -> FloorGrid:
	var text := FileAccess.get_file_as_string(base_path + ".txt")
	var params: Variant = {}
	if FileAccess.file_exists(base_path + ".json"):
		params = DataDB.load_json(base_path + ".json")
	return from_text(text, params if params is Dictionary else {})


func _add_marker(ch: String, c: Vector2i) -> void:
	if not markers.has(ch):
		markers[ch] = []
	markers[ch].append(c)


func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < width and c.y < height


func is_wall(c: Vector2i) -> bool:
	return not in_bounds(c) or cells[c.y * width + c.x] == Cell.WALL


## Walkable = not a wall and not blocked by a closed gate.
func is_walkable(c: Vector2i) -> bool:
	return not is_wall(c) and not _blocked.has(c)


func set_blocked(c: Vector2i, blocked: bool) -> void:
	if blocked:
		_blocked[c] = true
	else:
		_blocked.erase(c)


func marker_cells(ch: String) -> Array:
	return markers.get(ch, [])


static func cell_center(c: Vector2i) -> Vector2:
	return Vector2(c.x + 0.5, c.y + 0.5)


static func to_cell(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x), floori(p.y))


## Moves a circle by `motion`, sliding along blocked cells. Each axis is resolved separately
## and long moves are split into steps shorter than the radius, so walls are never tunnelled.
func move_circle(pos: Vector2, radius: float, motion: Vector2) -> Vector2:
	var steps := maxi(1, ceili(motion.length() / (radius * 0.5)))
	var step := motion / steps
	var p := pos
	for i in steps:
		p.x += step.x
		p = _resolve_axis(p, radius, true)
		p.y += step.y
		p = _resolve_axis(p, radius, false)
	return p


func circle_free(p: Vector2, radius: float) -> bool:
	for cy in range(floori(p.y - radius), floori(p.y + radius) + 1):
		for cx in range(floori(p.x - radius), floori(p.x + radius) + 1):
			var c := Vector2i(cx, cy)
			if is_walkable(c):
				continue
			var nearest := Vector2(clampf(p.x, cx, cx + 1.0), clampf(p.y, cy, cy + 1.0))
			if p.distance_squared_to(nearest) < radius * radius - 1e-6:
				return false
	return true


func _resolve_axis(p: Vector2, radius: float, x_axis: bool) -> Vector2:
	for cy in range(floori(p.y - radius), floori(p.y + radius) + 1):
		for cx in range(floori(p.x - radius), floori(p.x + radius) + 1):
			var c := Vector2i(cx, cy)
			if is_walkable(c):
				continue
			var nearest := Vector2(clampf(p.x, cx, cx + 1.0), clampf(p.y, cy, cy + 1.0))
			var d := p - nearest
			var dist_sq := d.length_squared()
			if dist_sq >= radius * radius:
				continue
			if dist_sq < 1e-9:
				# Centre inside the cell: push out along the resolved axis.
				if x_axis:
					p.x = cx - radius if p.x < cx + 0.5 else cx + 1.0 + radius
				else:
					p.y = cy - radius if p.y < cy + 0.5 else cy + 1.0 + radius
				continue
			var dist := sqrt(dist_sq)
			var push := d / dist * (radius - dist)
			if x_axis:
				p.x += push.x
			else:
				p.y += push.y
	return p


## True if a straight segment does not cross any wall cell (grid walk, DDA).
func has_line_of_sight(a: Vector2, b: Vector2) -> bool:
	var cell := to_cell(a)
	var target := to_cell(b)
	var d := b - a
	var step_x := 1 if d.x > 0 else -1
	var step_y := 1 if d.y > 0 else -1
	var t_delta_x := INF if absf(d.x) < 1e-9 else absf(1.0 / d.x)
	var t_delta_y := INF if absf(d.y) < 1e-9 else absf(1.0 / d.y)
	var t_max_x := INF if absf(d.x) < 1e-9 else ((cell.x + (1 if step_x > 0 else 0)) - a.x) / d.x
	var t_max_y := INF if absf(d.y) < 1e-9 else ((cell.y + (1 if step_y > 0 else 0)) - a.y) / d.y
	var guard := 0
	while cell != target and guard < 512:
		guard += 1
		if t_max_x < t_max_y:
			if t_max_x > 1.0:
				break
			t_max_x += t_delta_x
			cell.x += step_x
		else:
			if t_max_y > 1.0:
				break
			t_max_y += t_delta_y
			cell.y += step_y
		if is_wall(cell):
			return false
	return true
