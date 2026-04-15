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

@onready var noise_frequency_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/NoiseSectionRoot/ContentContainer/NoiseFrequencySpin
@onready var noise_threshold_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/NoiseSectionRoot/ContentContainer/NoiseThresholdSpin
@onready var noise_octaves_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/NoiseSectionRoot/ContentContainer/NoiseOctavesSpin

@onready var ca_fill_prob_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/CellularSectionRoot/ContentContainer/CAFillProbabilitySpin
@onready var ca_iterations_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/CellularSectionRoot/ContentContainer/CAIterationsSpin
@onready var ca_birth_limit_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/CellularSectionRoot/ContentContainer/CABirthLimitSpin
@onready var ca_death_limit_spin: SpinBox = $RootContainer/LeftPanel/ScrollContainer/ControlsRootVBox/CellularSectionRoot/ContentContainer/CADeathLimitSpin

@onready var preview_texture: TextureRect = $RootContainer/CenterPanel/PreviewVBox/PreviewTexture
@onready var metrics_label: RichTextLabel = $RootContainer/RightPanel/InfoVBox/MetricsLabel
@onready var log_label: RichTextLabel = $RootContainer/RightPanel/InfoVBox/LogLabel

@onready var test_runner: TestRunner = $TestRunner

func _ready() -> void:
	_populate_algorithms()

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
	var names := test_runner.get_algorithm_names()
	for name in names:
		algorithm_option.add_item(name)

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
	config.procgen_automaton_threads = 1

	config.noise_frequency = float(noise_frequency_spin.value)
	config.noise_threshold = float(noise_threshold_spin.value)
	config.noise_fractal_octaves = int(noise_octaves_spin.value)

	config.ca_fill_probability = float(ca_fill_prob_spin.value)
	config.ca_iterations = int(ca_iterations_spin.value)
	config.ca_birth_limit = int(ca_birth_limit_spin.value)
	config.ca_death_limit = int(ca_death_limit_spin.value)

	return config

func _get_selected_algorithm() -> String:
	return algorithm_option.get_item_text(algorithm_option.selected)

func _on_generate_pressed() -> void:
	var config := _build_config()
	var algorithm := _get_selected_algorithm()
	test_runner.generate_single(config, algorithm)

func _on_batch_pressed() -> void:
	var config := _build_config()
	var algorithm := _get_selected_algorithm()
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
	lines.append("[b]Metrics[/b]")
	lines.append("Algorithm: %s" % metrics.get("algorithm", ""))
	lines.append("Seed: %s" % metrics.get("seed", ""))
	lines.append("Generation time [ms]: %s" % str(metrics.get("generation_time_ms", "")))
	lines.append("Connected: %s" % str(metrics.get("is_connected", "")))
	lines.append("Path length: %s" % str(metrics.get("path_length", "")))
	lines.append("Floor count: %s" % str(metrics.get("floor_count", "")))
	lines.append("Wall count: %s" % str(metrics.get("wall_count", "")))
	lines.append("Floor ratio: %s" % str(metrics.get("floor_ratio", "")))
	lines.append("Room count: %s" % str(metrics.get("room_count", "")))
	lines.append("Largest room area: %s" % str(metrics.get("largest_room_area", "")))
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
