extends Node2D

var dragged_item : RigidBody2D

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if dragged_item and !event.is_pressed():
			dragged_item.drop(Input.get_last_mouse_velocity().limit_length(20))
			dragged_item = null

func _ready() -> void:
	for node in get_tree().get_nodes_in_group("item"):
		print(node.is_in_group("item"))
		node.clicked.connect(_on_item_clicked)

func _on_item_clicked(item: RigidBody2D) -> void:
	if !dragged_item:
		print("_on_item_clicked")
		item.pick_up()
		dragged_item = item
