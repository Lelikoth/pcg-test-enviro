extends RefCounted
class_name GraphMetrics


const DIRECTIONS_4: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(-1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1)
]


func calculate(grid: Array, start: Vector2i, end: Vector2i, validator: MapValidator) -> Dictionary:
	var floor_count: int = _count_floor_cells(grid)
	var node_count: int = floor_count
	var edge_count: int = _count_edges(grid)

	var dead_end_count: int = 0
	var junction_count: int = 0
	var total_degree: int = 0

	var degree_0_count: int = 0
	var degree_1_count: int = 0
	var degree_2_count: int = 0
	var degree_3_count: int = 0
	var degree_4_count: int = 0

	for y in range(grid.size()):
		for x in range(grid[y].size()):
			if grid[y][x] != MapTypes.FLOOR:
				continue

			var pos := Vector2i(x, y)
			var degree: int = _floor_degree(grid, pos)

			total_degree += degree

			match degree:
				0:
					degree_0_count += 1
				1:
					degree_1_count += 1
					dead_end_count += 1
				2:
					degree_2_count += 1
				3:
					degree_3_count += 1
					junction_count += 1
				4:
					degree_4_count += 1

	var connected_components_count: int = _count_connected_components(grid)

	var average_degree: float = _safe_divide(float(total_degree), float(max(1, node_count)))

	var path_length: int = validator.find_path_length(grid, start, end)

	var path_tortuosity: float = 0.0
	var path_directness: float = 0.0
	var start_end_euclidean_distance: float = start.distance_to(end)

	if path_length > 0 and start_end_euclidean_distance > 0.0:
		path_tortuosity = float(path_length) / start_end_euclidean_distance
		path_directness = start_end_euclidean_distance / float(path_length)

	var cycle_count_grid: int = 0
	if node_count > 0:
		cycle_count_grid = edge_count - node_count + connected_components_count
		cycle_count_grid = max(0, cycle_count_grid)

	var farthest_data: Dictionary = validator.farthest_reachable_from(grid, start)
	var farthest_reachable: Vector2i = farthest_data.get("pos", start)
	var farthest_reachable_path_length: int = int(farthest_data.get("dist", -1))

	return {
		"graph_node_count": node_count,
		"graph_edge_count": edge_count,
		"average_degree": average_degree,

		"dead_end_count": dead_end_count,
		"dead_end_ratio": _safe_divide(float(dead_end_count), float(max(1, floor_count))),

		"junction_count": junction_count,
		"junction_ratio": _safe_divide(float(junction_count), float(max(1, floor_count))),

		"cycle_count_grid": cycle_count_grid,
		"cycle_density_grid": _safe_divide(float(cycle_count_grid), float(max(1, floor_count))),

		"degree_0_count": degree_0_count,
		"degree_1_count": degree_1_count,
		"degree_2_count": degree_2_count,
		"degree_3_count": degree_3_count,
		"degree_4_count": degree_4_count,

		"degree_0_ratio": _safe_divide(float(degree_0_count), float(max(1, floor_count))),
		"degree_1_ratio": _safe_divide(float(degree_1_count), float(max(1, floor_count))),
		"degree_2_ratio": _safe_divide(float(degree_2_count), float(max(1, floor_count))),
		"degree_3_ratio": _safe_divide(float(degree_3_count), float(max(1, floor_count))),
		"degree_4_ratio": _safe_divide(float(degree_4_count), float(max(1, floor_count))),

		"path_length": path_length,
		"start_end_euclidean_distance": start_end_euclidean_distance,
		"path_tortuosity": path_tortuosity,
		"path_directness": path_directness,

		"farthest_reachable_x": farthest_reachable.x,
		"farthest_reachable_y": farthest_reachable.y,
		"farthest_reachable_path_length": farthest_reachable_path_length
	}


func _count_floor_cells(grid: Array) -> int:
	var count: int = 0

	for y in range(grid.size()):
		for x in range(grid[y].size()):
			if grid[y][x] == MapTypes.FLOOR:
				count += 1

	return count


func _count_edges(grid: Array) -> int:
	var edges: int = 0

	for y in range(grid.size()):
		for x in range(grid[y].size()):
			if grid[y][x] != MapTypes.FLOOR:
				continue

			if x + 1 < grid[y].size() and grid[y][x + 1] == MapTypes.FLOOR:
				edges += 1

			if y + 1 < grid.size() and grid[y + 1][x] == MapTypes.FLOOR:
				edges += 1

	return edges


func _count_connected_components(grid: Array) -> int:
	var visited := {}
	var components: int = 0

	for y in range(grid.size()):
		for x in range(grid[y].size()):
			var pos := Vector2i(x, y)
			var key := _pos_key(pos)

			if visited.has(key):
				continue

			if grid[y][x] != MapTypes.FLOOR:
				continue

			_flood_fill_component(grid, pos, visited)
			components += 1

	return components


func _flood_fill_component(grid: Array, start: Vector2i, visited: Dictionary) -> int:
	var queue: Array[Vector2i] = [start]
	var head: int = 0
	var size: int = 0

	visited[_pos_key(start)] = true

	while head < queue.size():
		var current: Vector2i = queue[head]
		head += 1
		size += 1

		for dir in DIRECTIONS_4:
			var next := current + dir
			var key := _pos_key(next)

			if visited.has(key):
				continue

			if not _is_inside(grid, next):
				continue

			if grid[next.y][next.x] != MapTypes.FLOOR:
				continue

			visited[key] = true
			queue.append(next)

	return size


func _floor_degree(grid: Array, pos: Vector2i) -> int:
	var degree: int = 0

	for dir in DIRECTIONS_4:
		var next := pos + dir

		if _is_inside(grid, next) and grid[next.y][next.x] == MapTypes.FLOOR:
			degree += 1

	return degree


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
