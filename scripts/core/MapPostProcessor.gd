class_name MapPostProcessor
extends RefCounted

## Applies common post-processing operations to generated maps.
##
## The processor optionally applies legacy fixed start/end rooms and then
## selects standardized start and end positions using EndpointSelector.


var endpoint_selector: EndpointSelector = EndpointSelector.new()


## Applies common post-processing to generated map data.
##
## Start and end positions are selected after all grid modifications so that
## every generator uses the same endpoint selection procedure.
func process_map(
	map_data: Dictionary,
	use_fixed_start_end_rooms: bool
) -> Dictionary:
	if not map_data.has("grid"):
		return map_data

	var grid: Array = map_data["grid"]

	if not _is_valid_grid(grid):
		return map_data

	# Legacy functionality retained from an earlier version of the testing
	# environment. It is not used in the final experiments.
	if use_fixed_start_end_rooms:
		_apply_fixed_start_end_rooms(grid)

	var endpoints: Dictionary = endpoint_selector.select_corner_endpoints(grid)

	map_data["start"] = endpoints.get("start", Vector2i.ZERO)
	map_data["end"] = endpoints.get("end", Vector2i.ZERO)
	map_data["has_valid_start"] = endpoints.get(
		"has_valid_start",
		false
	)
	map_data["has_valid_end"] = endpoints.get(
		"has_valid_end",
		false
	)

	return map_data


## Legacy operation that carves 3x3 floor rooms near opposite map corners.
func _apply_fixed_start_end_rooms(grid: Array) -> void:
	var height: int = grid.size()
	var width: int = grid[0].size()

	var start_center := Vector2i(3, 3)
	var end_center := Vector2i(width - 4, height - 4)

	_carve_room(grid, start_center, 3)
	_carve_room(grid, end_center, 3)


## Carves a square floor area around the provided center position.
func _carve_room(
	grid: Array,
	center: Vector2i,
	room_size: int
) -> void:
	var half_size: int = room_size / 2

	for y in range(
		center.y - half_size,
		center.y + half_size + 1
	):
		for x in range(
			center.x - half_size,
			center.x + half_size + 1
		):
			var position := Vector2i(x, y)

			if _is_inside_grid(grid, position):
				grid[y][x] = MapTypes.FLOOR


## Returns whether the grid contains at least one row and one column.
func _is_valid_grid(grid: Array) -> bool:
	return not grid.is_empty() and not grid[0].is_empty()


## Returns whether the provided position lies within the grid bounds.
func _is_inside_grid(grid: Array, position: Vector2i) -> bool:
	return (
		position.y >= 0
		and position.y < grid.size()
		and position.x >= 0
		and position.x < grid[0].size()
	)
