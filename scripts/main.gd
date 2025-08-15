extends Node2D

@onready var heart: Area2D = %Heart
@onready var ui: Control = $UI_Layer/UI
@onready var ui_coin_count_label: Control = $UI_Layer/UI/CoinCountLabel
@onready var house_container: Node2D = $HouseContainer



var coin_count : int = 0
var dragged_item : RigidBody2D
var intersect_params : PhysicsPointQueryParameters2D

@onready var house_positions: Array[Marker2D] = [
	$HousePositions/Position1,
	$HousePositions/Position2
]

var building_scenes = {
	"House": preload("res://scenes/house.tscn"),
	#"Tower": preload("res://scenes/tower.tscn"),
	#"Wall": preload("res://scenes/wall.tscn")
}

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if dragged_item and !event.is_pressed():
			dragged_item.drop(Input.get_last_mouse_velocity())
			dragged_item = null
		#elif event.is_pressed():
			#var mouse_pos := get_global_mouse_position()
			#var state_space := get_world_2d().direct_space_state 
			#
			## parameter setting for state_space.intersect_point()
			#set_intersect_params(mouse_pos)
			#
			#var result := state_space.intersect_point(intersect_params, 32)
			#var res_len : int = result.size()
			#print("number of enemy node: " + str(res_len))
			#if result.size() > 0:
				#var enemy = result[0].collider
				#enemy.take_damage()

#func set_intersect_params(mouse_pos : Vector2) -> void:
	#intersect_params.position = mouse_pos
	#intersect_params.collide_with_areas = false
	#intersect_params.collide_with_bodies = true
	#intersect_params.collision_mask = 1 << 2

func _ready() -> void:
	var vp := get_viewport()
	vp.physics_object_picking_sort = true
	vp.physics_object_picking_first_only = true
	
	#intersect_params = PhysicsPointQueryParameters2D.new()
	heart.menu_item_selected.connect(_selected_menu_item)
	heart.coin_in_heart.connect(_coin_entered_heart)
	for node in get_tree().get_nodes_in_group("item"):
		print(node.is_in_group("item"))
		node.clicked.connect(_on_item_clicked)

func _on_item_clicked(item: RigidBody2D) -> void:
	if !dragged_item:
		item.pick_up()
		dragged_item = item

func _coin_entered_heart(coin: RigidBody2D) -> void:
	coin_count += 1
	print("new coin count: " + str(coin_count))
	ui_coin_count_label.text = "COIN COUNT: " + str(coin_count)
	coin.queue_free()

func _selected_menu_item(cost: int, menu_item_type) -> void:
	print("item signal reached main: " + str(cost) + " coins and " + str(menu_item_type) + " type!")
	if cost > coin_count:
		print("Not enough coins!")
		if building_scenes.has(menu_item_type):
			var building = building_scenes[menu_item_type].instantiate()
	else:
		_create_item(cost, menu_item_type)

func _create_item(cost: int, type: String) -> void:
	print("A " + str(type) + " will be created!")
	
	match type:
		"House":
			if try_create_house():
				coin_count -= cost
				print("new coin count: " + str(coin_count))
				ui_coin_count_label.text = "COIN COUNT: " + str(coin_count)
		"Tower":
			pass
		"Wall":
			pass

func try_create_house() -> bool:
	var n_house : int = house_container.get_child_count()
	if n_house >= house_positions.size():
		return false # no spots left
	
	var house : Area2D = building_scenes["House"].instantiate()
	house_container.add_child(house)
	house.global_position = house_positions[n_house - 1].global_position
	return true
