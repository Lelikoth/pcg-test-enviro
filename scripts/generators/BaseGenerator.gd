extends RefCounted
class_name BaseGenerator

func get_algorithm_name() -> String:
	return "BaseGenerator"

func generate_map(config: Dictionary) -> Dictionary:
	push_error("generate_map() must be implemented in child class")
	return {}
