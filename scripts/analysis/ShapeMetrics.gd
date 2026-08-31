class_name ShapeMetrics
extends RefCounted

## Calculates shape-related metrics for the walkable area of a map.
##
## The normalized perimeter describes the amount of floor boundary relative
## to the total number of floor tiles. Higher values generally indicate
## more irregular or fragmented floor geometry.


const CARDINAL_DIRECTIONS: Array[Vector2i] = [
	Vector2i.RIGHT,
	Vector2i.LEFT,
	Vector2i.DOWN,
	Vector2i.UP
]


## Calculates perimeter-related metrics for the provided grid.
func calculate(grid: Array) -> Dictionary:
	var floor_count: int = 0
	var floor_wall_adjacency_count: int = 0

	for y in range(grid.size()):
		for x in range(grid[y].size()):
			if grid[y][x] != MapTypes.FLOOR:
				continue

			floor_count += 1

			var position := Vector2i(x, y)

			floor_wall_adjacency_count += _count_wall_sides(
				grid,
				position
			)

	var normalized_perimeter: float = 0.0

	if floor_count > 0:
		normalized_perimeter = (
			float(floor_wall_adjacency_count)
			/ float(floor_count)
		)

	return {
		"floor_wall_adjacency_count": floor_wall_adjacency_count,
		"normalized_perimeter": normalized_perimeter
	}


## Counts the sides of a floor tile that border either a wall or the map edge.
func _count_wall_sides(
	grid: Array,
	position: Vector2i
) -> int:
	var wall_side_count: int = 0

	for direction in CARDINAL_DIRECTIONS:
		var next_position := position + direction

		if not _is_inside_grid(grid, next_position):
			wall_side_count += 1
			continue

		if grid[next_position.y][next_position.x] != MapTypes.FLOOR:
			wall_side_count += 1

	return wall_side_count


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
