class_name EndpointSelector
extends RefCounted

## Selects standardized start and end positions on generated maps.
##
## Endpoint positions are chosen as floor tiles nearest to predefined anchors
## located near opposite map corners. This provides a consistent endpoint
## selection procedure across all generators.


## Selects start and end positions near opposite map corners.
##
## The start anchor is located at (1, 1), while the end anchor is located
## at (width - 2, height - 2). If an anchor is not a floor tile, the nearest
## floor tile is selected using squared Euclidean distance.
func select_corner_endpoints(grid: Array) -> Dictionary:
	var width := _get_width(grid)
	var height := _get_height(grid)

	if width <= 0 or height <= 0:
		return _create_invalid_result()

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


## Finds the floor tile nearest to the provided origin.
##
## Squared Euclidean distance is used because only relative distance
## comparisons are required.
func find_nearest_floor(
	grid: Array,
	origin: Vector2i
) -> Vector2i:
	if _is_floor(grid, origin):
		return origin

	var nearest_position := Vector2i.ZERO
	var nearest_distance: float = INF
	var found_floor := false

	for y in range(grid.size()):
		for x in range(grid[y].size()):
			if grid[y][x] != MapTypes.FLOOR:
				continue

			var candidate := Vector2i(x, y)
			var distance: float = origin.distance_squared_to(candidate)

			if distance < nearest_distance:
				nearest_distance = distance
				nearest_position = candidate
				found_floor = true

	return nearest_position if found_floor else Vector2i.ZERO


## Finds the floor tile farthest from the provided origin.
##
## Squared Euclidean distance is used instead of path distance.
func find_farthest_floor(
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
			var distance: float = origin.distance_squared_to(candidate)

			if distance > farthest_distance:
				farthest_distance = distance
				farthest_position = candidate

	return farthest_position


## Returns whether the provided position contains a floor tile.
func _is_floor(
	grid: Array,
	position: Vector2i
) -> bool:
	if not _is_inside_grid(grid, position):
		return false

	return grid[position.y][position.x] == MapTypes.FLOOR


## Returns whether the provided position lies within the grid bounds.
func _is_inside_grid(
	grid: Array,
	position: Vector2i
) -> bool:
	if grid.is_empty():
		return false

	return (
		position.y >= 0
		and position.y < grid.size()
		and position.x >= 0
		and position.x < grid[position.y].size()
	)


## Returns the width of the first grid row.
func _get_width(grid: Array) -> int:
	if grid.is_empty():
		return 0

	return grid[0].size()


## Returns the number of rows in the grid.
func _get_height(grid: Array) -> int:
	return grid.size()


## Creates the endpoint result returned for an invalid or empty grid.
func _create_invalid_result() -> Dictionary:
	return {
		"start": Vector2i.ZERO,
		"end": Vector2i.ZERO,
		"has_valid_start": false,
		"has_valid_end": false
	}
