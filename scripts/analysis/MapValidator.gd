extends RefCounted
class_name MapValidator


const DIRECTIONS_4: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(-1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1)
]


func is_inside(grid: Array, pos: Vector2i) -> bool:
	return (
		pos.y >= 0
		and pos.y < grid.size()
		and pos.x >= 0
		and grid.size() > 0
		and pos.x < grid[0].size()
	)


func is_walkable(grid: Array, pos: Vector2i) -> bool:
	if not is_inside(grid, pos):
		return false

	return grid[pos.y][pos.x] == MapTypes.FLOOR


func find_path_length(grid: Array, start: Vector2i, goal: Vector2i) -> int:
	if not is_walkable(grid, start) or not is_walkable(grid, goal):
		return -1

	var queue: Array[Dictionary] = [{
		"pos": start,
		"dist": 0
	}]
	var head: int = 0
	var visited := {}

	visited[_key(start)] = true

	while head < queue.size():
		var current: Dictionary = queue[head]
		head += 1

		var pos: Vector2i = current["pos"]
		var dist: int = current["dist"]

		if pos == goal:
			return dist

		for dir in DIRECTIONS_4:
			var next: Vector2i = pos + dir
			var key := _key(next)

			if visited.has(key):
				continue

			if not is_walkable(grid, next):
				continue

			visited[key] = true
			queue.append({
				"pos": next,
				"dist": dist + 1
			})

	return -1


func has_path(grid: Array, start: Vector2i, goal: Vector2i) -> bool:
	return find_path_length(grid, start, goal) != -1


func reachable_cells_from(grid: Array, start: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []

	if not is_walkable(grid, start):
		return result

	var queue: Array[Vector2i] = [start]
	var head: int = 0
	var visited := {}

	visited[_key(start)] = true

	while head < queue.size():
		var current: Vector2i = queue[head]
		head += 1

		result.append(current)

		for dir in DIRECTIONS_4:
			var next: Vector2i = current + dir
			var key := _key(next)

			if visited.has(key):
				continue

			if not is_walkable(grid, next):
				continue

			visited[key] = true
			queue.append(next)

	return result


func farthest_reachable_from(grid: Array, start: Vector2i) -> Dictionary:
	if not is_walkable(grid, start):
		return {
			"pos": start,
			"dist": -1
		}

	var queue: Array[Dictionary] = [{
		"pos": start,
		"dist": 0
	}]
	var head: int = 0
	var visited := {}

	visited[_key(start)] = true

	var best_pos := start
	var best_dist: int = 0

	while head < queue.size():
		var current: Dictionary = queue[head]
		head += 1

		var pos: Vector2i = current["pos"]
		var dist: int = current["dist"]

		if dist > best_dist:
			best_dist = dist
			best_pos = pos

		for dir in DIRECTIONS_4:
			var next: Vector2i = pos + dir
			var key := _key(next)

			if visited.has(key):
				continue

			if not is_walkable(grid, next):
				continue

			visited[key] = true
			queue.append({
				"pos": next,
				"dist": dist + 1
			})

	return {
		"pos": best_pos,
		"dist": best_dist
	}


func _key(pos: Vector2i) -> String:
	return "%d_%d" % [pos.x, pos.y]
