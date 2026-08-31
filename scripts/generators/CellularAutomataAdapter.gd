class_name CellularAutomataAdapter
extends BaseGenerator

## Adapts the Cellular Automata generator from the analyzed
## Procedural-Map-Generator addon to the common testing interface.
##
## The generator initializes a binary wall/floor grid, repeatedly applies
## the addon's neighborhood-based smoothing rule, and retains the floor
## component reachable from the central map area.


const DEFAULT_BORDER_WIDTH: int = 1

const CARDINAL_DIRECTIONS: Array[Vector2i] = [
	Vector2i.RIGHT,
	Vector2i.LEFT,
	Vector2i.DOWN,
	Vector2i.UP
]


## Returns the identifier used for this generator in test results and exports.
func get_algorithm_name() -> String:
	return "CellularAutomata"


## Generates a map using the adapted Cellular Automata algorithm.
##
## The configuration controls map dimensions, seed handling, initial wall
## probability, smoothing iterations, border width, and neighborhood threshold.
func generate_map(config: Dictionary) -> Dictionary:
	var width: int = config.get("width", 64)
	var height: int = config.get("height", 64)

	var use_random_seed: bool = config.get("random_seed", true)
	var seed_value: int = config.get("seed", 0)

	var fill_probability: float = config.get(
		"ca_fill_probability",
		0.45
	)

	var smoothing_iterations: int = config.get(
		"ca_iterations",
		5
	)

	var wall_threshold: int = config.get(
		"ca_wall_threshold",
		4
	)

	var border_width: int = config.get(
		"ca_border_width",
		DEFAULT_BORDER_WIDTH
	)

	# Legacy option retained for compatibility with an earlier version
	# of the testing environment.
	var use_fixed_start_end_rooms: bool = config.get(
		"use_fixed_start_end_rooms",
		false
	)

	var keep_only_reachable_area_from_start: bool = config.get(
		"keep_only_reachable_area_from_start",
		false
	)

	var rng := RandomNumberGenerator.new()

	if use_random_seed:
		rng.randomize()
		seed_value = rng.randi()

	rng.seed = seed_value

	fill_probability = clampf(
		fill_probability,
		0.0,
		1.0
	)

	smoothing_iterations = maxi(
		smoothing_iterations,
		0
	)

	var max_border_width: int = int(
		mini(width, height) / 2.0
	)

	border_width = clampi(
		border_width,
		0,
		max_border_width
	)

	var grid := _initialize_grid(
		width,
		height,
		border_width,
		fill_probability,
		rng
	)

	for _iteration in range(smoothing_iterations):
		grid = _smooth_map(
			grid,
			wall_threshold
		)

	# The original addon removes floor regions that are not reachable from
	# the central map area. This behavior is part of the adapted generator
	# and is independent of the optional test-environment reachability flag.
	var center := Vector2i(
		width / 2,
		height / 2
	)

	var center_floor := _find_nearest_floor(
		grid,
		center
	)

	_keep_only_reachable_from(
		grid,
		center_floor
	)

	# Legacy fixed-room behavior. MapPostProcessor later applies the common
	# version of this operation as well.
	if use_fixed_start_end_rooms:
		var start_room_center := Vector2i(3, 3)
		var end_room_center := Vector2i(
			width - 4,
			height - 4
		)

		_carve_room(
			grid,
			start_room_center,
			3
		)

		_carve_room(
			grid,
			end_room_center,
			3
		)

	var start: Vector2i
	var end: Vector2i

	if use_fixed_start_end_rooms:
		start = _find_nearest_floor(
			grid,
			Vector2i(3, 3)
		)

		end = _find_nearest_floor(
			grid,
			Vector2i(width - 4, height - 4)
		)
	else:
		start = _find_nearest_floor(
			grid,
			center
		)

		end = _find_farthest_floor(
			grid,
			start
		)

	# Optional test-environment filtering. This is separate from the
	# center-based component filtering inherited from the original addon.
	if keep_only_reachable_area_from_start:
		_keep_only_reachable_from(
			grid,
			start
		)

		end = _find_farthest_floor(
			grid,
			start
		)

	return {
		"grid": grid,
		"start": start,
		"end": end,
		"rooms": [],
		"algorithm": get_algorithm_name(),
		"seed": seed_value
	}


## Creates the initial random wall/floor grid.
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
			if _is_border_tile(
				x,
				y,
				width,
				height,
				border_width
			):
				row.append(MapTypes.WALL)
			elif rng.randf() < fill_probability:
				row.append(MapTypes.WALL)
			else:
				row.append(MapTypes.FLOOR)

		grid.append(row)

	return grid


## Returns whether a tile belongs to the forced outer wall border.
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


## Applies one cellular automata smoothing iteration.
##
## This mirrors the analyzed addon's SmoothMap() rule:
## - fewer neighbors than the threshold -> floor,
## - more neighbors than the threshold -> wall,
## - exactly the threshold -> preserve the previous state.
func _smooth_map(
	grid: Array,
	wall_threshold: int
) -> Array:
	var width: int = grid[0].size()
	var height: int = grid.size()

	var new_grid: Array = []

	for y in range(height):
		var row: Array = []

		for x in range(width):
			var wall_count := _count_wall_neighbors(
				grid,
				x,
				y
			)

			if wall_count < wall_threshold:
				row.append(MapTypes.FLOOR)
			elif wall_count > wall_threshold:
				row.append(MapTypes.WALL)
			else:
				row.append(grid[y][x])

		new_grid.append(row)

	return new_grid


## Counts wall tiles in the eight-cell Moore neighborhood.
##
## Positions outside the map are treated as walls.
func _count_wall_neighbors(
	grid: Array,
	cell_x: int,
	cell_y: int
) -> int:
	var wall_count: int = 0

	for y in range(cell_y - 1, cell_y + 2):
		for x in range(cell_x - 1, cell_x + 2):
			if x == cell_x and y == cell_y:
				continue

			var position := Vector2i(x, y)

			if not _is_inside_grid(grid, position):
				wall_count += 1
				continue

			if grid[y][x] == MapTypes.WALL:
				wall_count += 1

	return wall_count


## Removes all floor tiles that are not reachable from the provided start tile.
func _keep_only_reachable_from(
	grid: Array,
	start: Vector2i
) -> void:
	if not _is_inside_grid(grid, start):
		return

	if grid[start.y][start.x] != MapTypes.FLOOR:
		return

	var visited: Dictionary = {}
	var queue: Array[Vector2i] = [start]
	var head: int = 0

	visited[start] = true

	while head < queue.size():
		var current := queue[head]
		head += 1

		for direction in CARDINAL_DIRECTIONS:
			var next_position := current + direction

			if visited.has(next_position):
				continue

			if not _is_inside_grid(
				grid,
				next_position
			):
				continue

			if (
				grid[next_position.y][next_position.x]
				!= MapTypes.FLOOR
			):
				continue

			visited[next_position] = true
			queue.append(next_position)

	for y in range(grid.size()):
		for x in range(grid[y].size()):
			if grid[y][x] != MapTypes.FLOOR:
				continue

			var position := Vector2i(x, y)

			if not visited.has(position):
				grid[y][x] = MapTypes.WALL


## Legacy helper that carves a square floor room around a center position.
func _carve_room(
	grid: Array,
	center: Vector2i,
	room_size: int
) -> void:
	var half_size: int = int(
		room_size / 2.0
	)

	for y in range(
		center.y - half_size,
		center.y + half_size + 1
	):
		for x in range(
			center.x - half_size,
			center.x + half_size + 1
		):
			var position := Vector2i(x, y)

			if _is_inside_grid(grid, position):
				grid[y][x] = MapTypes.FLOOR


## Finds the floor tile nearest to the provided position using squared
## Euclidean distance.
func _find_nearest_floor(
	grid: Array,
	origin: Vector2i
) -> Vector2i:
	if (
		_is_inside_grid(grid, origin)
		and grid[origin.y][origin.x] == MapTypes.FLOOR
	):
		return origin

	var nearest_position := origin
	var nearest_distance: float = INF
	var found_floor := false

	for y in range(grid.size()):
		for x in range(grid[y].size()):
			if grid[y][x] != MapTypes.FLOOR:
				continue

			var candidate := Vector2i(x, y)
			var distance: float = origin.distance_squared_to(
				candidate
			)

			if distance < nearest_distance:
				nearest_distance = distance
				nearest_position = candidate
				found_floor = true

	return nearest_position if found_floor else Vector2i.ZERO


## Finds the floor tile farthest from the provided position using squared
## Euclidean distance.
func _find_farthest_floor(
	grid: Array,
	origin: Vector2i
) -> Vector2i:
	var farthest_position := origin
	var farthest_distance: float = -1.0

	for y in range(grid.size()):
		for x in range(grid[y].size()):
			if grid[y][x] != MapTypes.FLOOR:
				continue

			var candidate := Vector2i(x, y)
			var distance: float = origin.distance_squared_to(
				candidate
			)

			if distance > farthest_distance:
				farthest_distance = distance
				farthest_position = candidate

	return farthest_position


## Returns whether the provided position lies within the grid bounds.
func _is_inside_grid(
	grid: Array,
	position: Vector2i
) -> bool:
	if grid.is_empty():
		return false

	if position.y < 0 or position.y >= grid.size():
		return false

	return (
		position.x >= 0
		and position.x < grid[position.y].size()
	)
