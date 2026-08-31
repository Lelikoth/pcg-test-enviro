class_name MapValidator
extends RefCounted

## Provides common structural validation and pathfinding operations for maps.
##
## Walkability and connectivity are evaluated using four-directional movement
## without diagonal traversal.


const CARDINAL_DIRECTIONS: Array[Vector2i] = [
	Vector2i.RIGHT,
	Vector2i.LEFT,
	Vector2i.DOWN,
	Vector2i.UP
]


## Returns whether the provided position lies within the grid bounds.
func is_inside(
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


## Returns whether the provided position contains a walkable floor tile.
func is_walkable(
	grid: Array,
	position: Vector2i
) -> bool:
	if not is_inside(grid, position):
		return false

	return grid[position.y][position.x] == MapTypes.FLOOR


## Returns the length of the shortest walkable path between two positions.
##
## Breadth-first search is used with four-directional movement. A value of -1
## is returned when either endpoint is invalid or no path exists.
func find_path_length(
	grid: Array,
	start: Vector2i,
	goal: Vector2i
) -> int:
	if not is_walkable(grid, start) or not is_walkable(grid, goal):
		return -1

	var queue: Array[Dictionary] = [{
		"position": start,
		"distance": 0
	}]

	var head := 0
	var visited: Dictionary = {}

	visited[start] = true

	while head < queue.size():
		var current: Dictionary = queue[head]
		head += 1

		var position: Vector2i = current["position"]
		var distance: int = current["distance"]

		if position == goal:
			return distance

		for direction in CARDINAL_DIRECTIONS:
			var next_position := position + direction

			if visited.has(next_position):
				continue

			if not is_walkable(grid, next_position):
				continue

			visited[next_position] = true

			queue.append({
				"position": next_position,
				"distance": distance + 1
			})

	return -1


## Returns whether a walkable path exists between two positions.
func has_path(
	grid: Array,
	start: Vector2i,
	goal: Vector2i
) -> bool:
	return find_path_length(grid, start, goal) >= 0


## Returns all floor tiles reachable from the provided start position.
##
## Tiles are discovered using breadth-first search and four-directional
## movement.
func reachable_cells_from(
	grid: Array,
	start: Vector2i
) -> Array[Vector2i]:
	var reachable_cells: Array[Vector2i] = []

	if not is_walkable(grid, start):
		return reachable_cells

	var queue: Array[Vector2i] = [start]
	var head := 0
	var visited: Dictionary = {}

	visited[start] = true

	while head < queue.size():
		var current_position := queue[head]
		head += 1

		reachable_cells.append(current_position)

		for direction in CARDINAL_DIRECTIONS:
			var next_position := current_position + direction

			if visited.has(next_position):
				continue

			if not is_walkable(grid, next_position):
				continue

			visited[next_position] = true
			queue.append(next_position)

	return reachable_cells


## Finds the reachable floor tile with the greatest shortest-path distance
## from the provided start position.
##
## Returns distance -1 when the start position is not walkable.
func farthest_reachable_from(
	grid: Array,
	start: Vector2i
) -> Dictionary:
	if not is_walkable(grid, start):
		return {
			"position": start,
			"distance": -1
		}

	var queue: Array[Dictionary] = [{
		"position": start,
		"distance": 0
	}]

	var head := 0
	var visited: Dictionary = {}

	visited[start] = true

	var farthest_position := start
	var farthest_distance := 0

	while head < queue.size():
		var current: Dictionary = queue[head]
		head += 1

		var position: Vector2i = current["position"]
		var distance: int = current["distance"]

		if distance > farthest_distance:
			farthest_distance = distance
			farthest_position = position

		for direction in CARDINAL_DIRECTIONS:
			var next_position := position + direction

			if visited.has(next_position):
				continue

			if not is_walkable(grid, next_position):
				continue

			visited[next_position] = true

			queue.append({
				"position": next_position,
				"distance": distance + 1
			})

	return {
		"position": farthest_position,
		"distance": farthest_distance
	}
