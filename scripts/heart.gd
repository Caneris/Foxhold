extends Area2D

signal coin_in_heart(coin)

@export var max_health : float = 20.0
@onready var health_bar: ProgressBar = %HealthBar
@onready var menu : PopupMenu
@onready var sprite_2d: Sprite2D = $Sprite2D


func _ready() -> void:
	menu = get_tree().current_scene.get_node("UI_Layer/UI/HeartMenu")
	initiate_health(max_health)
	body_entered.connect(_on_body_entered)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_menu_mouse_exited)

func take_damage(damage: float) -> void:
	print("heart takes " + str(damage) + " damage!")
	health_bar.value = max(health_bar.value - damage, 0)

func initiate_health(value: float) -> void:
	health_bar.max_value = max_health
	health_bar.value = value

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("coin"):
		coin_in_heart.emit(body)

func _on_mouse_entered() -> void:
	var heart_pos = global_position
	var offset = Vector2(menu.size.x * 0.5, 0)
	var target_point = heart_pos - offset
	
	menu.position = target_point
	menu.show()

func _on_menu_mouse_exited() -> void:
	print("mouse exited heart")
