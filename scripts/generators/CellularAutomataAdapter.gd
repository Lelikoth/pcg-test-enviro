extends BaseGenerator
class_name CellularAutomataAdapter


const WALL_THRESHOLD: int = 4
const DEFAULT_BORDER_WIDTH: int = 1


func get_algorithm_name() -> String:
	return "CellularAutomata"


func generate_map(config: Dictionary) -> Dictionary:
	var width: int = config.get("width", 64)
	var height: int = config.get("height", 64)

	var use_random_seed: bool = config.get("random_seed", true)
	var seed_value: int = config.get("seed", 0)

	var fill_probability: float = config.get("ca_fill_probability", 0.45)
	var smoothing_iterations: int = config.get("ca_iterations", 5)

	# The original addon has borderWidth as a parameter.
	var border_width: int = config.get("ca_border_width", DEFAULT_BORDER_WIDTH)

	var use_fixed_start_end_rooms: bool = config.get("use_fixed_start_end_rooms", false)
	var keep_only_reachable_area_from_start: bool = config.get(
		"keep_only_reachable_area_from_start",
		false
	)

	var rng := RandomNumberGenerator.new()

	if use_random_seed:
		rng.randomize()
		seed_value = rng.randi()

	rng.seed = seed_value

	fill_probability = clamp(fill_probability, 0.0, 1.0)
	smoothing_iterations = max(smoothing_iterations, 0)
	border_width = clamp(border_width, 0, int(min(width, height) / 2))

	var grid: Array = _initialize_grid(
		width,
		height,
		border_width,
		fill_probability,
		rng
	)

	for i in range(smoothing_iterations):
		grid = _smooth_map(grid)

	# The original addon runs Dijkstra from the center and removes floor regions
	# unreachable from that central region.
	var center := Vector2i(width / 2, height / 2)
	var center_floor := _find_nearest_floor(grid, center)
	_keep_only_reachable_from(grid, center_floor)

	if use_fixed_start_end_rooms:
		var start_room_center := Vector2i(3, 3)
		var end_room_center := Vector2i(width - 4, height - 4)

		_carve_room(grid, start_room_center, 3)
		_carve_room(grid, end_room_center, 3)

	var start: Vector2i
	var end: Vector2i

	if use_fixed_start_end_rooms:
		start = _find_nearest_floor(grid, Vector2i(3, 3))
		end = _find_nearest_floor(grid, Vector2i(width - 4, height - 4))
	else:
		start = _find_nearest_floor(grid, center)
		end = _find_farthest_floor(grid, start)

	if keep_only_reachable_area_from_start:
		_keep_only_reachable_from(grid, start)
		end = _find_farthest_floor(grid, start)

	return {
		"grid": grid,
		"start": start,
		"end": end,
		"rooms": [],
		"algorithm": get_algorithm_name(),
		"seed": seed_value
	}


func _initialize_grid(
	width: int,
	height: int,
	border_width: int,
	fill_probability: float,
	rng: RandomNumberGenerator
) -> Array:
	var grid: Array = []

	for y in range(height):
		var row: Array = []

		for x in range(width):
			if _is_border_tile(x, y, width, height, border_width):
				row.append(MapTypes.WALL)
			else:
				row.append(MapTypes.WALL if rng.randf() < fill_probability else MapTypes.FLOOR)

		grid.append(row)

	return grid


func _is_border_tile(
	x: int,
	y: int,
	width: int,
	height: int,
	border_width: int
) -> bool:
	return (
		x < border_width
		or x >= width - border_width
		or y < border_width
		or y >= height - border_width
	)


func _smooth_map(grid: Array) -> Array:
	var width: int = grid[0].size()
	var height: int = grid.size()

	var new_grid: Array = []

	for y in range(height):
		var row: Array = []

		for x in range(width):
			var wall_count: int = _count_wall_neighbors(grid, x, y)

			# This mirrors the addon's SmoothMap() logic:
			# nWalls < 4  -> floor
			# nWalls > 4  -> wall
			# nWalls == 4 -> keep previous state
			if wall_count < WALL_THRESHOLD:
				row.append(MapTypes.FLOOR)
			elif wall_count > WALL_THRESHOLD:
				row.append(MapTypes.WALL)
			else:
				row.append(grid[y][x])

		new_grid.append(row)

	return new_grid


func _count_wall_neighbors(grid: Array, cell_x: int, cell_y: int) -> int:
	var count: int = 0

	for y in range(cell_y - 1, cell_y + 2):
		for x in range(cell_x - 1, cell_x + 2):
			if x == cell_x and y == cell_y:
				continue

			if y < 0 or y >= grid.size() or x < 0 or x >= grid[0].size():
				count += 1
			elif grid[y][x] == MapTypes.WALL:
				count += 1

	return count


func _keep_only_reachable_from(grid: Array, start: Vector2i) -> void:
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

	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()

		for direction in directions:
			var next: Vector2i = current + direction
			var key: String = _pos_key(next)

			if not _is_inside(grid, next):
				continue

			if visited.has(key):
				continue

			if grid[next.y][next.x] != MapTypes.FLOOR:
				continue

			visited[key] = true
			queue.append(next)

	for y in range(grid.size()):
		for x in range(grid[y].size()):
			if grid[y][x] != MapTypes.FLOOR:
				continue

			var pos := Vector2i(x, y)

			if not visited.has(_pos_key(pos)):
				grid[y][x] = MapTypes.WALL


func _carve_room(grid: Array, center: Vector2i, room_size: int) -> void:
	var half_size: int = int(room_size / 2)

	for y in range(center.y - half_size, center.y + half_size + 1):
		for x in range(center.x - half_size, center.x + half_size + 1):
			var pos := Vector2i(x, y)

			if _is_inside(grid, pos):
				grid[y][x] = MapTypes.FLOOR


func _find_nearest_floor(grid: Array, origin: Vector2i) -> Vector2i:
	if _is_inside(grid, origin) and grid[origin.y][origin.x] == MapTypes.FLOOR:
		return origin

	var best: Vector2i = origin
	var best_dist: float = INF
	var found: bool = false

	for y in range(grid.size()):
		for x in range(grid[y].size()):
			if grid[y][x] != MapTypes.FLOOR:
				continue

			var candidate := Vector2i(x, y)
			var dist: float = origin.distance_squared_to(candidate)

			if dist < best_dist:
				best_dist = dist
				best = candidate
				found = true

	if found:
		return best

	return Vector2i.ZERO


func _find_farthest_floor(grid: Array, origin: Vector2i) -> Vector2i:
	var best: Vector2i = origin
	var best_dist: float = -1.0

	for y in range(grid.size()):
		for x in range(grid[y].size()):
			if grid[y][x] != MapTypes.FLOOR:
				continue

			var candidate := Vector2i(x, y)
			var dist: float = origin.distance_squared_to(candidate)

			if dist > best_dist:
				best_dist = dist
				best = candidate

	return best


func _pos_key(pos: Vector2i) -> String:
	return "%d_%d" % [pos.x, pos.y]


func _is_inside(grid: Array, pos: Vector2i) -> bool:
	return (
		pos.y >= 0
		and pos.y < grid.size()
		and pos.x >= 0
		and pos.x < grid[0].size()
	)
