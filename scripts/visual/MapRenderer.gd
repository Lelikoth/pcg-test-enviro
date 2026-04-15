extends RefCounted
class_name MapRenderer

var wall_color := Color(0.08, 0.08, 0.08, 1.0)
var floor_color := Color(0.9, 0.9, 0.9, 1.0)
var start_color := Color(0.2, 0.9, 0.2, 1.0)
var end_color := Color(0.9, 0.2, 0.2, 1.0)

func render_to_image(map_data: Dictionary, cell_size: int = 8) -> Image:
	var grid: Array = map_data["grid"]
	var start: Vector2i = map_data["start"]
	var end: Vector2i = map_data["end"]

	var map_height: int = grid.size()
	var map_width: int = grid[0].size()

	var image := Image.create(map_width * cell_size, map_height * cell_size, false, Image.FORMAT_RGBA8)

	for y in range(map_height):
		for x in range(map_width):
			var color: Color = wall_color
			if grid[y][x] == MapTypes.FLOOR:
				color = floor_color

			if Vector2i(x, y) == start:
				color = start_color
			elif Vector2i(x, y) == end:
				color = end_color

			_fill_rect(image, x * cell_size, y * cell_size, cell_size, cell_size, color)

	return image

func image_to_texture(image: Image) -> ImageTexture:
	return ImageTexture.create_from_image(image)

func _fill_rect(image: Image, start_x: int, start_y: int, width: int, height: int, color: Color) -> void:
	for y in range(start_y, start_y + height):
		for x in range(start_x, start_x + width):
			image.set_pixel(x, y, color)
