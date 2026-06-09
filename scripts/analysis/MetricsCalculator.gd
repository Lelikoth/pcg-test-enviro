extends RefCounted
class_name MetricsCalculator


var entropy_metrics := EntropyMetrics.new()
var region_metrics := RegionMetrics.new()
var shape_metrics := ShapeMetrics.new()


func calculate_metrics(map_data: Dictionary, generation_time_ms: float, validator: MapValidator) -> Dictionary:
	var grid: Array = map_data["grid"]

	var width: int = _get_width(grid)
	var height: int = _get_height(grid)
	var total_cells: int = width * height

	var start: Vector2i = map_data.get("start", Vector2i.ZERO)
	var end: Vector2i = map_data.get("end", Vector2i.ZERO)

	var has_valid_start: bool = validator.is_walkable(grid, start)
	var has_valid_end: bool = validator.is_walkable(grid, end)

	var floor_count: int = 0
	var wall_count: int = 0

	for row_value in grid:
		var row: Array = row_value

		for cell_value in row:
			var cell: int = int(cell_value)

			if cell == MapTypes.FLOOR:
				floor_count += 1
			else:
				wall_count += 1

	var path_data: Dictionary = _calculate_path_metrics(grid, start, end, validator)
	var declared_room_data: Dictionary = _calculate_declared_room_metrics(map_data)
	var procgen_data: Dictionary = _calculate_procgen_metrics(map_data)
	var module_data: Dictionary = _calculate_module_metrics(map_data)

	var entropy_data: Dictionary = entropy_metrics.calculate(grid)
	var region_data: Dictionary = region_metrics.calculate(grid, start)
	var shape_data: Dictionary = shape_metrics.calculate(grid)

	var metrics := {
		"algorithm": map_data.get("algorithm", "UNKNOWN"),
		"seed": map_data.get("seed", 0),

		"map_width": width,
		"map_height": height,
		"total_cells": total_cells,

		"generation_time_ms": generation_time_ms,
		"time_per_cell_ms": _safe_divide(generation_time_ms, float(max(1, total_cells))),
		"time_per_floor_cell_ms": _safe_divide(generation_time_ms, float(max(1, floor_count))),

		"generation_success": not bool(map_data.get("failed_generation", false)),
		"retry_count": map_data.get("retry_count", 0),

		"start_x": start.x,
		"start_y": start.y,
		"end_x": end.x,
		"end_y": end.y,

		"has_valid_start": has_valid_start,
		"has_valid_end": has_valid_end,

		"floor_count": floor_count,
		"wall_count": wall_count,
		"floor_ratio": _safe_divide(float(floor_count), float(max(1, total_cells))),
		"wall_ratio": _safe_divide(float(wall_count), float(max(1, total_cells)))
	}

	for key in path_data.keys():
		metrics[key] = path_data[key]

	for key in declared_room_data.keys():
		metrics[key] = declared_room_data[key]

	for key in procgen_data.keys():
		metrics[key] = procgen_data[key]

	for key in module_data.keys():
		metrics[key] = module_data[key]

	for key in entropy_data.keys():
		metrics[key] = entropy_data[key]

	for key in region_data.keys():
		metrics[key] = region_data[key]

	for key in shape_data.keys():
		metrics[key] = shape_data[key]

	metrics["floor_ratio_in_target_range"] = (
		metrics["floor_ratio"] >= 0.25
		and metrics["floor_ratio"] <= 0.65
	)

	return metrics


func _calculate_path_metrics(
	grid: Array,
	start: Vector2i,
	end: Vector2i,
	validator: MapValidator
) -> Dictionary:
	var path_length: int = validator.find_path_length(grid, start, end)
	var is_connected: bool = path_length != -1

	var start_end_euclidean_distance: float = start.distance_to(end)

	var path_tortuosity: float = 0.0
	var path_directness: float = 0.0

	if path_length > 0 and start_end_euclidean_distance > 0.0:
		path_tortuosity = float(path_length) / start_end_euclidean_distance
		path_directness = start_end_euclidean_distance / float(path_length)

	var farthest_data: Dictionary = validator.farthest_reachable_from(grid, start)
	var farthest_reachable: Vector2i = farthest_data.get("pos", start)
	var farthest_reachable_path_length: int = int(farthest_data.get("dist", -1))

	return {
		"is_connected": is_connected,
		"path_length": path_length,
		"start_end_euclidean_distance": start_end_euclidean_distance,
		"path_tortuosity": path_tortuosity,
		"path_directness": path_directness,

		"farthest_reachable_x": farthest_reachable.x,
		"farthest_reachable_y": farthest_reachable.y,
		"farthest_reachable_path_length": farthest_reachable_path_length
	}


func _calculate_declared_room_metrics(map_data: Dictionary) -> Dictionary:
	var generator_rooms: Array = map_data.get("rooms", [])
	var normalized_rooms: Array = _normalize_generator_rooms(generator_rooms)

	return {
		"declared_room_count": normalized_rooms.size(),
		"largest_declared_room_area": _largest_room_area(normalized_rooms)
	}


func _calculate_procgen_metrics(map_data: Dictionary) -> Dictionary:
	var algorithm_name: String = str(map_data.get("algorithm", ""))

	if algorithm_name != "ProcGenHybrid":
		return {
			"procgen_corridor_link_count": 0,
			"procgen_dead_end_room_count": 0,
			"procgen_room_connection_min_degree": 0,
			"procgen_room_connection_max_degree": 0,
			"procgen_room_connection_average_degree": 0.0,
			"procgen_cycle_link_count": 0,
			"procgen_has_cycles": false
		}

	var rooms: Array = map_data.get("rooms", [])
	var room_links: Array = map_data.get("procgen_room_links", [])

	var room_count: int = rooms.size()
	var degree_by_room_index := {}

	for i in range(room_count):
		degree_by_room_index[i] = 0

	for link_value in room_links:
		if not link_value is Dictionary:
			continue

		var link: Dictionary = link_value

		var from_index: int = int(link.get("from_room_index", -1))
		var to_index: int = int(link.get("to_room_index", -1))

		if from_index < 0 or from_index >= room_count:
			continue

		if to_index < 0 or to_index >= room_count:
			continue

		degree_by_room_index[from_index] = int(degree_by_room_index[from_index]) + 1
		degree_by_room_index[to_index] = int(degree_by_room_index[to_index]) + 1

	var dead_end_room_count: int = 0
	var min_degree: int = 999999
	var max_degree: int = 0
	var total_degree: int = 0

	for room_index in degree_by_room_index.keys():
		var degree: int = int(degree_by_room_index[room_index])

		if degree == 1:
			dead_end_room_count += 1

		if degree < min_degree:
			min_degree = degree

		if degree > max_degree:
			max_degree = degree

		total_degree += degree

	if room_count == 0:
		min_degree = 0
		max_degree = 0

	var average_degree: float = _safe_divide(float(total_degree), float(max(1, room_count)))

	# For a connected tree with N rooms, the minimal number of links is N - 1.
	# Extra links usually come from corridor_cycle_chance.
	var expected_tree_link_count: int = max(0, room_count - 1)
	var cycle_link_count: int = max(0, room_links.size() - expected_tree_link_count)

	return {
		"procgen_corridor_link_count": room_links.size(),
		"procgen_dead_end_room_count": dead_end_room_count,
		"procgen_room_connection_min_degree": min_degree,
		"procgen_room_connection_max_degree": max_degree,
		"procgen_room_connection_average_degree": average_degree,
		"procgen_cycle_link_count": cycle_link_count,
		"procgen_has_cycles": cycle_link_count > 0
	}


func _calculate_module_metrics(map_data: Dictionary) -> Dictionary:
	if not map_data.has("module_cells"):
		return {
			"room_module_count": 0,
			"corridor_module_count": 0,
			"junction_module_count": 0,
			"special_module_count": 0,
			"small_room_count": 0,
			"medium_room_count": 0,
			"large_room_count": 0,
			"dead_end_module_count": 0,
			"dead_end_room_count": 0,
			"pass_through_room_count": 0,
			"hub_room_count": 0
		}

	var module_cells: Array = map_data["module_cells"]

	var room_module_count: int = 0
	var corridor_module_count: int = 0
	var junction_module_count: int = 0
	var special_module_count: int = 0

	var small_room_count: int = 0
	var medium_room_count: int = 0
	var large_room_count: int = 0

	var dead_end_module_count: int = 0
	var dead_end_room_count: int = 0
	var pass_through_room_count: int = 0
	var hub_room_count: int = 0

	for row_value in module_cells:
		var row: Array = row_value

		for cell_value in row:
			if not cell_value is Dictionary:
				continue

			var cell: Dictionary = cell_value
			var options: Array = cell.get("options", [])

			if options.size() != 1:
				continue

			var module: Dictionary = options[0]
			var tags: Array = module.get("tags", [])
			var scale_class: String = str(module.get("scale_class", ""))
			var opening_count: int = _count_module_openings(module)

			var is_room: bool = tags.has("room")
			var is_corridor: bool = tags.has("corridor")
			var is_junction: bool = tags.has("junction")
			var is_special: bool = tags.has("special")

			var has_dead_end_tag: bool = (
				tags.has("dead_end")
				or tags.has("dead_end_room")
				or tags.has("dead_end_module")
			)

			var is_dead_end_by_openings: bool = opening_count == 1

			if has_dead_end_tag or is_dead_end_by_openings:
				dead_end_module_count += 1

			if is_room:
				room_module_count += 1

				match scale_class:
					"small":
						small_room_count += 1
					"medium":
						medium_room_count += 1
					"large":
						large_room_count += 1

				if has_dead_end_tag or is_dead_end_by_openings:
					dead_end_room_count += 1
				elif opening_count == 2:
					pass_through_room_count += 1
				elif opening_count >= 3:
					hub_room_count += 1

			if is_corridor:
				corridor_module_count += 1

			if is_junction:
				junction_module_count += 1

			if is_special:
				special_module_count += 1

	return {
		"room_module_count": room_module_count,
		"corridor_module_count": corridor_module_count,
		"junction_module_count": junction_module_count,
		"special_module_count": special_module_count,
		"small_room_count": small_room_count,
		"medium_room_count": medium_room_count,
		"large_room_count": large_room_count,
		"dead_end_module_count": dead_end_module_count,
		"dead_end_room_count": dead_end_room_count,
		"pass_through_room_count": pass_through_room_count,
		"hub_room_count": hub_room_count
	}


func _count_module_openings(module: Dictionary) -> int:
	var count: int = 0

	if bool(module.get("up", false)):
		count += 1

	if bool(module.get("right", false)):
		count += 1

	if bool(module.get("down", false)):
		count += 1

	if bool(module.get("left", false)):
		count += 1

	return count


func _normalize_generator_rooms(generator_rooms: Array) -> Array:
	var normalized: Array = []

	for room_value in generator_rooms:
		if not room_value is Dictionary:
			continue

		var room: Dictionary = room_value

		if room.has("area"):
			normalized.append(room)
		elif room.has("size"):
			var size: Vector2i = room["size"]
			var area: int = size.x * size.y

			var normalized_room: Dictionary = room.duplicate()
			normalized_room["area"] = area
			normalized.append(normalized_room)

	return normalized


func _largest_room_area(rooms: Array) -> int:
	var best: int = 0

	for room_value in rooms:
		if not room_value is Dictionary:
			continue

		var room: Dictionary = room_value

		if not room.has("area"):
			continue

		var area: int = int(room["area"])

		if area > best:
			best = area

	return best


func _get_width(grid: Array) -> int:
	if grid.is_empty():
		return 0

	return grid[0].size()


func _get_height(grid: Array) -> int:
	return grid.size()


func _safe_divide(a: float, b: float) -> float:
	if b == 0.0:
		return 0.0

	return a / b
