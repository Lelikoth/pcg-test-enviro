class_name PerlinNoiseGenerator
extends BaseGenerator

## Generates binary maps from a two-dimensional Perlin noise field.
##
## FastNoiseLite is sampled independently for every map cell. Noise values
## below the configured threshold are converted to floor, while the remaining
## cells become walls.


## Returns the identifier used for this generator in test results and exports.
func get_algorithm_name() -> String:
	return "PerlinNoise"


## Generates a map using Perlin noise provided by FastNoiseLite.
##
## The configuration controls map dimensions, seed handling, noise frequency,
## threshold, and fractal octave count. Endpoint selection is handled
## separately by MapPostProcessor.
func generate_map(config: Dictionary) -> Dictionary:
	var width: int = config.get("width", 64)
	var height: int = config.get("height", 64)

	var use_random_seed: bool = config.get("random_seed", true)
	var seed_value: int = config.get("seed", 0)

	var frequency: float = config.get(
		"noise_frequency",
		0.05
	)

	var threshold: float = config.get(
		"noise_threshold",
		0.0
	)

	var octaves: int = config.get(
		"noise_fractal_octaves",
		3
	)

	if use_random_seed:
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		seed_value = rng.randi()

	var noise := FastNoiseLite.new()

	noise.seed = seed_value
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = frequency
	noise.fractal_octaves = octaves

	var grid := _generate_noise_grid(
		width,
		height,
		noise,
		threshold
	)

	_make_borders_walls(grid)

	return {
		"grid": grid,
		"rooms": [],
		"algorithm": get_algorithm_name(),
		"seed": seed_value
	}


## Converts sampled noise values into a binary floor/wall grid.
func _generate_noise_grid(
	width: int,
	height: int,
	noise: FastNoiseLite,
	threshold: float
) -> Array:
	var grid: Array = []

	for y in range(height):
		var row: Array = []

		for x in range(width):
			var noise_value: float = noise.get_noise_2d(
				float(x),
				float(y)
			)

			if noise_value < threshold:
				row.append(MapTypes.FLOOR)
			else:
				row.append(MapTypes.WALL)

		grid.append(row)

	return grid


## Forces the outermost map cells to be walls.
func _make_borders_walls(grid: Array) -> void:
	if grid.is_empty():
		return

	if grid[0].is_empty():
		return

	var height: int = grid.size()
	var width: int = grid[0].size()

	for x in range(width):
		grid[0][x] = MapTypes.WALL
		grid[height - 1][x] = MapTypes.WALL

	for y in range(height):
		grid[y][0] = MapTypes.WALL
		grid[y][width - 1] = MapTypes.WALL
