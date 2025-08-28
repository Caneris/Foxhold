extends Control

@onready var break_timer_circle: TextureProgressBar = $BreakTimerCircle

# var focused_structure_type : String = "Heart" # Default focused structure type

# # Heart Menu Buttons
# @onready var build_house_button: Button = $BottomPanel/HBoxContainer/ActionSectionBackground/HeartActionSection/BuildHouseButton
# @onready var build_tower_button: Button = $BottomPanel/HBoxContainer/ActionSectionBackground/HeartActionSection/BuildTowerButton
# @onready var build_wall_button: Button = $BottomPanel/HBoxContainer/ActionSectionBackground/HeartActionSection/BuildWallButton


# func _ready() -> void:

# 	# Connect button signals
# 	build_house_button.pressed.connect(_on_build_house_button_pressed)
# 	build_tower_button.pressed.connect(_on_build_tower_button_pressed)
# 	build_wall_button.pressed.connect(_on_build_wall_button_pressed)


func _on_countdown_started(duration : float) -> void:
	break_timer_circle.max_value = duration
	break_timer_circle.show()


func _on_countdown_updated(time_remaining : float) -> void:
	#print("UI received: ", time_remaining)
	break_timer_circle.value = time_remaining

# func _on_build_house_button_pressed() -> void:
# 	print("Build House button pressed")

# func _on_build_tower_button_pressed() -> void:
# 	print("Build Tower button pressed")

# func _on_build_wall_button_pressed() -> void:
# 	print("Build Wall button pressed")