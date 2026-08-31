class_name ModuleWFCGenerator
extends BaseGenerator

## Generates maps using a module-based Wave Function Collapse algorithm.
##
## The generator operates on a grid of predefined modules loaded from
## ModuleLibrary. Each cell initially contains all compatible module options.
## Constraint propagation and weighted collapse progressively reduce these
## options until a complete layout is obtained.
##
## Generated layouts are additionally validated for structural connectivity
## and minimum semantic composition requirements. Failed attempts may be
## retried up to the configured limit.


const CARDINAL_DIRECTIONS: Array[Vector2i] = [
	Vector2i.RIGHT,
	Vector2i.LEFT,
	Vector2i.DOWN,
	Vector2i.UP
]

const DIRECTION_NAMES: Array[String] = [
	"up",
	"right",
	"down",
	"left"
]

const DIRECTION_OFFSETS: Array[Vector2i] = [
	Vector2i.UP,
	Vector2i.RIGHT,
	Vector2i.DOWN,
	Vector2i.LEFT
]

const INVALID_CELL_POSITION := Vector2i(-1, -1)

const MIN_VALID_FLOOR_COUNT: int = 20
const MIN_LARGEST_COMPONENT_RATIO: float = 0.8


var module_library: ModuleLibrary = ModuleLibrary.new()


## Returns the identifier used for this generator in test results and exports.
func get_algorithm_name() -> String:
	return "ModuleWFC"


## Generates a map using module-based Wave Function Collapse.
##
## A generation attempt consists of boundary constraint application,
## iterative collapse and propagation, structural validation, and composition
## validation. Failed attempts are retried according to the configured limit.
func generate_map(config: Dictionary) -> Dictionary:
	var module_grid_width: int = config.get(
		"wfc_module_grid_width",
		8
	)

	var module_grid_height: int = config.get(
		"wfc_module_grid_height",
		8
	)

	var max_retries: int = config.get(
		"wfc_max_retries",
		20
	)

	var min_small_corridors: int = config.get(
		"wfc_min_small_corridors",
		4
	)

	var min_medium_rooms: int = config.get(
		"wfc_min_medium_rooms",
		2
	)

	var min_large_rooms: int = config.get(
		"wfc_min_large_rooms",
		1
	)

	var keep_only_reachable_area_from_start: bool = config.get(
		"keep_only_reachable_area_from_start",
		false
	)

	var use_random_seed: bool = config.get(
		"random_seed",
		true
	)

	var seed_value: int = config.get(
		"seed",
		0
	)

	var module_size: int = module_library.get_module_size()
	var available_modules: Array[Dictionary] = (
		module_library.get_modules()
	)

	if available_modules.is_empty():
		push_error(
			"ModuleWFCGenerator: module library is empty."
		)

		return _fallback_empty_map(
			module_grid_width * maxi(1, module_size),
			module_grid_height * maxi(1, module_size),
			seed_value,
			"empty_module_library"
		)

	if module_size <= 0:
		push_error(
			"ModuleWFCGenerator: invalid module size."
		)

		return _fallback_empty_map(
			module_grid_width * 5,
			module_grid_height * 5,
			seed_value,
			"invalid_module_size"
		)

	var rng := RandomNumberGenerator.new()

	if use_random_seed:
		rng.randomize()
		seed_value = rng.randi()

	rng.seed = seed_value

	var solved_cells: Array = []
	var generation_succeeded: bool = false
	var retries_used: int = 0

	# Store the most recent fully collapsed layout even when it fails
	# structural or composition validation. It can be returned for analysis
	# when all accepted attempts fail.
	var last_generated_cells: Array = []
	var last_generated_grid: Array = []
	var last_generated_valid_layout: bool = false
	var last_generated_valid_composition: bool = false
	var last_generated_attempt: int = -1

	for attempt in range(max_retries):
		retries_used = attempt

		var cells := _create_initial_cells(
			module_grid_width,
			module_grid_height
		)

		if not _apply_boundary_constraints(
			cells,
			module_grid_width,
			module_grid_height
		):
			continue

		var collapse_succeeded := _collapse_cells(
			cells,
			module_grid_width,
			module_grid_height,
			rng
		)

		if not collapse_succeeded:
			continue

		var preview_grid := _build_final_grid(
			cells,
			module_grid_width,
			module_grid_height,
			module_size
		)

		var preview_start := _find_nearest_floor(
			preview_grid,
			Vector2i(1, 1)
		)

		var preview_end := _find_farthest_floor(
			preview_grid,
			preview_start
		)

		var valid_layout := _is_valid_generated_map(
			preview_grid,
			preview_start,
			preview_end
		)

		var valid_composition := _has_valid_module_composition(
			cells,
			module_grid_width,
			module_grid_height,
			min_small_corridors,
			min_medium_rooms,
			min_large_rooms
		)

		last_generated_cells = cells.duplicate(true)
		last_generated_grid = preview_grid.duplicate(true)
		last_generated_valid_layout = valid_layout
		last_generated_valid_composition = valid_composition
		last_generated_attempt = attempt

		if valid_layout and valid_composition:
			solved_cells = cells
			generation_succeeded = true
			break

	if not generation_succeeded:
		push_warning(
			"ModuleWFCGenerator: generation failed after %d attempts."
			% max_retries
		)

		if (
			not last_generated_cells.is_empty()
			and not last_generated_grid.is_empty()
		):
			return _build_result_from_grid_and_cells(
				last_generated_grid,
				last_generated_cells,
				seed_value,
				retries_used + 1,
				keep_only_reachable_area_from_start,
				true,
				"last_generated_failed_constraints",
				last_generated_valid_layout,
				last_generated_valid_composition,
				last_generated_attempt + 1
			)

		var fallback := _fallback_empty_map(
			module_grid_width * module_size,
			module_grid_height * module_size,
			seed_value,
			"no_collapsed_map_available"
		)

		fallback["retry_count"] = retries_used + 1

		return fallback

	var grid := _build_final_grid(
		solved_cells,
		module_grid_width,
		module_grid_height,
		module_size
	)

	return _build_result_from_grid_and_cells(
		grid,
		solved_cells,
		seed_value,
		retries_used + 1,
		keep_only_reachable_area_from_start,
		false,
		"",
		true,
		true,
		retries_used + 1
	)


## Creates the common result representation for a generated WFC layout.
func _build_result_from_grid_and_cells(
	grid: Array,
	cells: Array,
	seed_value: int,
	retry_count: int,
	keep_only_reachable_area_from_start: bool,
	failed_generation: bool,
	fallback_reason: String,
	valid_layout: bool,
	valid_composition: bool,
	accepted_attempt: int
) -> Dictionary:
	var start := _find_nearest_floor(
		grid,
		Vector2i(1, 1)
	)

	var end := _find_farthest_floor(
		grid,
		start
	)

	if keep_only_reachable_area_from_start:
		_keep_only_reachable_from_start(
			grid,
			start
		)

		end = _find_farthest_floor(
			grid,
			start
		)

	return {
		"grid": grid,
		"start": start,
		"end": end,
		"rooms": [],
		"algorithm": get_algorithm_name(),
		"seed": seed_value,
		"retry_count": retry_count,
		"module_cells": cells,
		"failed_generation": failed_generation,
		"fallback_reason": fallback_reason,
		"wfc_valid_layout": valid_layout,
		"wfc_valid_composition": valid_composition,
		"wfc_accepted_attempt": accepted_attempt
	}


## Creates the initial WFC cell grid with every module available as an option.
func _create_initial_cells(
	module_grid_width: int,
	module_grid_height: int
) -> Array:
	var all_modules: Array[Dictionary] = module_library.get_modules()
	var cells: Array = []

	for _y in range(module_grid_height):
		var row: Array = []

		for _x in range(module_grid_width):
			row.append({
				"collapsed": false,
				"options": all_modules.duplicate(true)
			})

		cells.append(row)

	return cells


## Removes module options that would create openings outside the map boundary.
##
## Returns false if any cell loses all possible module options.
func _apply_boundary_constraints(
	cells: Array,
	module_grid_width: int,
	module_grid_height: int
) -> bool:
	for y in range(module_grid_height):
		for x in range(module_grid_width):
			var filtered_options: Array = []
			var current_options: Array = cells[y][x]["options"]

			for option_value in current_options:
				var module: Dictionary = option_value

				if y == 0 and bool(module["up"]):
					continue

				if (
					y == module_grid_height - 1
					and bool(module["down"])
				):
					continue

				if x == 0 and bool(module["left"]):
					continue

				if (
					x == module_grid_width - 1
					and bool(module["right"])
				):
					continue

				filtered_options.append(module)

			if filtered_options.is_empty():
				return false

			cells[y][x]["options"] = filtered_options

			if filtered_options.size() == 1:
				cells[y][x]["collapsed"] = true

	return true


## Collapses cells until the WFC grid is solved or a contradiction occurs.
## Collapses cells until the WFC grid is solved or a contradiction occurs.
func _collapse_cells(
	cells: Array,
	module_grid_width: int,
	module_grid_height: int,
	rng: RandomNumberGenerator
) -> bool:
	if not _propagate_all(
		cells,
		module_grid_width,
		module_grid_height
	):
		return false

	while true:
		var next_position := _find_lowest_entropy_cell(
			cells,
			module_grid_width,
			module_grid_height
		)

		if next_position == INVALID_CELL_POSITION:
			return true

		var cell: Dictionary = cells[
			next_position.y
		][next_position.x]

		var options: Array = cell["options"]

		if options.is_empty():
			return false

		var chosen_module := _choose_weighted_module(
			options,
			rng
		)

		cells[next_position.y][next_position.x]["options"] = [
			chosen_module
		]

		cells[next_position.y][next_position.x]["collapsed"] = true

		if not _propagate_from(
			cells,
			module_grid_width,
			module_grid_height,
			next_position
		):
			return false

	# Required by GDScript's static return-path analysis.
	return false
	if not _propagate_all(
		cells,
		module_grid_width,
		module_grid_height
	):
		return false

	while true:
		var next_position := _find_lowest_entropy_cell(
			cells,
			module_grid_width,
			module_grid_height
		)

		if next_position == INVALID_CELL_POSITION:
			return true

		var cell: Dictionary = cells[
			next_position.y
		][next_position.x]

		var options: Array = cell["options"]

		if options.is_empty():
			return false

		var chosen_module := _choose_weighted_module(
			options,
			rng
		)

		cells[next_position.y][next_position.x]["options"] = [
			chosen_module
		]

		cells[next_position.y][next_position.x]["collapsed"] = true

		if not _propagate_from(
			cells,
			module_grid_width,
			module_grid_height,
			next_position
		):
			return false


## Finds the unresolved cell with the smallest number of remaining options.
func _find_lowest_entropy_cell(
	cells: Array,
	module_grid_width: int,
	module_grid_height: int
) -> Vector2i:
	var best_position := INVALID_CELL_POSITION
	var lowest_option_count: int = 2147483647

	for y in range(module_grid_height):
		for x in range(module_grid_width):
			var cell: Dictionary = cells[y][x]
			var options: Array = cell["options"]
			var option_count := options.size()

			if option_count <= 1:
				continue

			if option_count < lowest_option_count:
				lowest_option_count = option_count
				best_position = Vector2i(x, y)

	return best_position


## Selects one module according to the weights stored in module definitions.
func _choose_weighted_module(
	options: Array,
	rng: RandomNumberGenerator
) -> Dictionary:
	var total_weight: float = 0.0

	for option_value in options:
		var module: Dictionary = option_value

		total_weight += float(
			module.get("weight", 1.0)
		)

	var roll := rng.randf() * total_weight
	var current_weight: float = 0.0

	for option_value in options:
		var module: Dictionary = option_value

		current_weight += float(
			module.get("weight", 1.0)
		)

		if roll <= current_weight:
			return module

	var fallback_module: Dictionary = options[
		options.size() - 1
	]

	return fallback_module


## Propagates constraints through the entire module grid.
func _propagate_all(
	cells: Array,
	module_grid_width: int,
	module_grid_height: int
) -> bool:
	var queue: Array[Vector2i] = []

	for y in range(module_grid_height):
		for x in range(module_grid_width):
			queue.append(Vector2i(x, y))

	return _process_propagation_queue(
		cells,
		module_grid_width,
		module_grid_height,
		queue
	)


## Propagates constraints starting from one changed cell.
func _propagate_from(
	cells: Array,
	module_grid_width: int,
	module_grid_height: int,
	start_position: Vector2i
) -> bool:
	var queue: Array[Vector2i] = [
		start_position
	]

	return _process_propagation_queue(
		cells,
		module_grid_width,
		module_grid_height,
		queue
	)


## Processes WFC constraint propagation until no additional options are removed.
func _process_propagation_queue(
	cells: Array,
	module_grid_width: int,
	module_grid_height: int,
	queue: Array[Vector2i]
) -> bool:
	var head: int = 0

	while head < queue.size():
		var current := queue[head]
		head += 1

		var current_cell: Dictionary = cells[
			current.y
		][current.x]

		var current_options: Array = current_cell["options"]

		for direction_index in range(DIRECTION_NAMES.size()):
			var direction_name: String = DIRECTION_NAMES[
				direction_index
			]

			var offset: Vector2i = DIRECTION_OFFSETS[
				direction_index
			]

			var neighbor_position := current + offset

			if not _is_inside_module_grid(
				neighbor_position,
				module_grid_width,
				module_grid_height
			):
				continue

			var neighbor_cell: Dictionary = cells[
				neighbor_position.y
			][neighbor_position.x]

			var neighbor_options: Array = neighbor_cell["options"]
			var filtered_neighbor_options: Array = []

			for neighbor_option_value in neighbor_options:
				var neighbor_module: Dictionary = (
					neighbor_option_value
				)

				var compatible := false

				for current_option_value in current_options:
					var current_module: Dictionary = (
						current_option_value
					)

					if module_library.are_modules_compatible(
						current_module,
						neighbor_module,
						direction_name
					):
						compatible = true
						break

				if compatible:
					filtered_neighbor_options.append(
						neighbor_module
					)

			if filtered_neighbor_options.is_empty():
				return false

			if (
				filtered_neighbor_options.size()
				< neighbor_options.size()
			):
				cells[
					neighbor_position.y
				][neighbor_position.x]["options"] = (
					filtered_neighbor_options
				)

				if filtered_neighbor_options.size() == 1:
					cells[
						neighbor_position.y
					][neighbor_position.x]["collapsed"] = true

				queue.append(neighbor_position)

	return true


## Converts the collapsed module grid to the common binary tile grid.
func _build_final_grid(
	cells: Array,
	module_grid_width: int,
	module_grid_height: int,
	module_size: int
) -> Array:
	var final_width := module_grid_width * module_size
	var final_height := module_grid_height * module_size

	var grid: Array = []

	for _y in range(final_height):
		var row: Array = []

		for _x in range(final_width):
			row.append(MapTypes.WALL)

		grid.append(row)

	for module_y in range(module_grid_height):
		for module_x in range(module_grid_width):
			var cell: Dictionary = cells[
				module_y
			][module_x]

			var options: Array = cell["options"]

			if options.is_empty():
				continue

			var module: Dictionary = options[0]
			var module_grid: Array = module["grid"]

			for local_y in range(module_size):
				for local_x in range(module_size):
					var world_x := (
						module_x * module_size
						+ local_x
					)

					var world_y := (
						module_y * module_size
						+ local_y
					)

					var value := int(
						module_grid[local_y][local_x]
					)

					if value == 0:
						grid[world_y][world_x] = MapTypes.FLOOR
					else:
						grid[world_y][world_x] = MapTypes.WALL

	return grid


## Returns whether a module-grid position lies within its bounds.
func _is_inside_module_grid(
	position: Vector2i,
	width: int,
	height: int
) -> bool:
	return (
		position.x >= 0
		and position.x < width
		and position.y >= 0
		and position.y < height
	)


## Validates the structural properties required from a collapsed WFC layout.
func _is_valid_generated_map(
	grid: Array,
	start: Vector2i,
	end: Vector2i
) -> bool:
	var floor_count := _count_floor_cells(grid)

	if floor_count < MIN_VALID_FLOOR_COUNT:
		return false

	var path_length := _find_path_length(
		grid,
		start,
		end
	)

	if path_length == -1:
		return false

	var largest_component_size := (
		_largest_connected_floor_component(grid)
	)

	var largest_component_ratio := (
		float(largest_component_size)
		/ maxf(1.0, float(floor_count))
	)

	return (
		largest_component_ratio
		>= MIN_LARGEST_COMPONENT_RATIO
	)


## Checks whether a collapsed layout satisfies minimum module composition.
func _has_valid_module_composition(
	cells: Array,
	module_grid_width: int,
	module_grid_height: int,
	min_small_corridors: int,
	min_medium_rooms: int,
	min_large_rooms: int
) -> bool:
	var counts := _count_module_categories(
		cells,
		module_grid_width,
		module_grid_height
	)

	var small_corridors := int(
		counts.get("small_corridors", 0)
	)

	var medium_rooms := int(
		counts.get("medium_rooms", 0)
	)

	var large_rooms := int(
		counts.get("large_rooms", 0)
	)

	return (
		small_corridors >= min_small_corridors
		and medium_rooms >= min_medium_rooms
		and large_rooms >= min_large_rooms
	)


## Counts selected semantic module categories in a collapsed layout.
func _count_module_categories(
	cells: Array,
	module_grid_width: int,
	module_grid_height: int
) -> Dictionary:
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
			var scale_class := str(
				module.get("scale_class", "")
			)

			if (
				tags.has("corridor")
				and scale_class == "small"
			):
				counts["small_corridors"] = (
					int(counts["small_corridors"]) + 1
				)

			if (
				tags.has("room")
				and scale_class == "medium"
			):
				counts["medium_rooms"] = (
					int(counts["medium_rooms"]) + 1
				)

			if (
				tags.has("room")
				and scale_class == "large"
			):
				counts["large_rooms"] = (
					int(counts["large_rooms"]) + 1
				)

	return counts


## Returns the shortest four-directional path length between two floor tiles.
func _find_path_length(
	grid: Array,
	start: Vector2i,
	end: Vector2i
) -> int:
	if (
		not _is_inside_grid(grid, start)
		or not _is_inside_grid(grid, end)
	):
		return -1

	if (
		grid[start.y][start.x] != MapTypes.FLOOR
		or grid[end.y][end.x] != MapTypes.FLOOR
	):
		return -1

	var queue: Array[Dictionary] = [{
		"position": start,
		"distance": 0
	}]

	var head: int = 0
	var visited: Dictionary = {}

	visited[start] = true

	while head < queue.size():
		var current_entry: Dictionary = queue[head]
		head += 1

		var current: Vector2i = current_entry["position"]
		var distance: int = current_entry["distance"]

		if current == end:
			return distance

		for direction in CARDINAL_DIRECTIONS:
			var next_position := current + direction

			if visited.has(next_position):
				continue

			if not _is_inside_grid(
				grid,
				next_position
			):
				continue

			if (
				grid[next_position.y][next_position.x]
				!= MapTypes.FLOOR
			):
				continue

			visited[next_position] = true

			queue.append({
				"position": next_position,
				"distance": distance + 1
			})

	return -1


## Returns the size of the largest connected floor component.
func _largest_connected_floor_component(
	grid: Array
) -> int:
	var visited: Dictionary = {}
	var largest_component_size: int = 0

	for y in range(grid.size()):
		for x in range(grid[y].size()):
			var position := Vector2i(x, y)

			if visited.has(position):
				continue

			if grid[y][x] != MapTypes.FLOOR:
				continue

			var component_size := _flood_fill_floor_component(
				grid,
				position,
				visited
			)

			largest_component_size = maxi(
				largest_component_size,
				component_size
			)

	return largest_component_size


## Flood-fills one connected floor component and returns its size.
func _flood_fill_floor_component(
	grid: Array,
	start: Vector2i,
	visited: Dictionary
) -> int:
	var queue: Array[Vector2i] = [start]
	var head: int = 0
	var component_size: int = 0

	visited[start] = true

	while head < queue.size():
		var current := queue[head]
		head += 1

		component_size += 1

		for direction in CARDINAL_DIRECTIONS:
			var next_position := current + direction

			if visited.has(next_position):
				continue

			if not _is_inside_grid(
				grid,
				next_position
			):
				continue

			if (
				grid[next_position.y][next_position.x]
				!= MapTypes.FLOOR
			):
				continue

			visited[next_position] = true
			queue.append(next_position)

	return component_size


## Finds the floor tile nearest to the provided origin.
func _find_nearest_floor(
	grid: Array,
	origin: Vector2i
) -> Vector2i:
	if (
		_is_inside_grid(grid, origin)
		and grid[origin.y][origin.x] == MapTypes.FLOOR
	):
		return origin

	var nearest_position := origin
	var nearest_distance: float = INF

	for y in range(grid.size()):
		for x in range(grid[y].size()):
			if grid[y][x] != MapTypes.FLOOR:
				continue

			var candidate := Vector2i(x, y)

			var distance: float = (
				origin.distance_squared_to(candidate)
			)

			if distance < nearest_distance:
				nearest_distance = distance
				nearest_position = candidate

	return nearest_position


## Finds the floor tile farthest from the provided origin.
func _find_farthest_floor(
	grid: Array,
	origin: Vector2i
) -> Vector2i:
	var farthest_position := origin
	var farthest_distance: float = -1.0

	for y in range(grid.size()):
		for x in range(grid[y].size()):
			if grid[y][x] != MapTypes.FLOOR:
				continue

			var candidate := Vector2i(x, y)

			var distance: float = (
				origin.distance_squared_to(candidate)
			)

			if distance > farthest_distance:
				farthest_distance = distance
				farthest_position = candidate

	return farthest_position


## Removes floor tiles that are not reachable from the selected start tile.
func _keep_only_reachable_from_start(
	grid: Array,
	start: Vector2i
) -> void:
	if not _is_inside_grid(grid, start):
		return

	if grid[start.y][start.x] != MapTypes.FLOOR:
		return

	var visited: Dictionary = {}
	var queue: Array[Vector2i] = [start]
	var head: int = 0

	visited[start] = true

	while head < queue.size():
		var current := queue[head]
		head += 1

		for direction in CARDINAL_DIRECTIONS:
			var next_position := current + direction

			if visited.has(next_position):
				continue

			if not _is_inside_grid(
				grid,
				next_position
			):
				continue

			if (
				grid[next_position.y][next_position.x]
				!= MapTypes.FLOOR
			):
				continue

			visited[next_position] = true
			queue.append(next_position)

	for y in range(grid.size()):
		for x in range(grid[y].size()):
			if grid[y][x] != MapTypes.FLOOR:
				continue

			var position := Vector2i(x, y)

			if not visited.has(position):
				grid[y][x] = MapTypes.WALL


## Returns whether a position lies within the binary tile grid.
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


## Counts all floor tiles in the binary tile grid.
func _count_floor_cells(grid: Array) -> int:
	var floor_count: int = 0

	for y in range(grid.size()):
		for x in range(grid[y].size()):
			if grid[y][x] == MapTypes.FLOOR:
				floor_count += 1

	return floor_count


## Returns an all-wall result when WFC cannot produce a collapsed map.
func _fallback_empty_map(
	width: int,
	height: int,
	seed_value: int,
	reason: String = "empty_fallback"
) -> Dictionary:
	var grid: Array = []

	for _y in range(height):
		var row: Array = []

		for _x in range(width):
			row.append(MapTypes.WALL)

		grid.append(row)

	return {
		"grid": grid,
		"start": Vector2i(1, 1),
		"end": Vector2i(1, 1),
		"rooms": [],
		"algorithm": get_algorithm_name(),
		"seed": seed_value,
		"retry_count": 0,
		"module_cells": [],
		"failed_generation": true,
		"fallback_reason": reason,
		"wfc_valid_layout": false,
		"wfc_valid_composition": false,
		"wfc_accepted_attempt": 0
	}
