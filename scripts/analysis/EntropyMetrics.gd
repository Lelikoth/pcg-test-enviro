class_name EntropyMetrics
extends RefCounted

## Calculates Shannon entropy metrics for generated maps.
##
## Tile entropy measures the distribution of individual tile values, while
## 2x2 pattern entropy measures the diversity of local spatial patterns.
## Entropy values are expressed in bits.


## Maximum entropy for a binary FLOOR/WALL tile distribution.
const MAX_TILE_ENTROPY: float = 1.0

## A binary 2x2 pattern has 16 possible configurations:
## log2(16) = 4 bits of maximum entropy.
const MAX_PATTERN_ENTROPY_2X2: float = 4.0


## Calculates tile-level and local 2x2 pattern entropy metrics.
func calculate(grid: Array) -> Dictionary:
	var tile_entropy := _calculate_tile_entropy(grid)
	var pattern_entropy_2x2 := _calculate_pattern_entropy_2x2(grid)

	return {
		"tile_entropy": tile_entropy,
		"tile_entropy_normalized": (
			tile_entropy / MAX_TILE_ENTROPY
		),
		"pattern_entropy_2x2": pattern_entropy_2x2,
		"pattern_entropy_2x2_normalized": (
			pattern_entropy_2x2 / MAX_PATTERN_ENTROPY_2X2
		)
	}


## Calculates Shannon entropy for individual tile values.
func _calculate_tile_entropy(grid: Array) -> float:
	var counts: Dictionary = {}
	var total_count: int = 0

	for row_value in grid:
		var row: Array = row_value

		for cell_value in row:
			var tile_value := int(cell_value)

			counts[tile_value] = (
				int(counts.get(tile_value, 0)) + 1
			)

			total_count += 1

	return _calculate_shannon_entropy(
		counts,
		total_count
	)


## Calculates Shannon entropy for overlapping 2x2 tile patterns.
func _calculate_pattern_entropy_2x2(grid: Array) -> float:
	if not _has_valid_2x2_area(grid):
		return 0.0

	var pattern_counts: Dictionary = {}
	var total_patterns: int = 0

	for y in range(grid.size() - 1):
		var pattern_width: int = mini(
			grid[y].size(),
			grid[y + 1].size()
		)

		for x in range(pattern_width - 1):
			var pattern_key := _pattern_2x2_key(
				grid,
				x,
				y
			)

			pattern_counts[pattern_key] = (
				int(pattern_counts.get(pattern_key, 0)) + 1
			)

			total_patterns += 1

	return _calculate_shannon_entropy(
		pattern_counts,
		total_patterns
	)


## Calculates Shannon entropy from a frequency distribution.
func _calculate_shannon_entropy(
	counts: Dictionary,
	total_count: int
) -> float:
	if total_count <= 0:
		return 0.0

	var entropy: float = 0.0

	for key in counts.keys():
		var count := int(counts[key])
		var probability := (
			float(count) / float(total_count)
		)

		if probability <= 0.0:
			continue

		entropy -= (
			probability
			* (log(probability) / log(2.0))
		)

	return entropy


## Encodes a binary 2x2 tile pattern as a compact integer key.
func _pattern_2x2_key(
	grid: Array,
	x: int,
	y: int
) -> int:
	var top_left := int(grid[y][x])
	var top_right := int(grid[y][x + 1])
	var bottom_left := int(grid[y + 1][x])
	var bottom_right := int(grid[y + 1][x + 1])

	return (
		(top_left << 3)
		| (top_right << 2)
		| (bottom_left << 1)
		| bottom_right
	)


## Returns whether the grid contains at least one complete 2x2 area.
func _has_valid_2x2_area(grid: Array) -> bool:
	if grid.size() < 2:
		return false

	return (
		grid[0].size() >= 2
		and grid[1].size() >= 2
	)
