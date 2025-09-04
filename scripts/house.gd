extends Area2D

# house id
var house_id : int
@export var max_foxlings : int = 5
var n_foxlings : int = 0

# id in the structures array in main.gd
var structure_index : int = -1
var focused: bool = false

signal menu_item_selected(house_id, cost, menu_item_type)

@onready var menu : PopupMenu
@onready var main_scene = get_tree().current_scene
@onready var shader_material : ShaderMaterial = $Sprite2D.material

#@export var foxling_scenes = {
	#"Knight_Foxling": preload("res://scenes/knight_foxling.tscn"),
	#"Collector_Foxling": preload("res://scenes/collector_foxling.tscn")
#}


var foxling_scenes = {
	"Knight_Foxling": preload("res://scenes/knight_foxling.tscn")
}


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
	# Create a unique menu for this house instead of sharing
	menu = PopupMenu.new()
	get_tree().current_scene.get_node("UI_Layer/UI").add_child(menu)
	_populate_house_menu()
	
	input_event.connect(_on_house_input_event)
	menu.id_pressed.connect(_on_menu_item_selected)


func handle_ui_action(action_type: String) -> void:
	var cost = menu_item_costs[menu_item_ids[action_type]]

	# Emit signal to main for coin checking and deduction
	menu_item_selected.emit(house_id, cost, action_type)


func set_focused(is_focused: bool) -> void:
	if focused == is_focused:
		return  # No change, skip animation

	focused = is_focused

	if focused:
		show_outline()
	else:
		hide_outline()


func _set_outline_thickness(thickness: float) -> void:
	shader_material.set_shader_parameter("thickness", thickness)


func show_outline() -> void:
	var tween = create_tween()
	tween.tween_method(_set_outline_thickness, 0.0, main_scene.focus_outline_thickness, 0.3) # animate to thickness 2.0 over 0.3 seconds


func hide_outline() -> void:
	var tween = create_tween()
	tween.tween_method(_set_outline_thickness, main_scene.focus_outline_thickness, 0.0, 0.2)


func _on_house_input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
		_show_menu_at_mouse()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		# Left click focuses this house
		print("Focus house " + str(house_id) + " at index " + str(structure_index))
		main_scene.set_focus(main_scene.FocusType.HOUSE, structure_index)


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
	if n_foxlings >= max_foxlings:
		print("Max foxlings reached for this house!")
		return
	
	var foxling : CharacterBody2D = foxling_scenes[type].instantiate()
	foxling.position = global_position + Vector2(0, -50)  # Spawn
	get_tree().current_scene.add_child(foxling)
	n_foxlings += 1


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
