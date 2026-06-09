extends RefCounted
class_name TransitionGraphBuilder


const DIRECTIONS_4: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(-1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1)
]


func build(map_data: Dictionary) -> Dictionary:
	var grid: Array = map_data.get("grid", [])

	if grid.is_empty() or grid[0].is_empty():
		return {
			"nodes": [],
			"edges": [],
			"node_lookup": {}
		}

	var nodes: Array = []
	var edges: Array = []
	var node_lookup := {}

	# 1. Semantic nodes from known generator data.
	_add_declared_room_nodes(map_data, grid, nodes, node_lookup)
	_add_module_nodes(map_data, grid, nodes, node_lookup)

	# 2. Geometry fallback for algorithms without declared rooms.
	_add_open_area_nodes_from_geometry(grid, nodes, node_lookup)

	# 3. Corridor-level significant nodes: junctions and corridor terminals.
	_add_corridor_significant_nodes(grid, nodes, node_lookup)

	# 4. Trace corridor edges between nodes.
	_trace_edges(grid, nodes, node_lookup, edges)

	_update_node_degrees(nodes, edges)

	return {
		"nodes": nodes,
		"edges": edges,
		"node_lookup": node_lookup
	}


func _add_declared_room_nodes(
	map_data: Dictionary,
	grid: Array,
	nodes: Array,
	node_lookup: Dictionary
) -> void:
	var rooms: Array = map_data.get("rooms", [])

	for room_value in rooms:
		if not room_value is Dictionary:
			continue

		var room: Dictionary = room_value

		if not room.has("position") or not room.has("size"):
			continue

		var pos: Vector2i = room["position"]
		var size: Vector2i = room["size"]

		var cells: Array[Vector2i] = []

		for y in range(pos.y, pos.y + size.y):
			for x in range(pos.x, pos.x + size.x):
				var cell := Vector2i(x, y)

				if not _is_floor(grid, cell):
					continue

				cells.append(cell)

		if cells.is_empty():
			continue

		_add_node(nodes, node_lookup, "room", cells, {
			"source": "declared_room"
		})


func _add_module_nodes(
	map_data: Dictionary,
	grid: Array,
	nodes: Array,
	node_lookup: Dictionary
) -> void:
	if not map_data.has("module_cells"):
		return

	var module_cells: Array = map_data["module_cells"]

	if module_cells.is_empty() or module_cells[0].is_empty():
		return

	var module_rows: int = module_cells.size()
	var module_cols: int = module_cells[0].size()

	if module_rows <= 0 or module_cols <= 0:
		return

	var grid_width: int = grid[0].size()
	var grid_height: int = grid.size()

	var module_size_x: int = int(grid_width / module_cols)
	var module_size_y: int = int(grid_height / module_rows)
	var module_size: int = min(module_size_x, module_size_y)

	if module_size <= 0:
		return

	for module_y in range(module_rows):
		for module_x in range(module_cols):
			var cell: Dictionary = module_cells[module_y][module_x]
			var options: Array = cell.get("options", [])

			if options.size() != 1:
				continue

			var module: Dictionary = options[0]
			var tags: Array = module.get("tags", [])

			var node_type := ""

			if tags.has("room"):
				node_type = "room"
			elif tags.has("junction"):
				node_type = "junction"
			elif tags.has("special"):
				node_type = "special"

			if node_type == "":
				continue

			var cells: Array[Vector2i] = []

			var start_x: int = module_x * module_size
			var start_y: int = module_y * module_size

			for local_y in range(module_size):
				for local_x in range(module_size):
					var world_pos := Vector2i(start_x + local_x, start_y + local_y)

					if _is_floor(grid, world_pos):
						cells.append(world_pos)

			if cells.is_empty():
				continue

			_add_node(nodes, node_lookup, node_type, cells, {
				"source": "module",
				"module_id": str(module.get("id", "")),
				"module_tags": tags,
				"scale_class": str(module.get("scale_class", ""))
			})


func _add_open_area_nodes_from_geometry(
	grid: Array,
	nodes: Array,
	node_lookup: Dictionary
) -> void:
	var visited := {}

	for y in range(grid.size()):
		for x in range(grid[y].size()):
			var pos := Vector2i(x, y)
			var key := _pos_key(pos)

			if visited.has(key):
				continue

			if not _is_floor(grid, pos):
				continue

			if node_lookup.has(key):
				continue

			if not _is_open_area_seed(grid, pos):
				continue

			var cells: Array[Vector2i] = _flood_fill_open_area(grid, pos, visited, node_lookup)

			if cells.is_empty():
				continue

			var data: Dictionary = _analyze_cells(cells)

			var area: int = int(data.get("area", 0))
			var size: Vector2i = data.get("size", Vector2i.ZERO)
			var fill_ratio: float = float(data.get("bbox_fill_ratio", 0.0))

			# Avoid treating tiny bumps and corridor corners as rooms/open areas.
			if area < 9:
				continue

			if size.x < 3 or size.y < 3:
				continue

			if fill_ratio < 0.45:
				continue

			_add_node(nodes, node_lookup, "open_area", cells, {
				"source": "geometry"
			})


func _flood_fill_open_area(
	grid: Array,
	start: Vector2i,
	visited: Dictionary,
	node_lookup: Dictionary
) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var queue: Array[Vector2i] = [start]
	var head: int = 0

	visited[_pos_key(start)] = true

	while head < queue.size():
		var current: Vector2i = queue[head]
		head += 1

		if not _is_floor(grid, current):
			continue

		if node_lookup.has(_pos_key(current)):
			continue

		if not _is_open_area_candidate(grid, current):
			continue

		cells.append(current)

		for dir in DIRECTIONS_4:
			var next := current + dir
			var key := _pos_key(next)

			if visited.has(key):
				continue

			if not _is_floor(grid, next):
				continue

			if node_lookup.has(key):
				continue

			if not _is_open_area_candidate(grid, next):
				continue

			visited[key] = true
			queue.append(next)

	return cells


func _is_open_area_seed(grid: Array, pos: Vector2i) -> bool:
	if not _is_floor(grid, pos):
		return false

	if _is_narrow_corridor_tile(grid, pos):
		return false

	var local_floor_count: int = _count_floor_in_3x3(grid, pos)
	var degree: int = _floor_degree(grid, pos)

	return local_floor_count >= 6 or degree >= 3


func _is_open_area_candidate(grid: Array, pos: Vector2i) -> bool:
	if not _is_floor(grid, pos):
		return false

	if _is_narrow_corridor_tile(grid, pos):
		return false

	var local_floor_count: int = _count_floor_in_3x3(grid, pos)
	var degree: int = _floor_degree(grid, pos)

	return local_floor_count >= 5 or degree >= 3


func _add_corridor_significant_nodes(
	grid: Array,
	nodes: Array,
	node_lookup: Dictionary
) -> void:
	var candidate_keys := {}

	for y in range(grid.size()):
		for x in range(grid[y].size()):
			var pos := Vector2i(x, y)
			var key := _pos_key(pos)

			if not _is_floor(grid, pos):
				continue

			if node_lookup.has(key):
				continue

			if not _is_corridor_space(grid, pos):
				continue

			var exits: int = _floor_degree(grid, pos)

			if exits <= 1:
				candidate_keys[key] = "corridor_terminal"
			elif exits >= 3:
				candidate_keys[key] = "junction"

	var visited := {}

	for key in candidate_keys.keys():
		if visited.has(key):
			continue

		var start: Vector2i = _key_to_pos(str(key))
		var cluster: Array[Vector2i] = _flood_fill_candidate_cluster(
			grid,
			start,
			candidate_keys,
			visited,
			node_lookup
		)

		if cluster.is_empty():
			continue

		var type_counts := {
			"corridor_terminal": 0,
			"junction": 0
		}

		for cell in cluster:
			var cell_type: String = str(candidate_keys.get(_pos_key(cell), ""))
			if type_counts.has(cell_type):
				type_counts[cell_type] += 1

		var node_type := "junction"
		if int(type_counts["corridor_terminal"]) > int(type_counts["junction"]):
			node_type = "corridor_terminal"

		_add_node(nodes, node_lookup, node_type, cluster, {
			"source": "corridor_geometry"
		})


func _flood_fill_candidate_cluster(
	grid: Array,
	start: Vector2i,
	candidate_keys: Dictionary,
	visited: Dictionary,
	node_lookup: Dictionary
) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var queue: Array[Vector2i] = [start]
	var head: int = 0

	visited[_pos_key(start)] = true

	while head < queue.size():
		var current: Vector2i = queue[head]
		head += 1

		var current_key := _pos_key(current)

		if not candidate_keys.has(current_key):
			continue

		if node_lookup.has(current_key):
			continue

		result.append(current)

		for dir in DIRECTIONS_4:
			var next := current + dir
			var key := _pos_key(next)

			if visited.has(key):
				continue

			if not candidate_keys.has(key):
				continue

			if node_lookup.has(key):
				continue

			visited[key] = true
			queue.append(next)

	return result


func _trace_edges(
	grid: Array,
	nodes: Array,
	node_lookup: Dictionary,
	edges: Array
) -> void:
	var edge_keys := {}
	var visited_corridor_cells := {}

	for node in nodes:
		var node_id: int = int(node.get("id", -1))
		var cells: Array = node.get("cells", [])

		for cell_value in cells:
			var cell: Vector2i = cell_value

			for dir in DIRECTIONS_4:
				var next := cell + dir

				if not _is_floor(grid, next):
					continue

				var next_key := _pos_key(next)

				if node_lookup.has(next_key):
					var other_node_id: int = int(node_lookup[next_key])

					if other_node_id == node_id:
						continue

					var direct_key := _edge_key(node_id, other_node_id)

					if edge_keys.has(direct_key):
						continue

					edge_keys[direct_key] = true

					edges.append({
						"from": node_id,
						"to": other_node_id,
						"length": 1,
						"cells": [],
						"type": "direct_connection"
					})

					continue

				if visited_corridor_cells.has(next_key):
					continue

				var traced: Dictionary = _trace_corridor_from(
					grid,
					node_lookup,
					node_id,
					cell,
					next
				)

				if traced.is_empty():
					continue

				var to_id: int = int(traced.get("to", -1))

				if to_id < 0:
					continue

				var traced_key := _edge_key_with_path(node_id, to_id, traced.get("cells", []))

				if edge_keys.has(traced_key):
					continue

				edge_keys[traced_key] = true
				edges.append(traced)

				var corridor_cells: Array = traced.get("cells", [])
				for corridor_cell_value in corridor_cells:
					var corridor_cell: Vector2i = corridor_cell_value
					visited_corridor_cells[_pos_key(corridor_cell)] = true


func _trace_corridor_from(
	grid: Array,
	node_lookup: Dictionary,
	start_node_id: int,
	from_node_cell: Vector2i,
	first_cell: Vector2i
) -> Dictionary:
	var previous: Vector2i = from_node_cell
	var current: Vector2i = first_cell
	var corridor_cells: Array[Vector2i] = []
	var length: int = 1

	var safety_limit: int = grid.size() * grid[0].size()
	var safety_counter: int = 0

	while safety_counter < safety_limit:
		safety_counter += 1

		if not _is_floor(grid, current):
			return {}

		var current_key := _pos_key(current)

		if node_lookup.has(current_key):
			var end_node_id: int = int(node_lookup[current_key])

			if end_node_id == start_node_id:
				return {}

			return {
				"from": start_node_id,
				"to": end_node_id,
				"length": length,
				"cells": corridor_cells,
				"type": "corridor"
			}

		corridor_cells.append(current)

		var neighbors: Array[Vector2i] = _floor_neighbors(grid, current)
		var next_candidates: Array[Vector2i] = []

		for neighbor in neighbors:
			if neighbor != previous:
				next_candidates.append(neighbor)

		if next_candidates.is_empty():
			return {}

		if next_candidates.size() > 1:
			# This should normally become a junction node.
			# If it was not caught, stop to avoid inventing fake paths.
			return {}

		previous = current
		current = next_candidates[0]
		length += 1

	return {}


func _add_node(
	nodes: Array,
	node_lookup: Dictionary,
	node_type: String,
	cells: Array[Vector2i],
	extra_data: Dictionary = {}
) -> void:
	var filtered_cells: Array[Vector2i] = []

	for cell in cells:
		var key := _pos_key(cell)

		if node_lookup.has(key):
			continue

		filtered_cells.append(cell)

	if filtered_cells.is_empty():
		return

	var node_id: int = nodes.size()
	var data: Dictionary = _analyze_cells(filtered_cells)

	var node := {
		"id": node_id,
		"type": node_type,
		"cells": filtered_cells,
		"position": data.get("position", Vector2i.ZERO),
		"size": data.get("size", Vector2i.ZERO),
		"area": data.get("area", 0),
		"bbox_area": data.get("bbox_area", 0),
		"bbox_fill_ratio": data.get("bbox_fill_ratio", 0.0),
		"degree": 0
	}

	for key in extra_data.keys():
		node[key] = extra_data[key]

	nodes.append(node)

	for cell in filtered_cells:
		node_lookup[_pos_key(cell)] = node_id


func _update_node_degrees(nodes: Array, edges: Array) -> void:
	for node in nodes:
		node["degree"] = 0

	for edge in edges:
		var from_id: int = int(edge.get("from", -1))
		var to_id: int = int(edge.get("to", -1))

		if from_id >= 0 and from_id < nodes.size():
			nodes[from_id]["degree"] = int(nodes[from_id]["degree"]) + 1

		if to_id >= 0 and to_id < nodes.size():
			nodes[to_id]["degree"] = int(nodes[to_id]["degree"]) + 1


func _analyze_cells(cells: Array[Vector2i]) -> Dictionary:
	if cells.is_empty():
		return {
			"position": Vector2i.ZERO,
			"size": Vector2i.ZERO,
			"area": 0,
			"bbox_area": 0,
			"bbox_fill_ratio": 0.0
		}

	var first: Vector2i = cells[0]

	var min_x: int = first.x
	var max_x: int = first.x
	var min_y: int = first.y
	var max_y: int = first.y

	for cell in cells:
		min_x = min(min_x, cell.x)
		max_x = max(max_x, cell.x)
		min_y = min(min_y, cell.y)
		max_y = max(max_y, cell.y)

	var size := Vector2i(max_x - min_x + 1, max_y - min_y + 1)
	var bbox_area: int = size.x * size.y
	var area: int = cells.size()

	return {
		"position": Vector2i(min_x, min_y),
		"size": size,
		"area": area,
		"bbox_area": bbox_area,
		"bbox_fill_ratio": _safe_divide(float(area), float(max(1, bbox_area)))
	}


func _is_corridor_space(grid: Array, pos: Vector2i) -> bool:
	if not _is_floor(grid, pos):
		return false

	if _is_narrow_corridor_tile(grid, pos):
		return true

	var local_floor_count: int = _count_floor_in_3x3(grid, pos)

	# Corridor corners and thin endings can fail the strict opposite-wall test.
	return local_floor_count <= 4


func _is_narrow_corridor_tile(grid: Array, pos: Vector2i) -> bool:
	if not _is_floor(grid, pos):
		return false

	var horizontal_corridor: bool = (
		_is_wall_or_outside(grid, pos + Vector2i(0, -1))
		and _is_wall_or_outside(grid, pos + Vector2i(0, 1))
	)

	var vertical_corridor: bool = (
		_is_wall_or_outside(grid, pos + Vector2i(-1, 0))
		and _is_wall_or_outside(grid, pos + Vector2i(1, 0))
	)

	return horizontal_corridor or vertical_corridor


func _count_floor_in_3x3(grid: Array, center: Vector2i) -> int:
	var count: int = 0

	for y in range(center.y - 1, center.y + 2):
		for x in range(center.x - 1, center.x + 2):
			var pos := Vector2i(x, y)

			if _is_floor(grid, pos):
				count += 1

	return count


func _floor_degree(grid: Array, pos: Vector2i) -> int:
	var degree: int = 0

	for dir in DIRECTIONS_4:
		if _is_floor(grid, pos + dir):
			degree += 1

	return degree


func _floor_neighbors(grid: Array, pos: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []

	for dir in DIRECTIONS_4:
		var next := pos + dir

		if _is_floor(grid, next):
			result.append(next)

	return result


func _is_floor(grid: Array, pos: Vector2i) -> bool:
	if not _is_inside(grid, pos):
		return false

	return grid[pos.y][pos.x] == MapTypes.FLOOR


func _is_wall_or_outside(grid: Array, pos: Vector2i) -> bool:
	if not _is_inside(grid, pos):
		return true

	return grid[pos.y][pos.x] != MapTypes.FLOOR


func _is_inside(grid: Array, pos: Vector2i) -> bool:
	return (
		pos.y >= 0
		and pos.y < grid.size()
		and pos.x >= 0
		and grid.size() > 0
		and pos.x < grid[0].size()
	)


func _edge_key(a: int, b: int) -> String:
	var min_id: int = min(a, b)
	var max_id: int = max(a, b)

	return "%d_%d" % [min_id, max_id]


func _edge_key_with_path(a: int, b: int, cells: Array) -> String:
	var base := _edge_key(a, b)

	if cells.is_empty():
		return base

	var first: Vector2i = cells[0]
	var last: Vector2i = cells[cells.size() - 1]

	return "%s_%s_%s" % [
		base,
		_pos_key(first),
		_pos_key(last)
	]


func _pos_key(pos: Vector2i) -> String:
	return "%d_%d" % [pos.x, pos.y]


func _key_to_pos(key: String) -> Vector2i:
	var parts: PackedStringArray = key.split("_")

	if parts.size() != 2:
		return Vector2i.ZERO

	return Vector2i(int(parts[0]), int(parts[1]))


func _safe_divide(a: float, b: float) -> float:
	if b == 0.0:
		return 0.0

	return a / b
