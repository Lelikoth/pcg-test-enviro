extends RefCounted
class_name ResultLogger

func save_csv(path: String, rows: Array) -> bool:
	if rows.is_empty():
		push_warning("ResultLogger.save_csv: no rows to save for path: " + path)
		return false

	var headers: Array = _collect_headers(rows)
	if headers.is_empty():
		push_warning("ResultLogger.save_csv: no headers found for path: " + path)
		return false

	if not _ensure_parent_dir(path):
		push_error("ResultLogger.save_csv: failed to create parent dir for path: " + path)
		return false

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("ResultLogger.save_csv: failed to open file for writing: " + path)
		return false

	file.store_line(_csv_line_from_values(headers))

	for row_value in rows:
		var row: Dictionary = row_value
		var values: Array = _row_to_values(row, headers)
		file.store_line(_csv_line_from_values(values))

	file.close()
	return true

func append_csv(path: String, row: Dictionary, include_header_if_new: bool = true) -> bool:
	if row.is_empty():
		push_warning("ResultLogger.append_csv: empty row for path: " + path)
		return false

	if not _ensure_parent_dir(path):
		push_error("ResultLogger.append_csv: failed to create parent dir for path: " + path)
		return false

	var file_exists: bool = FileAccess.file_exists(path)

	if not file_exists:
		var write_file := FileAccess.open(path, FileAccess.WRITE)
		if write_file == null:
			push_error("ResultLogger.append_csv: failed to create file: " + path)
			return false

		var headers_new: Array = _collect_headers([row])
		if include_header_if_new:
			write_file.store_line(_csv_line_from_values(headers_new))

		write_file.store_line(_csv_line_from_values(_row_to_values(row, headers_new)))
		write_file.close()
		return true

	var existing_headers: Array = _read_header(path)
	var row_headers: Array = _collect_headers([row])

	if existing_headers.is_empty():
		var rewrite_headers: Array = row_headers
		var rewrite_file := FileAccess.open(path, FileAccess.WRITE)
		if rewrite_file == null:
			push_error("ResultLogger.append_csv: failed to rewrite empty-header file: " + path)
			return false

		if include_header_if_new:
			rewrite_file.store_line(_csv_line_from_values(rewrite_headers))
		rewrite_file.store_line(_csv_line_from_values(_row_to_values(row, rewrite_headers)))
		rewrite_file.close()
		return true

	var merged_headers: Array = _merge_headers(existing_headers, row_headers)

	if merged_headers.size() != existing_headers.size():
		return _rewrite_csv_with_new_header(path, merged_headers, row)

	var append_file := FileAccess.open(path, FileAccess.READ_WRITE)
	if append_file == null:
		push_error("ResultLogger.append_csv: failed to open file for append: " + path)
		return false

	append_file.seek_end()
	append_file.store_line(_csv_line_from_values(_row_to_values(row, existing_headers)))
	append_file.close()
	return true

func _rewrite_csv_with_new_header(path: String, new_headers: Array, new_row: Dictionary) -> bool:
	var existing_rows: Array = _read_csv_rows(path)
	if existing_rows.is_empty():
		existing_rows = []

	existing_rows.append(new_row)
	return save_csv(path, existing_rows)

func _read_csv_rows(path: String) -> Array:
	var rows: Array = []

	if not FileAccess.file_exists(path):
		return rows

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("ResultLogger._read_csv_rows: failed to open file: " + path)
		return rows

	if file.eof_reached():
		file.close()
		return rows

	var header_line: String = file.get_line()
	var headers: Array = _parse_csv_line(header_line)

	while not file.eof_reached():
		var line: String = file.get_line()
		if line.strip_edges() == "":
			continue

		var values: Array = _parse_csv_line(line)
		var row := {}

		for i in range(headers.size()):
			var header: String = str(headers[i])
			var value: String = ""
			if i < values.size():
				value = str(values[i])
			row[header] = value

		rows.append(row)

	file.close()
	return rows

func _read_header(path: String) -> Array:
	if not FileAccess.file_exists(path):
		return []

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return []

	if file.eof_reached():
		file.close()
		return []

	var line: String = file.get_line()
	file.close()

	if line.strip_edges() == "":
		return []

	return _parse_csv_line(line)

func _collect_headers(rows: Array) -> Array:
	var seen := {}
	var headers: Array = []

	for row_value in rows:
		if row_value is Dictionary:
			var row: Dictionary = row_value
			var keys: Array = row.keys()
			keys.sort()

			for key_value in keys:
				var key: String = str(key_value)
				if not seen.has(key):
					seen[key] = true
					headers.append(key)

	return headers

func _merge_headers(existing_headers: Array, new_headers: Array) -> Array:
	var seen := {}
	var merged: Array = []

	for header_value in existing_headers:
		var header: String = str(header_value)
		if not seen.has(header):
			seen[header] = true
			merged.append(header)

	for header_value in new_headers:
		var header: String = str(header_value)
		if not seen.has(header):
			seen[header] = true
			merged.append(header)

	return merged

func _row_to_values(row: Dictionary, headers: Array) -> Array:
	var values: Array = []

	for header_value in headers:
		var header: String = str(header_value)
		var value = row.get(header, "")
		values.append(_stringify_value(value))

	return values

func _stringify_value(value) -> String:
	match typeof(value):
		TYPE_BOOL:
			return "true" if value else "false"
		TYPE_FLOAT:
			return str(value)
		TYPE_INT:
			return str(value)
		TYPE_STRING:
			return value
		TYPE_VECTOR2I:
			var v: Vector2i = value
			return "%d,%d" % [v.x, v.y]
		TYPE_ARRAY, TYPE_DICTIONARY:
			return JSON.stringify(value)
		_:
			return str(value)

func _csv_line_from_values(values: Array) -> String:
	var escaped: Array = []

	for value in values:
		var text: String = str(value)
		escaped.append(_escape_csv(text))

	return ",".join(PackedStringArray(escaped))

func _escape_csv(text: String) -> String:
	var needs_quotes: bool = false

	if text.contains(",") or text.contains("\"") or text.contains("\n") or text.contains("\r"):
		needs_quotes = true

	text = text.replace("\"", "\"\"")

	if needs_quotes:
		return "\"" + text + "\""

	return text

func _parse_csv_line(line: String) -> Array:
	var result: Array = []
	var current: String = ""
	var in_quotes: bool = false
	var i: int = 0

	while i < line.length():
		var ch: String = line.substr(i, 1)

		if ch == "\"":
			if in_quotes and i + 1 < line.length() and line.substr(i + 1, 1) == "\"":
				current += "\""
				i += 1
			else:
				in_quotes = not in_quotes
		elif ch == "," and not in_quotes:
			result.append(current)
			current = ""
		else:
			current += ch

		i += 1

	result.append(current)
	return result

func _ensure_parent_dir(path: String) -> bool:
	var dir_path: String = path.get_base_dir()
	if dir_path == "":
		return true

	var err: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path))
	return err == OK or err == ERR_ALREADY_EXISTS
