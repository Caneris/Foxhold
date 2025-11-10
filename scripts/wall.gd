extends Area2D

# id in the structures array in main.gd
var structure_index : int = -1
var focused: bool = false

@export var max_health: int = 100
var is_destroyed: bool = false
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = %HealthBar
var damage_tween: Tween  # Add this 
@onready var shader_material : ShaderMaterial = $AnimatedSprite2D.material
@onready var main_scene = get_tree().current_scene

func _ready() -> void:
	_set_destroyed(false)
	health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	initiate_health(max_health)
	input_event.connect(_on_wall_input_event)


func _on_wall_input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		# Left click focuses this wall
		print("Focus wall at index " + str(structure_index))
		main_scene.set_focus(main_scene.FocusType.WALL, structure_index)


func set_focused(is_focused: bool) -> void:
	if focused == is_focused:
		return  # No change, skip animation

	focused = is_focused

	if focused:
		show_outline()
	else:
		hide_outline()


func _set_outline_thickness(thickness: float) -> void:
	shader_material.set_shader_parameter("thickness", thickness)


func show_outline() -> void:
	var tween = create_tween()
	tween.tween_method(_set_outline_thickness, 0.0, main_scene.focus_outline_thickness, 0.3) # animate to thickness 2.0 over 0.3 seconds


func hide_outline() -> void:
	var tween = create_tween()
	tween.tween_method(_set_outline_thickness, main_scene.focus_outline_thickness, 0.0, 0.2)


func initiate_health(value: int) -> void:
	health_bar.max_value = max_health
	health_bar.value = value


func take_damage(amount: int):
	if is_destroyed:
		return  # Can't damage a destroyed wall
	
	health_bar.value = max(health_bar.value - amount, 0)

	# Kill any existing tween before creating a new one
	if damage_tween:
		damage_tween.kill()
	
	# Reset to base color first, then flash
	animated_sprite.modulate = Color(1, 1, 1, 1)
	
	damage_tween = create_tween()
	damage_tween.tween_property(animated_sprite, "modulate", Color(3.0, 3.0, 3.0, 1), 0.1)
	damage_tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1, 1), 0.1)

	if health_bar.value <= 0:
		_set_destroyed(true)


func _set_destroyed(destroyed: bool):
	is_destroyed = destroyed
	$CollisionShape2D.set_deferred("disabled", destroyed)

	if destroyed:
		$AnimatedSprite2D.play("destroyed")
	else:
		$AnimatedSprite2D.play("default")  # or "intact"/"normal"


func repair(amount: int):
	health_bar.value = min(health_bar.value + amount, max_health)

	if is_destroyed and health_bar.value > 0:
		_set_destroyed(false)


func rebuild():
	if is_destroyed:
		health_bar.value = max_health
		_set_destroyed(false)
