extends BaseGenerator
class_name ProcGenHybridAdapter


func get_algorithm_name() -> String:
	return "ProcGenHybrid"


func generate_map(config: Dictionary) -> Dictionary:
	print("ProcGenHybrid: start")

	var width: int = config.get("width", 64)
	var height: int = config.get("height", 64)
	var use_random_seed: bool = config.get("random_seed", true)
	var seed_value: int = config.get("seed", 0)

	if use_random_seed:
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		seed_value = rng.randi()

	var procgen := ProcGen.new()

	# Basic map settings
	procgen.map_size = Vector2i(width, height)
	procgen.generate_seed = false
	procgen.seed = seed_value

	# Parameters controlled from UI / TestConfig
	procgen.room_amount = int(config.get("procgen_room_amount", 14))

	procgen.room_min_coverage = float(config.get("procgen_room_min_coverage", 0.16))
	procgen.room_max_coverage = float(config.get("procgen_room_max_coverage", 0.34))

	if procgen.room_min_coverage > procgen.room_max_coverage:
		var tmp := procgen.room_min_coverage
		procgen.room_min_coverage = procgen.room_max_coverage
		procgen.room_max_coverage = tmp

	procgen.room_center_ratio = float(config.get("procgen_room_center_ratio", 0.75))
	procgen.corridor_cycle_chance = float(config.get("procgen_corridor_cycle_chance", 0.08))

	procgen.automaton_iterations = int(config.get("procgen_automaton_iterations", 2))

	# Keep threads disabled for stable generation and benchmarking.
	procgen.automaton_threads = 0

	procgen.automaton_noise_rate = float(config.get("procgen_automaton_noise_rate", 0.28))

	if procgen.automaton_iterations <= 0:
		procgen.automaton_noise_rate = 0.0

	# Stable dungeon-oriented preset values
	procgen.zone_split_max_ratio = 0.5
	procgen.zone_parent_inverse_orientation_chance = 0.85

	procgen.room_min_squared_ratio = 0.35
	procgen.room_max_squared_ratio = 1.0

	procgen.corridor_edge_overlap_min_ratio = 0.20

	procgen.automaton_flood_fill = true
	procgen.automaton_cell_min_neighbors = 5
	procgen.automaton_cell_max_neighbors = 8
	procgen.automaton_smoothing_step_cell_min_neighbors = 4

	procgen.automaton_zones_fixed_outline_expand = 0
	procgen.automaton_corridor_fixed_width_expand = 0
	procgen.automaton_corridor_non_fixed_width_expand = 0

	print(
		"ProcGen config | rooms=%d, iter=%d, min_cov=%.2f, max_cov=%.2f, center=%.2f, cycles=%.2f, noise=%.2f, seed=%d" % [
			procgen.room_amount,
			procgen.automaton_iterations,
			procgen.room_min_coverage,
			procgen.room_max_coverage,
			procgen.room_center_ratio,
			procgen.corridor_cycle_chance,
			procgen.automaton_noise_rate,
			seed_value
		]
	)

	var tree := Engine.get_main_loop() as SceneTree

	if tree == null:
		push_error("ProcGenHybrid: no SceneTree available.")
		return _empty_result(width, height, seed_value)

	procgen.finished.connect(func():
		print("ProcGenHybrid: finished signal received")
	)

	print("ProcGenHybrid: before add_child")

	tree.root.add_child(procgen)

	print("ProcGenHybrid: after add_child")

	var start_time := Time.get_ticks_msec()
	var timeout_ms := 5000

	while procgen.is_generating() and Time.get_ticks_msec() - start_time < timeout_ms:
		await tree.process_frame

	if procgen.is_generating():
		push_error("ProcGenHybrid: timeout while waiting for ProcGen.")
		procgen.queue_free()
		return _empty_result(width, height, seed_value)

	print("ProcGenHybrid: building grid")

	var grid := _build_grid_from_procgen(procgen, width, height)
	var rooms := _convert_rooms(procgen.get_rooms())
	var corridors := procgen.get_corridor_areas()

	var start := _find_first_floor(grid)
	var end := _find_farthest_floor(grid, start)

	procgen.queue_free()

	print("ProcGenHybrid: done")

	return {
		"grid": grid,
		"start": start,
		"end": end,
		"rooms": rooms,
		"corridor_areas": corridors,
		"algorithm": get_algorithm_name(),
		"seed": seed_value
	}


func _build_grid_from_procgen(procgen: ProcGen, width: int, height: int) -> Array:
	var grid: Array = []

	for y in range(height):
		var row: Array = []

		for x in range(width):
			var is_wall := procgen.is_full_at(Vector2i(x, y))
			row.append(MapTypes.WALL if is_wall else MapTypes.FLOOR)

		grid.append(row)

	return grid


func _convert_rooms(raw_rooms: Array[Rect2i]) -> Array:
	var rooms: Array = []

	for room in raw_rooms:
		rooms.append({
			"position": room.position,
			"size": room.size
		})

	return rooms


func _find_first_floor(grid: Array) -> Vector2i:
	for y in range(grid.size()):
		for x in range(grid[y].size()):
			if grid[y][x] == MapTypes.FLOOR:
				return Vector2i(x, y)

	return Vector2i.ZERO


func _find_farthest_floor(grid: Array, start: Vector2i) -> Vector2i:
	var best := start
	var best_dist := -1.0

	for y in range(grid.size()):
		for x in range(grid[y].size()):
			if grid[y][x] != MapTypes.FLOOR:
				continue

			var pos := Vector2i(x, y)
			var dist := start.distance_squared_to(pos)

			if dist > best_dist:
				best_dist = dist
				best = pos

	return best


func _empty_result(width: int, height: int, seed_value: int) -> Dictionary:
	var grid: Array = []

	for y in range(height):
		var row: Array = []

		for x in range(width):
			row.append(MapTypes.WALL)

		grid.append(row)

	return {
		"grid": grid,
		"start": Vector2i.ZERO,
		"end": Vector2i.ZERO,
		"rooms": [],
		"corridor_areas": [],
		"algorithm": get_algorithm_name(),
		"seed": seed_value
	}
