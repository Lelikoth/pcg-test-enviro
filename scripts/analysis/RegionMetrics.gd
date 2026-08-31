class_name RegionMetrics
extends RefCounted

## Calculates connectivity and region-based metrics for generated maps.
##
## Floor regions are identified using four-directional flood fill. The class
## also measures how much of the walkable area is reachable from the selected
## start position.


const CARDINAL_DIRECTIONS: Array[Vector2i] = [
	Vector2i.RIGHT,
	Vector2i.LEFT,
	Vector2i.DOWN,
	Vector2i.UP
]


## Calculates connected-region and reachability metrics for the provided grid.
func calculate(
	grid: Array,
	start: Vector2i
) -> Dictionary:
	var components := _find_floor_components(grid)
	var floor_count := _count_floor_cells(grid)

	var largest_component_size := 0
	var total_component_area := 0

	for component_value in components:
		var component: Dictionary = component_value
		var component_size := int(component["area"])

		total_component_area += component_size
		largest_component_size = maxi(
			largest_component_size,
			component_size
		)

	var average_component_area := 0.0

	if not components.is_empty():
		average_component_area = (
			float(total_component_area)
			/ float(components.size())
		)

	var reachable_count := _reachable_floor_count(
		grid,
		start
	)

	var unreachable_count: int = maxi(
		0,
		floor_count - reachable_count
	)

	return {
		"open_region_count": components.size(),

		"largest_open_region_area": largest_component_size,
		"largest_open_region_ratio": _safe_divide(
			float(largest_component_size),
			float(maxi(1, floor_count))
		),

		"average_open_region_area": average_component_area,

		"reachable_floor_count_from_start": reachable_count,
		"reachable_floor_ratio_from_start": _safe_divide(
			float(reachable_count),
			float(maxi(1, floor_count))
		),

		"unreachable_floor_count": unreachable_count,
		"unreachable_floor_ratio": _safe_divide(
			float(unreachable_count),
			float(maxi(1, floor_count))
		)
	}


## Finds all connected floor components in the grid.
func _find_floor_components(grid: Array) -> Array:
	var components: Array = []
	var visited: Dictionary = {}

	for y in range(grid.size()):
		for x in range(grid[y].size()):
			var position := Vector2i(x, y)

			if visited.has(position):
				continue

			if grid[y][x] != MapTypes.FLOOR:
				continue

			var component_cells := _flood_fill_component(
				grid,
				position,
				visited
			)

			var component_data := _analyze_component(
				component_cells
			)

			components.append(component_data)

	return components


## Performs flood fill starting from a floor tile and returns all cells
## belonging to the same connected component.
func _flood_fill_component(
	grid: Array,
	start: Vector2i,
	visited: Dictionary
) -> Array[Vector2i]:
	var component: Array[Vector2i] = []
	var queue: Array[Vector2i] = [start]
	var head := 0

	visited[start] = true

	while head < queue.size():
		var current := queue[head]
		head += 1

		component.append(current)

		for direction in CARDINAL_DIRECTIONS:
			var next_position := current + direction

			if visited.has(next_position):
				continue

			if not _is_inside_grid(grid, next_position):
				continue

			if grid[next_position.y][next_position.x] != MapTypes.FLOOR:
				continue

			visited[next_position] = true
			queue.append(next_position)

	return component


## Calculates the area and bounding box of a connected floor component.
func _analyze_component(
	component: Array[Vector2i]
) -> Dictionary:
	if component.is_empty():
		return {
			"area": 0,
			"position": Vector2i.ZERO,
			"size": Vector2i.ZERO,
			"bbox_area": 0,
			"bbox_fill_ratio": 0.0
		}

	var first := component[0]

	var min_x := first.x
	var max_x := first.x
	var min_y := first.y
	var max_y := first.y

	for cell in component:
		min_x = mini(min_x, cell.x)
		max_x = maxi(max_x, cell.x)
		min_y = mini(min_y, cell.y)
		max_y = maxi(max_y, cell.y)

	var width := max_x - min_x + 1
	var height := max_y - min_y + 1
	var bounding_box_area := width * height
	var area := component.size()

	return {
		"area": area,
		"position": Vector2i(min_x, min_y),
		"size": Vector2i(width, height),
		"bbox_area": bounding_box_area,
		"bbox_fill_ratio": _safe_divide(
			float(area),
			float(maxi(1, bounding_box_area))
		)
	}


## Counts floor tiles reachable from the provided start position.
func _reachable_floor_count(
	grid: Array,
	start: Vector2i
) -> int:
	if not _is_inside_grid(grid, start):
		return 0

	if grid[start.y][start.x] != MapTypes.FLOOR:
		return 0

	var visited: Dictionary = {}
	var queue: Array[Vector2i] = [start]
	var head := 0

	visited[start] = true

	while head < queue.size():
		var current := queue[head]
		head += 1

		for direction in CARDINAL_DIRECTIONS:
			var next_position := current + direction

			if visited.has(next_position):
				continue

			if not _is_inside_grid(grid, next_position):
				continue

			if grid[next_position.y][next_position.x] != MapTypes.FLOOR:
				continue

			visited[next_position] = true
			queue.append(next_position)

	return visited.size()


## Counts all walkable floor tiles in the grid.
func _count_floor_cells(grid: Array) -> int:
	var floor_count := 0

	for y in range(grid.size()):
		for x in range(grid[y].size()):
			if grid[y][x] == MapTypes.FLOOR:
				floor_count += 1

	return floor_count


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


## Performs division while preventing division by zero.
func _safe_divide(
	numerator: float,
	denominator: float
) -> float:
	if denominator == 0.0:
		return 0.0

	return numerator / denominator
