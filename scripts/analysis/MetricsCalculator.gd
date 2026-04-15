extends RefCounted
class_name MetricsCalculator

var room_detector := RoomDetector.new()

func calculate_metrics(map_data: Dictionary, generation_time_ms: float, validator: MapValidator) -> Dictionary:
	var grid: Array = map_data["grid"]
	var start: Vector2i = map_data["start"]
	var end: Vector2i = map_data["end"]

	var floor_count: int = 0
	var wall_count: int = 0

	for row in grid:
		for cell in row:
			if cell == MapTypes.FLOOR:
				floor_count += 1
			else:
				wall_count += 1

	var total: int = floor_count + wall_count
	var path_length: int = validator.find_path_length(grid, start, end)
	var connected: bool = path_length != -1

	var rooms_for_metrics: Array = _get_rooms_for_metrics(map_data, grid)

	return {
		"algorithm": map_data.get("algorithm", "UNKNOWN"),
		"seed": map_data.get("seed", 0),
		"generation_time_ms": generation_time_ms,
		"is_connected": connected,
		"path_length": path_length,
		"floor_count": floor_count,
		"wall_count": wall_count,
		"floor_ratio": float(floor_count) / max(1.0, float(total)),
		"room_count": rooms_for_metrics.size(),
		"largest_room_area": _largest_room_area(rooms_for_metrics)
	}

func _get_rooms_for_metrics(map_data: Dictionary, grid: Array) -> Array:
	var generator_rooms: Array = map_data.get("rooms", [])

	if generator_rooms.size() > 0:
		return _normalize_generator_rooms(generator_rooms)

	return room_detector.detect_rooms(grid)

func _normalize_generator_rooms(generator_rooms: Array) -> Array:
	var normalized: Array = []

	for room in generator_rooms:
		if room is Dictionary:
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

	for room in rooms:
		if room is Dictionary and room.has("area"):
			var area: int = room["area"]
			if area > best:
				best = area

	return best
