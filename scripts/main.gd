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
@onready var ui_coin_count_label: Control = $UI_Layer/UI/BottomPanel/HBoxContainer/StatsSectionBackground/StatsSection/CoinCountLabel
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


# building mode and placement variables
var building_mode: bool = false
var building_preview: Area2D = null  # Changed to Area2D to match house scene root
@export var grid_size: int = 64
@export var house_floor_y: float = 233.267
var grid_dots: Array[Sprite2D] = []
# pending cost for an in-progress building preview (refunded on cancel)
var pending_build_cost: int = 0

# grid dot visuals
@export var grid_dot_color: Color = Color(1, 1, 1, 0.25)
@export var grid_dot_highlight_color: Color = Color(1, 0.7, 0, 0.9)
@export var grid_dot_radius: float = 3.0

# focus variables and constants

enum FocusType { HEART, HOUSE, WALL, TOWER }
var current_focus_type: FocusType = FocusType.HEART
var focusable_structures: Array = []
var old_focus_index: int = -1
var current_focus_index: int = 0
# var focused_structure: Node = null
var focus_outline_thickness: float = 1.0

# ui action sections
@onready var heart_action_section: Control = $UI_Layer/UI/BottomPanel/HBoxContainer/ActionSectionBackground/HeartActionSection
@onready var house_action_section: Control = $UI_Layer/UI/BottomPanel/HBoxContainer/ActionSectionBackground/HouseActionSection

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if dragged_item and !event.is_pressed():
			dragged_item.drop(Input.get_last_mouse_velocity())
			dragged_item = null
	
	# Add focus switching using input actions
	if Input.is_action_just_pressed("ui_left"):
		print("left pressed")
		_cycle_focus_left()
	elif Input.is_action_just_pressed("ui_right"):
		print("right pressed")
		_cycle_focus_right()

	if building_mode and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_place_building()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_cancel_building()


func _ready() -> void:
	var vp := get_viewport()
	vp.physics_object_picking_sort = true
	vp.physics_object_picking_first_only = true

	# initialize coin count display
	ui_coin_count_label.text = "coin count: " + str(coin_count)
	ui.action_button_pressed.connect(_on_ui_action_pressed)
	
	# connect ui and enemy spawner signals
	enemy_spawner.wave_countdown_started.connect(ui._on_countdown_started)
	enemy_spawner.countdown_updated.connect(ui._on_countdown_updated)
	
	#intersect_params = PhysicsPointQueryParameters2D.new()
	heart.menu_item_selected.connect(_selected_menu_item)
	heart.coin_in_heart.connect(_coin_entered_heart)

	for node in get_tree().get_nodes_in_group("item"):
		print(node.is_in_group("item"))
		node.clicked.connect(_on_item_clicked)

	# setup focus system
	_setup_focus_system()
	_focus_structure_at_index(current_focus_index)


func _process(delta: float) -> void:
	if building_mode and building_preview:
		var mouse_pos = get_global_mouse_position()
		# snap preview X to grid
		var snapped_x = snap_to_grid(mouse_pos.x)
		building_preview.position.x = snapped_x
		# preview cannot go out of screen (house position plus half house width, get house width from building scene)
		var house_width = building_preview.get_node("Sprite2D").texture.get_size().x
		var house_scale = building_preview.get_node("Sprite2D").scale.x
		var scaled_house_width = house_width * house_scale
		if building_preview.position.x < scaled_house_width / 2:
			building_preview.position.x = scaled_house_width / 2
		elif building_preview.position.x > get_viewport_rect().size.x - scaled_house_width / 2:
			building_preview.position.x = get_viewport_rect().size.x - scaled_house_width / 2

		if building_mode:
			# ensure grid is drawn while in building mode
			queue_redraw()


func _draw() -> void:
	# Only draw grid dots during building mode
	if not building_mode:
		return

	var vp := get_viewport_rect()
	var start_x := 0
	var end_x := int(vp.size.x)

	# draw regular dots along the floor row
	for x in range(start_x, end_x + 1, grid_size):
		draw_circle(Vector2(x, house_floor_y), grid_dot_radius, grid_dot_color)

	# highlight the snapped position under the preview (if present)
	if building_preview:
		var local_x := building_preview.position.x
		var highlight_pos := Vector2(local_x, house_floor_y)
		draw_circle(highlight_pos, grid_dot_radius * 1.8, grid_dot_highlight_color)

func snap_to_grid(x_pos: float) -> float:
	return round(x_pos / grid_size) * grid_size


func _create_building_preview():
	building_preview = building_scenes["House"].instantiate()
	building_preview.modulate.a = 0.5  # Make it semi-transparent
	add_child(building_preview)
	building_preview.position.y = house_floor_y
	# Disable UI so buttons cannot be clicked while preview is active
	_set_ui_interactable(false)


func _place_building() -> void:
	print("Placing building at: " + str(building_preview.position))
	if building_preview:
		var final_global_position = building_preview.global_position
		building_preview.modulate.a = 1.0  # Make it solid
		building_preview.house_id = n_house
		house_array.append(building_preview)
		building_preview.menu_item_selected.connect(_selected_house_menu_item)
		# # Reparent while keeping global transform so it doesn't jump/disappear
		building_preview.reparent(house_container, true)
		building_preview.global_position = final_global_position
		n_house += 1
		building_preview = null
		building_mode = false
		queue_redraw()  # Clear the grid
		# Re-enable UI after placement
		_set_ui_interactable(true)
		_setup_focus_system()
		pending_build_cost = 0


func _cancel_building() -> void:
	if building_preview:
		building_preview.queue_free()
		building_preview = null
	building_mode = false
	queue_redraw()  # Clear the grid
	# Re-enable UI after cancel
	_set_ui_interactable(true)
	# refund coins
	if pending_build_cost > 0:
		update_coin_count(pending_build_cost)
		pending_build_cost = 0

func _on_ui_action_pressed(action_type: String) -> void:
	print("Main received action: " + action_type)
	# Ignore UI actions while placing a building
	if building_mode:
		print("Ignoring UI action while in building mode")
		return
	if current_focus_index >= 0 and current_focus_index < focusable_structures.size():
		var focused_structure = focusable_structures[current_focus_index]
		focused_structure.handle_ui_action(action_type)


func _cycle_focus_left() -> void:
	current_focus_index = (current_focus_index - 1 + focusable_structures.size()) % focusable_structures.size()
	_focus_structure_at_index(current_focus_index)


func _cycle_focus_right() -> void:
	current_focus_index = (current_focus_index + 1) % focusable_structures.size()
	_focus_structure_at_index(current_focus_index)


func _setup_focus_system() -> void:
	# Get all focusable structures and sort by x position
	var structures := get_tree().get_nodes_in_group("focusable_structures")
	structures.sort_custom(func(a, b): return a.global_position.x < b.global_position.x)

	# Store for cycling
	focusable_structures = structures

	# Find heart index and loop through structures to assign indices
	for i in range(focusable_structures.size()):

		focusable_structures[i].structure_index = i

		if focusable_structures[i].is_in_group("heart"):
			current_focus_index = i

	# print("Found %d focusable structures, heart at index %d" % [focusable_structures.size(), current_focus_index])


func set_focus(focus_type: FocusType, structure_id: int = -1) -> void:

	# Set all structures to unfocused
	for structure in focusable_structures:
		structure.set_focused(false)

	# store old focus index
	old_focus_index = current_focus_index
	current_focus_type = focus_type
	current_focus_index = structure_id

	# # Hide outline on previously focused structure
	# if old_focus_index >= 0 and old_focus_index < focusable_structures.size():
	# 	focusable_structures[old_focus_index].hide_outline()

	# Show outline on newly focused structure
	if current_focus_index >= 0 and current_focus_index < focusable_structures.size():
		focusable_structures[current_focus_index].set_focused(true)

	_update_ui_visibility()


func _focus_structure_at_index(index: int) -> void:
	var structure = focusable_structures[index]

	if structure.is_in_group("heart"):
		set_focus(FocusType.HEART, index)
	elif structure.is_in_group("house"):
		set_focus(FocusType.HOUSE, index)
	elif structure.is_in_group("tower"):
		set_focus(FocusType.TOWER, index)  # when you add towers
	elif structure.is_in_group("wall"):
		set_focus(FocusType.WALL, index)    # when you add walls


func _update_ui_visibility() -> void:
	heart_action_section.visible = (current_focus_type == FocusType.HEART)
	house_action_section.visible = (current_focus_type == FocusType.HOUSE)


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
	# print("main: A " + str(type) + " will be created!")
	
	match type:
		"House":
			# if try_create_house():
			# 	_setup_focus_system()
			# 	update_coin_count(-cost)
			if coin_count >= cost:
				building_mode = true
				update_coin_count(-cost)
				pending_build_cost = cost
				_create_building_preview()
		"Tower":
			pass
		"Wall":
			pass


func _create_house_item(house_id : int, cost: int, type: String) -> void:
	# print("main: A " + str(type) + " will be created for house " + str(house_id) + "!")
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

# Helper: recursively enable/disable interactive UI controls (buttons/etc.)
func _set_ui_interactable(enabled: bool) -> void:
	# start from the main UI control so we affect only UI elements
	_set_ui_node_interactable(ui, enabled)

func _set_ui_node_interactable(node: Node, enabled: bool) -> void:
	if node is Button:
		node.disabled = not enabled
	elif node is BaseButton: # cover other button types
		node.disabled = not enabled
	# recurse into child controls
	if node is Control:
		for child in node.get_children():
			_set_ui_node_interactable(child, enabled)
