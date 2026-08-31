class_name MainUIController
extends Control

## Coordinates the testing environment user interface.
##
## The controller synchronizes UI controls with TestConfig, starts single
## and batch generation through TestRunner, displays generated maps and
## metrics, and presents runtime log messages.


# General controls.
@onready var algorithm_option: OptionButton = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/GeneralSectionRoot/ContentContainer/AlgorithmOption
@onready var width_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/GeneralSectionRoot/ContentContainer/WidthSpin
@onready var height_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/GeneralSectionRoot/ContentContainer/HeightSpin
@onready var runs_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/GeneralSectionRoot/ContentContainer/RunsSpin
@onready var max_pngs_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/GeneralSectionRoot/ContentContainer/MaxPNGsSpin

@onready var random_seed_check: CheckBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/GeneralSectionRoot/ContentContainer/RandomSeedCheck
@onready var seed_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/GeneralSectionRoot/ContentContainer/SeedSpin

@onready var fixed_start_end_check: CheckBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/FixedStartEndCheck
@onready var reachable_area_check: CheckBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/ReachableAreaCheck
@onready var save_png_check: CheckBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/SavePNGCheck
@onready var save_csv_check: CheckBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/SaveCSVCheck
@onready var generate_button: Button = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/GenerateButton
@onready var batch_button: Button = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/BatchButton


# Random Walk controls.
@onready var steps_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/RandomWalkSectionRoot/ContentContainer/StepsSpin


# ProcGen Hybrid controls.
@onready var procgen_rooms_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/ProcGenSectionRoot/ContentContainer/ProcGenRoomsSpin
@onready var procgen_iterations_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/ProcGenSectionRoot/ContentContainer/ProcGenIterationsSpin
@onready var procgen_room_min_coverage_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/ProcGenSectionRoot/ContentContainer/ProcGenRoomMinCoverageSpin
@onready var procgen_room_max_coverage_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/ProcGenSectionRoot/ContentContainer/ProcGenRoomMaxCoverageSpin
@onready var procgen_room_center_ratio_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/ProcGenSectionRoot/ContentContainer/ProcGenRoomCenterRatioSpin
@onready var procgen_corridor_cycle_chance_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/ProcGenSectionRoot/ContentContainer/ProcGenCorridorCycleChanceSpin
@onready var procgen_automaton_noise_rate_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/ProcGenSectionRoot/ContentContainer/ProcGenAutomatonNoiseRateSpin
@onready var procgen_zone_split_max_ratio_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/ProcGenSectionRoot/ContentContainer/ProcGenZoneSplitMaxRatioSpin
@onready var procgen_zone_inverse_orientation_chance_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/ProcGenSectionRoot/ContentContainer/ProcGenZoneInverseOrientationChanceSpin
@onready var procgen_room_min_squared_ratio_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/ProcGenSectionRoot/ContentContainer/ProcGenRoomMinSquaredRatioSpin
@onready var procgen_room_max_squared_ratio_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/ProcGenSectionRoot/ContentContainer/ProcGenRoomMaxSquaredRatioSpin
@onready var procgen_corridor_edge_overlap_min_ratio_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/ProcGenSectionRoot/ContentContainer/ProcGenCorridorEdgeOverlapMinRatioSpin
@onready var procgen_automaton_cell_min_neighbors_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/ProcGenSectionRoot/ContentContainer/ProcGenAutomatonCellMinNeighborsSpin
@onready var procgen_automaton_cell_max_neighbors_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/ProcGenSectionRoot/ContentContainer/ProcGenAutomatonCellMaxNeighborsSpin
@onready var procgen_automaton_smoothing_min_neighbors_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/ProcGenSectionRoot/ContentContainer/ProcGenAutomatonSmoothingMinNeighborsSpin


# Perlin Noise controls.
@onready var noise_frequency_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/NoiseSectionRoot/ContentContainer/NoiseFrequencySpin
@onready var noise_threshold_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/NoiseSectionRoot/ContentContainer/NoiseThresholdSpin
@onready var noise_octaves_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/NoiseSectionRoot/ContentContainer/NoiseOctavesSpin


# Cellular Automata controls.
@onready var ca_fill_prob_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/CellularSectionRoot/ContentContainer/CAFillProbabilitySpin
@onready var ca_iterations_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/CellularSectionRoot/ContentContainer/CAIterationsSpin
@onready var ca_border_width_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/CellularSectionRoot/ContentContainer/CABorderWidthSpin
@onready var ca_wall_threshold_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/CellularSectionRoot/ContentContainer/CAWallThresholdSpin


# Module WFC controls.
@onready var wfc_module_grid_width_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/ModuleWFCSectionRoot/ContentContainer/WFCModuleGridWidthSpin
@onready var wfc_module_grid_height_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/ModuleWFCSectionRoot/ContentContainer/WFCModuleGridHeightSpin
@onready var wfc_max_retries_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/ModuleWFCSectionRoot/ContentContainer/WFCMaxRetriesSpin
@onready var wfc_min_small_corridors_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/ModuleWFCSectionRoot/ContentContainer/WFCMinSmallCorridorsSpin
@onready var wfc_min_medium_rooms_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/ModuleWFCSectionRoot/ContentContainer/WFCMinMediumRoomsSpin
@onready var wfc_min_large_rooms_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/ModuleWFCSectionRoot/ContentContainer/WFCMinLargeRoomsSpin


# Output controls.
@onready var preview_texture: TextureRect = $RootContainer/CenterPanel/PreviewVBox/PreviewTexture
@onready var metrics_label: RichTextLabel = $RootContainer/RightPanel/InfoVBox/MetricsLabel
@onready var log_label: RichTextLabel = $RootContainer/RightPanel/InfoVBox/LogLabel


@onready var test_runner: TestRunner = $TestRunner


func _ready() -> void:
	_populate_algorithms()
	_apply_default_config_to_ui()
	_connect_signals()

	_update_seed_editability(
		random_seed_check.button_pressed
	)

	_append_log("Test environment ready.")


## Connects UI and TestRunner signals used by the controller.
func _connect_signals() -> void:
	test_runner.generation_finished.connect(
		_on_generation_finished
	)

	test_runner.batch_finished.connect(
		_on_batch_finished
	)

	test_runner.log_message.connect(
		_append_log
	)

	generate_button.pressed.connect(
		_on_generate_pressed
	)

	batch_button.pressed.connect(
		_on_batch_pressed
	)

	random_seed_check.toggled.connect(
		_on_random_seed_toggled
	)


## Populates the algorithm selector using generators registered in TestRunner.
func _populate_algorithms() -> void:
	algorithm_option.clear()

	var algorithm_names: Array[String] = (
		test_runner.get_algorithm_names()
	)

	for algorithm_name in algorithm_names:
		algorithm_option.add_item(
			algorithm_name
		)


## Applies a fresh TestConfig instance to all UI controls.
func _apply_default_config_to_ui() -> void:
	var config: TestConfig = TestConfig.new()

	_apply_general_defaults(config)
	_apply_random_walk_defaults(config)
	_apply_procgen_defaults(config)
	_apply_perlin_defaults(config)
	_apply_cellular_defaults(config)
	_apply_wfc_defaults(config)


func _apply_general_defaults(config: TestConfig) -> void:
	width_spin.value = config.width
	height_spin.value = config.height
	runs_spin.value = config.runs_per_algorithm
	max_pngs_spin.value = config.max_pngs_per_batch

	fixed_start_end_check.button_pressed = (
		config.use_fixed_start_end_rooms
	)

	reachable_area_check.button_pressed = (
		config.keep_only_reachable_area_from_start
	)

	random_seed_check.button_pressed = config.random_seed
	seed_spin.value = config.seed

	save_png_check.button_pressed = config.save_png
	save_csv_check.button_pressed = config.save_csv


func _apply_random_walk_defaults(
	config: TestConfig
) -> void:
	steps_spin.value = config.rw_steps


func _apply_procgen_defaults(
	config: TestConfig
) -> void:
	procgen_rooms_spin.value = (
		config.procgen_room_amount
	)

	procgen_iterations_spin.value = (
		config.procgen_automaton_iterations
	)

	procgen_room_min_coverage_spin.value = (
		config.procgen_room_min_coverage
	)

	procgen_room_max_coverage_spin.value = (
		config.procgen_room_max_coverage
	)

	procgen_room_center_ratio_spin.value = (
		config.procgen_room_center_ratio
	)

	procgen_corridor_cycle_chance_spin.value = (
		config.procgen_corridor_cycle_chance
	)

	procgen_automaton_noise_rate_spin.value = (
		config.procgen_automaton_noise_rate
	)

	procgen_zone_split_max_ratio_spin.value = (
		config.procgen_zone_split_max_ratio
	)

	procgen_zone_inverse_orientation_chance_spin.value = (
		config.procgen_zone_parent_inverse_orientation_chance
	)

	procgen_room_min_squared_ratio_spin.value = (
		config.procgen_room_min_squared_ratio
	)

	procgen_room_max_squared_ratio_spin.value = (
		config.procgen_room_max_squared_ratio
	)

	procgen_corridor_edge_overlap_min_ratio_spin.value = (
		config.procgen_corridor_edge_overlap_min_ratio
	)

	procgen_automaton_cell_min_neighbors_spin.value = (
		config.procgen_automaton_cell_min_neighbors
	)

	procgen_automaton_cell_max_neighbors_spin.value = (
		config.procgen_automaton_cell_max_neighbors
	)

	procgen_automaton_smoothing_min_neighbors_spin.value = (
		config.procgen_automaton_smoothing_step_cell_min_neighbors
	)


func _apply_perlin_defaults(
	config: TestConfig
) -> void:
	noise_frequency_spin.value = config.noise_frequency
	noise_threshold_spin.value = config.noise_threshold
	noise_octaves_spin.value = config.noise_fractal_octaves


func _apply_cellular_defaults(
	config: TestConfig
) -> void:
	ca_fill_prob_spin.value = config.ca_fill_probability
	ca_iterations_spin.value = config.ca_iterations
	ca_border_width_spin.value = config.ca_border_width
	ca_wall_threshold_spin.value = config.ca_wall_threshold


func _apply_wfc_defaults(
	config: TestConfig
) -> void:
	wfc_module_grid_width_spin.value = (
		config.wfc_module_grid_width
	)

	wfc_module_grid_height_spin.value = (
		config.wfc_module_grid_height
	)

	wfc_max_retries_spin.value = (
		config.wfc_max_retries
	)

	wfc_min_small_corridors_spin.value = (
		config.wfc_min_small_corridors
	)

	wfc_min_medium_rooms_spin.value = (
		config.wfc_min_medium_rooms
	)

	wfc_min_large_rooms_spin.value = (
		config.wfc_min_large_rooms
	)


## Builds a TestConfig instance from the current UI state.
func _build_config() -> TestConfig:
	var config: TestConfig = TestConfig.new()

	_read_general_config(config)
	_read_random_walk_config(config)
	_read_procgen_config(config)
	_read_perlin_config(config)
	_read_cellular_config(config)
	_read_wfc_config(config)

	return config


func _read_general_config(
	config: TestConfig
) -> void:
	config.width = int(width_spin.value)
	config.height = int(height_spin.value)

	config.runs_per_algorithm = int(
		runs_spin.value
	)

	config.max_pngs_per_batch = int(
		max_pngs_spin.value
	)

	config.use_fixed_start_end_rooms = (
		fixed_start_end_check.button_pressed
	)

	config.keep_only_reachable_area_from_start = (
		reachable_area_check.button_pressed
	)

	config.random_seed = (
		random_seed_check.button_pressed
	)

	config.seed = int(seed_spin.value)

	config.save_png = save_png_check.button_pressed
	config.save_csv = save_csv_check.button_pressed


func _read_random_walk_config(
	config: TestConfig
) -> void:
	config.rw_steps = int(
		steps_spin.value
	)


func _read_procgen_config(
	config: TestConfig
) -> void:
	config.procgen_room_amount = int(
		procgen_rooms_spin.value
	)

	config.procgen_automaton_iterations = int(
		procgen_iterations_spin.value
	)

	# Threading remains disabled to keep benchmark execution stable
	# and comparable between runs.
	config.procgen_automaton_threads = 0

	config.procgen_room_min_coverage = float(
		procgen_room_min_coverage_spin.value
	)

	config.procgen_room_max_coverage = float(
		procgen_room_max_coverage_spin.value
	)

	config.procgen_room_center_ratio = float(
		procgen_room_center_ratio_spin.value
	)

	config.procgen_corridor_cycle_chance = float(
		procgen_corridor_cycle_chance_spin.value
	)

	config.procgen_automaton_noise_rate = float(
		procgen_automaton_noise_rate_spin.value
	)

	if config.procgen_automaton_iterations <= 0:
		config.procgen_automaton_noise_rate = 0.0

	_normalize_procgen_coverage(config)

	config.procgen_zone_split_max_ratio = float(
		procgen_zone_split_max_ratio_spin.value
	)

	config.procgen_zone_parent_inverse_orientation_chance = float(
		procgen_zone_inverse_orientation_chance_spin.value
	)

	config.procgen_room_min_squared_ratio = float(
		procgen_room_min_squared_ratio_spin.value
	)

	config.procgen_room_max_squared_ratio = float(
		procgen_room_max_squared_ratio_spin.value
	)

	config.procgen_corridor_edge_overlap_min_ratio = float(
		procgen_corridor_edge_overlap_min_ratio_spin.value
	)

	config.procgen_automaton_cell_min_neighbors = int(
		procgen_automaton_cell_min_neighbors_spin.value
	)

	config.procgen_automaton_cell_max_neighbors = int(
		procgen_automaton_cell_max_neighbors_spin.value
	)

	config.procgen_automaton_smoothing_step_cell_min_neighbors = int(
		procgen_automaton_smoothing_min_neighbors_spin.value
	)


## Ensures that the ProcGen minimum coverage does not exceed its maximum.
func _normalize_procgen_coverage(
	config: TestConfig
) -> void:
	if (
		config.procgen_room_min_coverage
		<= config.procgen_room_max_coverage
	):
		return

	var temporary_value: float = (
		config.procgen_room_min_coverage
	)

	config.procgen_room_min_coverage = (
		config.procgen_room_max_coverage
	)

	config.procgen_room_max_coverage = temporary_value


func _read_perlin_config(
	config: TestConfig
) -> void:
	config.noise_frequency = float(
		noise_frequency_spin.value
	)

	config.noise_threshold = float(
		noise_threshold_spin.value
	)

	config.noise_fractal_octaves = int(
		noise_octaves_spin.value
	)


func _read_cellular_config(
	config: TestConfig
) -> void:
	config.ca_fill_probability = float(
		ca_fill_prob_spin.value
	)

	config.ca_iterations = int(
		ca_iterations_spin.value
	)

	config.ca_border_width = int(
		ca_border_width_spin.value
	)

	config.ca_wall_threshold = int(
		ca_wall_threshold_spin.value
	)


func _read_wfc_config(
	config: TestConfig
) -> void:
	config.wfc_module_grid_width = int(
		wfc_module_grid_width_spin.value
	)

	config.wfc_module_grid_height = int(
		wfc_module_grid_height_spin.value
	)

	config.wfc_max_retries = int(
		wfc_max_retries_spin.value
	)

	config.wfc_min_small_corridors = int(
		wfc_min_small_corridors_spin.value
	)

	config.wfc_min_medium_rooms = int(
		wfc_min_medium_rooms_spin.value
	)

	config.wfc_min_large_rooms = int(
		wfc_min_large_rooms_spin.value
	)


## Returns the currently selected generation algorithm.
func _get_selected_algorithm() -> String:
	return algorithm_option.get_item_text(
		algorithm_option.selected
	)


func _on_generate_pressed() -> void:
	var config := _build_config()
	var algorithm := _get_selected_algorithm()

	test_runner.generate_single(
		config,
		algorithm
	)


func _on_batch_pressed() -> void:
	var config := _build_config()
	var algorithm := _get_selected_algorithm()

	test_runner.run_batch(
		config,
		algorithm
	)


func _on_generation_finished(
	_map_data: Dictionary,
	metrics: Dictionary,
	image: Image,
	png_path: String
) -> void:
	var texture := ImageTexture.create_from_image(
		image
	)

	preview_texture.texture = texture
	metrics_label.text = _format_metrics(metrics)

	if not png_path.is_empty():
		_append_log(
			"Single generation PNG: %s"
			% png_path
		)


func _on_batch_finished(
	results: Array
) -> void:
	if results.is_empty():
		_append_log(
			"Batch finished, but no results were returned."
		)
		return

	var last_result: Dictionary = results[
		results.size() - 1
	]

	metrics_label.text = _format_metrics(
		last_result
	)

	_append_log(
		"Batch finished. Total results: %d"
		% results.size()
	)


## Formats calculated metrics for display in the RichTextLabel.
func _format_metrics(
	metrics: Dictionary
) -> String:
	var lines: Array[String] = []
	var algorithm := str(
		metrics.get("algorithm", "")
	)

	_append_basic_metrics(lines, metrics)
	_append_performance_metrics(lines, metrics)
	_append_tile_metrics(lines, metrics)
	_append_path_metrics(lines, metrics)
	_append_region_metrics(lines, metrics)
	_append_shape_metrics(lines, metrics)
	_append_room_metrics(lines, metrics)

	if algorithm == "ProcGenHybrid":
		_append_procgen_metrics(
			lines,
			metrics
		)

	if algorithm == "ModuleWFC":
		_append_wfc_metrics(
			lines,
			metrics
		)

	_append_option_metrics(lines, metrics)

	return "\n".join(lines)


func _append_basic_metrics(
	lines: Array[String],
	metrics: Dictionary
) -> void:
	_append_section(lines, "Basic")

	_append_metric(
		lines,
		metrics,
		"Algorithm",
		"algorithm"
	)

	_append_metric(
		lines,
		metrics,
		"Seed",
		"seed"
	)

	lines.append(
		"Map size: %sx%s" % [
			str(metrics.get("map_width", "")),
			str(metrics.get("map_height", ""))
		]
	)

	_append_metric(
		lines,
		metrics,
		"Total cells",
		"total_cells"
	)


func _append_performance_metrics(
	lines: Array[String],
	metrics: Dictionary
) -> void:
	_append_section(lines, "Performance")

	_append_metric(
		lines,
		metrics,
		"Generation time [ms]",
		"generation_time_ms"
	)

	_append_metric(
		lines,
		metrics,
		"Time per cell [ms]",
		"time_per_cell_ms"
	)

	_append_metric(
		lines,
		metrics,
		"Time per floor cell [ms]",
		"time_per_floor_cell_ms"
	)

	_append_metric(
		lines,
		metrics,
		"Generation success",
		"generation_success"
	)

	_append_metric(
		lines,
		metrics,
		"Retry count",
		"retry_count"
	)

	if metrics.has("fallback_reason"):
		_append_metric(
			lines,
			metrics,
			"Fallback reason",
			"fallback_reason"
		)


func _append_tile_metrics(
	lines: Array[String],
	metrics: Dictionary
) -> void:
	_append_section(lines, "Tiles")

	_append_metric(lines, metrics, "Floor count", "floor_count")
	_append_metric(lines, metrics, "Wall count", "wall_count")
	_append_metric(lines, metrics, "Floor ratio", "floor_ratio")
	_append_metric(lines, metrics, "Wall ratio", "wall_ratio")

	_append_metric(
		lines,
		metrics,
		"Floor ratio in target range",
		"floor_ratio_in_target_range"
	)


func _append_path_metrics(
	lines: Array[String],
	metrics: Dictionary
) -> void:
	_append_section(lines, "Start / End / Path")

	lines.append(
		"Start: (%s, %s)" % [
			str(metrics.get("start_x", "")),
			str(metrics.get("start_y", ""))
		]
	)

	lines.append(
		"End: (%s, %s)" % [
			str(metrics.get("end_x", "")),
			str(metrics.get("end_y", ""))
		]
	)

	_append_metric(
		lines,
		metrics,
		"Valid start",
		"has_valid_start"
	)

	_append_metric(
		lines,
		metrics,
		"Valid end",
		"has_valid_end"
	)

	_append_metric(
		lines,
		metrics,
		"Connected start-end",
		"is_connected"
	)

	_append_metric(
		lines,
		metrics,
		"Path length",
		"path_length"
	)

	_append_metric(
		lines,
		metrics,
		"Euclidean distance",
		"start_end_euclidean_distance"
	)

	_append_metric(
		lines,
		metrics,
		"Path tortuosity",
		"path_tortuosity"
	)

	_append_metric(
		lines,
		metrics,
		"Path directness",
		"path_directness"
	)

	_append_metric(
		lines,
		metrics,
		"Farthest reachable path length",
		"farthest_reachable_path_length"
	)

	lines.append(
		"Farthest reachable: (%s, %s)" % [
			str(metrics.get("farthest_reachable_x", "")),
			str(metrics.get("farthest_reachable_y", ""))
		]
	)


func _append_region_metrics(
	lines: Array[String],
	metrics: Dictionary
) -> void:
	_append_section(
		lines,
		"Reachability / Open Regions"
	)

	_append_metric(
		lines,
		metrics,
		"Open region count",
		"open_region_count"
	)

	_append_metric(
		lines,
		metrics,
		"Largest open region area",
		"largest_open_region_area"
	)

	_append_metric(
		lines,
		metrics,
		"Largest open region ratio",
		"largest_open_region_ratio"
	)

	_append_metric(
		lines,
		metrics,
		"Average open region area",
		"average_open_region_area"
	)

	_append_metric(
		lines,
		metrics,
		"Reachable floor count from start",
		"reachable_floor_count_from_start"
	)

	_append_metric(
		lines,
		metrics,
		"Reachable floor ratio from start",
		"reachable_floor_ratio_from_start"
	)

	_append_metric(
		lines,
		metrics,
		"Unreachable floor count",
		"unreachable_floor_count"
	)

	_append_metric(
		lines,
		metrics,
		"Unreachable floor ratio",
		"unreachable_floor_ratio"
	)


func _append_shape_metrics(
	lines: Array[String],
	metrics: Dictionary
) -> void:
	_append_section(
		lines,
		"Shape / Local Complexity"
	)

	_append_metric(
		lines,
		metrics,
		"Floor-wall adjacency count",
		"floor_wall_adjacency_count"
	)

	_append_metric(
		lines,
		metrics,
		"Normalized perimeter",
		"normalized_perimeter"
	)

	_append_metric(
		lines,
		metrics,
		"Tile entropy",
		"tile_entropy"
	)

	_append_metric(
		lines,
		metrics,
		"Tile entropy normalized",
		"tile_entropy_normalized"
	)

	_append_metric(
		lines,
		metrics,
		"Pattern entropy 2x2",
		"pattern_entropy_2x2"
	)

	_append_metric(
		lines,
		metrics,
		"Pattern entropy 2x2 normalized",
		"pattern_entropy_2x2_normalized"
	)


func _append_room_metrics(
	lines: Array[String],
	metrics: Dictionary
) -> void:
	_append_section(lines, "Declared Rooms")

	_append_metric(
		lines,
		metrics,
		"Declared room count",
		"declared_room_count"
	)

	_append_metric(
		lines,
		metrics,
		"Largest declared room area",
		"largest_declared_room_area"
	)


func _append_procgen_metrics(
	lines: Array[String],
	metrics: Dictionary
) -> void:
	_append_section(lines, "ProcGen Structure")

	_append_metric(
		lines,
		metrics,
		"Corridor links",
		"procgen_corridor_link_count"
	)

	_append_metric(
		lines,
		metrics,
		"Dead-end rooms",
		"procgen_dead_end_room_count"
	)

	_append_metric(
		lines,
		metrics,
		"Room min degree",
		"procgen_room_connection_min_degree"
	)

	_append_metric(
		lines,
		metrics,
		"Room max degree",
		"procgen_room_connection_max_degree"
	)

	_append_metric(
		lines,
		metrics,
		"Room average degree",
		"procgen_room_connection_average_degree"
	)

	_append_metric(
		lines,
		metrics,
		"Cycle links",
		"procgen_cycle_link_count"
	)

	_append_metric(
		lines,
		metrics,
		"Has cycles",
		"procgen_has_cycles"
	)


func _append_wfc_metrics(
	lines: Array[String],
	metrics: Dictionary
) -> void:
	_append_section(lines, "Module WFC")

	_append_metric(lines, metrics, "Room modules", "room_module_count")
	_append_metric(lines, metrics, "Corridor modules", "corridor_module_count")
	_append_metric(lines, metrics, "Junction modules", "junction_module_count")
	_append_metric(lines, metrics, "Special modules", "special_module_count")

	_append_metric(lines, metrics, "Small rooms", "small_room_count")
	_append_metric(lines, metrics, "Medium rooms", "medium_room_count")
	_append_metric(lines, metrics, "Large rooms", "large_room_count")

	_append_metric(
		lines,
		metrics,
		"Dead-end modules",
		"dead_end_module_count"
	)

	_append_metric(
		lines,
		metrics,
		"Dead-end rooms",
		"dead_end_room_count"
	)

	_append_metric(
		lines,
		metrics,
		"Pass-through rooms",
		"pass_through_room_count"
	)

	_append_metric(
		lines,
		metrics,
		"Hub rooms",
		"hub_room_count"
	)

	if metrics.has("wfc_valid_layout"):
		_append_metric(
			lines,
			metrics,
			"WFC valid layout",
			"wfc_valid_layout"
		)

	if metrics.has("wfc_valid_composition"):
		_append_metric(
			lines,
			metrics,
			"WFC valid composition",
			"wfc_valid_composition"
		)

	if metrics.has("wfc_accepted_attempt"):
		_append_metric(
			lines,
			metrics,
			"WFC accepted attempt",
			"wfc_accepted_attempt"
		)


func _append_option_metrics(
	lines: Array[String],
	metrics: Dictionary
) -> void:
	_append_section(lines, "Options")

	_append_metric(
		lines,
		metrics,
		"Fixed start/end rooms",
		"used_fixed_start_end_rooms",
		false
	)

	_append_metric(
		lines,
		metrics,
		"Keep only reachable area",
		"keep_only_reachable_area_from_start",
		false
	)

	if metrics.has("run_index"):
		_append_metric(
			lines,
			metrics,
			"Run index",
			"run_index"
		)

	if metrics.has("png_path"):
		_append_metric(
			lines,
			metrics,
			"PNG path",
			"png_path"
		)


## Adds a formatted metric section header.
func _append_section(
	lines: Array[String],
	title: String
) -> void:
	if not lines.is_empty():
		lines.append("")

	lines.append(
		"[b]%s[/b]" % title
	)


## Adds one metric label/value pair to the formatted output.
func _append_metric(
	lines: Array[String],
	metrics: Dictionary,
	label: String,
	key: String,
	default_value: Variant = ""
) -> void:
	var value: Variant = metrics.get(
		key,
		default_value
	)

	lines.append(
		"%s: %s" % [
			label,
			str(value)
		]
	)


## Appends a message to the runtime log.
func _append_log(text: String) -> void:
	log_label.text += text + "\n"


func _on_random_seed_toggled(
	enabled: bool
) -> void:
	_update_seed_editability(enabled)


## Enables manual seed editing only when random seed generation is disabled.
func _update_seed_editability(
	random_seed_enabled: bool
) -> void:
	seed_spin.editable = not random_seed_enabled
