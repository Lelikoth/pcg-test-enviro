extends RefCounted
class_name MapValidator

func is_inside(grid: Array, pos: Vector2i) -> bool:
	return pos.y >= 0 and pos.y < grid.size() and pos.x >= 0 and pos.x < grid[0].size()

func is_walkable(grid: Array, pos: Vector2i) -> bool:
	if not is_inside(grid, pos):
		return false
	return grid[pos.y][pos.x] == MapTypes.FLOOR

func find_path_length(grid: Array, start: Vector2i, goal: Vector2i) -> int:
	if not is_walkable(grid, start) or not is_walkable(grid, goal):
		return -1

	var queue: Array = []
	var visited := {}
	queue.append({"pos": start, "dist": 0})
	visited[_key(start)] = true

	var directions := [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1)
	]

	while queue.size() > 0:
		var current: Dictionary = queue.pop_front()
		var pos: Vector2i = current["pos"]
		var dist: int = current["dist"]

		if pos == goal:
			return dist

		for dir in directions:
			var next : Vector2i = pos + dir
			var key := _key(next)

			if not visited.has(key) and is_walkable(grid, next):
				visited[key] = true
				queue.append({
					"pos": next,
					"dist": dist + 1
				})

	return -1

func has_path(grid: Array, start: Vector2i, goal: Vector2i) -> bool:
	return find_path_length(grid, start, goal) != -1

func _key(pos: Vector2i) -> String:
	return "%d_%d" % [pos.x, pos.y]
