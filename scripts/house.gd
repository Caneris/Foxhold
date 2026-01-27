extends Area2D

# house id
var house_id : int
@export var max_foxlings : int = 5
var n_foxlings : int = 0
var foxlings: Array = []
var level : int = 1
var paid_cost : int = 0

# id in the structures array in main.gd
var structure_index : int = -1
var focused: bool = false

signal menu_item_selected(house_id, cost, menu_item_type)

@onready var main_scene = get_tree().current_scene
@onready var shader_material : ShaderMaterial = $Sprite2D.material
@onready var foxling_number_label : Label = $FoxlingNumberLabel

#@export var foxling_scenes = {
	#"Knight_Foxling": preload("res://scenes/knight_foxling.tscn"),
	#"Collector_Foxling": preload("res://scenes/collector_foxling.tscn")
#}


var foxling_scenes = {
	"Knight_Foxling": preload("res://scenes/knight_foxling.tscn"),
	"Collector_Foxling": preload("res://scenes/collector_foxling.tscn")
}


var menu_item_ids = {
	"House_Upgrade": 0,
	"Knight_Foxling": 1,
	"Collector_Foxling": 2,
	"House_Destroy": 3
}


var menu_item_costs = {
	0: 0,  # House Upgrade cost
	1: 0,  # Knight Foxling cost
	2: 0,  # Collector Foxling cost
	3: 0   # House Destroy cost
}


func _ready() -> void:

	input_event.connect(_on_house_input_event)
	update_foxling_number_label()

	_initialize_costs()


func _initialize_costs() -> void:
	print("Initializing costs for house ", house_id)
	var wave : int = main_scene.enemy_spawner.wave_number
	print("Current wave: ", wave)
	menu_item_costs[0] = main_scene.cost_data.get_inflated_cost("House_Upgrade", wave)  # House Upgrade
	menu_item_costs[1] = main_scene.cost_data.get_inflated_cost("Knight_Foxling", wave)   # Knight Foxling
	menu_item_costs[2] = main_scene.cost_data.get_inflated_cost("Collector_Foxling", wave) # Collector Foxling


func handle_ui_action(action_type: String) -> void:
	var cost = menu_item_costs[menu_item_ids[action_type]]
	print("House ", house_id, " selected action: ", action_type, " with cost: ", cost)
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
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		# Left click focuses this house
		print("Focus house " + str(house_id) + " at index " + str(structure_index))
		main_scene.set_focus(main_scene.FocusType.HOUSE, structure_index)


# func _show_menu_at_mouse() -> void:
# 	menu.position = get_global_mouse_position()
# 	menu.show()


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
	level += 1
	max_foxlings += 2
	update_foxling_number_label()
	# You can add more upgrade logic here (e.g., change appearance, stats, etc.)

func _spawn_foxling(type : String) -> void:
	print("create a foxling of type ", type)
	if n_foxlings >= max_foxlings:
		print("Max foxlings reached for this house!")
		return
	
	var foxling : CharacterBody2D = foxling_scenes[type].instantiate()
	foxling.position = global_position + Vector2(0, -50)  # Spawn
	get_tree().current_scene.add_child(foxling)
	foxlings.append(foxling)
	n_foxlings += 1

	if type == "Collector_Foxling":
		foxling.coin_deposited.connect(main_scene._coin_entered_heart)

	update_foxling_number_label()


func update_foxling_number_label() -> void:
	foxling_number_label.text = "🦊" + str(n_foxlings) + "/" + str(max_foxlings)


func destroy() -> void:
	for foxling in foxlings:
		if is_instance_valid(foxling):
			if foxling.has_method("cleanup"):
				foxling.cleanup()
			foxling.queue_free()
	foxlings.clear()
	remove_from_group("focusable_structures")
	queue_free()
