class_name ModuleLibrary
extends RefCounted

## Loads and validates the module definitions used by ModuleWFC.
##
## Module definitions are stored in a JSON file and cached in memory.
## Each module contains a fixed-size binary tile grid, directional openings,
## generation weight, and semantic tags.


const MODULES_JSON_PATH: String = "res://data/wfc/modules_7x7.json"


var _modules_cache: Array[Dictionary] = []
var _module_size: int = 0


func _init() -> void:
	_load_data_from_json()


## Returns all validated modules loaded from the module library.
func get_modules() -> Array[Dictionary]:
	return _modules_cache


## Returns the width and height of a single square module in tiles.
func get_module_size() -> int:
	return _module_size


## Returns the module with the provided identifier.
##
## An empty Dictionary is returned when no matching module exists.
func get_module_by_id(module_id: String) -> Dictionary:
	for module in _modules_cache:
		if str(module.get("id", "")) == module_id:
			return module

	return {}


## Returns whether two modules can be adjacent in the provided direction.
##
## Compatibility is determined by matching openings on opposite module edges.
func are_modules_compatible(
	module_a: Dictionary,
	module_b: Dictionary,
	direction: String
) -> bool:
	match direction:
		"up":
			return bool(module_a["up"]) == bool(module_b["down"])

		"right":
			return bool(module_a["right"]) == bool(module_b["left"])

		"down":
			return bool(module_a["down"]) == bool(module_b["up"])

		"left":
			return bool(module_a["left"]) == bool(module_b["right"])

		_:
			return false


## Returns all loaded modules compatible with the provided module
## in the selected direction.
func get_allowed_neighbors(
	module: Dictionary,
	direction: String
) -> Array[Dictionary]:
	var allowed_modules: Array[Dictionary] = []

	for candidate in _modules_cache:
		if are_modules_compatible(
			module,
			candidate,
			direction
		):
			allowed_modules.append(candidate)

	return allowed_modules


## Loads, parses, and validates the WFC module library from JSON.
func _load_data_from_json() -> void:
	_modules_cache.clear()
	_module_size = 0

	if not FileAccess.file_exists(MODULES_JSON_PATH):
		push_error(
			"ModuleLibrary: JSON file not found: "
			+ MODULES_JSON_PATH
		)
		return

	var file := FileAccess.open(
		MODULES_JSON_PATH,
		FileAccess.READ
	)

	if file == null:
		push_error(
			"ModuleLibrary: failed to open JSON file: "
			+ MODULES_JSON_PATH
		)
		return

	var json_text: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(json_text)

	if parsed == null:
		push_error(
			"ModuleLibrary: failed to parse module JSON."
		)
		return

	if typeof(parsed) != TYPE_DICTIONARY:
		push_error(
			"ModuleLibrary: JSON root must be a Dictionary."
		)
		return

	var root: Dictionary = parsed

	if not root.has("module_size"):
		push_error(
			"ModuleLibrary: JSON root has no 'module_size' field."
		)
		return

	if not root.has("modules"):
		push_error(
			"ModuleLibrary: JSON root has no 'modules' field."
		)
		return

	var module_size_value: Variant = root.get(
		"module_size",
		0
	)

	if (
		typeof(module_size_value) != TYPE_INT
		and typeof(module_size_value) != TYPE_FLOAT
	):
		push_error(
			"ModuleLibrary: 'module_size' must be numeric."
		)
		return

	_module_size = int(module_size_value)

	if _module_size <= 0:
		push_error(
			"ModuleLibrary: 'module_size' must be greater than zero."
		)
		return

	var modules_value: Variant = root.get(
		"modules",
		[]
	)

	if typeof(modules_value) != TYPE_ARRAY:
		push_error(
			"ModuleLibrary: 'modules' must be an Array."
		)
		return

	var modules: Array = modules_value
	var validated_modules: Array[Dictionary] = []

	for module_value in modules:
		if typeof(module_value) != TYPE_DICTIONARY:
			push_warning(
				"ModuleLibrary: skipping non-Dictionary module entry."
			)
			continue

		var module: Dictionary = module_value

		if not _is_valid_module(
			module,
			_module_size
		):
			push_warning(
				"ModuleLibrary: skipping invalid module: %s"
				% str(module.get("id", "UNKNOWN"))
			)
			continue

		validated_modules.append(module)

	_modules_cache = validated_modules


## Validates the required fields and tile-grid dimensions of a module.
func _is_valid_module(
	module: Dictionary,
	module_size: int
) -> bool:
	const REQUIRED_KEYS: Array[String] = [
		"id",
		"name",
		"grid",
		"up",
		"right",
		"down",
		"left",
		"weight",
		"tags"
	]

	for key in REQUIRED_KEYS:
		if not module.has(key):
			push_warning(
				"ModuleLibrary: module '%s' is missing required field '%s'."
				% [
					str(module.get("id", "UNKNOWN")),
					key
				]
			)
			return false

	var grid_value: Variant = module["grid"]

	if typeof(grid_value) != TYPE_ARRAY:
		return false

	var grid: Array = grid_value

	if grid.size() != module_size:
		return false

	for row_value in grid:
		if typeof(row_value) != TYPE_ARRAY:
			return false

		var row: Array = row_value

		if row.size() != module_size:
			return false

	return true
