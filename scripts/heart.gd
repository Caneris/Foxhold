extends Area2D

signal coin_in_heart(coin)

@export var max_health : float = 20.0
@onready var health_bar: ProgressBar = %HealthBar
@onready var menu : PopupMenu
@onready var sprite_2d: Sprite2D = $Sprite2D

#var mouse_over_heart : bool = false

func _ready() -> void:
	health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu = get_tree().current_scene.get_node("UI_Layer/UI/HeartMenu")
	initiate_health(max_health)
	body_entered.connect(_on_body_entered)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_heart_mouse_exited)
	
	menu.mouse_exited.connect(_on_menu_mouse_exited)

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

func _on_heart_mouse_exited() -> void:
	print("mouse exited heart")
	call_deferred("_try_hide_menu")

func _on_menu_mouse_exited() -> void:
	print("mouse exited menu")
	call_deferred("_try_hide_menu")

func _try_hide_menu() -> void:
	var mpos = get_viewport().get_mouse_position()
	var menu_rect : Rect2 = Rect2(menu.position, menu.size)
	
	# build heart rect
	var tex_size : Vector2 = sprite_2d.texture.get_size() * sprite_2d.global_scale
	var heart_tl : Vector2 = global_position - tex_size * 0.5
	var heart_rect : Rect2 = Rect2(heart_tl, tex_size)
	
	var over_menu : bool = menu_rect.has_point(mpos)
	var over_heart : bool = heart_rect.has_point(mpos)
	
	if not over_heart and not over_menu:
		menu.hide()
		print("neither over heart nor menu")

func _populate_heart_menu() -> void:
	pass
