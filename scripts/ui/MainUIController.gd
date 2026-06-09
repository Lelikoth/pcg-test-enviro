extends Control
class_name MainUIController

@onready var algorithm_option: OptionButton = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/GeneralSectionRoot/ContentContainer/AlgorithmOption
@onready var width_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/GeneralSectionRoot/ContentContainer/WidthSpin
@onready var height_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/GeneralSectionRoot/ContentContainer/HeightSpin
@onready var runs_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/GeneralSectionRoot/ContentContainer/RunsSpin
@onready var max_pngs_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/GeneralSectionRoot/ContentContainer/MaxPNGsSpin

@onready var fixed_start_end_check: CheckBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/FixedStartEndCheck
@onready var reachable_area_check: CheckBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/ReachableAreaCheck

@onready var random_seed_check: CheckBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/GeneralSectionRoot/ContentContainer/RandomSeedCheck
@onready var seed_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/GeneralSectionRoot/ContentContainer/SeedSpin
@onready var save_png_check: CheckBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/SavePNGCheck
@onready var save_csv_check: CheckBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/SaveCSVCheck
@onready var generate_button: Button = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/GenerateButton
@onready var batch_button: Button = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/BatchButton

@onready var steps_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/RandomWalkSectionRoot/ContentContainer/StepsSpin

@onready var procgen_rooms_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/ProcGenSectionRoot/ContentContainer/ProcGenRoomsSpin
@onready var procgen_iterations_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/ProcGenSectionRoot/ContentContainer/ProcGenIterationsSpin
@onready var procgen_room_min_coverage_spin: SpinBox = get_node_or_null("RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/ProcGenSectionRoot/ContentContainer/ProcGenRoomMinCoverageSpin")
@onready var procgen_room_max_coverage_spin: SpinBox = get_node_or_null("RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/ProcGenSectionRoot/ContentContainer/ProcGenRoomMaxCoverageSpin")
@onready var procgen_room_center_ratio_spin: SpinBox = get_node_or_null("RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/ProcGenSectionRoot/ContentContainer/ProcGenRoomCenterRatioSpin")
@onready var procgen_corridor_cycle_chance_spin: SpinBox = get_node_or_null("RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/ProcGenSectionRoot/ContentContainer/ProcGenCorridorCycleChanceSpin")
@onready var procgen_automaton_noise_rate_spin: SpinBox = get_node_or_null("RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/ProcGenSectionRoot/ContentContainer/ProcGenAutomatonNoiseRateSpin")

@onready var noise_frequency_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/NoiseSectionRoot/ContentContainer/NoiseFrequencySpin
@onready var noise_threshold_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/NoiseSectionRoot/ContentContainer/NoiseThresholdSpin
@onready var noise_octaves_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/NoiseSectionRoot/ContentContainer/NoiseOctavesSpin

@onready var ca_fill_prob_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/CellularSectionRoot/ContentContainer/CAFillProbabilitySpin
@onready var ca_iterations_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/CellularSectionRoot/ContentContainer/CAIterationsSpin
@onready var ca_border_width_spin: SpinBox = get_node_or_null("RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/CellularSectionRoot/ContentContainer/CABorderWidthSpin")

@onready var wfc_module_grid_width_spin: SpinBox = get_node_or_null("RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/ModuleWFCSectionRoot/ContentContainer/WFCModuleGridWidthSpin")
@onready var wfc_module_grid_height_spin: SpinBox = get_node_or_null("RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/ModuleWFCSectionRoot/ContentContainer/WFCModuleGridHeightSpin")
@onready var wfc_max_retries_spin: SpinBox = get_node_or_null("RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/ModuleWFCSectionRoot/ContentContainer/WFCMaxRetriesSpin")
@onready var wfc_min_small_corridors_spin: SpinBox = get_node_or_null("RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/ModuleWFCSectionRoot/ContentContainer/WFCMinSmallCorridorsSpin")
@onready var wfc_min_medium_rooms_spin: SpinBox = get_node_or_null("RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/ModuleWFCSectionRoot/ContentContainer/WFCMinMediumRoomsSpin")
@onready var wfc_min_large_rooms_spin: SpinBox = get_node_or_null("RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/ModuleWFCSectionRoot/ContentContainer/WFCMinLargeRoomsSpin")

@onready var preview_texture: TextureRect = $RootContainer/CenterPanel/PreviewVBox/PreviewTexture
@onready var metrics_label: RichTextLabel = $RootContainer/RightPanel/InfoVBox/MetricsLabel
@onready var log_label: RichTextLabel = $RootContainer/RightPanel/InfoVBox/LogLabel

@onready var test_runner: TestRunner = $TestRunner


func _ready() -> void:
	_populate_algorithms()
	_apply_default_config_to_ui()

	test_runner.generation_finished.connect(_on_generation_finished)
	test_runner.batch_finished.connect(_on_batch_finished)
	test_runner.log_message.connect(_append_log)

	generate_button.pressed.connect(_on_generate_pressed)
	batch_button.pressed.connect(_on_batch_pressed)
	random_seed_check.toggled.connect(_on_random_seed_toggled)

	_on_random_seed_toggled(random_seed_check.button_pressed)
	_append_log("Test environment ready.")


func _populate_algorithms() -> void:
	algorithm_option.clear()

	var names: Array[String] = test_runner.get_algorithm_names()

	for name in names:
		algorithm_option.add_item(name)


func _apply_default_config_to_ui() -> void:
	var config := TestConfig.new()

	width_spin.value = config.width
	height_spin.value = config.height
	runs_spin.value = config.runs_per_algorithm
	max_pngs_spin.value = config.max_pngs_per_batch

	fixed_start_end_check.button_pressed = config.use_fixed_start_end_rooms
	reachable_area_check.button_pressed = config.keep_only_reachable_area_from_start

	random_seed_check.button_pressed = config.random_seed
	seed_spin.value = config.seed
	save_png_check.button_pressed = config.save_png
	save_csv_check.button_pressed = config.save_csv

	steps_spin.value = config.rw_steps

	procgen_rooms_spin.value = config.procgen_room_amount
	procgen_iterations_spin.value = config.procgen_automaton_iterations

	if procgen_room_min_coverage_spin != null:
		procgen_room_min_coverage_spin.value = config.procgen_room_min_coverage

	if procgen_room_max_coverage_spin != null:
		procgen_room_max_coverage_spin.value = config.procgen_room_max_coverage

	if procgen_room_center_ratio_spin != null:
		procgen_room_center_ratio_spin.value = config.procgen_room_center_ratio

	if procgen_corridor_cycle_chance_spin != null:
		procgen_corridor_cycle_chance_spin.value = config.procgen_corridor_cycle_chance

	if procgen_automaton_noise_rate_spin != null:
		procgen_automaton_noise_rate_spin.value = config.procgen_automaton_noise_rate

	noise_frequency_spin.value = config.noise_frequency
	noise_threshold_spin.value = config.noise_threshold
	noise_octaves_spin.value = config.noise_fractal_octaves

	ca_fill_prob_spin.value = config.ca_fill_probability
	ca_iterations_spin.value = config.ca_iterations

	if ca_border_width_spin != null:
		ca_border_width_spin.value = config.ca_border_width

	if wfc_module_grid_width_spin != null:
		wfc_module_grid_width_spin.value = config.wfc_module_grid_width

	if wfc_module_grid_height_spin != null:
		wfc_module_grid_height_spin.value = config.wfc_module_grid_height

	if wfc_max_retries_spin != null:
		wfc_max_retries_spin.value = config.wfc_max_retries

	if wfc_min_small_corridors_spin != null:
		wfc_min_small_corridors_spin.value = config.wfc_min_small_corridors

	if wfc_min_medium_rooms_spin != null:
		wfc_min_medium_rooms_spin.value = config.wfc_min_medium_rooms

	if wfc_min_large_rooms_spin != null:
		wfc_min_large_rooms_spin.value = config.wfc_min_large_rooms


func _build_config() -> TestConfig:
	var config := TestConfig.new()

	config.width = int(width_spin.value)
	config.height = int(height_spin.value)
	config.runs_per_algorithm = int(runs_spin.value)
	config.max_pngs_per_batch = int(max_pngs_spin.value)

	config.use_fixed_start_end_rooms = fixed_start_end_check.button_pressed
	config.keep_only_reachable_area_from_start = reachable_area_check.button_pressed

	config.rw_steps = int(steps_spin.value)
	config.random_seed = random_seed_check.button_pressed
	config.seed = int(seed_spin.value)
	config.save_png = save_png_check.button_pressed
	config.save_csv = save_csv_check.button_pressed

	config.procgen_room_amount = int(procgen_rooms_spin.value)
	config.procgen_automaton_iterations = int(procgen_iterations_spin.value)

	# Keep this fixed for now.
	# ProcGen threading is unstable and makes benchmarking harder.
	config.procgen_automaton_threads = 0

	if procgen_room_min_coverage_spin != null:
		config.procgen_room_min_coverage = float(procgen_room_min_coverage_spin.value)

	if procgen_room_max_coverage_spin != null:
		config.procgen_room_max_coverage = float(procgen_room_max_coverage_spin.value)

	if procgen_room_center_ratio_spin != null:
		config.procgen_room_center_ratio = float(procgen_room_center_ratio_spin.value)

	if procgen_corridor_cycle_chance_spin != null:
		config.procgen_corridor_cycle_chance = float(procgen_corridor_cycle_chance_spin.value)

	if procgen_automaton_noise_rate_spin != null:
		config.procgen_automaton_noise_rate = float(procgen_automaton_noise_rate_spin.value)

	if config.procgen_automaton_iterations <= 0:
		config.procgen_automaton_noise_rate = 0.0

	if config.procgen_room_min_coverage > config.procgen_room_max_coverage:
		var tmp := config.procgen_room_min_coverage
		config.procgen_room_min_coverage = config.procgen_room_max_coverage
		config.procgen_room_max_coverage = tmp

	config.noise_frequency = float(noise_frequency_spin.value)
	config.noise_threshold = float(noise_threshold_spin.value)
	config.noise_fractal_octaves = int(noise_octaves_spin.value)

	config.ca_fill_probability = float(ca_fill_prob_spin.value)
	config.ca_iterations = int(ca_iterations_spin.value)

	if ca_border_width_spin != null:
		config.ca_border_width = int(ca_border_width_spin.value)

	if wfc_module_grid_width_spin != null:
		config.wfc_module_grid_width = int(wfc_module_grid_width_spin.value)

	if wfc_module_grid_height_spin != null:
		config.wfc_module_grid_height = int(wfc_module_grid_height_spin.value)

	if wfc_max_retries_spin != null:
		config.wfc_max_retries = int(wfc_max_retries_spin.value)

	if wfc_min_small_corridors_spin != null:
		config.wfc_min_small_corridors = int(wfc_min_small_corridors_spin.value)

	if wfc_min_medium_rooms_spin != null:
		config.wfc_min_medium_rooms = int(wfc_min_medium_rooms_spin.value)

	if wfc_min_large_rooms_spin != null:
		config.wfc_min_large_rooms = int(wfc_min_large_rooms_spin.value)

	return config


func _get_selected_algorithm() -> String:
	return algorithm_option.get_item_text(algorithm_option.selected)


func _on_generate_pressed() -> void:
	var config := _build_config()
	var algorithm: String = _get_selected_algorithm()

	test_runner.generate_single(config, algorithm)


func _on_batch_pressed() -> void:
	var config := _build_config()
	var algorithm: String = _get_selected_algorithm()

	test_runner.run_batch(config, algorithm)


func _on_generation_finished(map_data: Dictionary, metrics: Dictionary, image: Image, png_path: String) -> void:
	var texture := ImageTexture.create_from_image(image)

	preview_texture.texture = texture
	metrics_label.text = _format_metrics(metrics)

	if png_path != "":
		_append_log("Single generation PNG: %s" % png_path)


func _on_batch_finished(results: Array) -> void:
	if results.is_empty():
		_append_log("Batch finished, but no results were returned.")
		return

	var last_result: Dictionary = results[results.size() - 1]

	metrics_label.text = _format_metrics(last_result)
	_append_log("Batch finished. Total results: %d" % results.size())


func _format_metrics(metrics: Dictionary) -> String:
	var lines: Array[String] = []

	lines.append("[b]Basic[/b]")
	lines.append("Algorithm: %s" % str(metrics.get("algorithm", "")))
	lines.append("Seed: %s" % str(metrics.get("seed", "")))
	lines.append("Map size: %sx%s" % [
		str(metrics.get("map_width", "")),
		str(metrics.get("map_height", ""))
	])
	lines.append("Total cells: %s" % str(metrics.get("total_cells", "")))

	lines.append("")
	lines.append("[b]Performance[/b]")
	lines.append("Generation time [ms]: %s" % str(metrics.get("generation_time_ms", "")))
	lines.append("Time per cell [ms]: %s" % str(metrics.get("time_per_cell_ms", "")))
	lines.append("Time per floor cell [ms]: %s" % str(metrics.get("time_per_floor_cell_ms", "")))
	lines.append("Generation success: %s" % str(metrics.get("generation_success", "")))
	lines.append("Retry count: %s" % str(metrics.get("retry_count", "")))

	if metrics.has("fallback_reason"):
		lines.append("Fallback reason: %s" % str(metrics.get("fallback_reason", "")))

	lines.append("")
	lines.append("[b]Tiles[/b]")
	lines.append("Floor count: %s" % str(metrics.get("floor_count", "")))
	lines.append("Wall count: %s" % str(metrics.get("wall_count", "")))
	lines.append("Floor ratio: %s" % str(metrics.get("floor_ratio", "")))
	lines.append("Wall ratio: %s" % str(metrics.get("wall_ratio", "")))
	lines.append("Floor ratio in target range: %s" % str(metrics.get("floor_ratio_in_target_range", "")))

	lines.append("")
	lines.append("[b]Start / End / Path[/b]")
	lines.append("Start: (%s, %s)" % [
		str(metrics.get("start_x", "")),
		str(metrics.get("start_y", ""))
	])
	lines.append("End: (%s, %s)" % [
		str(metrics.get("end_x", "")),
		str(metrics.get("end_y", ""))
	])
	lines.append("Valid start: %s" % str(metrics.get("has_valid_start", "")))
	lines.append("Valid end: %s" % str(metrics.get("has_valid_end", "")))
	lines.append("Connected start-end: %s" % str(metrics.get("is_connected", "")))
	lines.append("Path length: %s" % str(metrics.get("path_length", "")))
	lines.append("Euclidean distance: %s" % str(metrics.get("start_end_euclidean_distance", "")))
	lines.append("Path tortuosity: %s" % str(metrics.get("path_tortuosity", "")))
	lines.append("Path directness: %s" % str(metrics.get("path_directness", "")))
	lines.append("Farthest reachable path length: %s" % str(metrics.get("farthest_reachable_path_length", "")))
	lines.append("Farthest reachable: (%s, %s)" % [
		str(metrics.get("farthest_reachable_x", "")),
		str(metrics.get("farthest_reachable_y", ""))
	])

	lines.append("")
	lines.append("[b]Reachability / Open Regions[/b]")
	lines.append("Open region count: %s" % str(metrics.get("open_region_count", "")))
	lines.append("Largest open region area: %s" % str(metrics.get("largest_open_region_area", "")))
	lines.append("Largest open region ratio: %s" % str(metrics.get("largest_open_region_ratio", "")))
	lines.append("Average open region area: %s" % str(metrics.get("average_open_region_area", "")))
	lines.append("Reachable floor count from start: %s" % str(metrics.get("reachable_floor_count_from_start", "")))
	lines.append("Reachable floor ratio from start: %s" % str(metrics.get("reachable_floor_ratio_from_start", "")))
	lines.append("Unreachable floor count: %s" % str(metrics.get("unreachable_floor_count", "")))
	lines.append("Unreachable floor ratio: %s" % str(metrics.get("unreachable_floor_ratio", "")))

	lines.append("")
	lines.append("[b]Shape / Local Complexity[/b]")
	lines.append("Floor-wall adjacency count: %s" % str(metrics.get("floor_wall_adjacency_count", "")))
	lines.append("Normalized perimeter: %s" % str(metrics.get("normalized_perimeter", "")))
	lines.append("Tile entropy: %s" % str(metrics.get("tile_entropy", "")))
	lines.append("Tile entropy normalized: %s" % str(metrics.get("tile_entropy_normalized", "")))
	lines.append("Pattern entropy 2x2: %s" % str(metrics.get("pattern_entropy_2x2", "")))
	lines.append("Pattern entropy 2x2 normalized: %s" % str(metrics.get("pattern_entropy_2x2_normalized", "")))

	lines.append("")
	lines.append("[b]Declared Rooms[/b]")
	lines.append("Declared room count: %s" % str(metrics.get("declared_room_count", "")))
	lines.append("Largest declared room area: %s" % str(metrics.get("largest_declared_room_area", "")))

	if str(metrics.get("algorithm", "")) == "ProcGenHybrid":
		lines.append("")
		lines.append("[b]ProcGen Structure[/b]")
		lines.append("Corridor links: %s" % str(metrics.get("procgen_corridor_link_count", "")))
		lines.append("Dead-end rooms: %s" % str(metrics.get("procgen_dead_end_room_count", "")))
		lines.append("Room min degree: %s" % str(metrics.get("procgen_room_connection_min_degree", "")))
		lines.append("Room max degree: %s" % str(metrics.get("procgen_room_connection_max_degree", "")))
		lines.append("Room average degree: %s" % str(metrics.get("procgen_room_connection_average_degree", "")))
		lines.append("Cycle links: %s" % str(metrics.get("procgen_cycle_link_count", "")))
		lines.append("Has cycles: %s" % str(metrics.get("procgen_has_cycles", "")))

	if str(metrics.get("algorithm", "")) == "ModuleWFC":
		lines.append("")
		lines.append("[b]Module WFC[/b]")
		lines.append("Room modules: %s" % str(metrics.get("room_module_count", "")))
		lines.append("Corridor modules: %s" % str(metrics.get("corridor_module_count", "")))
		lines.append("Junction modules: %s" % str(metrics.get("junction_module_count", "")))
		lines.append("Special modules: %s" % str(metrics.get("special_module_count", "")))
		lines.append("Small rooms: %s" % str(metrics.get("small_room_count", "")))
		lines.append("Medium rooms: %s" % str(metrics.get("medium_room_count", "")))
		lines.append("Large rooms: %s" % str(metrics.get("large_room_count", "")))
		lines.append("Dead-end modules: %s" % str(metrics.get("dead_end_module_count", "")))
		lines.append("Dead-end rooms: %s" % str(metrics.get("dead_end_room_count", "")))
		lines.append("Pass-through rooms: %s" % str(metrics.get("pass_through_room_count", "")))
		lines.append("Hub rooms: %s" % str(metrics.get("hub_room_count", "")))

		if metrics.has("wfc_valid_layout"):
			lines.append("WFC valid layout: %s" % str(metrics.get("wfc_valid_layout", "")))

		if metrics.has("wfc_valid_composition"):
			lines.append("WFC valid composition: %s" % str(metrics.get("wfc_valid_composition", "")))

		if metrics.has("wfc_accepted_attempt"):
			lines.append("WFC accepted attempt: %s" % str(metrics.get("wfc_accepted_attempt", "")))

	lines.append("")
	lines.append("[b]Options[/b]")
	lines.append("Fixed start/end rooms: %s" % str(metrics.get("used_fixed_start_end_rooms", false)))
	lines.append("Keep only reachable area: %s" % str(metrics.get("keep_only_reachable_area_from_start", false)))

	if metrics.has("run_index"):
		lines.append("Run index: %s" % str(metrics["run_index"]))

	if metrics.has("png_path"):
		lines.append("PNG path: %s" % str(metrics["png_path"]))

	return "\n".join(lines)


func _append_log(text: String) -> void:
	log_label.text += text + "\n"


func _on_random_seed_toggled(enabled: bool) -> void:
	seed_spin.editable = not enabled
