extends RefCounted
class_name PNGExporter

func save_image(image: Image, file_path: String) -> void:
	_ensure_directory(file_path)

	var absolute_path: String = ProjectSettings.globalize_path(file_path)
	var err := image.save_png(absolute_path)
	if err != OK:
		push_error("Failed to save PNG: " + absolute_path)

func _ensure_directory(file_path: String) -> void:
	var dir_path: String = ProjectSettings.globalize_path(file_path.get_base_dir())
	if not DirAccess.dir_exists_absolute(dir_path):
		var err := DirAccess.make_dir_recursive_absolute(dir_path)
		if err != OK:
			push_error("Failed to create directory: " + dir_path)
