extends BaseGenerator
class_name PerlinNoiseGenerator

func get_algorithm_name() -> String:
	return "PerlinNoise"

func generate_map(config: Dictionary) -> Dictionary:
	var width: int = config.get("width", 64)
	var height: int = config.get("height", 64)
	var use_random_seed: bool = config.get("random_seed", true)
	var seed_value: int = config.get("seed", 0)

	var frequency: float = config.get("noise_frequency", 0.05)
	var threshold: float = config.get("noise_threshold", 0.0)
	var octaves: int = config.get("noise_fractal_octaves", 3)

	var rng := RandomNumberGenerator.new()
	if use_random_seed:
		rng.randomize()
		seed_value = rng.randi()

	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = frequency
	noise.fractal_octaves = octaves

	var grid: Array = []
	for y in range(height):
		var row: Array = []
		for x in range(width):
			var value: float = noise.get_noise_2d(float(x), float(y))
			if value < threshold:
				row.append(MapTypes.FLOOR)
			else:
				row.append(MapTypes.WALL)
		grid.append(row)

	_make_borders_walls(grid)

	var start: Vector2i = _find_nearest_floor(grid, Vector2i(1, 1))
	var end: Vector2i = _find_farthest_floor(grid, start)

	return {
		"grid": grid,
		"start": start,
		"end": end,
		"rooms": [],
		"algorithm": get_algorithm_name(),
		"seed": seed_value
	}

func _make_borders_walls(grid: Array) -> void:
	var h: int = grid.size()
	if h == 0:
		return
	var w: int = grid[0].size()

	for x in range(w):
		grid[0][x] = MapTypes.WALL
		grid[h - 1][x] = MapTypes.WALL

	for y in range(h):
		grid[y][0] = MapTypes.WALL
		grid[y][w - 1] = MapTypes.WALL

func _find_nearest_floor(grid: Array, origin: Vector2i) -> Vector2i:
	if _is_inside(grid, origin) and grid[origin.y][origin.x] == MapTypes.FLOOR:
		return origin

	var best: Vector2i = origin
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

func _find_farthest_floor(grid: Array, origin: Vector2i) -> Vector2i:
	var best: Vector2i = origin
	var best_dist: float = -1.0

	for y in range(grid.size()):
		for x in range(grid[y].size()):
			if grid[y][x] == MapTypes.FLOOR:
				var candidate: Vector2i = Vector2i(x, y)
				var dist: float = origin.distance_squared_to(candidate)
				if dist > best_dist:
					best_dist = dist
					best = candidate

	return best

func _is_inside(grid: Array, pos: Vector2i) -> bool:
	return pos.y >= 0 and pos.y < grid.size() and pos.x >= 0 and pos.x < grid[0].size()
