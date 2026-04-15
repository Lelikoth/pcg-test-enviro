extends RefCounted
class_name MapPostProcessor

func apply_fixed_start_end_rooms(map_data: Dictionary) -> Dictionary:
	var grid: Array = map_data["grid"]

	if grid.is_empty() or grid[0].is_empty():
		return map_data

	var height: int = grid.size()
	var width: int = grid[0].size()

	# Keep a 1-tile margin from map borders
	# Start room: 3x3 around (3,3)
	# End room: 3x3 around (width-4, height-4)
	var start_center := Vector2i(3, 3)
	var end_center := Vector2i(width - 4, height - 4)

	_carve_room(grid, start_center, 3)
	_carve_room(grid, end_center, 3)

	map_data["start"] = start_center
	map_data["end"] = end_center

	return map_data

func _carve_room(grid: Array, center: Vector2i, room_size: int) -> void:
	var half_size: int = room_size / 2

	for y in range(center.y - half_size, center.y + half_size + 1):
		for x in range(center.x - half_size, center.x + half_size + 1):
			if _is_inside(grid, Vector2i(x, y)):
				grid[y][x] = MapTypes.FLOOR

func _is_inside(grid: Array, pos: Vector2i) -> bool:
	return pos.y >= 0 and pos.y < grid.size() and pos.x >= 0 and pos.x < grid[0].size()
