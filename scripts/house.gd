extends Area2D

# house id
var house_id : int
var max_foxlings : int = 2
var n_foxlings : int = 0

signal menu_item_selected(house_id, cost, menu_item_type)

@onready var menu : PopupMenu


#@export var foxling_scenes = {
	#"Knight_Foxling": preload("res://scenes/knight_foxling.tscn"),
	#"Collector_Foxling": preload("res://scenes/collector_foxling.tscn")
#}


var menu_item_ids = {
	"House_Upgrade": 0,
	"Knight_Foxling": 1,
	"Collector_Foxling": 2
}


var menu_item_costs = {
	0: 5,  # House Upgrade cost
	1: 3,  # Knight Foxling cost
	2: 2    # Collector Foxling cost
}


func _ready() -> void:
	menu = get_tree().current_scene.get_node("UI_Layer/UI/HouseMenu")
	_populate_house_menu()
	
	input_event.connect(_on_house_input_event)
	menu.id_pressed.connect(_on_menu_item_selected)


func _on_house_input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
		_show_menu_at_mouse()


func _show_menu_at_mouse() -> void:
	menu.position = get_global_mouse_position()
	menu.show()


func _on_menu_item_selected(id: int) -> void:
	var cost : int = menu_item_costs[id]
	match id:
		0:
			menu_item_selected.emit(house_id, cost, "House_Upgrade")
		1:
			menu_item_selected.emit(house_id, cost, "Knight_Foxling")
		2:
			menu_item_selected.emit(house_id, cost, "Collector_Foxling")




# func _create_item(type: String) -> void:
# 	match type:
# 		"House_Upgrade" : _upgrade_house()
# 		"Knight_Foxling", "Collector_Foxling": _spawn_foxling(type) 


func _upgrade_house() -> void:
	print("upgrade house!")


func _spawn_foxling(type : String) -> void:
	print("create a foxling of type ", type)


func _populate_house_menu() -> void:
	menu.clear()
	_add_menu_item("House_Upgrade")
	menu.add_separator()  # This adds the horizontal line
	_add_menu_item("Knight_Foxling")
	_add_menu_item("Collector_Foxling")


func _add_menu_item(item_name: String) -> void:
	var id : int = menu_item_ids[item_name]
	var display_name = item_name.replace("_", " ")  # Convert underscores to spaces for display
	menu.add_item(display_name + " (" + str(menu_item_costs[id]) + " coins)", id)
