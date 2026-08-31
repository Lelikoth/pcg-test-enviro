class_name PNGExporter
extends RefCounted

## Saves rendered map images as PNG files.
##
## The exporter ensures that the target directory exists before writing
## the image to disk.


## Saves the provided image to a PNG file.
##
## Returns true when the image was saved successfully.
func save_image(
	image: Image,
	file_path: String
) -> bool:
	if not _ensure_directory(file_path):
		return false

	var absolute_path := ProjectSettings.globalize_path(
		file_path
	)

	var error: Error = image.save_png(
		absolute_path
	)

	if error != OK:
		push_error(
			"PNGExporter: failed to save PNG: "
			+ absolute_path
		)
		return false

	return true


## Ensures that the parent directory of the target file exists.
func _ensure_directory(file_path: String) -> bool:
	var directory_path := ProjectSettings.globalize_path(
		file_path.get_base_dir()
	)

	if DirAccess.dir_exists_absolute(directory_path):
		return true

	var error: Error = DirAccess.make_dir_recursive_absolute(
		directory_path
	)

	if error != OK and error != ERR_ALREADY_EXISTS:
		push_error(
			"PNGExporter: failed to create directory: "
			+ directory_path
		)
		return false

	return true
