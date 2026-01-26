extends RigidBody2D

signal clicked

var dragging : bool = false
var throwing : bool = false

var last_position : Vector2
var throw_velocity : Vector2

var drag_offset := Vector2.ZERO

@export var max_throw_speed : float = 150.0
@export var min_throw_speed : float = 100.0

func _ready() -> void:
	input_pickable = true
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC

func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			clicked.emit(self)

func _physics_process(delta: float) -> void:
	if dragging:
		var current_pos : Vector2 = get_global_mouse_position()
		if last_position != Vector2.ZERO:
			throw_velocity = ((current_pos - last_position) / delta).limit_length(max_throw_speed)
		last_position = current_pos
		global_transform.origin = current_pos
		# global_transform.origin = get_global_mouse_position()
	else:
		if linear_velocity.length() > max_throw_speed and throwing:
			linear_velocity = linear_velocity.normalized() * max_throw_speed

func pick_up() -> void:
	if dragging:
		return
	freeze = true
	dragging = true
	throwing = false
	collision_layer = 0
	
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0

func drop(impulse = Vector2.ZERO) -> void:
	# impulse = impulse.limit_length(max_throw_speed)
	if dragging:
		freeze = false
		if throw_velocity.length() > min_throw_speed:
			throwing = true
			apply_central_impulse(throw_velocity*mass)
		dragging = false
		throw_velocity = Vector2.ZERO

		# Restore collision after physics has a frame to apply the impulse
		await get_tree().physics_frame
		collision_layer = 8
