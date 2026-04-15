extends Node
class_name TestRunner

signal generation_finished(map_data: Dictionary, metrics: Dictionary, image: Image, png_path: String)
signal batch_finished(results: Array)
signal log_message(text: String)

var validator := MapValidator.new()
var metrics_calculator := MetricsCalculator.new()
var result_logger := ResultLogger.new()
var map_renderer := MapRenderer.new()
var png_exporter := PNGExporter.new()
var map_post_processor := MapPostProcessor.new()

var generators: Dictionary = {}

func _ready() -> void:
	_register_generators()

func _register_generators() -> void:
	generators.clear()
	generators["RandomWalk"] = RandomWalkGenerator.new()
	generators["PerlinNoise"] = PerlinNoiseGenerator.new()
	generators["CellularAutomata"] = CellularAutomataAdapter.new()
	generators["ProcGenHybrid"] = ProcGenHybridAdapter.new()
	generators["WFC"] = WFCAdapter.new()


func get_algorithm_names() -> Array[String]:
	var names: Array[String] = []
	for key in generators.keys():
		names.append(str(key))
	names.sort()
	return names

func generate_single(config: TestConfig, algorithm_name: String) -> void:
	if not generators.has(algorithm_name):
		emit_signal("log_message", "Generator not found: %s" % algorithm_name)
		return

	var generator: BaseGenerator = generators[algorithm_name]
	emit_signal("log_message", "Generating map with %s..." % algorithm_name)

	var start_time := Time.get_ticks_usec()
	var map_data: Dictionary = await generator.generate_map(config.to_dictionary())
	var end_time := Time.get_ticks_usec()

	if config.use_fixed_start_end_rooms:
		map_data = map_post_processor.apply_fixed_start_end_rooms(map_data)
		emit_signal("log_message", "Applied fixed start/end rooms.")

	var generation_time_ms := float(end_time - start_time) / 1000.0
	var metrics := metrics_calculator.calculate_metrics(map_data, generation_time_ms, validator)
	metrics["used_fixed_start_end_rooms"] = config.use_fixed_start_end_rooms
	metrics["keep_only_reachable_area_from_start"] = config.keep_only_reachable_area_from_start

	var image := map_renderer.render_to_image(map_data, 8)
	var png_path := ""

	if config.save_png:
		png_path = _build_png_path(metrics["algorithm"], 0, metrics["seed"])
		png_exporter.save_image(image, png_path)
		emit_signal("log_message", "PNG saved: %s" % png_path)

	if config.save_csv:
		var csv_path := _build_csv_path(algorithm_name)
		var single_row := metrics.duplicate()
		single_row["run_index"] = 0
		single_row["png_path"] = png_path
		var csv_ok: bool = result_logger.append_csv(csv_path, single_row, true)
		if csv_ok:
			emit_signal("log_message", "CSV row appended: %s" % csv_path)
		else:
			emit_signal("log_message", "CSV append failed: %s" % csv_path)

	emit_signal("generation_finished", map_data, metrics, image, png_path)

func run_batch(config: TestConfig, algorithm_name: String) -> void:
	if not generators.has(algorithm_name):
		emit_signal("log_message", "Generator not found: %s" % algorithm_name)
		return

	var generator: BaseGenerator = generators[algorithm_name]
	var all_results: Array = []

	emit_signal("log_message", "Starting batch for %s..." % algorithm_name)

	for run_index in range(config.runs_per_algorithm):
		var run_config := TestConfig.new()
		run_config.width = config.width
		run_config.height = config.height
		run_config.seed = config.seed + run_index
		run_config.random_seed = config.random_seed
		run_config.save_png = config.save_png
		run_config.save_csv = config.save_csv
		run_config.runs_per_algorithm = config.runs_per_algorithm
		run_config.max_pngs_per_batch = config.max_pngs_per_batch
		run_config.use_fixed_start_end_rooms = config.use_fixed_start_end_rooms
		run_config.keep_only_reachable_area_from_start = config.keep_only_reachable_area_from_start

		run_config.rw_steps = config.rw_steps
		run_config.rw_start_from_center = config.rw_start_from_center

		run_config.procgen_room_amount = config.procgen_room_amount
		run_config.procgen_automaton_iterations = config.procgen_automaton_iterations
		run_config.procgen_automaton_threads = config.procgen_automaton_threads

		run_config.noise_frequency = config.noise_frequency
		run_config.noise_threshold = config.noise_threshold
		run_config.noise_fractal_octaves = config.noise_fractal_octaves
		
		run_config.ca_fill_probability = config.ca_fill_probability
		run_config.ca_iterations = config.ca_iterations
		run_config.ca_birth_limit = config.ca_birth_limit
		run_config.ca_death_limit = config.ca_death_limit

		var start_time := Time.get_ticks_usec()
		var map_data: Dictionary = await generator.generate_map(run_config.to_dictionary())
		var end_time := Time.get_ticks_usec()

		if run_config.use_fixed_start_end_rooms:
			map_data = map_post_processor.apply_fixed_start_end_rooms(map_data)

		var generation_time_ms := float(end_time - start_time) / 1000.0
		var metrics := metrics_calculator.calculate_metrics(map_data, generation_time_ms, validator)
		metrics["run_index"] = run_index
		metrics["used_fixed_start_end_rooms"] = run_config.use_fixed_start_end_rooms
		metrics["keep_only_reachable_area_from_start"] = run_config.keep_only_reachable_area_from_start

		var png_path := ""
		if config.save_png and run_index < config.max_pngs_per_batch:
			var image := map_renderer.render_to_image(map_data, 8)
			png_path = _build_png_path(metrics["algorithm"], run_index, metrics["seed"])
			png_exporter.save_image(image, png_path)
			emit_signal("log_message", "Saved PNG for run %d" % run_index)

		metrics["png_path"] = png_path
		all_results.append(metrics)

		emit_signal("log_message", "Finished run %d / %d" % [run_index + 1, config.runs_per_algorithm])

	if config.save_csv:
		var csv_path := _build_csv_path(algorithm_name)
		var csv_ok: bool = result_logger.save_csv(csv_path, all_results)
		if csv_ok:
			emit_signal("log_message", "CSV saved: %s" % csv_path)
		else:
			emit_signal("log_message", "CSV save failed: %s" % csv_path)

	emit_signal("batch_finished", all_results)

func _build_png_path(algorithm_name: String, run_index: int, seed: int) -> String:
	return "res://output/png/%s/run_%03d_seed_%d.png" % [algorithm_name, run_index, seed]

func _build_csv_path(algorithm_name: String) -> String:
	return "res://output/csv/%s_results.csv" % algorithm_name
