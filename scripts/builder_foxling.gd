extends BaseFoxling
class_name BuilderFoxling
## Builder foxling - patrols and heals damaged structures (Heart priority, then Walls)

# Healing parameters
@export var heal_percentage: float = 0.1  # 10% of max health per heal tick
@export var heal_cooldown: float = 1.0    # Heal every second
@export var detection_radius: float = 50.0

# Detection
@onready var detection_area: Area2D = $DetectionArea
@onready var detection_shape: CollisionShape2D = $DetectionArea/CollisionShape2D

# Builder-specific state
enum State { IDLE, MOVING_TO_STRUCTURE, HEAL_STRUCTURE, RETURNING_HOME }
var current_state: State = State.IDLE

# Structure tracking
var current_target: Node2D = null
var available_structures: Array = []
var heart_reference: Node2D = null
var heal_timer: float = 0.0


func _on_foxling_ready() -> void:
	heart_reference = get_tree().current_scene.get_node("Heart")

	# Set up detection area
	detection_shape.shape.radius = detection_radius
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	detection_area.area_entered.connect(_on_detection_area_area_entered)
	detection_area.area_exited.connect(_on_detection_area_area_exited)

	add_to_group("builders")


func _process_state(delta: float) -> void:
	match current_state:
		State.IDLE:
			_state_idle(delta)
		State.MOVING_TO_STRUCTURE:
			_state_moving_to_structure(delta)
			print("builder moving to structure")
		State.HEAL_STRUCTURE:
			_state_heal_structure(delta)
		State.RETURNING_HOME:
			_state_returning_home(delta)


func _state_idle(delta: float) -> void:
	patrol(delta)
	_check_for_damaged_structures()


func _state_moving_to_structure(delta: float) -> void:
	# Validate target still exists and is damaged
	if not _is_valid_target(current_target):
		current_target = null
		current_state = State.RETURNING_HOME
		return

	move_towards(current_target.global_position, delta)

	# Close enough to start healing (15-20 pixels)
	if global_position.distance_to(current_target.global_position) < 50.0:
		current_state = State.HEAL_STRUCTURE
		heal_timer = 0.0  # Start healing immediately


func _state_heal_structure(delta: float) -> void:
	# Stop movement while healing
	velocity.x = 0
	move_and_slide()

	# Validate target still exists and needs healing
	if not _is_valid_target(current_target):
		current_target = null
		current_state = State.RETURNING_HOME
		return

	# Tick down heal timer
	heal_timer -= delta
	if heal_timer <= 0.0:
		_apply_heal()
		heal_timer = heal_cooldown


func _state_returning_home(delta: float) -> void:
	_check_for_damaged_structures()

	if return_home(delta):
		current_state = State.IDLE


func _check_for_damaged_structures() -> void:
	var target = _find_nearest_damaged_structure()
	if target != null:
		current_target = target
		current_state = State.MOVING_TO_STRUCTURE


func _find_nearest_damaged_structure() -> Node2D:
	# Always check Heart first (highest priority)
	if _is_valid_target(heart_reference):
		return heart_reference

	# Then find nearest damaged Wall
	var nearest_structure: Node2D = null
	var shortest_distance: float = INF

	for structure in available_structures:
		if not _is_valid_target(structure):
			continue

		var distance = global_position.distance_to(structure.global_position)
		if distance < shortest_distance:
			shortest_distance = distance
			nearest_structure = structure

	return nearest_structure


func _is_valid_target(target: Node2D) -> bool:
	if target == null or not is_instance_valid(target):
		return false

	# Check if structure is damaged
	if target.has_node("%HealthBar"):
		var health_bar = target.get_node("%HealthBar")
		return health_bar.value < target.max_health

	return false


func _apply_heal() -> void:
	if current_target == null or not is_instance_valid(current_target):
		return

	var heal_amount = roundi(current_target.max_health * heal_percentage)

	print("trying to heal")

	# Call the heal method on the structure
	if current_target.has_method("heal"):
		current_target.heal(heal_amount)
	elif current_target.has_method("repair"):
		# Fallback for Wall which uses repair()
		current_target.repair(heal_amount)

	# Check if fully healed
	if current_target.has_node("%HealthBar"):
		var health_bar = current_target.get_node("%HealthBar")
		if health_bar.value >= current_target.max_health:
			current_target = null
			current_state = State.RETURNING_HOME


# Area2D detection (for Heart which is Area2D)
func _on_detection_area_area_entered(area: Node2D) -> void:
	if area.is_in_group("heart") or area == heart_reference:
		if area not in available_structures:
			available_structures.append(area)


func _on_detection_area_area_exited(area: Node2D) -> void:
	if area in available_structures:
		available_structures.erase(area)
	if area == current_target:
		current_target = null
		current_state = State.RETURNING_HOME


# Body detection (for Walls which are typically CharacterBody2D or StaticBody2D)
func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("walls") and body not in available_structures:
		available_structures.append(body)


func _on_detection_area_body_exited(body: Node2D) -> void:
	if body in available_structures:
		available_structures.erase(body)
	if body == current_target:
		current_target = null
		current_state = State.RETURNING_HOME


func cleanup() -> void:
	current_target = null
	available_structures.clear()
