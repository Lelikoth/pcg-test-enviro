class_name TestRunner
extends Node

## Coordinates single and batch procedural map generation tests.
##
## TestRunner selects the requested generator, measures generation time,
## applies common post-processing, calculates metrics, renders map previews,
## and exports test results.


const MAP_RENDER_SCALE: int = 8


signal generation_finished(
	map_data: Dictionary,
	metrics: Dictionary,
	image: Image,
	png_path: String
)

signal batch_finished(results: Array)

signal log_message(text: String)


var validator: MapValidator = MapValidator.new()
var metrics_calculator: MetricsCalculator = MetricsCalculator.new()
var result_logger: ResultLogger = ResultLogger.new()
var map_renderer: MapRenderer = MapRenderer.new()
var png_exporter: PNGExporter = PNGExporter.new()
var map_post_processor: MapPostProcessor = MapPostProcessor.new()

var generators: Dictionary = {}


func _ready() -> void:
	_register_generators()


## Registers all procedural generators available in the testing environment.
func _register_generators() -> void:
	generators = {
		"RandomWalk": RandomWalkGenerator.new(),
		"PerlinNoise": PerlinNoiseGenerator.new(),
		"CellularAutomata": CellularAutomataAdapter.new(),
		"ProcGenHybrid": ProcGenHybridAdapter.new(),
		"ModuleWFC": ModuleWFCGenerator.new()
	}


## Returns the available algorithm identifiers in alphabetical order.
func get_algorithm_names() -> Array[String]:
	var algorithm_names: Array[String] = []

	for algorithm_name in generators.keys():
		algorithm_names.append(
			str(algorithm_name)
		)

	algorithm_names.sort()

	return algorithm_names


## Runs a single generation test using the selected algorithm.
func generate_single(
	config: TestConfig,
	algorithm_name: String
) -> void:
	var generator := _get_generator(
		algorithm_name
	)

	if generator == null:
		return

	log_message.emit(
		"Generating map with %s..."
		% algorithm_name
	)

	var run_result := await _execute_run(
		generator,
		config,
		0
	)

	var map_data: Dictionary = run_result["map_data"]
	var metrics: Dictionary = run_result["metrics"]

	var image := map_renderer.render_to_image(
		map_data,
		MAP_RENDER_SCALE
	)

	var png_path: String = ""

	if config.save_png:
		png_path = _build_png_path(
			str(metrics.get(
				"algorithm",
				algorithm_name
			)),
			0,
			int(metrics.get(
				"seed",
				config.seed
			))
		)

		var png_saved: bool = png_exporter.save_image(
			image,
			png_path
		)

		if png_saved:
			log_message.emit(
				"PNG saved: %s"
				% png_path
			)
		else:
			log_message.emit(
				"PNG save failed: %s"
				% png_path
			)

			png_path = ""

	if config.save_csv:
		var csv_path := _build_csv_path(
			algorithm_name
		)

		var csv_row: Dictionary = metrics.duplicate()

		csv_row["run_index"] = 0
		csv_row["png_path"] = png_path

		var csv_saved := result_logger.append_csv(
			csv_path,
			csv_row,
			true
		)

		if csv_saved:
			log_message.emit(
				"CSV row appended: %s"
				% csv_path
			)
		else:
			log_message.emit(
				"CSV append failed: %s"
				% csv_path
			)

	generation_finished.emit(
		map_data,
		metrics,
		image,
		png_path
	)


## Runs multiple generation tests using the selected algorithm.
##
## Each deterministic batch run receives a sequential seed derived from the
## base seed. When random seed mode is enabled, individual generators replace
## that value with a randomly generated seed internally.
func run_batch(
	config: TestConfig,
	algorithm_name: String
) -> void:
	var generator := _get_generator(
		algorithm_name
	)

	if generator == null:
		return

	var all_results: Array = []

	log_message.emit(
		"Starting batch for %s..."
		% algorithm_name
	)

	for run_index in range(
		config.runs_per_algorithm
	):
		var run_result := await _execute_run(
			generator,
			config,
			run_index
		)

		var map_data: Dictionary = run_result["map_data"]
		var metrics: Dictionary = run_result["metrics"]

		metrics["run_index"] = run_index

		var png_path: String = ""

		if (
			config.save_png
			and run_index < config.max_pngs_per_batch
		):
			var image := map_renderer.render_to_image(
				map_data,
				MAP_RENDER_SCALE
			)

			png_path = _build_png_path(
				str(metrics.get(
					"algorithm",
					algorithm_name
				)),
				run_index,
				int(metrics.get(
					"seed",
					config.seed + run_index
				))
			)

			var png_saved := png_exporter.save_image(
				image,
				png_path
			)

			if png_saved:
				log_message.emit(
					"Saved PNG for run %d"
					% run_index
				)
			else:
				log_message.emit(
					"PNG save failed for run %d"
					% run_index
				)

				png_path = ""

		metrics["png_path"] = png_path
		all_results.append(metrics)

		log_message.emit(
			"Finished run %d / %d" % [
				run_index + 1,
				config.runs_per_algorithm
			]
		)

	if config.save_csv:
		var csv_path := _build_csv_path(
			algorithm_name
		)

		var csv_saved := result_logger.save_csv(
			csv_path,
			all_results
		)

		if csv_saved:
			log_message.emit(
				"CSV saved: %s"
				% csv_path
			)
		else:
			log_message.emit(
				"CSV save failed: %s"
				% csv_path
			)

	batch_finished.emit(
		all_results
	)


## Returns the generator registered under the provided identifier.
##
## If no matching generator exists, a log message is emitted and null is
## returned.
func _get_generator(
	algorithm_name: String
) -> BaseGenerator:
	if not generators.has(algorithm_name):
		log_message.emit(
			"Generator not found: %s"
			% algorithm_name
		)

		return null

	return generators[algorithm_name]


## Executes the shared generation pipeline for one test run.
##
## Generation time includes only generator execution. Common post-processing,
## metric calculation, rendering, and file export are intentionally excluded.
func _execute_run(
	generator: BaseGenerator,
	config: TestConfig,
	run_index: int
) -> Dictionary:
	var generator_config := _build_generator_config(
		config,
		run_index
	)

	var start_time := Time.get_ticks_usec()

	var map_data: Dictionary = await generator.generate_map(
		generator_config
	)

	var end_time := Time.get_ticks_usec()

	var generation_time_ms := float(
		end_time - start_time
	) / 1000.0

	map_data = map_post_processor.process_map(
		map_data,
		config.use_fixed_start_end_rooms
	)

	if config.use_fixed_start_end_rooms:
		log_message.emit(
			"Applied fixed start/end rooms."
		)

	var metrics := _calculate_metrics(
		map_data,
		generation_time_ms,
		config
	)

	return {
		"map_data": map_data,
		"metrics": metrics
	}


## Creates the generator configuration for one test run.
##
## Batch runs use sequential seed values. Generators configured for random
## seeds may replace this value internally.
func _build_generator_config(
	config: TestConfig,
	run_index: int
) -> Dictionary:
	var generator_config := config.to_dictionary()

	generator_config["seed"] = (
		config.seed + run_index
	)

	return generator_config


## Calculates metrics and appends test configuration metadata.
func _calculate_metrics(
	map_data: Dictionary,
	generation_time_ms: float,
	config: TestConfig
) -> Dictionary:
	var metrics := metrics_calculator.calculate_metrics(
		map_data,
		generation_time_ms,
		validator
	)

	# Legacy option retained for compatibility with earlier test results.
	metrics["used_fixed_start_end_rooms"] = (
		config.use_fixed_start_end_rooms
	)

	metrics["keep_only_reachable_area_from_start"] = (
		config.keep_only_reachable_area_from_start
	)

	return metrics


## Builds the PNG output path for a generated map.
func _build_png_path(
	algorithm_name: String,
	run_index: int,
	seed: int
) -> String:
	return "res://output/png/%s/run_%03d_seed_%d.png" % [
		algorithm_name,
		run_index,
		seed
	]


## Builds the CSV output path for the selected generator.
func _build_csv_path(
	algorithm_name: String
) -> String:
	return (
		"res://output/csv/%s_results_v2.csv"
		% algorithm_name
	)
