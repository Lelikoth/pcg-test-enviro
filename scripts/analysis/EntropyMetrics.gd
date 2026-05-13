extends RefCounted
class_name EntropyMetrics


func calculate(grid: Array) -> Dictionary:
	var tile_entropy: float = _calculate_tile_entropy(grid)
	var pattern_entropy_2x2: float = _calculate_pattern_entropy_2x2(grid)

	return {
		"tile_entropy": tile_entropy,
		"tile_entropy_normalized": tile_entropy / 1.0,
		"pattern_entropy_2x2": pattern_entropy_2x2,
		"pattern_entropy_2x2_normalized": pattern_entropy_2x2 / 4.0
	}


func _calculate_tile_entropy(grid: Array) -> float:
	var counts := {}
	var total: int = 0

	for y in range(grid.size()):
		for x in range(grid[y].size()):
			var value: int = int(grid[y][x])

			if not counts.has(value):
				counts[value] = 0

			counts[value] += 1
			total += 1

	if total == 0:
		return 0.0

	var entropy: float = 0.0

	for key in counts.keys():
		var count: int = counts[key]
		var p: float = float(count) / float(total)

		if p > 0.0:
			entropy -= p * (log(p) / log(2.0))

	return entropy


func _calculate_pattern_entropy_2x2(grid: Array) -> float:
	if grid.size() < 2 or grid[0].size() < 2:
		return 0.0

	var pattern_counts := {}
	var total_patterns: int = 0

	for y in range(grid.size() - 1):
		for x in range(grid[y].size() - 1):
			var pattern: String = _pattern_2x2_key(grid, x, y)

			if not pattern_counts.has(pattern):
				pattern_counts[pattern] = 0

			pattern_counts[pattern] += 1
			total_patterns += 1

	if total_patterns == 0:
		return 0.0

	var entropy: float = 0.0

	for pattern_key in pattern_counts.keys():
		var count: int = pattern_counts[pattern_key]
		var p: float = float(count) / float(total_patterns)

		if p > 0.0:
			entropy -= p * (log(p) / log(2.0))

	return entropy


func _pattern_2x2_key(grid: Array, x: int, y: int) -> String:
	return "%d%d%d%d" % [
		int(grid[y][x]),
		int(grid[y][x + 1]),
		int(grid[y + 1][x]),
		int(grid[y + 1][x + 1])
	]
