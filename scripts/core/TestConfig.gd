extends RefCounted
class_name TestConfig

var width: int = 64
var height: int = 64
var seed: int = 0
var random_seed: bool = true
var save_png: bool = true
var save_csv: bool = true
var runs_per_algorithm: int = 10

# Save only first N PNG files in batch to reduce clutter
var max_pngs_per_batch: int = 5

# If enabled, fixed 3x3 start/end rooms are carved after generation
var use_fixed_start_end_rooms: bool = false

# If enabled, keep only the connected walkable area reachable from start
var keep_only_reachable_area_from_start: bool = false

# Random Walk parameters
var rw_steps: int = 500
var rw_start_from_center: bool = true

# ProcGen parameters
var procgen_room_amount: int = 12
var procgen_automaton_iterations: int = 0
var procgen_automaton_threads: int = 1

# Perlin / FastNoiseLite parameters
var noise_frequency: float = 0.05
var noise_threshold: float = 0.0
var noise_fractal_octaves: int = 3

# Cellular Automata parameters
var ca_fill_probability: float = 0.45
var ca_iterations: int = 5
var ca_birth_limit: int = 4
var ca_death_limit: int = 3

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

		"noise_frequency": noise_frequency,
		"noise_threshold": noise_threshold,
		"noise_fractal_octaves": noise_fractal_octaves,
		
		"ca_fill_probability": ca_fill_probability,
		"ca_iterations": ca_iterations,
		"ca_birth_limit": ca_birth_limit,
		"ca_death_limit": ca_death_limit,
	}
