class_name MapRenderer
extends RefCounted

## Converts generated map data into a raster image.
##
## Walls and floor tiles are rendered using separate colors, while the
## selected start and end positions receive dedicated markers.


var wall_color: Color = Color(0.08, 0.08, 0.08, 1.0)
var floor_color: Color = Color(0.9, 0.9, 0.9, 1.0)
var start_color: Color = Color(0.2, 0.9, 0.2, 1.0)
var end_color: Color = Color(0.9, 0.2, 0.2, 1.0)


## Renders the provided map data to an RGBA image.
##
## Each logical map tile is represented by a square block of cell_size pixels.
## Start and end markers override the underlying floor or wall color.
func render_to_image(
	map_data: Dictionary,
	cell_size: int = 8
) -> Image:
	var grid: Array = map_data["grid"]
	var start: Vector2i = map_data["start"]
	var end: Vector2i = map_data["end"]

	var map_height: int = grid.size()
	var map_width: int = grid[0].size()

	var image := Image.create(
		map_width * cell_size,
		map_height * cell_size,
		false,
		Image.FORMAT_RGBA8
	)

	for y in range(map_height):
		for x in range(map_width):
			var position := Vector2i(x, y)

			var color := _get_cell_color(
				grid,
				position,
				start,
				end
			)

			_fill_cell(
				image,
				position,
				cell_size,
				color
			)

	return image


## Converts a rendered Image to an ImageTexture for display in the UI.
func image_to_texture(image: Image) -> ImageTexture:
	return ImageTexture.create_from_image(image)


## Returns the display color assigned to a map tile.
func _get_cell_color(
	grid: Array,
	position: Vector2i,
	start: Vector2i,
	end: Vector2i
) -> Color:
	if position == start:
		return start_color

	if position == end:
		return end_color

	if grid[position.y][position.x] == MapTypes.FLOOR:
		return floor_color

	return wall_color


## Fills the pixel area corresponding to a single logical map tile.
func _fill_cell(
	image: Image,
	position: Vector2i,
	cell_size: int,
	color: Color
) -> void:
	var start_x := position.x * cell_size
	var start_y := position.y * cell_size

	for y in range(start_y, start_y + cell_size):
		for x in range(start_x, start_x + cell_size):
			image.set_pixel(x, y, color)
