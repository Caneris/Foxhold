extends Node2D

@onready var heart: Area2D = %Heart
@onready var ui: Control = $UI
@onready var ui_coin_count_label: Control = $UI/CoinCountLabel

var coin_count : int = 0
var dragged_item : RigidBody2D

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if dragged_item and !event.is_pressed():
			dragged_item.drop(Input.get_last_mouse_velocity())
			dragged_item = null

func _ready() -> void:
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
