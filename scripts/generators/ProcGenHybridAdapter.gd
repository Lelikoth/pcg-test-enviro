extends BaseGenerator
class_name ProcGenHybridAdapter

func get_algorithm_name() -> String:
	return "ProcGenHybrid"

func generate_map(config: Dictionary) -> Dictionary:
	var width: int = config.get("width", 64)
	var height: int = config.get("height", 64)
	var use_random_seed: bool = config.get("random_seed", true)
	var seed_value: int = config.get("seed", 0)

	var room_amount: int = config.get("procgen_room_amount", 12)
	var automaton_iterations: int = config.get("procgen_automaton_iterations", 0)
	var automaton_threads: int = config.get("procgen_automaton_threads", 1)
	var keep_only_reachable_area_from_start: bool = config.get("keep_only_reachable_area_from_start", false)

	var rng := RandomNumberGenerator.new()
	if use_random_seed:
		rng.randomize()
		seed_value = rng.randi()

	var procgen: ProcGen = ProcGen.new()

	procgen.map_size = Vector2i(width, height)
	procgen.seed = seed_value
	procgen.generate_seed = false
	procgen.room_amount = room_amount

	procgen.automaton_iterations = automaton_iterations
	procgen.automaton_threads = automaton_threads

	# Keep ProcGen mostly room/corridor based, but still allow some natural terrain
	procgen.automaton_noise_rate = 0.45
	procgen.automaton_flood_fill = true
	procgen.automaton_corridor_fixed_width_expand = 0
	procgen.automaton_corridor_non_fixed_width_expand = 1

	procgen.room_min_coverage = 0.18
	procgen.room_max_coverage = 0.35
	procgen.room_center_ratio = 0.8

	await procgen.generate()

	var rooms: Array = _convert_rooms(procgen.get_rooms())
	var corridor_areas: Array = procgen.get_corridor_areas()

	var grid: Array = _build_grid_from_procgen(procgen, width, height)

	# Force rooms and corridors to stay walkable even if automaton leaves artifacts
	_carve_rooms_into_grid(grid, rooms)
	_carve_corridors_into_grid(grid, corridor_areas)

	var start: Vector2i = _find_start(grid, rooms)

	if keep_only_reachable_area_from_start:
		_keep_only_reachable_from_start(grid, start)
		rooms = _filter_reachable_rooms(grid, rooms)

	var end: Vector2i = _find_end(grid, start, rooms)

	return {
		"grid": grid,
		"start": start,
		"end": end,
		"rooms": rooms,
		"corridor_areas": corridor_areas,
		"algorithm": get_algorithm_name(),
		"seed": seed_value
	}

func _build_grid_from_procgen(procgen: ProcGen, width: int, height: int) -> Array:
	var grid: Array = []
	for y in range(height):
		var row: Array = []
		for x in range(width):
			var is_full: bool = procgen.is_full_at(Vector2i(x, y))
			row.append(MapTypes.WALL if is_full else MapTypes.FLOOR)
		grid.append(row)
	return grid

func _convert_rooms(raw_rooms: Array[Rect2i]) -> Array:
	var converted: Array = []

	for room in raw_rooms:
		converted.append({
			"position": room.position,
			"size": room.size
		})

	return converted

func _carve_rooms_into_grid(grid: Array, rooms: Array) -> void:
	for room in rooms:
		var pos: Vector2i = room["position"]
		var size: Vector2i = room["size"]

		for y in range(pos.y, pos.y + size.y):
			for x in range(pos.x, pos.x + size.x):
				if _is_inside(grid, Vector2i(x, y)):
					grid[y][x] = MapTypes.FLOOR

func _carve_corridors_into_grid(grid: Array, corridor_areas: Array) -> void:
	for point in corridor_areas:
		if point is Vector2i and _is_inside(grid, point):
			grid[point.y][point.x] = MapTypes.FLOOR

func _find_start(grid: Array, rooms: Array) -> Vector2i:
	if not rooms.is_empty():
		var room: Dictionary = rooms[0]
		return _room_center_on_floor(grid, room)

	return _find_nearest_floor(grid, Vector2i(1, 1))

func _find_end(grid: Array, start: Vector2i, rooms: Array) -> Vector2i:
	if rooms.size() >= 2:
		var best: Vector2i = start
		var best_dist: float = -1.0

		for room in rooms:
			var center: Vector2i = _room_center_on_floor(grid, room)
			var dist: float = start.distance_squared_to(center)
			if center != start and dist > best_dist:
				best_dist = dist
				best = center

		return best

	var floors: Array = _collect_floor_cells(grid)
	if floors.is_empty():
		return start

	var fallback_best: Vector2i = start
	var fallback_best_dist: float = -1.0

	for cell in floors:
		var dist: float = start.distance_squared_to(cell)
		if dist > fallback_best_dist:
			fallback_best_dist = dist
			fallback_best = cell

	return fallback_best

func _room_center_on_floor(grid: Array, room: Dictionary) -> Vector2i:
	var pos: Vector2i = room["position"]
	var size: Vector2i = room["size"]
	var center: Vector2i = pos + Vector2i(size.x / 2, size.y / 2)
	return _find_nearest_floor(grid, center)

func _collect_floor_cells(grid: Array) -> Array:
	var cells: Array = []
	for y in range(grid.size()):
		for x in range(grid[y].size()):
			if grid[y][x] == MapTypes.FLOOR:
				cells.append(Vector2i(x, y))
	return cells

func _find_nearest_floor(grid: Array, origin: Vector2i) -> Vector2i:
	if _is_inside(grid, origin):
		if grid[origin.y][origin.x] == MapTypes.FLOOR:
			return origin

	var best: Vector2i = Vector2i(1, 1)
	var best_dist: float = INF

	for y in range(grid.size()):
		for x in range(grid[y].size()):
			if grid[y][x] == MapTypes.FLOOR:
				var candidate: Vector2i = Vector2i(x, y)
				var dist: float = origin.distance_squared_to(candidate)
				if dist < best_dist:
					best_dist = dist
					best = candidate

	return best

func _keep_only_reachable_from_start(grid: Array, start: Vector2i) -> void:
	if not _is_inside(grid, start):
		return
	if grid[start.y][start.x] != MapTypes.FLOOR:
		return

	var visited := {}
	var queue: Array[Vector2i] = [start]
	visited[_pos_key(start)] = true

	var directions: Array[Vector2i] = [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1)
	]

	while queue.size() > 0:
		var current: Vector2i = queue.pop_front()

		for dir in directions:
			var next: Vector2i = current + dir
			var key: String = _pos_key(next)

			if _is_inside(grid, next) and not visited.has(key):
				if grid[next.y][next.x] == MapTypes.FLOOR:
					visited[key] = true
					queue.append(next)

	for y in range(grid.size()):
		for x in range(grid[y].size()):
			if grid[y][x] == MapTypes.FLOOR:
				var pos: Vector2i = Vector2i(x, y)
				if not visited.has(_pos_key(pos)):
					grid[y][x] = MapTypes.WALL

func _filter_reachable_rooms(grid: Array, rooms: Array) -> Array:
	var filtered: Array = []

	for room in rooms:
		var center: Vector2i = _room_center_on_floor(grid, room)
		if _is_inside(grid, center) and grid[center.y][center.x] == MapTypes.FLOOR:
			filtered.append(room)

	return filtered

func _pos_key(pos: Vector2i) -> String:
	return "%d_%d" % [pos.x, pos.y]

func _is_inside(grid: Array, pos: Vector2i) -> bool:
	return pos.y >= 0 and pos.y < grid.size() and pos.x >= 0 and pos.x < grid[0].size()
