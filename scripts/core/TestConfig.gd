extends RefCounted
class_name TestConfig

var width: int = 64
var height: int = 64
var seed: int = 0
var random_seed: bool = true
var save_png: bool = true
var save_csv: bool = true
var runs_per_algorithm: int = 10

# Save only first N PNG files in batch to reduce clutter.
var max_pngs_per_batch: int = 5

# If enabled, fixed 3x3 start/end rooms are carved after generation.
var use_fixed_start_end_rooms: bool = false

# If enabled, keep only the connected walkable area reachable from start.
var keep_only_reachable_area_from_start: bool = false


# Random Walk parameters
var rw_steps: int = 500
var rw_start_from_center: bool = true


# ProcGen parameters
#
# ProcGen is a hybrid generator:
# BSP rooms + A* corridors + light cellular automata shaping.
#
# Current default preset:
# Dungeon-oriented, with slight organic variation.
var procgen_room_amount: int = 14

# 2 gives a small amount of organic shaping without turning the map into a cave.
# Use 0 only for a clean room/corridor dungeon.
var procgen_automaton_iterations: int = 2

# 0 is safest and avoids threading-related timing issues during benchmarks.
var procgen_automaton_threads: int = 0

# Smaller coverage prevents gigantic rooms.
var procgen_room_min_coverage: float = 0.16
var procgen_room_max_coverage: float = 0.34

# Higher value keeps rooms fairly centered and dungeon-like.
var procgen_room_center_ratio: float = 0.75

# A few alternative paths, but not spaghetti.
var procgen_corridor_cycle_chance: float = 0.08

# Light organic variation.
# If procgen_automaton_iterations is 0, to_dictionary() forces this to 0.0.
var procgen_automaton_noise_rate: float = 0.28


# Perlin / FastNoiseLite parameters
var noise_frequency: float = 0.05
var noise_threshold: float = 0.0
var noise_fractal_octaves: int = 3


# Cellular Automata parameters
#
# This follows the analyzed Procedural-Map-Generator addon.
# The original addon does not use separate birth/death limits.
# It uses:
# - density / fill probability
# - smoothing iterations
# - border width
# - fixed wall threshold = 4 inside the adapter
var ca_fill_probability: float = 0.45
var ca_iterations: int = 5
var ca_border_width: int = 1


# Module WFC parameters
var wfc_module_grid_width: int = 8
var wfc_module_grid_height: int = 8
var wfc_max_retries: int = 20


# Module WFC composition requirements
var wfc_min_small_corridors: int = 4
var wfc_min_medium_rooms: int = 2
var wfc_min_large_rooms: int = 1


func to_dictionary() -> Dictionary:
	return {
		"width": width,
		"height": height,
		"seed": seed,
		"random_seed": random_seed,
		"save_png": save_png,
		"save_csv": save_csv,
		"runs_per_algorithm": runs_per_algorithm,
		"max_pngs_per_batch": max_pngs_per_batch,
		"use_fixed_start_end_rooms": use_fixed_start_end_rooms,
		"keep_only_reachable_area_from_start": keep_only_reachable_area_from_start,

		"rw_steps": rw_steps,
		"rw_start_from_center": rw_start_from_center,

		"procgen_room_amount": procgen_room_amount,
		"procgen_automaton_iterations": procgen_automaton_iterations,
		"procgen_automaton_threads": procgen_automaton_threads,
		"procgen_room_min_coverage": procgen_room_min_coverage,
		"procgen_room_max_coverage": procgen_room_max_coverage,
		"procgen_room_center_ratio": procgen_room_center_ratio,
		"procgen_corridor_cycle_chance": procgen_corridor_cycle_chance,
		"procgen_automaton_noise_rate": 0.0 if procgen_automaton_iterations <= 0 else procgen_automaton_noise_rate,

		"noise_frequency": noise_frequency,
		"noise_threshold": noise_threshold,
		"noise_fractal_octaves": noise_fractal_octaves,

		"ca_fill_probability": ca_fill_probability,
		"ca_iterations": ca_iterations,
		"ca_border_width": ca_border_width,

		"wfc_module_grid_width": wfc_module_grid_width,
		"wfc_module_grid_height": wfc_module_grid_height,
		"wfc_max_retries": wfc_max_retries,

		"wfc_min_small_corridors": wfc_min_small_corridors,
		"wfc_min_medium_rooms": wfc_min_medium_rooms,
		"wfc_min_large_rooms": wfc_min_large_rooms
	}
