extends RefCounted
class_name MapPostProcessor


var endpoint_selector := EndpointSelector.new()


func process_map(map_data: Dictionary, use_fixed_start_end_rooms: bool) -> Dictionary:
	if not map_data.has("grid"):
		return map_data

	var grid: Array = map_data["grid"]

	if grid.is_empty() or grid[0].is_empty():
		return map_data

	if use_fixed_start_end_rooms:
		_apply_fixed_start_end_rooms_to_grid(grid)

	var endpoints: Dictionary = endpoint_selector.select_corner_endpoints(grid)

	map_data["start"] = endpoints.get("start", Vector2i.ZERO)
	map_data["end"] = endpoints.get("end", Vector2i.ZERO)
	map_data["has_valid_start"] = endpoints.get("has_valid_start", false)
	map_data["has_valid_end"] = endpoints.get("has_valid_end", false)

	return map_data


func _apply_fixed_start_end_rooms_to_grid(grid: Array) -> void:
	var height: int = grid.size()
	var width: int = grid[0].size()

	var start_center := Vector2i(3, 3)
	var end_center := Vector2i(width - 4, height - 4)

	_carve_room(grid, start_center, 3)
	_carve_room(grid, end_center, 3)


func _carve_room(grid: Array, center: Vector2i, room_size: int) -> void:
	var half_size: int = int(room_size / 2)

	for y in range(center.y - half_size, center.y + half_size + 1):
		for x in range(center.x - half_size, center.x + half_size + 1):
			var pos := Vector2i(x, y)

			if _is_inside(grid, pos):
				grid[y][x] = MapTypes.FLOOR


func _is_inside(grid: Array, pos: Vector2i) -> bool:
	return (
		pos.y >= 0
		and pos.y < grid.size()
		and pos.x >= 0
		and grid.size() > 0
		and pos.x < grid[0].size()
	)
