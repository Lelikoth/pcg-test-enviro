extends BaseGenerator
class_name CellularAutomataAdapter

func get_algorithm_name() -> String:
	return "CellularAutomata"

func generate_map(config: Dictionary) -> Dictionary:
	var width: int = config.get("width", 64)
	var height: int = config.get("height", 64)
	var use_random_seed: bool = config.get("random_seed", true)
	var seed_value: int = config.get("seed", 0)

	var fill_probability: float = config.get("ca_fill_probability", 0.45)
	var iterations: int = config.get("ca_iterations", 5)
	var birth_limit: int = config.get("ca_birth_limit", 4)
	var death_limit: int = config.get("ca_death_limit", 3)
	var use_fixed_start_end_rooms: bool = config.get("use_fixed_start_end_rooms", false)
	var keep_only_reachable_area_from_start: bool = config.get("keep_only_reachable_area_from_start", false)

	var rng := RandomNumberGenerator.new()
	if use_random_seed:
		rng.randomize()
		seed_value = rng.randi()
	rng.seed = seed_value

	var grid: Array = _initialize_grid(width, height, fill_probability, rng)

	for i in range(iterations):
		grid = _simulate_step(grid, birth_limit, death_limit)

	if use_fixed_start_end_rooms:
		_carve_room(grid, Vector2i(3, 3), 3)
		_carve_room(grid, Vector2i(width - 4, height - 4), 3)

	var start: Vector2i = _find_nearest_floor(grid, Vector2i(1, 1))
	var end: Vector2i = _find_farthest_floor(grid, start)

	if keep_only_reachable_area_from_start:
		_keep_only_reachable_from_start(grid, start)
		end = _find_farthest_floor(grid, start)

	return {
		"grid": grid,
		"start": start,
		"end": end,
		"rooms": [],
		"algorithm": get_algorithm_name(),
		"seed": seed_value
	}

func _initialize_grid(width: int, height: int, fill_probability: float, rng: RandomNumberGenerator) -> Array:
	var grid: Array = []

	for y in range(height):
		var row: Array = []
		for x in range(width):
			if x == 0 or y == 0 or x == width - 1 or y == height - 1:
				row.append(MapTypes.WALL)
			else:
				var roll: float = rng.randf()
				row.append(MapTypes.WALL if roll < fill_probability else MapTypes.FLOOR)
		grid.append(row)

	return grid

func _simulate_step(grid: Array, birth_limit: int, death_limit: int) -> Array:
	var new_grid: Array = []

	for y in range(grid.size()):
		var row: Array = []
		for x in range(grid[y].size()):
			var wall_count: int = _count_wall_neighbors(grid, x, y)

			if grid[y][x] == MapTypes.WALL:
				row.append(MapTypes.WALL if wall_count >= death_limit else MapTypes.FLOOR)
			else:
				row.append(MapTypes.WALL if wall_count > birth_limit else MapTypes.FLOOR)
		new_grid.append(row)

	return new_grid

func _count_wall_neighbors(grid: Array, cell_x: int, cell_y: int) -> int:
	var count := 0
	for y in range(cell_y - 1, cell_y + 2):
		for x in range(cell_x - 1, cell_x + 2):
			if x == cell_x and y == cell_y:
				continue

			if y < 0 or y >= grid.size() or x < 0 or x >= grid[0].size():
				count += 1
			elif grid[y][x] == MapTypes.WALL:
				count += 1

	return count

func _carve_room(grid: Array, center: Vector2i, room_size: int) -> void:
	var half_size: int = room_size / 2

	for y in range(center.y - half_size, center.y + half_size + 1):
		for x in range(center.x - half_size, center.x + half_size + 1):
			if _is_inside(grid, Vector2i(x, y)):
				grid[y][x] = MapTypes.FLOOR

func _find_nearest_floor(grid: Array, origin: Vector2i) -> Vector2i:
	if _is_inside(grid, origin) and grid[origin.y][origin.x] == MapTypes.FLOOR:
		return origin

	var best: Vector2i = origin
	var best_dist: float = INF

	for y in range(grid.size()):
		for x in range(grid[y].size()):
			if grid[y][x] == MapTypes.FLOOR:
				var candidate := Vector2i(x, y)
				var dist: float = origin.distance_squared_to(candidate)
				if dist < best_dist:
					best_dist = dist
					best = candidate

	return best

func _find_farthest_floor(grid: Array, origin: Vector2i) -> Vector2i:
	var best: Vector2i = origin
	var best_dist: float = -1.0

	for y in range(grid.size()):
		for x in range(grid[y].size()):
			if grid[y][x] == MapTypes.FLOOR:
				var candidate := Vector2i(x, y)
				var dist: float = origin.distance_squared_to(candidate)
				if dist > best_dist:
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
				var pos := Vector2i(x, y)
				if not visited.has(_pos_key(pos)):
					grid[y][x] = MapTypes.WALL

func _pos_key(pos: Vector2i) -> String:
	return "%d_%d" % [pos.x, pos.y]

func _is_inside(grid: Array, pos: Vector2i) -> bool:
	return pos.y >= 0 and pos.y < grid.size() and pos.x >= 0 and pos.x < grid[0].size()
