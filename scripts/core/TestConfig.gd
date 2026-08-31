extends RefCounted
class_name TestConfig

## Stores the complete configuration of a generation test.
##
## The configuration contains common test settings and parameters specific
## to each procedural generation algorithm. It is converted to a Dictionary
## before being passed to generator adapters and other test components.


# -----------------------------------------------------------------------------
# Common test settings
# -----------------------------------------------------------------------------

## Requested output map dimensions in tiles.
var width: int = 64
var height: int = 64

## Seed used for deterministic generation when random_seed is disabled.
var seed: int = 0

## If enabled, the generator uses a randomly generated seed instead of seed.
var random_seed: bool = true

## Controls result export.
var save_png: bool = true
var save_csv: bool = true

## Number of maps generated during a batch test.
var runs_per_algorithm: int = 10

## Maximum number of map images saved during a single batch.
## Limiting PNG export prevents large batches from producing excessive files.
var max_pngs_per_batch: int = 5


# -----------------------------------------------------------------------------
# Common map post-processing
# -----------------------------------------------------------------------------

## Legacy option retained from an earlier version of the testing environment.
## If enabled, fixed 3x3 start and end rooms are carved during post-processing.
## This option is not used in the final experiments.
var use_fixed_start_end_rooms: bool = false

## Optional reachability filtering retained by generators that support it.
##
## The option is currently handled internally by selected generators rather
## than by the common MapPostProcessor. Its final role is reviewed separately
## during the test-pipeline audit.
var keep_only_reachable_area_from_start: bool = false


# -----------------------------------------------------------------------------
# Random Walk
# -----------------------------------------------------------------------------

## Maximum number of movement steps performed by the walker.
var rw_steps: int = 500

## If enabled, the walk begins at the center of the generated map.
var rw_start_from_center: bool = true


# -----------------------------------------------------------------------------
# ProcGenHybrid
# -----------------------------------------------------------------------------

## ProcGenHybrid combines BSP-based room placement, A* corridor generation
## and cellular-automata-based map shaping.

## Target number of generated rooms.
var procgen_room_amount: int = 14

## Number of cellular automata shaping iterations.
## A value of 0 disables the automaton stage.
var procgen_automaton_iterations: int = 2

## Compatibility field retained from an earlier version of the test
## configuration. ProcGenHybridAdapter always forces single-threaded
## generation by setting the corresponding ProcGen value to 0.
## This field is not an active experimental parameter.
var procgen_automaton_threads: int = 0

## Minimum and maximum room coverage within the assigned generation zone.
var procgen_room_min_coverage: float = 0.16
var procgen_room_max_coverage: float = 0.34

## Controls how strongly generated rooms are positioned toward zone centers.
var procgen_room_center_ratio: float = 0.75

## Probability of creating additional corridor connections between rooms.
var procgen_corridor_cycle_chance: float = 0.08

## Probability of introducing noise during cellular automata shaping.
## The effective value is forced to 0 when the automaton stage is disabled.
var procgen_automaton_noise_rate: float = 0.28

## Maximum ratio used when splitting generation zones.
var procgen_zone_split_max_ratio: float = 0.5

## Probability of using the inverse orientation of the parent zone during
## recursive subdivision.
var procgen_zone_parent_inverse_orientation_chance: float = 0.85

## Minimum and maximum allowed room aspect ratio expressed by ProcGen
## as a squared-ratio constraint.
var procgen_room_min_squared_ratio: float = 0.35
var procgen_room_max_squared_ratio: float = 1.0

## Minimum overlap ratio required when connecting corridor edges.
var procgen_corridor_edge_overlap_min_ratio: float = 0.20

## Cellular automata configuration used by ProcGenHybrid.
var procgen_automaton_flood_fill: bool = true
var procgen_automaton_cell_min_neighbors: int = 4
var procgen_automaton_cell_max_neighbors: int = 8
var procgen_automaton_smoothing_step_cell_min_neighbors: int = 4

## Optional expansion values applied to selected ProcGenHybrid structures.
var procgen_automaton_zones_fixed_outline_expand: int = 0
var procgen_automaton_corridor_fixed_width_expand: int = 0
var procgen_automaton_corridor_non_fixed_width_expand: int = 0


# -----------------------------------------------------------------------------
# Perlin Noise / FastNoiseLite
# -----------------------------------------------------------------------------

## Spatial frequency of the generated noise field.
var noise_frequency: float = 0.05

## Threshold separating walkable and non-walkable cells.
var noise_threshold: float = 0.0

## Number of fractal noise octaves used by FastNoiseLite.
var noise_fractal_octaves: int = 3


# -----------------------------------------------------------------------------
# Cellular Automata
# -----------------------------------------------------------------------------

## Parameters corresponding to the analyzed Procedural-Map-Generator addon.
##
## The addon uses an initial fill probability followed by repeated smoothing
## based on a wall-neighbor threshold. It does not expose separate birth and
## death limits.

## Probability that a cell is initialized as a wall.
var ca_fill_probability: float = 0.45

## Number of cellular automata smoothing iterations.
var ca_iterations: int = 5

## Width of the forced wall border surrounding the generated map.
var ca_border_width: int = 1

## Neighbor threshold used by the cellular automata smoothing rule.
var ca_wall_threshold: int = 4


# -----------------------------------------------------------------------------
# Module WFC
# -----------------------------------------------------------------------------

## Dimensions of the WFC module grid.
var wfc_module_grid_width: int = 8
var wfc_module_grid_height: int = 8

## Maximum number of complete WFC generation attempts.
##
## The name is retained for compatibility with the existing test environment.
## A value of 20 permits at most 20 attempts in total, not 20 retries after
## an initial attempt.
var wfc_max_retries: int = 20

## Minimum composition requirements enforced for generated WFC maps.
var wfc_min_small_corridors: int = 4
var wfc_min_medium_rooms: int = 2
var wfc_min_large_rooms: int = 1


# -----------------------------------------------------------------------------
# Serialization
# -----------------------------------------------------------------------------

## Converts the configuration to the Dictionary format consumed by the
## test runner and generator adapters.
func to_dictionary() -> Dictionary:
	return {
		# Common settings
		"width": width,
		"height": height,
		"seed": seed,
		"random_seed": random_seed,
		"save_png": save_png,
		"save_csv": save_csv,
		"runs_per_algorithm": runs_per_algorithm,
		"max_pngs_per_batch": max_pngs_per_batch,

		# Common post-processing
		"use_fixed_start_end_rooms": use_fixed_start_end_rooms,
		"keep_only_reachable_area_from_start": keep_only_reachable_area_from_start,

		# Random Walk
		"rw_steps": rw_steps,
		"rw_start_from_center": rw_start_from_center,

		# ProcGenHybrid
		"procgen_room_amount": procgen_room_amount,
		"procgen_automaton_iterations": procgen_automaton_iterations,
		"procgen_automaton_threads": procgen_automaton_threads,
		"procgen_room_min_coverage": procgen_room_min_coverage,
		"procgen_room_max_coverage": procgen_room_max_coverage,
		"procgen_room_center_ratio": procgen_room_center_ratio,
		"procgen_corridor_cycle_chance": procgen_corridor_cycle_chance,
		"procgen_automaton_noise_rate": _get_effective_procgen_noise_rate(),
		"procgen_zone_split_max_ratio": procgen_zone_split_max_ratio,
		"procgen_zone_parent_inverse_orientation_chance": procgen_zone_parent_inverse_orientation_chance,
		"procgen_room_min_squared_ratio": procgen_room_min_squared_ratio,
		"procgen_room_max_squared_ratio": procgen_room_max_squared_ratio,
		"procgen_corridor_edge_overlap_min_ratio": procgen_corridor_edge_overlap_min_ratio,
		"procgen_automaton_flood_fill": procgen_automaton_flood_fill,
		"procgen_automaton_cell_min_neighbors": procgen_automaton_cell_min_neighbors,
		"procgen_automaton_cell_max_neighbors": procgen_automaton_cell_max_neighbors,
		"procgen_automaton_smoothing_step_cell_min_neighbors": procgen_automaton_smoothing_step_cell_min_neighbors,
		"procgen_automaton_zones_fixed_outline_expand": procgen_automaton_zones_fixed_outline_expand,
		"procgen_automaton_corridor_fixed_width_expand": procgen_automaton_corridor_fixed_width_expand,
		"procgen_automaton_corridor_non_fixed_width_expand": procgen_automaton_corridor_non_fixed_width_expand,

		# Perlin Noise
		"noise_frequency": noise_frequency,
		"noise_threshold": noise_threshold,
		"noise_fractal_octaves": noise_fractal_octaves,

		# Cellular Automata
		"ca_fill_probability": ca_fill_probability,
		"ca_iterations": ca_iterations,
		"ca_border_width": ca_border_width,
		"ca_wall_threshold": ca_wall_threshold,

		# Module WFC
		"wfc_module_grid_width": wfc_module_grid_width,
		"wfc_module_grid_height": wfc_module_grid_height,
		"wfc_max_retries": wfc_max_retries,
		"wfc_min_small_corridors": wfc_min_small_corridors,
		"wfc_min_medium_rooms": wfc_min_medium_rooms,
		"wfc_min_large_rooms": wfc_min_large_rooms
	}


## Returns the ProcGenHybrid noise rate actually passed to the generator.
## Noise has no effect when the cellular automata stage is disabled.
func _get_effective_procgen_noise_rate() -> float:
	if procgen_automaton_iterations <= 0:
		return 0.0

	return procgen_automaton_noise_rate
