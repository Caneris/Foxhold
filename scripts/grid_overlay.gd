extends Node2D

var main: Node

func _draw() -> void:
	if not main or not main.building_mode:
		return

	var vp_size: Vector2 = main.sub_viewport.size
	var start_x := 0
	var end_x := int(vp_size.x)

	for x in range(start_x, end_x + 1, main.grid_size):
		draw_circle(Vector2(x, main.house_floor_y), main.grid_dot_radius, main.grid_dot_color)

	if main.building_preview:
		var local_x : float = main.building_preview.position.x
		var highlight_pos := Vector2(local_x, main.house_floor_y)
		draw_circle(highlight_pos, main.grid_dot_radius * 1.8, main.grid_dot_highlight_color)