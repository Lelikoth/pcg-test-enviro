class_name RandomWalkGenerator
extends BaseGenerator

## Generates maps using a cardinal-direction random walk.
##
## The generator repeatedly moves one tile in one of four cardinal directions.
## Every visited tile is converted to floor, producing an irregular but
## internally connected walkable region.


const CARDINAL_DIRECTIONS: Array[Vector2i] = [
	Vector2i.RIGHT,
	Vector2i.LEFT,
	Vector2i.DOWN,
	Vector2i.UP
]


## Returns the identifier used for this generator in test results and exports.
func get_algorithm_name() -> String:
	return "RandomWalk"


## Generates a map using the Random Walk algorithm.
##
## The configuration controls map dimensions, seed handling, number of walk
## steps, and the initial walker position. Endpoint selection and other common
## post-processing operations are handled separately by MapPostProcessor.
func generate_map(config: Dictionary) -> Dictionary:
	var width: int = config.get("width", 64)
	var height: int = config.get("height", 64)

	var use_random_seed: bool = config.get("random_seed", true)
	var seed_value: int = config.get("seed", 0)

	var steps: int = config.get("rw_steps", 500)
	var start_from_center: bool = config.get(
		"rw_start_from_center",
		true
	)

	var rng := RandomNumberGenerator.new()

	if use_random_seed:
		rng.randomize()
		seed_value = rng.randi()

	rng.seed = seed_value

	var grid := _create_filled_grid(
		width,
		height,
		MapTypes.WALL
	)

	var current_position: Vector2i

	if start_from_center:
		current_position = Vector2i(
			width / 2,
			height / 2
		)
	else:
		current_position = Vector2i(
			rng.randi_range(1, width - 2),
			rng.randi_range(1, height - 2)
		)

	grid[current_position.y][current_position.x] = MapTypes.FLOOR

	for _step in range(steps):
		var direction: Vector2i = CARDINAL_DIRECTIONS[
			rng.randi_range(
				0,
				CARDINAL_DIRECTIONS.size() - 1
			)
		]

		var next_position := current_position + direction

		# Preserve a one-tile wall border around the generated map.
		next_position.x = clampi(
			next_position.x,
			1,
			width - 2
		)

		next_position.y = clampi(
			next_position.y,
			1,
			height - 2
		)

		current_position = next_position
		grid[current_position.y][current_position.x] = MapTypes.FLOOR

	return {
		"grid": grid,
		"rooms": [],
		"algorithm": get_algorithm_name(),
		"seed": seed_value
	}


## Creates a rectangular grid initialized with the provided tile value.
func _create_filled_grid(
	width: int,
	height: int,
	value: int
) -> Array:
	var grid: Array = []

	for _y in range(height):
		var row: Array = []

		for _x in range(width):
			row.append(value)

		grid.append(row)

	return grid
