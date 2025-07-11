extends RigidBody2D

var dragging : bool = false
var drag_offset := Vector2.ZERO
var prev_mouse_pos := Vector2.ZERO
var mouse_velocity := Vector2.ZERO

@export var throw_strength : float = 1.0
@export var max_throw_speed : float = 10.0

func _ready() -> void:
	input_pickable = true
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE

func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			# drag the item
			dragging = true
			# freeze physics and behave like kinematic
			freeze = true
			freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
			# reset any existing motion
			linear_velocity = Vector2.ZERO
			prev_mouse_pos = get_global_mouse_position()
			drag_offset = global_position - prev_mouse_pos

func _physics_process(delta: float) -> void:
	if dragging:
		# follow the mouse
		var mp = get_global_mouse_position()
		global_position = mp + drag_offset
		
		# sample mouse velocity
		mouse_velocity = Input.get_last_mouse_velocity() #((mp - prev_mouse_pos) / delta).limit_length(max_throw_speed)
		print("mouse_velocity: " + str(mouse_velocity.length()))
		prev_mouse_pos = mp
		
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			# throw / drop
			dragging = false
			freeze = false
			
			# apply impulse
			apply_central_impulse(mouse_velocity.limit_length(max_throw_speed) * throw_strength)
