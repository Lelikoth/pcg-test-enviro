extends RefCounted
class_name ModuleLibrary

const MODULES_JSON_PATH := "res://data/wfc/modules_7x7.json"

var _modules_cache: Array = []
var _module_size: int = 0

func _init() -> void:
	_load_data_from_json()
	print("ModuleLibrary: loaded modules count = ", _modules_cache.size())
	print("ModuleLibrary: module size = ", _module_size)

func get_modules() -> Array:
	return _modules_cache

func get_module_size() -> int:
	return _module_size

func get_module_by_id(module_id: String) -> Dictionary:
	for module in _modules_cache:
		var m: Dictionary = module
		if m.get("id", "") == module_id:
			return m
	return {}

func are_modules_compatible(module_a: Dictionary, module_b: Dictionary, direction: String) -> bool:
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

func get_allowed_neighbors(module: Dictionary, direction: String) -> Array:
	var allowed: Array = []

	for candidate in _modules_cache:
		var candidate_dict: Dictionary = candidate
		if are_modules_compatible(module, candidate_dict, direction):
			allowed.append(candidate_dict)

	return allowed

func _load_data_from_json() -> void:
	print("ModuleLibrary: loading JSON from ", MODULES_JSON_PATH)

	_modules_cache = []
	_module_size = 0

	if not FileAccess.file_exists(MODULES_JSON_PATH):
		push_error("ModuleLibrary: JSON file not found: " + MODULES_JSON_PATH)
		return

	var file := FileAccess.open(MODULES_JSON_PATH, FileAccess.READ)
	if file == null:
		push_error("ModuleLibrary: Failed to open JSON file: " + MODULES_JSON_PATH)
		return

	var json_text: String = file.get_as_text()
	file.close()

	print("ModuleLibrary: JSON text length = ", json_text.length())

	var parsed = JSON.parse_string(json_text)
	if parsed == null:
		push_error("ModuleLibrary: JSON.parse_string returned null.")
		return

	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("ModuleLibrary: JSON root must be a dictionary, got type " + str(typeof(parsed)))
		return

	var root: Dictionary = parsed
	print("ModuleLibrary: root keys = ", root.keys())

	if not root.has("module_size"):
		push_error("ModuleLibrary: JSON root has no 'module_size' key.")
		return

	if not root.has("modules"):
		push_error("ModuleLibrary: JSON root has no 'modules' key.")
		return

	var module_size_value = root.get("module_size", 0)
	print("ModuleLibrary: raw module_size value = ", module_size_value, " type = ", typeof(module_size_value))

	if typeof(module_size_value) != TYPE_INT and typeof(module_size_value) != TYPE_FLOAT:
		push_error("ModuleLibrary: 'module_size' must be numeric.")
		return

	_module_size = int(module_size_value)
	if _module_size <= 0:
		push_error("ModuleLibrary: 'module_size' must be > 0.")
		return

	var modules = root.get("modules", [])
	if typeof(modules) != TYPE_ARRAY:
		push_error("ModuleLibrary: 'modules' must be an array, got type " + str(typeof(modules)))
		return

	print("ModuleLibrary: raw module entries count = ", modules.size())

	var validated: Array = []

	for module_entry in modules:
		if typeof(module_entry) != TYPE_DICTIONARY:
			push_warning("ModuleLibrary: Skipping non-dictionary module entry.")
			continue

		var module_dict: Dictionary = module_entry
		if _is_valid_module(module_dict, _module_size):
			validated.append(module_dict)
		else:
			push_warning("ModuleLibrary: Skipping invalid module: " + str(module_dict.get("id", "UNKNOWN")))

	_modules_cache = validated

func _is_valid_module(module: Dictionary, module_size: int) -> bool:
	var required_keys: Array[String] = [
		"id", "name", "grid", "up", "right", "down", "left", "weight", "tags"
	]

	for key in required_keys:
		if not module.has(key):
			print("ModuleLibrary: module missing key ", key, " in ", module)
			return false

	var grid = module["grid"]
	if typeof(grid) != TYPE_ARRAY:
		print("ModuleLibrary: module grid is not an array in ", module.get("id", "UNKNOWN"))
		return false

	if grid.size() != module_size:
		print("ModuleLibrary: module grid size is not ", module_size, " in ", module.get("id", "UNKNOWN"))
		return false

	for row in grid:
		if typeof(row) != TYPE_ARRAY:
			print("ModuleLibrary: module row is not an array in ", module.get("id", "UNKNOWN"))
			return false
		if row.size() != module_size:
			print("ModuleLibrary: module row size is not ", module_size, " in ", module.get("id", "UNKNOWN"))
			return false

	return true
