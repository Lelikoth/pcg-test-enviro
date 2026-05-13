extends RefCounted
class_name RoomDetector

func detect_rooms(grid: Array) -> Array:
	var rooms: Array = []
	var visited := {}

	for y in range(grid.size()):
		for x in range(grid[y].size()):
			var pos := Vector2i(x, y)
			var key := _pos_key(pos)

			if visited.has(key):
				continue

			if grid[y][x] != MapTypes.FLOOR:
				continue

			var component: Array = _flood_fill_component(grid, pos, visited)
			var room := _analyze_component(component)

			if _is_room(room):
				rooms.append(room)

	return rooms

func _flood_fill_component(grid: Array, start: Vector2i, visited: Dictionary) -> Array:
	var component: Array = []
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
		component.append(current)

		for dir in directions:
			var next: Vector2i = current + dir
			var key := _pos_key(next)

			if not _is_inside(grid, next):
				continue
			if visited.has(key):
				continue
			if grid[next.y][next.x] != MapTypes.FLOOR:
				continue

			visited[key] = true
			queue.append(next)

	return component

func _analyze_component(component: Array) -> Dictionary:
	var first: Vector2i = component[0]

	var min_x: int = first.x
	var max_x: int = first.x
	var min_y: int = first.y
	var max_y: int = first.y

	for cell in component:
		var c: Vector2i = cell
		min_x = min(min_x, c.x)
		max_x = max(max_x, c.x)
		min_y = min(min_y, c.y)
		max_y = max(max_y, c.y)

	var width: int = max_x - min_x + 1
	var height: int = max_y - min_y + 1
	var area: int = component.size()
	var bbox_area: int = width * height
	var fill_ratio: float = float(area) / max(1.0, float(bbox_area))

	return {
		"cells": component,
		"position": Vector2i(min_x, min_y),
		"size": Vector2i(width, height),
		"area": area,
		"fill_ratio": fill_ratio
	}

func _is_room(room: Dictionary) -> bool:
	var size: Vector2i = room["size"]
	var area: int = room["area"]
	var fill_ratio: float = room["fill_ratio"]

	return area >= 9 and size.x >= 3 and size.y >= 3 and fill_ratio >= 0.6

func _is_inside(grid: Array, pos: Vector2i) -> bool:
	return pos.y >= 0 and pos.y < grid.size() and pos.x >= 0 and pos.x < grid[0].size()

func _pos_key(pos: Vector2i) -> String:
	return "%d_%d" % [pos.x, pos.y]
