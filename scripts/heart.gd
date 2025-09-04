extends Area2D

signal coin_in_heart(coin)
signal menu_item_selected(cost, menu_item_type)


# id in the structures array in main.gd
var structure_index : int = -1
var focused: bool = false

# get main scene
@onready var main_scene = get_tree().current_scene

@export var max_health : float = 20.0
@onready var health_bar: ProgressBar = %HealthBar
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var shader_material : ShaderMaterial = $AnimatedSprite2D.material


var menu_item_ids = {
	"House": 0,
	"Tower": 1,
	"Wall": 2
}

var menu_item_costs = {
	0: 2, # House cost
	1: 10, # Tower cost
	2: 25 # Wall cost
}


func _ready() -> void:

	animated_sprite.play("default")
	health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	initiate_health(max_health)
	body_entered.connect(_on_body_entered)
	
	input_event.connect(_on_heart_input_event)
	#mouse_entered.connect(_on_mouse_entered)
	#mouse_exited.connect(_on_heart_mouse_exited)

	
	# build_house_button.pressed.connect(func(): _create_item(menu_item_costs[0], "House"))
	# build_tower_button.pressed.connect(func(): _create_item(menu_item_costs[1], "Tower"))
	# build_wall_button.pressed.connect(func(): _create_item(menu_item_costs[2], "Wall"))


func handle_ui_action(action_type: String) -> void:
	var cost = menu_item_costs[menu_item_ids[action_type]]

	# Emit signal to main for coin checking and deduction
	_create_item(cost, action_type)


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


func _on_heart_input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		# Left click focuses this heart
		print("Focus heart at index " + str(structure_index))
		main_scene.set_focus(main_scene.FocusType.HEART, structure_index)


func _on_menu_item_selected(id: int) -> void:
	var cost : int = menu_item_costs[id]
	match id:
		0:
			_create_item(cost, "House")
		1:
			_create_item(cost, "Tower")
		2:
			_create_item(cost, "Wall")


func _create_item(cost: int, type: String) -> void:
	menu_item_selected.emit(cost, type)


func take_damage(damage: float) -> void:
	health_bar.value = max(health_bar.value - damage, 0)


func initiate_health(value: float) -> void:
	health_bar.max_value = max_health
	health_bar.value = value


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("coin"):
		coin_in_heart.emit(body)
