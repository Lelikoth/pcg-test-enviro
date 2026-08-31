class_name ResultLogger
extends RefCounted

## Handles CSV export of test results.
##
## Result rows are stored as dictionaries and automatically converted to
## a CSV representation. When appending a row containing previously unseen
## fields, the existing file is rewritten with an expanded header.


## Saves all provided result rows to a CSV file, replacing existing content.
func save_csv(
	path: String,
	rows: Array
) -> bool:
	if rows.is_empty():
		push_warning(
			"ResultLogger.save_csv: no rows to save for path: " + path
		)
		return false

	var headers := _collect_headers(rows)

	if headers.is_empty():
		push_warning(
			"ResultLogger.save_csv: no headers found for path: " + path
		)
		return false

	return _write_csv(path, rows, headers)


## Appends a single result row to a CSV file.
##
## If the row introduces new columns, the existing file is rewritten using
## the merged header so that all rows retain a consistent column structure.
func append_csv(
	path: String,
	row: Dictionary,
	include_header_if_new: bool = true
) -> bool:
	if row.is_empty():
		push_warning(
			"ResultLogger.append_csv: empty row for path: " + path
		)
		return false

	if not _ensure_parent_dir(path):
		push_error(
			"ResultLogger.append_csv: failed to create parent directory: "
			+ path
		)
		return false

	var row_headers := _collect_headers([row])

	if not FileAccess.file_exists(path):
		return _create_csv_file(
			path,
			row,
			row_headers,
			include_header_if_new
		)

	var existing_headers := _read_header(path)

	# An existing file without a valid header is treated as a new CSV file.
	if existing_headers.is_empty():
		return _create_csv_file(
			path,
			row,
			row_headers,
			include_header_if_new
		)

	var merged_headers := _merge_headers(
		existing_headers,
		row_headers
	)

	if merged_headers.size() != existing_headers.size():
		return _rewrite_csv_with_new_header(
			path,
			merged_headers,
			row
		)

	var file := FileAccess.open(
		path,
		FileAccess.READ_WRITE
	)

	if file == null:
		push_error(
			"ResultLogger.append_csv: failed to open file for append: "
			+ path
		)
		return false

	file.seek_end()

	file.store_line(
		_csv_line_from_values(
			_row_to_values(row, existing_headers)
		)
	)

	file.close()

	return true


## Writes a complete CSV file using the provided column order.
func _write_csv(
	path: String,
	rows: Array,
	headers: Array
) -> bool:
	if not _ensure_parent_dir(path):
		push_error(
			"ResultLogger: failed to create parent directory: " + path
		)
		return false

	var file := FileAccess.open(
		path,
		FileAccess.WRITE
	)

	if file == null:
		push_error(
			"ResultLogger: failed to open file for writing: " + path
		)
		return false

	file.store_line(
		_csv_line_from_values(headers)
	)

	for row_value in rows:
		if not row_value is Dictionary:
			continue

		var row: Dictionary = row_value
		var values := _row_to_values(row, headers)

		file.store_line(
			_csv_line_from_values(values)
		)

	file.close()

	return true


## Creates a new CSV file containing a single row.
func _create_csv_file(
	path: String,
	row: Dictionary,
	headers: Array,
	include_header: bool
) -> bool:
	var file := FileAccess.open(
		path,
		FileAccess.WRITE
	)

	if file == null:
		push_error(
			"ResultLogger.append_csv: failed to create file: " + path
		)
		return false

	if include_header:
		file.store_line(
			_csv_line_from_values(headers)
		)

	file.store_line(
		_csv_line_from_values(
			_row_to_values(row, headers)
		)
	)

	file.close()

	return true


## Rewrites an existing CSV file after new columns are introduced.
func _rewrite_csv_with_new_header(
	path: String,
	new_headers: Array,
	new_row: Dictionary
) -> bool:
	var existing_rows := _read_csv_rows(path)

	existing_rows.append(new_row)

	return _write_csv(
		path,
		existing_rows,
		new_headers
	)


## Reads all CSV rows and converts them to dictionaries using the file header.
func _read_csv_rows(path: String) -> Array:
	var rows: Array = []

	if not FileAccess.file_exists(path):
		return rows

	var file := FileAccess.open(
		path,
		FileAccess.READ
	)

	if file == null:
		push_warning(
			"ResultLogger._read_csv_rows: failed to open file: " + path
		)
		return rows

	if file.eof_reached():
		file.close()
		return rows

	var header_line := file.get_line()
	var headers := _parse_csv_line(header_line)

	while not file.eof_reached():
		var line := file.get_line()

		if line.strip_edges().is_empty():
			continue

		var values := _parse_csv_line(line)
		var row: Dictionary = {}

		for index in range(headers.size()):
			var header := str(headers[index])
			var value := ""

			if index < values.size():
				value = str(values[index])

			row[header] = value

		rows.append(row)

	file.close()

	return rows


## Reads and parses the header of an existing CSV file.
func _read_header(path: String) -> Array:
	if not FileAccess.file_exists(path):
		return []

	var file := FileAccess.open(
		path,
		FileAccess.READ
	)

	if file == null:
		return []

	if file.eof_reached():
		file.close()
		return []

	var header_line := file.get_line()

	file.close()

	if header_line.strip_edges().is_empty():
		return []

	return _parse_csv_line(header_line)


## Collects all unique dictionary keys used by the provided result rows.
func _collect_headers(rows: Array) -> Array:
	var seen: Dictionary = {}
	var headers: Array = []

	for row_value in rows:
		if not row_value is Dictionary:
			continue

		var row: Dictionary = row_value
		var keys := row.keys()

		keys.sort()

		for key_value in keys:
			var key := str(key_value)

			if seen.has(key):
				continue

			seen[key] = true
			headers.append(key)

	return headers


## Merges two header lists while preserving their existing order.
func _merge_headers(
	existing_headers: Array,
	new_headers: Array
) -> Array:
	var seen: Dictionary = {}
	var merged_headers: Array = []

	for header_value in existing_headers:
		var header := str(header_value)

		if seen.has(header):
			continue

		seen[header] = true
		merged_headers.append(header)

	for header_value in new_headers:
		var header := str(header_value)

		if seen.has(header):
			continue

		seen[header] = true
		merged_headers.append(header)

	return merged_headers


## Converts a result dictionary to values following the provided header order.
func _row_to_values(
	row: Dictionary,
	headers: Array
) -> Array:
	var values: Array = []

	for header_value in headers:
		var header := str(header_value)
		var value: Variant = row.get(header, "")

		values.append(
			_stringify_value(value)
		)

	return values


## Converts supported Godot values to their CSV string representation.
func _stringify_value(value: Variant) -> String:
	match typeof(value):
		TYPE_BOOL:
			return "true" if value else "false"

		TYPE_FLOAT, TYPE_INT:
			return str(value)

		TYPE_STRING:
			return str(value)

		TYPE_VECTOR2I:
			var vector: Vector2i = value
			return "%d,%d" % [
				vector.x,
				vector.y
			]

		TYPE_ARRAY, TYPE_DICTIONARY:
			return JSON.stringify(value)

		_:
			return str(value)


## Converts a list of values to a properly escaped CSV line.
func _csv_line_from_values(values: Array) -> String:
	var escaped_values: Array[String] = []

	for value in values:
		escaped_values.append(
			_escape_csv(str(value))
		)

	return ",".join(
		PackedStringArray(escaped_values)
	)


## Escapes a single value according to standard CSV quoting rules.
func _escape_csv(text: String) -> String:
	var needs_quotes := (
		text.contains(",")
		or text.contains("\"")
		or text.contains("\n")
		or text.contains("\r")
	)

	text = text.replace(
		"\"",
		"\"\""
	)

	if needs_quotes:
		return "\"" + text + "\""

	return text


## Parses a single CSV line while respecting quoted fields and escaped quotes.
func _parse_csv_line(line: String) -> Array:
	var values: Array = []
	var current_value := ""
	var in_quotes := false
	var index := 0

	while index < line.length():
		var character := line.substr(
			index,
			1
		)

		if character == "\"":
			if (
				in_quotes
				and index + 1 < line.length()
				and line.substr(index + 1, 1) == "\""
			):
				current_value += "\""
				index += 1
			else:
				in_quotes = not in_quotes

		elif character == "," and not in_quotes:
			values.append(current_value)
			current_value = ""

		else:
			current_value += character

		index += 1

	values.append(current_value)

	return values


## Ensures that the parent directory of the provided path exists.
func _ensure_parent_dir(path: String) -> bool:
	var directory_path := path.get_base_dir()

	if directory_path.is_empty():
		return true

	var error: Error = DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(directory_path)
	)

	return (
		error == OK
		or error == ERR_ALREADY_EXISTS
	)
