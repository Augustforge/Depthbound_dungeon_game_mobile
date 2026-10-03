class_name FloorPopulator
extends RefCounted
## Turns map markers and floor json into logic objects (GDD 19.5). Mobs are spawned by World.

const CHEST_TIERS := {"C": &"wood", "G": &"iron", "R": &"relic"}


static func populate(world: World) -> void:
	var grid := world.grid
	var data := grid.data
	var lever_links := {}
	for link: Dictionary in data.get("links", []):
		var key := _key(link["lever_at"])
		if not lever_links.has(key):
			lever_links[key] = []
		lever_links[key].append(link)
	if grid.in_bounds(grid.exit):
		_add(world, FloorObject.Kind.STAIRS, grid.exit)
	for ch: String in CHEST_TIERS:
		for c: Vector2i in grid.marker_cells(ch):
			var o := _add(world, FloorObject.Kind.CHEST, c)
			o.tier = CHEST_TIERS[ch]
			o.radius = 0.45
	for c: Vector2i in grid.marker_cells("L"):
		var o := _add(world, FloorObject.Kind.LEVER, c)
		o.links = lever_links.get(_key([c.x, c.y]), [])
	for c: Vector2i in grid.marker_cells("D"):
		var o := _add(world, FloorObject.Kind.GATE, c)
		o.closed = true
		grid.set_blocked(c, true)
	var locks: Dictionary = data.get("locks", {})
	for c: Vector2i in grid.marker_cells("B"):
		var o := _add(world, FloorObject.Kind.LOCK_GATE, c)
		o.pack = _lock_pack(grid, locks, c)
		# Lock gates start open and close when their pack is pulled (GDD 10.4).
		grid.set_blocked(c, false)
	for c: Vector2i in grid.marker_cells("V"):
		_add(world, FloorObject.Kind.VALVE, c)
	var floods: Dictionary = {}
	for f: Dictionary in data.get("floods", []):
		floods[_key(f["valve_at"])] = f
	for c: Vector2i in grid.marker_cells("W"):
		var o := _add(world, FloorObject.Kind.FLOOD_VALVE, c)
		var f: Dictionary = floods.get(_key([c.x, c.y]), {})
		if not f.is_empty():
			var r: Array = f["rect"]
			o.flood_rect = Rect2i(int(r[0]), int(r[1]), int(r[2]), int(r[3]))
	for c: Vector2i in grid.marker_cells("F"):
		_add(world, FloorObject.Kind.SPRING, c)
	var notes: Dictionary = data.get("notes", {})
	for c: Vector2i in grid.marker_cells("N"):
		var o := _add(world, FloorObject.Kind.NOTE, c)
		o.note_key = str(notes.get("N", ""))
	for c: Vector2i in grid.marker_cells("T"):
		_add(world, FloorObject.Kind.BEAR_TRAP, c)
	_add_spike_zones(world)
	_add_harpoons(world)


static func _add(world: World, kind: FloorObject.Kind, c: Vector2i) -> FloorObject:
	var o := FloorObject.new()
	o.kind = kind
	o.cell = c
	o.pos = FloorGrid.cell_center(c)
	o.radius = 0.0
	world.add_entity(o)
	return o


static func _key(a: Array) -> String:
	return "%d,%d" % [int(a[0]), int(a[1])]


## Lock gate -> pack: from json "locks": {"c": [[x, y], ...]}, else the nearest pack letter.
static func _lock_pack(grid: FloorGrid, locks: Dictionary, c: Vector2i) -> String:
	for letter: String in locks:
		for cell: Array in locks[letter]:
			if Vector2i(int(cell[0]), int(cell[1])) == c:
				return letter
	var best := ""
	var best_d := INF
	for letter: String in grid.data.get("packs", {}):
		for p: Vector2i in grid.marker_cells(letter):
			var d := Vector2(p).distance_to(Vector2(c))
			if d < best_d:
				best_d = d
				best = letter
	return best


## Adjacent ^ cells form one zone; zones are phase-shifted so not all spikes fire together.
static func _add_spike_zones(world: World) -> void:
	var left := {}
	for c: Vector2i in world.grid.marker_cells("^"):
		left[c] = true
	var index := 0
	while not left.is_empty():
		var start: Vector2i = left.keys()[0]
		var zone := SpikeZone.new()
		var stack: Array[Vector2i] = [start]
		left.erase(start)
		while not stack.is_empty():
			var c: Vector2i = stack.pop_back()
			zone.cells.append(c)
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if left.has(c + d):
					left.erase(c + d)
					stack.append(c + d)
		var centre := Vector2.ZERO
		for c in zone.cells:
			centre += FloorGrid.cell_center(c)
		zone.pos = centre / zone.cells.size()
		zone.cycle = fmod(index * 1.1, zone.period())
		world.add_entity(zone)
		index += 1


static func _add_harpoons(world: World) -> void:
	var dirs: Dictionary = world.grid.data.get("harpoons", {})
	var i := 0
	for c: Vector2i in world.grid.marker_cells("H"):
		var d := Vector2.ZERO
		var key := _key([c.x, c.y])
		if dirs.has(key):
			d = Vector2(float(dirs[key][0]), float(dirs[key][1]))
		else:
			for n: Vector2i in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1)]:
				if world.grid.is_walkable(c + n):
					d = Vector2(n)
					break
		var h := HarpoonWall.new()
		world.add_entity(h)
		h.setup_wall(c, d.normalized(), 1.5 + i * 0.7)
		i += 1
