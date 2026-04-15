extends BaseGenerator
class_name RandomWalkGenerator

func get_algorithm_name() -> String:
	return "RandomWalk"

func generate_map(config: Dictionary) -> Dictionary:
	var width: int = config.get("width", 64)
	var height: int = config.get("height", 64)
	var use_random_seed: bool = config.get("random_seed", true)
	var seed_value: int = config.get("seed", 0)
	var steps: int = config.get("rw_steps", 500)
	var start_from_center: bool = config.get("rw_start_from_center", true)
	var use_fixed_start_end_rooms: bool = config.get("use_fixed_start_end_rooms", false)

	var rng := RandomNumberGenerator.new()
	if use_random_seed:
		rng.randomize()
		seed_value = rng.randi()
	rng.seed = seed_value

	var grid := _create_filled_grid(width, height, MapTypes.WALL)

	var current: Vector2i

	if use_fixed_start_end_rooms:
		current = Vector2i(3, 3)
		_carve_room(grid, current, 3)
	elif start_from_center:
		current = Vector2i(width / 2, height / 2)
	else:
		current = Vector2i(
			rng.randi_range(1, width - 2),
			rng.randi_range(1, height - 2)
		)

	grid[current.y][current.x] = MapTypes.FLOOR

	var directions: Array[Vector2i] = [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1)
	]

	for i in range(steps):
		var dir: Vector2i = directions[rng.randi_range(0, directions.size() - 1)]
		var next: Vector2i = current + dir

		next.x = clamp(next.x, 1, width - 2)
		next.y = clamp(next.y, 1, height - 2)

		current = next
		grid[current.y][current.x] = MapTypes.FLOOR

	var floor_cells: Array = _collect_floor_cells(grid)
	var start: Vector2i = Vector2i(width / 2, height / 2)

	if use_fixed_start_end_rooms:
		start = Vector2i(3, 3)
	else:
		start = _find_nearest_floor(grid, start)

	var end: Vector2i = start
	if floor_cells.size() > 1:
		end = _find_farthest_floor(start, floor_cells)

	return {
		"grid": grid,
		"start": start,
		"end": end,
		"rooms": [],
		"algorithm": get_algorithm_name(),
		"seed": seed_value
	}

func _create_filled_grid(width: int, height: int, value: int) -> Array:
	var grid: Array = []
	for y in range(height):
		var row: Array = []
		for x in range(width):
			row.append(value)
		grid.append(row)
	return grid

func _carve_room(grid: Array, center: Vector2i, room_size: int) -> void:
	var half_size: int = room_size / 2
	for y in range(center.y - half_size, center.y + half_size + 1):
		for x in range(center.x - half_size, center.x + half_size + 1):
			if y >= 0 and y < grid.size() and x >= 0 and x < grid[0].size():
				grid[y][x] = MapTypes.FLOOR

func _collect_floor_cells(grid: Array) -> Array:
	var cells: Array = []
	for y in range(grid.size()):
		for x in range(grid[y].size()):
			if grid[y][x] == MapTypes.FLOOR:
				cells.append(Vector2i(x, y))
	return cells

func _find_nearest_floor(grid: Array, pos: Vector2i) -> Vector2i:
	if grid[pos.y][pos.x] == MapTypes.FLOOR:
		return pos

	var best: Vector2i = pos
	var best_dist: float = INF

	for y in range(grid.size()):
		for x in range(grid[y].size()):
			if grid[y][x] == MapTypes.FLOOR:
				var candidate: Vector2i = Vector2i(x, y)
				var dist: float = pos.distance_squared_to(candidate)
				if dist < best_dist:
					best_dist = dist
					best = candidate

	return best

func _find_farthest_floor(origin: Vector2i, floor_cells: Array) -> Vector2i:
	var best: Vector2i = origin
	var best_dist: float = -1.0

	for cell in floor_cells:
		var dist: float = origin.distance_squared_to(cell)
		if dist > best_dist:
			best_dist = dist
			best = cell

	return best
