extends RigidBody2D

signal clicked

var dragging : bool = false
var drag_offset := Vector2.ZERO

func _ready() -> void:
	input_pickable = true
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE

func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			print("clicked")
			clicked.emit(self)

func _physics_process(delta: float) -> void:
	if dragging:
		global_transform.origin = get_global_mouse_position()

func pick_up() -> void:
	if dragging:
		return
	freeze = true
	dragging = true

func drop(impulse = Vector2.ZERO) -> void:
	if dragging:
		freeze = false
		apply_central_impulse(impulse)
		dragging = false
