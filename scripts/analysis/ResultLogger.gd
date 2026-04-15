extends RefCounted
class_name ResultLogger

func save_csv(path: String, rows: Array) -> bool:
	if rows.is_empty():
		push_warning("No rows to save for CSV: " + path)
		return false

	_ensure_directory(path)

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open CSV file for writing: " + path)
		return false

	var headers: Array = rows[0].keys()
	var header_strings: Array[String] = []
	for h in headers:
		header_strings.append(str(h))
	file.store_line(",".join(header_strings))

	for row in rows:
		var values: Array[String] = []
		for h in headers:
			values.append(_escape_csv_value(row.get(h, "")))
		file.store_line(",".join(values))

	file.flush()
	file.close()

	print("CSV saved successfully: ", ProjectSettings.globalize_path(path))
	return true

func append_csv(path: String, row: Dictionary, write_header_if_needed: bool = true) -> bool:
	_ensure_directory(path)

	var file_exists: bool = FileAccess.file_exists(path)
	var mode := FileAccess.READ_WRITE if file_exists else FileAccess.WRITE
	var file := FileAccess.open(path, mode)

	if file == null:
		push_error("Failed to open CSV file: " + path)
		return false

	if file_exists:
		file.seek_end()

	var headers: Array = row.keys()
	if write_header_if_needed and not file_exists:
		var header_strings: Array[String] = []
		for h in headers:
			header_strings.append(str(h))
		file.store_line(",".join(header_strings))

	var values: Array[String] = []
	for h in headers:
		values.append(_escape_csv_value(row.get(h, "")))
	file.store_line(",".join(values))

	file.flush()
	file.close()

	print("CSV row appended successfully: ", ProjectSettings.globalize_path(path))
	return true

func _escape_csv_value(value) -> String:
	var text := str(value)
	if text.contains(",") or text.contains("\"") or text.contains("\n"):
		text = text.replace("\"", "\"\"")
		text = "\"" + text + "\""
	return text

func _ensure_directory(file_path: String) -> void:
	var dir_path: String = ProjectSettings.globalize_path(file_path.get_base_dir())
	if not DirAccess.dir_exists_absolute(dir_path):
		var err := DirAccess.make_dir_recursive_absolute(dir_path)
		if err != OK:
			push_error("Failed to create directory: " + dir_path)
