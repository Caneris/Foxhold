extends Node2D

func _ready() -> void:
	for node in get_tree().get_nodes_in_group("item"):
		node.clicked.connect(_on_item_clicked)

func _on_item_clicked() -> void:
	print("_on_item_clicked")
