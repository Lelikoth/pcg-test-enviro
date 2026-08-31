class_name ProcGenHybridAdapter
extends BaseGenerator

## Adapts the ProcGen addon to the common procedural generation interface.
##
## The generator combines BSP-based room generation, corridor construction,
## and cellular-automata shaping. The adapter configures ProcGen using the
## shared TestConfig representation and converts its output to the binary
## grid format used by the testing environment.


const GENERATION_TIMEOUT_MS: int = 5000


## Returns the identifier used for this generator in test results and exports.
func get_algorithm_name() -> String:
	return "ProcGenHybrid"


## Generates a map using the adapted ProcGen generator.
##
## ProcGen operates as a Node and performs generation after being added to the
## scene tree. This method therefore waits asynchronously until generation
## finishes or the configured timeout is reached.
func generate_map(config: Dictionary) -> Dictionary:
	var width: int = config.get("width", 64)
	var height: int = config.get("height", 64)

	var use_random_seed: bool = config.get("random_seed", true)
	var seed_value: int = config.get("seed", 0)

	if use_random_seed:
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		seed_value = rng.randi()

	var procgen: ProcGen = ProcGen.new()

	_configure_procgen(
		procgen,
		config,
		width,
		height,
		seed_value
	)

	var tree: SceneTree = Engine.get_main_loop() as SceneTree

	if tree == null:
		push_error(
			"ProcGenHybridAdapter: no SceneTree available."
		)
		return _empty_result(
			width,
			height,
			seed_value
		)

	# ProcGen starts its generation lifecycle after entering the scene tree.
	tree.root.add_child(procgen)

	var generation_start_time: int = Time.get_ticks_msec()

	while (
		procgen.is_generating()
		and Time.get_ticks_msec() - generation_start_time
		< GENERATION_TIMEOUT_MS
	):
		await tree.process_frame

	if procgen.is_generating():
		push_error(
			"ProcGenHybridAdapter: generation timed out."
		)

		procgen.queue_free()

		return _empty_result(
			width,
			height,
			seed_value
		)

	var grid: Array = _build_grid_from_procgen(
		procgen,
		width,
		height
	)

	var rooms: Array = _convert_rooms(
		procgen.get_rooms()
	)

	var corridor_areas: Array = procgen.get_corridor_areas()

	# Extract source topology from ProcGen's internal BSP graph.
	# MetricsCalculator interprets this data later.
	var procgen_room_links: Array = _extract_procgen_room_links(
		procgen
	)

	procgen.queue_free()

	return {
		"grid": grid,
		"rooms": rooms,
		"corridor_areas": corridor_areas,
		"procgen_room_links": procgen_room_links,
		"algorithm": get_algorithm_name(),
		"seed": seed_value
	}


## Applies TestConfig values to a ProcGen instance.
##
## Parameter ordering and defaults mirror the configuration used by the
## testing environment. Threaded automaton processing remains disabled to
## keep benchmark execution deterministic and comparable.
func _configure_procgen(
	procgen: ProcGen,
	config: Dictionary,
	width: int,
	height: int,
	seed_value: int
) -> void:
	# Basic generation settings.
	procgen.map_size = Vector2i(width, height)
	procgen.generate_seed = false
	procgen.seed = seed_value

	# Room generation.
	procgen.room_amount = int(
		config.get("procgen_room_amount", 14)
	)

	procgen.room_min_coverage = float(
		config.get("procgen_room_min_coverage", 0.16)
	)

	procgen.room_max_coverage = float(
		config.get("procgen_room_max_coverage", 0.34)
	)

	if procgen.room_min_coverage > procgen.room_max_coverage:
		var coverage_temp: float = procgen.room_min_coverage

		procgen.room_min_coverage = procgen.room_max_coverage
		procgen.room_max_coverage = coverage_temp

	procgen.room_center_ratio = float(
		config.get("procgen_room_center_ratio", 0.75)
	)

	# Corridor generation.
	procgen.corridor_cycle_chance = float(
		config.get("procgen_corridor_cycle_chance", 0.08)
	)

	procgen.corridor_edge_overlap_min_ratio = float(
		config.get(
			"procgen_corridor_edge_overlap_min_ratio",
			0.20
		)
	)

	# BSP subdivision.
	procgen.zone_split_max_ratio = float(
		config.get("procgen_zone_split_max_ratio", 0.5)
	)

	procgen.zone_parent_inverse_orientation_chance = float(
		config.get(
			"procgen_zone_parent_inverse_orientation_chance",
			0.85
		)
	)

	procgen.room_min_squared_ratio = float(
		config.get("procgen_room_min_squared_ratio", 0.35)
	)

	procgen.room_max_squared_ratio = float(
		config.get("procgen_room_max_squared_ratio", 1.0)
	)

	if (
		procgen.room_min_squared_ratio
		> procgen.room_max_squared_ratio
	):
		var squared_ratio_temp: float = (
			procgen.room_min_squared_ratio
		)

		procgen.room_min_squared_ratio = (
			procgen.room_max_squared_ratio
		)

		procgen.room_max_squared_ratio = squared_ratio_temp

	# Cellular automata shaping.
	procgen.automaton_iterations = int(
		config.get("procgen_automaton_iterations", 2)
	)

	# Threading is deliberately disabled for stable benchmark timing.
	procgen.automaton_threads = 0

	procgen.automaton_noise_rate = float(
		config.get("procgen_automaton_noise_rate", 0.28)
	)

	if procgen.automaton_iterations <= 0:
		procgen.automaton_noise_rate = 0.0

	procgen.automaton_flood_fill = bool(
		config.get("procgen_automaton_flood_fill", true)
	)

	procgen.automaton_cell_min_neighbors = int(
		config.get(
			"procgen_automaton_cell_min_neighbors",
			4
		)
	)

	procgen.automaton_cell_max_neighbors = int(
		config.get(
			"procgen_automaton_cell_max_neighbors",
			8
		)
	)

	procgen.automaton_smoothing_step_cell_min_neighbors = int(
		config.get(
			"procgen_automaton_smoothing_step_cell_min_neighbors",
			4
		)
	)

	# Optional structure expansion.
	procgen.automaton_zones_fixed_outline_expand = int(
		config.get(
			"procgen_automaton_zones_fixed_outline_expand",
			0
		)
	)

	procgen.automaton_corridor_fixed_width_expand = int(
		config.get(
			"procgen_automaton_corridor_fixed_width_expand",
			0
		)
	)

	procgen.automaton_corridor_non_fixed_width_expand = int(
		config.get(
			"procgen_automaton_corridor_non_fixed_width_expand",
			0
		)
	)


## Converts ProcGen's internal representation to the common binary grid.
func _build_grid_from_procgen(
	procgen: ProcGen,
	width: int,
	height: int
) -> Array:
	var grid: Array = []

	for y in range(height):
		var row: Array = []

		for x in range(width):
			var is_wall: bool = procgen.is_full_at(
				Vector2i(x, y)
			)

			row.append(
				MapTypes.WALL
				if is_wall
				else MapTypes.FLOOR
			)

		grid.append(row)

	return grid


## Converts ProcGen room rectangles to the common room metadata format.
func _convert_rooms(
	raw_rooms: Array[Rect2i]
) -> Array:
	var rooms: Array = []

	for room in raw_rooms:
		rooms.append({
			"position": room.position,
			"size": room.size,
			"area": room.size.x * room.size.y
		})

	return rooms


## Extracts room connections from ProcGen's internal BSP graph.
##
## This method depends on ProcGen's private `_generator` implementation and
## therefore intentionally isolates this addon-specific dependency here.
func _extract_procgen_room_links(
	procgen: ProcGen
) -> Array:
	var room_links: Array = []

	if procgen == null:
		return room_links

	if procgen._generator == null:
		return room_links

	if procgen._generator.bsp == null:
		return room_links

	if procgen._generator.bsp.graph == null:
		return room_links

	var leaves: Array = procgen._generator.bsp.get_leaves()
	var final_links: Array = procgen._generator.bsp.graph.final_links

	var room_index_by_key: Dictionary = {}

	for index in range(leaves.size()):
		# ProcGen's BSP leaf type belongs to the external addon and is kept
		# as Variant here to avoid coupling the adapter to its concrete class.
		var leaf: Variant = leaves[index]

		if leaf == null:
			continue

		var room: Rect2i = leaf.room_rect
		var room_key := _room_key(room)

		room_index_by_key[room_key] = index

	for link_value in final_links:
		if link_value is not Array:
			continue

		var link: Array = link_value

		if link.size() < 2:
			continue

		var leaf_a: Variant = link[0]
		var leaf_b: Variant = link[1]

		if leaf_a == null or leaf_b == null:
			continue

		var room_a: Rect2i = leaf_a.room_rect
		var room_b: Rect2i = leaf_b.room_rect

		var key_a := _room_key(room_a)
		var key_b := _room_key(room_b)

		if not room_index_by_key.has(key_a):
			continue

		if not room_index_by_key.has(key_b):
			continue

		room_links.append({
			"from_room_index": int(
				room_index_by_key[key_a]
			),
			"to_room_index": int(
				room_index_by_key[key_b]
			)
		})

	return room_links


## Creates a deterministic key identifying a ProcGen room rectangle.
func _room_key(room: Rect2i) -> String:
	return "%d_%d_%d_%d" % [
		room.position.x,
		room.position.y,
		room.size.x,
		room.size.y
	]


## Returns an all-wall result when ProcGen cannot complete generation.
func _empty_result(
	width: int,
	height: int,
	seed_value: int
) -> Dictionary:
	var grid: Array = []

	for _y in range(height):
		var row: Array = []

		for _x in range(width):
			row.append(MapTypes.WALL)

		grid.append(row)

	return {
		"grid": grid,
		"rooms": [],
		"corridor_areas": [],
		"procgen_room_links": [],
		"algorithm": get_algorithm_name(),
		"seed": seed_value,
		"failed_generation": true
	}
