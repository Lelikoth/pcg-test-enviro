extends BaseGenerator
class_name ModuleWFCGenerator

const MODULE_LIBRARY_SCRIPT := preload("res://scripts/generators/ModuleLibrary.gd")

var module_library := ModuleLibrary.new()

func get_algorithm_name() -> String:
	return "ModuleWFC"

func generate_map(config: Dictionary) -> Dictionary:
	var module_grid_width: int = config.get("wfc_module_grid_width", 8)
	var module_grid_height: int = config.get("wfc_module_grid_height", 8)
	var max_retries: int = config.get("wfc_max_retries", 20)

	var min_small_corridors: int = config.get("wfc_min_small_corridors", 4)
	var min_medium_rooms: int = config.get("wfc_min_medium_rooms", 2)
	var min_large_rooms: int = config.get("wfc_min_large_rooms", 1)

	var keep_only_reachable_area_from_start: bool = config.get("keep_only_reachable_area_from_start", false)
	var use_random_seed: bool = config.get("random_seed", true)
	var seed_value: int = config.get("seed", 0)

	var module_size: int = module_library.get_module_size()

	print("ModuleWFC config: grid=", module_grid_width, "x", module_grid_height, ", retries=", max_retries)
	print("ModuleWFC loaded modules count: ", module_library.get_modules().size())
	print("ModuleWFC module size: ", module_size)

	if module_library.get_modules().is_empty():
		push_error("ModuleWFC: Module library is empty.")
		return _fallback_empty_map(module_grid_width * max(1, module_size), module_grid_height * max(1, module_size), seed_value)

	if module_size <= 0:
		push_error("ModuleWFC: Invalid module size.")
		return _fallback_empty_map(module_grid_width * 5, module_grid_height * 5, seed_value)

	var rng := RandomNumberGenerator.new()
	if use_random_seed:
		rng.randomize()
		seed_value = rng.randi()
	rng.seed = seed_value

	var solved_cells: Array = []
	var success: bool = false
	var retries_used: int = 0

	for attempt in range(max_retries):
		retries_used = attempt
		success = false

		print("ModuleWFC attempt ", attempt + 1, " / ", max_retries)

		var cells: Array = _create_initial_cells(module_grid_width, module_grid_height)

		if not _apply_boundary_constraints(cells, module_grid_width, module_grid_height):
			print("ModuleWFC boundary constraints failed on attempt ", attempt + 1)
			continue

		success = _collapse_cells(cells, module_grid_width, module_grid_height, rng)
		print("ModuleWFC collapse success: ", success)

		if success:
			var preview_grid: Array = _build_final_grid(cells, module_grid_width, module_grid_height, module_size)

			var preview_start: Vector2i = _find_nearest_floor(preview_grid, Vector2i(1, 1))
			var preview_end: Vector2i = _find_farthest_floor(preview_grid, preview_start)

			var valid_layout: bool = _is_valid_generated_map(preview_grid, preview_start, preview_end)
			var valid_composition: bool = _has_valid_module_composition(
				cells,
				module_grid_width,
				module_grid_height,
				min_small_corridors,
				min_medium_rooms,
				min_large_rooms
			)

			print("ModuleWFC map validation success: ", valid_layout)
			print("ModuleWFC composition validation success: ", valid_composition)

			if valid_layout and valid_composition:
				solved_cells = cells
				break
			else:
				success = false

	if not success:
		push_warning("ModuleWFC failed after %d retries. Returning fallback map." % max_retries)
		print("ModuleWFC FAILED: returning fallback empty map")
		var fallback := _fallback_empty_map(module_grid_width * module_size, module_grid_height * module_size, seed_value)
		fallback["retry_count"] = retries_used + 1
		return fallback

	var grid: Array = _build_final_grid(solved_cells, module_grid_width, module_grid_height, module_size)
	print("ModuleWFC floor count after build: ", _count_floor_cells(grid))
	print("ModuleWFC accepted composition counts: ", _count_module_categories(solved_cells, module_grid_width, module_grid_height))

	var start: Vector2i = _find_nearest_floor(grid, Vector2i(1, 1))
	var end: Vector2i = _find_farthest_floor(grid, start)

	if keep_only_reachable_area_from_start:
		_keep_only_reachable_from_start(grid, start)
		end = _find_farthest_floor(grid, start)

	return {
		"grid": grid,
		"start": start,
		"end": end,
		"rooms": [],
		"algorithm": get_algorithm_name(),
		"seed": seed_value,
		"retry_count": retries_used + 1,
		"module_cells": solved_cells
	}

func _create_initial_cells(module_grid_width: int, module_grid_height: int) -> Array:
	var all_modules: Array = module_library.get_modules()
	var cells: Array = []

	for y in range(module_grid_height):
		var row: Array = []
		for x in range(module_grid_width):
			row.append({
				"collapsed": false,
				"options": all_modules.duplicate(true)
			})
		cells.append(row)

	return cells

func _apply_boundary_constraints(cells: Array, module_grid_width: int, module_grid_height: int) -> bool:
	for y in range(module_grid_height):
		for x in range(module_grid_width):
			var filtered_options: Array = []
			var current_options: Array = cells[y][x]["options"]

			for option in current_options:
				var module: Dictionary = option

				if y == 0 and bool(module["up"]):
					continue
				if y == module_grid_height - 1 and bool(module["down"]):
					continue
				if x == 0 and bool(module["left"]):
					continue
				if x == module_grid_width - 1 and bool(module["right"]):
					continue

				filtered_options.append(module)

			if filtered_options.is_empty():
				print("ModuleWFC boundary constraint removed all options at cell ", Vector2i(x, y))
				return false

			cells[y][x]["options"] = filtered_options

			if filtered_options.size() == 1:
				cells[y][x]["collapsed"] = true

	return true

func _collapse_cells(cells: Array, module_grid_width: int, module_grid_height: int, rng: RandomNumberGenerator) -> bool:
	if not _propagate_all(cells, module_grid_width, module_grid_height):
		return false

	while true:
		var next_pos: Vector2i = _find_lowest_entropy_cell(cells, module_grid_width, module_grid_height)
		if next_pos == Vector2i(-1, -1):
			return true

		var cell: Dictionary = cells[next_pos.y][next_pos.x]
		var options: Array = cell["options"]

		if options.is_empty():
			return false

		var chosen_module: Dictionary = _choose_weighted_module(options, rng)

		cells[next_pos.y][next_pos.x]["options"] = [chosen_module]
		cells[next_pos.y][next_pos.x]["collapsed"] = true

		if not _propagate_from(cells, module_grid_width, module_grid_height, next_pos):
			return false

	return true

func _find_lowest_entropy_cell(cells: Array, module_grid_width: int, module_grid_height: int) -> Vector2i:
	var best_pos: Vector2i = Vector2i(-1, -1)
	var best_entropy: float = INF

	for y in range(module_grid_height):
		for x in range(module_grid_width):
			var cell: Dictionary = cells[y][x]
			var options: Array = cell["options"]
			var option_count: int = options.size()

			if option_count <= 1:
				continue

			if option_count < best_entropy:
				best_entropy = option_count
				best_pos = Vector2i(x, y)

	return best_pos

func _choose_weighted_module(options: Array, rng: RandomNumberGenerator) -> Dictionary:
	var total_weight: float = 0.0

	for option in options:
		var module: Dictionary = option
		total_weight += float(module.get("weight", 1.0))

	var roll: float = rng.randf() * total_weight
	var current: float = 0.0

	for option in options:
		var module: Dictionary = option
		current += float(module.get("weight", 1.0))
		if roll <= current:
			return module

	return options[options.size() - 1]

func _propagate_all(cells: Array, module_grid_width: int, module_grid_height: int) -> bool:
	var queue: Array = []

	for y in range(module_grid_height):
		for x in range(module_grid_width):
			queue.append(Vector2i(x, y))

	return _process_propagation_queue(cells, module_grid_width, module_grid_height, queue)

func _propagate_from(cells: Array, module_grid_width: int, module_grid_height: int, start_pos: Vector2i) -> bool:
	var queue: Array = [start_pos]
	return _process_propagation_queue(cells, module_grid_width, module_grid_height, queue)

func _process_propagation_queue(cells: Array, module_grid_width: int, module_grid_height: int, queue: Array) -> bool:
	var directions := {
		"up": Vector2i(0, -1),
		"right": Vector2i(1, 0),
		"down": Vector2i(0, 1),
		"left": Vector2i(-1, 0)
	}

	while queue.size() > 0:
		var current: Vector2i = queue.pop_front()
		var current_cell: Dictionary = cells[current.y][current.x]
		var current_options: Array = current_cell["options"]

		for direction in directions.keys():
			var dir_name: String = direction
			var offset: Vector2i = directions[dir_name]
			var neighbor_pos: Vector2i = current + offset

			if not _is_inside_module_grid(neighbor_pos, module_grid_width, module_grid_height):
				continue

			var neighbor_cell: Dictionary = cells[neighbor_pos.y][neighbor_pos.x]
			var neighbor_options: Array = neighbor_cell["options"]

			var filtered_neighbor_options: Array = []

			for neighbor_option in neighbor_options:
				var neighbor_module: Dictionary = neighbor_option
				var compatible: bool = false

				for current_option in current_options:
					var current_module: Dictionary = current_option
					if module_library.are_modules_compatible(current_module, neighbor_module, dir_name):
						compatible = true
						break

				if compatible:
					filtered_neighbor_options.append(neighbor_module)

			if filtered_neighbor_options.is_empty():
				return false

			if filtered_neighbor_options.size() < neighbor_options.size():
				cells[neighbor_pos.y][neighbor_pos.x]["options"] = filtered_neighbor_options

				if filtered_neighbor_options.size() == 1:
					cells[neighbor_pos.y][neighbor_pos.x]["collapsed"] = true

				queue.append(neighbor_pos)

	return true

func _build_final_grid(cells: Array, module_grid_width: int, module_grid_height: int, module_size: int) -> Array:
	var final_width: int = module_grid_width * module_size
	var final_height: int = module_grid_height * module_size
	var grid: Array = []

	for y in range(final_height):
		var row: Array = []
		for x in range(final_width):
			row.append(MapTypes.WALL)
		grid.append(row)

	for module_y in range(module_grid_height):
		for module_x in range(module_grid_width):
			var cell: Dictionary = cells[module_y][module_x]
			var options: Array = cell["options"]

			if options.is_empty():
				continue

			var module: Dictionary = options[0]
			var module_grid: Array = module["grid"]

			for local_y in range(module_size):
				for local_x in range(module_size):
					var world_x: int = module_x * module_size + local_x
					var world_y: int = module_y * module_size + local_y
					var value: int = module_grid[local_y][local_x]

					if value == 0:
						grid[world_y][world_x] = MapTypes.FLOOR
					else:
						grid[world_y][world_x] = MapTypes.WALL

	return grid

func _is_inside_module_grid(pos: Vector2i, width: int, height: int) -> bool:
	return pos.x >= 0 and pos.x < width and pos.y >= 0 and pos.y < height

func _is_valid_generated_map(grid: Array, start: Vector2i, end: Vector2i) -> bool:
	var floor_count: int = _count_floor_cells(grid)
	if floor_count < 20:
		print("ModuleWFC validation failed: too few floor cells = ", floor_count)
		return false

	var path_length: int = _find_path_length(grid, start, end)
	if path_length == -1:
		print("ModuleWFC validation failed: no path from start to end")
		return false

	var largest_component_size: int = _largest_connected_floor_component(grid)
	var largest_component_ratio: float = float(largest_component_size) / max(1.0, float(floor_count))

	if largest_component_ratio < 0.8:
		print("ModuleWFC validation failed: largest component ratio too small = ", largest_component_ratio)
		return false

	return true

func _has_valid_module_composition(
	cells: Array,
	module_grid_width: int,
	module_grid_height: int,
	min_small_corridors: int,
	min_medium_rooms: int,
	min_large_rooms: int
) -> bool:
	var counts: Dictionary = _count_module_categories(cells, module_grid_width, module_grid_height)

	var small_corridors: int = counts.get("small_corridors", 0)
	var medium_rooms: int = counts.get("medium_rooms", 0)
	var large_rooms: int = counts.get("large_rooms", 0)

	if small_corridors < min_small_corridors:
		print("ModuleWFC composition failed: small corridors = ", small_corridors, ", required = ", min_small_corridors)
		return false

	if medium_rooms < min_medium_rooms:
		print("ModuleWFC composition failed: medium rooms = ", medium_rooms, ", required = ", min_medium_rooms)
		return false

	if large_rooms < min_large_rooms:
		print("ModuleWFC composition failed: large rooms = ", large_rooms, ", required = ", min_large_rooms)
		return false

	return true

func _count_module_categories(cells: Array, module_grid_width: int, module_grid_height: int) -> Dictionary:
	var counts := {
		"small_corridors": 0,
		"medium_rooms": 0,
		"large_rooms": 0
	}

	for y in range(module_grid_height):
		for x in range(module_grid_width):
			var cell: Dictionary = cells[y][x]
			var options: Array = cell["options"]

			if options.size() != 1:
				continue

			var module: Dictionary = options[0]
			var tags: Array = module.get("tags", [])
			var scale_class: String = str(module.get("scale_class", ""))

			if tags.has("corridor") and scale_class == "small":
				counts["small_corridors"] += 1

			if tags.has("room") and scale_class == "medium":
				counts["medium_rooms"] += 1

			if tags.has("room") and scale_class == "large":
				counts["large_rooms"] += 1

	return counts

func _find_path_length(grid: Array, start: Vector2i, end: Vector2i) -> int:
	if not _is_inside_grid(grid, start) or not _is_inside_grid(grid, end):
		return -1
	if grid[start.y][start.x] != MapTypes.FLOOR or grid[end.y][end.x] != MapTypes.FLOOR:
		return -1

	var visited := {}
	var queue: Array = [{
		"pos": start,
		"dist": 0
	}]
	visited[_pos_key(start)] = true

	var directions: Array = [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1)
	]

	while queue.size() > 0:
		var current_entry: Dictionary = queue.pop_front()
		var current: Vector2i = current_entry["pos"]
		var dist: int = current_entry["dist"]

		if current == end:
			return dist

		for dir in directions:
			var d: Vector2i = dir
			var next: Vector2i = current + d
			var key: String = _pos_key(next)

			if not _is_inside_grid(grid, next):
				continue
			if visited.has(key):
				continue
			if grid[next.y][next.x] != MapTypes.FLOOR:
				continue

			visited[key] = true
			queue.append({
				"pos": next,
				"dist": dist + 1
			})

	return -1

func _largest_connected_floor_component(grid: Array) -> int:
	var visited := {}
	var best_size: int = 0

	for y in range(grid.size()):
		for x in range(grid[y].size()):
			var pos := Vector2i(x, y)
			var key := _pos_key(pos)

			if visited.has(key):
				continue
			if grid[y][x] != MapTypes.FLOOR:
				continue

			var component_size: int = _flood_fill_floor_component(grid, pos, visited)
			if component_size > best_size:
				best_size = component_size

	return best_size

func _flood_fill_floor_component(grid: Array, start: Vector2i, visited: Dictionary) -> int:
	var queue: Array = [start]
	visited[_pos_key(start)] = true
	var size: int = 0

	var directions: Array = [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1)
	]

	while queue.size() > 0:
		var current: Vector2i = queue.pop_front()
		size += 1

		for dir in directions:
			var d: Vector2i = dir
			var next: Vector2i = current + d
			var key: String = _pos_key(next)

			if not _is_inside_grid(grid, next):
				continue
			if visited.has(key):
				continue
			if grid[next.y][next.x] != MapTypes.FLOOR:
				continue

			visited[key] = true
			queue.append(next)

	return size

func _find_nearest_floor(grid: Array, origin: Vector2i) -> Vector2i:
	if _is_inside_grid(grid, origin) and grid[origin.y][origin.x] == MapTypes.FLOOR:
		return origin

	var best: Vector2i = origin
	var best_dist: float = INF

	for y in range(grid.size()):
		for x in range(grid[y].size()):
			if grid[y][x] == MapTypes.FLOOR:
				var candidate: Vector2i = Vector2i(x, y)
				var dist: float = origin.distance_squared_to(candidate)
				if dist < best_dist:
					best_dist = dist
					best = candidate

	return best

func _find_farthest_floor(grid: Array, origin: Vector2i) -> Vector2i:
	var best: Vector2i = origin
	var best_dist: float = -1.0

	for y in range(grid.size()):
		for x in range(grid[y].size()):
			if grid[y][x] == MapTypes.FLOOR:
				var candidate: Vector2i = Vector2i(x, y)
				var dist: float = origin.distance_squared_to(candidate)
				if dist > best_dist:
					best_dist = dist
					best = candidate

	return best

func _keep_only_reachable_from_start(grid: Array, start: Vector2i) -> void:
	if not _is_inside_grid(grid, start):
		return
	if grid[start.y][start.x] != MapTypes.FLOOR:
		return

	var visited := {}
	var queue: Array = [start]
	visited[_pos_key(start)] = true

	var directions: Array = [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1)
	]

	while queue.size() > 0:
		var current: Vector2i = queue.pop_front()

		for dir in directions:
			var d: Vector2i = dir
			var next: Vector2i = current + d
			var key: String = _pos_key(next)

			if _is_inside_grid(grid, next) and not visited.has(key):
				if grid[next.y][next.x] == MapTypes.FLOOR:
					visited[key] = true
					queue.append(next)

	for y in range(grid.size()):
		for x in range(grid[y].size()):
			if grid[y][x] == MapTypes.FLOOR:
				var pos: Vector2i = Vector2i(x, y)
				if not visited.has(_pos_key(pos)):
					grid[y][x] = MapTypes.WALL

func _is_inside_grid(grid: Array, pos: Vector2i) -> bool:
	return pos.y >= 0 and pos.y < grid.size() and pos.x >= 0 and pos.x < grid[0].size()

func _pos_key(pos: Vector2i) -> String:
	return "%d_%d" % [pos.x, pos.y]

func _count_floor_cells(grid: Array) -> int:
	var count: int = 0

	for y in range(grid.size()):
		for x in range(grid[y].size()):
			if grid[y][x] == MapTypes.FLOOR:
				count += 1

	return count

func _fallback_empty_map(width: int, height: int, seed_value: int) -> Dictionary:
	var grid: Array = []
	for y in range(height):
		var row: Array = []
		for x in range(width):
			row.append(MapTypes.WALL)
		grid.append(row)

	return {
		"grid": grid,
		"start": Vector2i(1, 1),
		"end": Vector2i(1, 1),
		"rooms": [],
		"algorithm": get_algorithm_name(),
		"seed": seed_value,
		"retry_count": 0
	}
