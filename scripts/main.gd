extends Node2D

@onready var heart: Area2D = %Heart
@onready var ui: Control = $UI
@onready var ui_coin_count_label: Control = $UI/CoinCountLabel

var coin_count : int = 0
var dragged_item : RigidBody2D
var intersect_params : PhysicsPointQueryParameters2D

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
