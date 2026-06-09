extends BaseGenerator
class_name WFCAdapter

const WFC_WORKSPACE_SCENE := preload("res://scenes/WFCWorkspace.tscn")

const FLOOR_SOURCE_ID := 0
const WALL_SOURCE_ID := 1

const DEFAULT_ATLAS_COORDS := Vector2i(0, 0)
const DEFAULT_ALTERNATIVE_TILE := 0

func get_algorithm_name() -> String:
	return "WFC"

func generate_map(config: Dictionary) -> Dictionary:
	var width: int = config.get("width", 64)
	var height: int = config.get("height", 64)
	var use_fixed_start_end_rooms: bool = config.get("use_fixed_start_end_rooms", false)
	var keep_only_reachable_area_from_start: bool = config.get("keep_only_reachable_area_from_start", false)
	var seed_value: int = config.get("seed", 0)

	print("WFC config width = ", width, ", height = ", height)

	var workspace = WFC_WORKSPACE_SCENE.instantiate()
	Engine.get_main_loop().root.add_child(workspace)
	await Engine.get_main_loop().process_frame

	var sample_map: TileMapLayer = workspace.get_node("WFCSampleMap")
	var target_map: TileMapLayer = workspace.get_node("WFCTargetMap")
	var generator = workspace.get_node("WFC2DGenerator")

	if sample_map == null or target_map == null or generator == null:
		push_error("WFC workspace is missing required nodes.")
		workspace.queue_free()
		return _fallback_empty_map(width, height, seed_value)

	#target_map.clear()

	if use_fixed_start_end_rooms:
		_seed_fixed_rooms_in_target(target_map, width, height)

	generator.rect = Rect2i(0, 0, width, height)
	print("WFC rect = ", generator.rect)

	if "seed" in generator:
		generator.seed = seed_value

	print("WFC adapter: workspace added to tree")
	print("WFC adapter: starting generator")

	# This addon appears to generate asynchronously internally.
	# Start it, then wait until the target map stops changing.
	generator.start()
	await _wait_until_target_stabilizes(target_map, width, height)

	print("WFC adapter: target stabilization wait finished")
	print("WFC target used rect = ", target_map.get_used_rect())

	var grid: Array = _build_grid_from_tilemap(target_map, width, height)

	if use_fixed_start_end_rooms:
		_carve_room(grid, Vector2i(3, 3), 3)
		_carve_room(grid, Vector2i(width - 4, height - 4), 3)

	var start: Vector2i = _find_nearest_floor(grid, Vector2i(1, 1))
	var end: Vector2i = _find_farthest_floor(grid, start)

	if keep_only_reachable_area_from_start:
		_keep_only_reachable_from_start(grid, start)
		end = _find_farthest_floor(grid, start)

	# Give the addon one more frame before cleanup to reduce thread-exit issues
	await Engine.get_main_loop().process_frame
	workspace.queue_free()

	return {
		"grid": grid,
		"start": start,
		"end": end,
		"rooms": [],
		"algorithm": get_algorithm_name(),
		"seed": seed_value
	}

func _wait_until_target_stabilizes(target_map: TileMapLayer, width: int, height: int) -> void:
	var last_count: int = -1
	var stable_frames: int = 0
	var max_frames: int = 240

	for i in range(max_frames):
		await Engine.get_main_loop().process_frame

		var current_count: int = _count_non_empty_cells(target_map, width, height)

		if current_count == last_count and current_count > 0:
			stable_frames += 1
		else:
			stable_frames = 0
			last_count = current_count

		if stable_frames >= 15:
			print("WFC adapter: target stabilized after frame ", i + 1, " with ", current_count, " filled cells")
			return

	print("WFC adapter: target did not fully stabilize after waiting ", max_frames, " frames")

func _count_non_empty_cells(target_map: TileMapLayer, width: int, height: int) -> int:
	var count := 0

	for y in range(height):
		for x in range(width):
			var source_id: int = target_map.get_cell_source_id(Vector2i(x, y))
			if source_id != -1:
				count += 1

	return count

func _seed_fixed_rooms_in_target(target_map: TileMapLayer, width: int, height: int) -> void:
	_place_room_tiles(target_map, Vector2i(3, 3), 3)
	_place_room_tiles(target_map, Vector2i(width - 4, height - 4), 3)

func _place_room_tiles(target_map: TileMapLayer, center: Vector2i, room_size: int) -> void:
	var half_size: int = room_size / 2

	for y in range(center.y - half_size, center.y + half_size + 1):
		for x in range(center.x - half_size, center.x + half_size + 1):
			target_map.set_cell(
				Vector2i(x, y),
				FLOOR_SOURCE_ID,
				DEFAULT_ATLAS_COORDS,
				DEFAULT_ALTERNATIVE_TILE
			)

func _build_grid_from_tilemap(tilemap: TileMapLayer, width: int, height: int) -> Array:
	var grid: Array = []
	var source_counts := {}

	for y in range(height):
		var row: Array = []
		for x in range(width):
			var cell: Vector2i = Vector2i(x, y)
			var source_id: int = tilemap.get_cell_source_id(cell)

			if not source_counts.has(source_id):
				source_counts[source_id] = 0
			source_counts[source_id] += 1

			if source_id == FLOOR_SOURCE_ID:
				row.append(MapTypes.FLOOR)
			else:
				row.append(MapTypes.WALL)

		grid.append(row)

	print("WFC generated source counts: ", source_counts)

	return grid

func _carve_room(grid: Array, center: Vector2i, room_size: int) -> void:
	var half_size: int = room_size / 2

	for y in range(center.y - half_size, center.y + half_size + 1):
		for x in range(center.x - half_size, center.x + half_size + 1):
			if _is_inside(grid, Vector2i(x, y)):
				grid[y][x] = MapTypes.FLOOR

func _find_nearest_floor(grid: Array, origin: Vector2i) -> Vector2i:
	if _is_inside(grid, origin) and grid[origin.y][origin.x] == MapTypes.FLOOR:
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
	if not _is_inside(grid, start):
		return
	if grid[start.y][start.x] != MapTypes.FLOOR:
		return

	var visited := {}
	var queue: Array[Vector2i] = [start]
	visited[_pos_key(start)] = true

	var directions: Array[Vector2i] = [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1)
	]

	while queue.size() > 0:
		var current: Vector2i = queue.pop_front()

		for dir in directions:
			var next: Vector2i = current + dir
			var key: String = _pos_key(next)

			if _is_inside(grid, next) and not visited.has(key):
				if grid[next.y][next.x] == MapTypes.FLOOR:
					visited[key] = true
					queue.append(next)

	for y in range(grid.size()):
		for x in range(grid[y].size()):
			if grid[y][x] == MapTypes.FLOOR:
				var pos: Vector2i = Vector2i(x, y)
				if not visited.has(_pos_key(pos)):
					grid[y][x] = MapTypes.WALL

func _pos_key(pos: Vector2i) -> String:
	return "%d_%d" % [pos.x, pos.y]

func _is_inside(grid: Array, pos: Vector2i) -> bool:
	return pos.y >= 0 and pos.y < grid.size() and pos.x >= 0 and pos.x < grid[0].size()

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
		"seed": seed_value
	}
