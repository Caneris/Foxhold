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

var zoom_levels: Array[float] = [0.5, 1.0, 2.0]
var target_zoom_index: int = 1
var zoom_tween: Tween

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
	if Input.is_action_just_pressed("zoom_in"):
		# _adjust_zoom(zoom_speed * delta * 5.0)
		_adjust_zoom(1.0)
	if Input.is_action_just_pressed("zoom_out"):
		# _adjust_zoom(-zoom_speed * delta * 5.0)
		_adjust_zoom(-1.0)

	# Apply panning (scale by inverse zoom so pan feels consistent)
	if pan_direction != 0.0:
		position.x += pan_direction * pan_speed * delta / zoom.x
		_clamp_position()

	# Always keep Y anchored to floor (must be after any position changes)
	var vp_size = get_viewport_rect().size
	var visible_height = vp_size.y - ui_height
	position.y = floor_y - (visible_height / zoom.y)


func _unhandled_input(event: InputEvent) -> void:
	# Mouse wheel zoom
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			# _adjust_zoom(zoom_speed)
			_adjust_zoom(1.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			# _adjust_zoom(-zoom_speed)
			_adjust_zoom(-1.0)

	# Trackpad pinch zoom
	if event is InputEventPanGesture:
		_adjust_zoom(-1.0*float(sign(event.delta.y)))


func _adjust_zoom(direction: float) -> void: # before the argument was amount: float, I change it to have a snap zoom (because of pixel art)
	# var new_zoom: float = clamp(zoom.x + amount, min_zoom, max_zoom)
	# zoom = Vector2(new_zoom, new_zoom)
	var old_index = target_zoom_index

	if direction > 0 and target_zoom_index < zoom_levels.size() - 1:
		target_zoom_index += 1
	elif direction < 0 and target_zoom_index > 0:
		target_zoom_index -= 1

	if old_index == target_zoom_index:
		return

	# Get mouse position in world space before zoom
	var mouse_world_x = get_global_mouse_position().x

	# Calculate target camera position
	var target_zoom_value = zoom_levels[target_zoom_index]
	var viewport_size = get_viewport_rect().size
	var view_width = viewport_size.x / target_zoom_value
	var target_x = mouse_world_x - view_width / 2.0

	# Clamp target_x
	target_x = clamp(target_x, floor_left, floor_right - view_width)

	# Kill existing tween if running
	if zoom_tween and zoom_tween.is_running():
		zoom_tween.kill()

	# Create smooth tween
	zoom_tween = create_tween()
	zoom_tween.set_parallel(true)
	zoom_tween.tween_property(self, "zoom", Vector2(target_zoom_value, target_zoom_value), 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	zoom_tween.tween_property(self, "position:x", target_x, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	# zoom_tween.tween_callback(_apply_zoom_and_clamp).set_delay(0.3)


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
