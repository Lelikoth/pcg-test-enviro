extends RefCounted
class_name ShapeMetrics


func calculate(grid: Array) -> Dictionary:
	var floor_count: int = 0
	var floor_wall_adjacency_count: int = 0

	for y in range(grid.size()):
		for x in range(grid[y].size()):
			if grid[y][x] != MapTypes.FLOOR:
				continue

			floor_count += 1

			var pos := Vector2i(x, y)
			floor_wall_adjacency_count += _count_wall_sides(grid, pos)

	var normalized_perimeter: float = 0.0
	if floor_count > 0:
		normalized_perimeter = float(floor_wall_adjacency_count) / float(floor_count)

	return {
		"floor_wall_adjacency_count": floor_wall_adjacency_count,
		"normalized_perimeter": normalized_perimeter
	}


func _count_wall_sides(grid: Array, pos: Vector2i) -> int:
	var count: int = 0

	var directions: Array[Vector2i] = [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1)
	]

	for dir in directions:
		var next := pos + dir

		if not _is_inside(grid, next):
			count += 1
		elif grid[next.y][next.x] != MapTypes.FLOOR:
			count += 1

	return count


func _is_inside(grid: Array, pos: Vector2i) -> bool:
	return (
		pos.y >= 0
		and pos.y < grid.size()
		and pos.x >= 0
		and grid.size() > 0
		and pos.x < grid[0].size()
	)
