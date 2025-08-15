extends Area2D

signal coin_in_heart(coin)
signal menu_item_selected(cost, menu_item_type)


@export var max_health : float = 20.0
@onready var health_bar: ProgressBar = %HealthBar
@onready var menu : PopupMenu
@onready var sprite_2d: Sprite2D = $Sprite2D

#var mouse_over_heart : bool = false

var menu_item_ids = {
	"House": 0,
	"Tower": 1,
	"Wall": 2
}

var menu_item_costs = {
	0: 5, # House cost
	1: 10, # Tower cost
	2: 25 # Wall cost
}


func _ready() -> void:
	health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu = get_tree().current_scene.get_node("UI_Layer/UI/HeartMenu")
	_populate_heart_menu()
	initiate_health(max_health)
	body_entered.connect(_on_body_entered)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_heart_mouse_exited)
	
	menu.mouse_exited.connect(_on_menu_mouse_exited)
	menu.id_pressed.connect(_on_menu_item_selected)


func _populate_heart_menu() -> void:
	menu.clear()
	_add_menu_item("House")
	_add_menu_item("Tower")
	_add_menu_item("Wall")

func _add_menu_item(name: String) -> void:
	var id : int = menu_item_ids[name]
	menu.add_item(name + " (" + str(menu_item_costs[id]) + " coins)", id)

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
	print("Created an item of type " + str(type) + "!")
	print("It costs " + str(cost) + " coins")
	menu_item_selected.emit(cost, type)

#func _create_tower(cost: int) -> void:
	#print("Created a tower!")
	#print("It costs " + str(cost) + " coins")
	#menu_item_selected.emit(cost)
#
#func _create_wall(cost: int) -> void:
	#print("Created a wall!")
	#print("It costs " + str(cost) + " coins")
	#menu_item_selected.emit(cost)

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
	call_deferred("_try_hide_menu")

func _on_menu_mouse_exited() -> void:
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
