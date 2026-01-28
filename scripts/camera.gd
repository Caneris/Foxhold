extends Camera2D

@export var pan_speed: float = 300.0
@export var edge_margin: float = 50.0
@export var min_zoom: float = 0.5  # zoomed out, sees more
@export var max_zoom: float = 1.0  # zoomed in, normal view
@export var zoom_speed: float = 0.1
@export var floor_left: float = -320.0
@export var floor_right: float = 960.0
@export var floor_y: float = 300.0  # world Y position of the floor
@export var ui_height: float = 81.0  # height of bottom UI panel in pixels


func _ready() -> void:
	_apply_zoom_and_clamp()


func _process(delta: float) -> void:
	var pan_direction := 0.0

	# Keyboard panning
	if Input.is_action_pressed("camera_left"):
		pan_direction -= 1.0
	if Input.is_action_pressed("camera_right"):
		pan_direction += 1.0

	# Mouse edge panning
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var viewport_size: Vector2 = get_viewport_rect().size

	if mouse_pos.x < edge_margin:
		pan_direction -= 1.0
	elif mouse_pos.x > viewport_size.x - edge_margin:
		pan_direction += 1.0

	# Keyboard zoom
	if Input.is_action_pressed("zoom_in"):
		_adjust_zoom(zoom_speed * delta * 5.0)
	if Input.is_action_pressed("zoom_out"):
		_adjust_zoom(-zoom_speed * delta * 5.0)

	# Apply panning (scale by inverse zoom so pan feels consistent)
	if pan_direction != 0.0:
		position.x += pan_direction * pan_speed * delta / zoom.x
		_clamp_position()


func _unhandled_input(event: InputEvent) -> void:
	# Mouse wheel zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_adjust_zoom(zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_adjust_zoom(-zoom_speed)

	# Trackpad pinch zoom
	if event is InputEventPanGesture:
		_adjust_zoom(-event.delta.y * zoom_speed)


func _adjust_zoom(amount: float) -> void:
	var new_zoom: float = clamp(zoom.x + amount, min_zoom, max_zoom)
	zoom = Vector2(new_zoom, new_zoom)
	_apply_zoom_and_clamp()


func _apply_zoom_and_clamp() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size

	# Position floor_y at screen position just above the UI panel
	# Formula: (floor_y - position.y) * zoom = viewport_height - ui_height
	var visible_height: float = viewport_size.y - ui_height
	position.y = floor_y - (visible_height / zoom.y)

	_clamp_position()


func _clamp_position() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var view_width: float = viewport_size.x / zoom.x

	# Clamp X so visible area stays within floor bounds
	position.x = clamp(position.x, floor_left, floor_right - view_width)
