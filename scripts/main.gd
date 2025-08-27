"""
In this script, the main game logic is managed. Structures for the game world, 
such as houses and enemies, are created and managed. 
While house etc are managed created here, foxlings are created in the house.gd script.
However, the main script also listens to signals from the house.gd script to create foxlings
and check whether the player has enough coins to create items.
"""

extends Node2D

@onready var heart: Area2D = %Heart
@onready var ui: Control = $UI_Layer/UI
@onready var ui_coin_count_label: Control = $UI_Layer/UI/BottomPanel/HBoxContainer/NinePatchRect/StatsSection/CoinCountLabel
@onready var house_container: Node2D = $HouseContainer
@onready var enemy_spawner: Node2D = $EnemySpawner



var coin_count : int = 10
var dragged_item : RigidBody2D
var intersect_params : PhysicsPointQueryParameters2D
var n_house : int = 0
var house_array : Array[Area2D] = []


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

	# initialize coin count display
	ui_coin_count_label.text = "coin count: " + str(coin_count)
	
	# connect ui and enemy spawner signals
	enemy_spawner.wave_countdown_started.connect(ui._on_countdown_started)
	enemy_spawner.countdown_updated.connect(ui._on_countdown_updated)
	
	#intersect_params = PhysicsPointQueryParameters2D.new()
	heart.menu_item_selected.connect(_selected_menu_item)
	heart.coin_in_heart.connect(_coin_entered_heart)

	for node in get_tree().get_nodes_in_group("item"):
		print(node.is_in_group("item"))
		node.clicked.connect(_on_item_clicked)


func update_coin_count(amount: int) -> void:
	coin_count += amount
	ui_coin_count_label.text = "coin count: " + str(coin_count)

func _on_item_clicked(item: RigidBody2D) -> void:
	if !dragged_item:
		item.pick_up()
		dragged_item = item

func _coin_entered_heart(coin: RigidBody2D) -> void:
	update_coin_count(1)
	coin.queue_free()

func _selected_menu_item(cost : int, menu_item_type : String) -> void:
	print("item signal reached main: " + str(cost) + " coins and " + str(menu_item_type) + " type!")
	if cost > coin_count:
		print("Not enough coins!")
	else:
		_create_item(cost, menu_item_type)


func _selected_house_menu_item(house_id: int, cost: int, menu_item_type: String) -> void:
	print("House " + str(house_id) + " selected item: " + str(menu_item_type) + " with cost: " + str(cost))
	if cost > coin_count:
		print("Not enough coins!")
	else:
		_create_house_item(house_id, cost, menu_item_type)


func _create_item(cost: int, type: String) -> void:
	print("main: A " + str(type) + " will be created!")
	
	match type:
		"House":
			if try_create_house():
				update_coin_count(-cost)
		"Tower":
			pass
		"Wall":
			pass


func _create_house_item(house_id : int, cost: int, type: String) -> void:
	print("main: A " + str(type) + " will be created for house " + str(house_id) + "!")
	var house : Area2D = house_array[house_id]
	match type:
		"House_Upgrade":
			if coin_count >= cost:
				update_coin_count(-cost)
				# Call the house's upgrade function
				house._upgrade_house()
			else:
				print("Not enough coins to upgrade house!")
		"Knight_Foxling", "Collector_Foxling":
			if coin_count >= cost and house.n_foxlings < house.max_foxlings:
				update_coin_count(-cost)
				house._spawn_foxling(type)
			else:
				print("Not enough coins or max foxlings reached!")


func try_create_house() -> bool:
	if n_house >= house_positions.size():
		return false # no spots left

	var house : Area2D = building_scenes["House"].instantiate()
	house_container.add_child(house)
	house.house_id = n_house
	house_array.append(house)
	# connect house menu item selected signal to main script
	house.menu_item_selected.connect(_selected_house_menu_item)
	house.global_position = house_positions[n_house].global_position
	n_house += 1
	return true
