extends Area2D

signal menu_item_selected(cost, menu_item_type)

@onready var menu : PopupMenu


var menu_item_ids = {
	"House_Upgrade": 0,
	"Knight_Foxling": 1,
	"Collector_Foxling": 2
}


var menu_item_costs = {
	0: 15,  # House Upgrade cost
	1: 10,  # Knight Foxling cost
	2: 8    # Collector Foxling cost
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
			_create_item(cost, "House_Upgrade")
		1:
			_create_item(cost, "Knight_Foxling")
		2:
			_create_item(cost, "Collector_Foxling")


func _create_item(cost: int, type: String) -> void:
	print("Created an item of type " + str(type) + "!")
	print("It costs " + str(cost) + " coins")
	menu_item_selected.emit(cost, type)


func _populate_house_menu() -> void:
	menu.clear()
	_add_menu_item("House_Upgrade")
	menu.add_separator()  # This adds the horizontal line
	_add_menu_item("Knight_Foxling")
	_add_menu_item("Collector_Foxling")


func _add_menu_item(name: String) -> void:
	var id : int = menu_item_ids[name]
	var display_name = name.replace("_", " ")  # Convert underscores to spaces for display
	menu.add_item(display_name + " (" + str(menu_item_costs[id]) + " coins)", id)
