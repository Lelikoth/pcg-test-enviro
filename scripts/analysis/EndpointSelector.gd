extends RefCounted
class_name EndpointSelector


func select_corner_endpoints(grid: Array) -> Dictionary:
	var width: int = _get_width(grid)
	var height: int = _get_height(grid)

	if width <= 0 or height <= 0:
		return {
			"start": Vector2i.ZERO,
			"end": Vector2i.ZERO,
			"has_valid_start": false,
			"has_valid_end": false
		}

	var start_anchor := Vector2i(1, 1)
	var end_anchor := Vector2i(width - 2, height - 2)

	var start := find_nearest_floor(grid, start_anchor)
	var end := find_nearest_floor(grid, end_anchor)

	return {
		"start": start,
		"end": end,
		"has_valid_start": _is_floor(grid, start),
		"has_valid_end": _is_floor(grid, end)
	}


func find_nearest_floor(grid: Array, origin: Vector2i) -> Vector2i:
	if _is_floor(grid, origin):
		return origin

	var best := Vector2i.ZERO
	var best_dist: float = INF
	var found: bool = false

	for y in range(grid.size()):
		for x in range(grid[y].size()):
			if grid[y][x] != MapTypes.FLOOR:
				continue

			var candidate := Vector2i(x, y)
			var dist := origin.distance_squared_to(candidate)

			if dist < best_dist:
				best_dist = dist
				best = candidate
				found = true

	return best if found else Vector2i.ZERO


func find_farthest_floor(grid: Array, origin: Vector2i) -> Vector2i:
	var best := origin
	var best_dist: float = -1.0

	for y in range(grid.size()):
		for x in range(grid[y].size()):
			if grid[y][x] != MapTypes.FLOOR:
				continue

			var candidate := Vector2i(x, y)
			var dist := origin.distance_squared_to(candidate)

			if dist > best_dist:
				best_dist = dist
				best = candidate

	return best


func _is_floor(grid: Array, pos: Vector2i) -> bool:
	if not _is_inside(grid, pos):
		return false

	return grid[pos.y][pos.x] == MapTypes.FLOOR


func _is_inside(grid: Array, pos: Vector2i) -> bool:
	return (
		pos.y >= 0
		and pos.y < grid.size()
		and pos.x >= 0
		and grid.size() > 0
		and pos.x < grid[0].size()
	)


func _get_width(grid: Array) -> int:
	if grid.is_empty():
		return 0

	return grid[0].size()


func _get_height(grid: Array) -> int:
	return grid.size()
