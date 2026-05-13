extends RefCounted
class_name RegionMetrics


const DIRECTIONS_4: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(-1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1)
]


func calculate(grid: Array, start: Vector2i) -> Dictionary:
	var components: Array = _find_floor_components(grid)
	var floor_count: int = _count_floor_cells(grid)

	var largest_component_size: int = 0
	var total_component_area: int = 0

	for component in components:
		var comp: Dictionary = component
		var size: int = int(comp["area"])

		total_component_area += size

		if size > largest_component_size:
			largest_component_size = size

	var average_component_area: float = 0.0
	if not components.is_empty():
		average_component_area = float(total_component_area) / float(components.size())

	var reachable_count: int = _reachable_floor_count(grid, start)
	var unreachable_count: int = max(0, floor_count - reachable_count)

	return {
		"open_region_count": components.size(),
		"largest_open_region_area": largest_component_size,
		"largest_open_region_ratio": _safe_divide(float(largest_component_size), float(max(1, floor_count))),
		"average_open_region_area": average_component_area,

		"reachable_floor_count_from_start": reachable_count,
		"reachable_floor_ratio_from_start": _safe_divide(float(reachable_count), float(max(1, floor_count))),
		"unreachable_floor_count": unreachable_count,
		"unreachable_floor_ratio": _safe_divide(float(unreachable_count), float(max(1, floor_count)))
	}


func _find_floor_components(grid: Array) -> Array:
	var components: Array = []
	var visited := {}

	for y in range(grid.size()):
		for x in range(grid[y].size()):
			var pos := Vector2i(x, y)
			var key := _pos_key(pos)

			if visited.has(key):
				continue

			if grid[y][x] != MapTypes.FLOOR:
				continue

			var component_cells: Array[Vector2i] = _flood_fill_component(grid, pos, visited)
			var component_data: Dictionary = _analyze_component(component_cells)

			components.append(component_data)

	return components


func _flood_fill_component(grid: Array, start: Vector2i, visited: Dictionary) -> Array[Vector2i]:
	var component: Array[Vector2i] = []
	var queue: Array[Vector2i] = [start]
	var head: int = 0

	visited[_pos_key(start)] = true

	while head < queue.size():
		var current: Vector2i = queue[head]
		head += 1

		component.append(current)

		for dir in DIRECTIONS_4:
			var next: Vector2i = current + dir
			var key := _pos_key(next)

			if visited.has(key):
				continue

			if not _is_inside(grid, next):
				continue

			if grid[next.y][next.x] != MapTypes.FLOOR:
				continue

			visited[key] = true
			queue.append(next)

	return component


func _analyze_component(component: Array[Vector2i]) -> Dictionary:
	if component.is_empty():
		return {
			"area": 0,
			"position": Vector2i.ZERO,
			"size": Vector2i.ZERO,
			"bbox_area": 0,
			"bbox_fill_ratio": 0.0
		}

	var first: Vector2i = component[0]
	var min_x: int = first.x
	var max_x: int = first.x
	var min_y: int = first.y
	var max_y: int = first.y

	for cell in component:
		min_x = min(min_x, cell.x)
		max_x = max(max_x, cell.x)
		min_y = min(min_y, cell.y)
		max_y = max(max_y, cell.y)

	var width: int = max_x - min_x + 1
	var height: int = max_y - min_y + 1
	var bbox_area: int = width * height
	var area: int = component.size()

	return {
		"area": area,
		"position": Vector2i(min_x, min_y),
		"size": Vector2i(width, height),
		"bbox_area": bbox_area,
		"bbox_fill_ratio": _safe_divide(float(area), float(max(1, bbox_area)))
	}


func _reachable_floor_count(grid: Array, start: Vector2i) -> int:
	if not _is_inside(grid, start):
		return 0

	if grid[start.y][start.x] != MapTypes.FLOOR:
		return 0

	var visited := {}
	var queue: Array[Vector2i] = [start]
	var head: int = 0

	visited[_pos_key(start)] = true

	while head < queue.size():
		var current: Vector2i = queue[head]
		head += 1

		for dir in DIRECTIONS_4:
			var next: Vector2i = current + dir
			var key := _pos_key(next)

			if visited.has(key):
				continue

			if not _is_inside(grid, next):
				continue

			if grid[next.y][next.x] != MapTypes.FLOOR:
				continue

			visited[key] = true
			queue.append(next)

	return visited.size()


func _count_floor_cells(grid: Array) -> int:
	var count: int = 0

	for y in range(grid.size()):
		for x in range(grid[y].size()):
			if grid[y][x] == MapTypes.FLOOR:
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


func _pos_key(pos: Vector2i) -> String:
	return "%d_%d" % [pos.x, pos.y]


func _safe_divide(a: float, b: float) -> float:
	if b == 0.0:
		return 0.0

	return a / b
