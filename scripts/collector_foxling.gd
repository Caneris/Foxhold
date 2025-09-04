extends CharacterBody2D

signal coin_deposited(coin)

# State management
enum State { IDLE, MOVING_TO_COIN, CARRYING_COIN, RETURNING_HOME, DEPOSITING_COIN }
var current_state: State = State.IDLE
var home_position: Vector2


@export var speed: float = 100.0
@export var detection_radius: float = 50.0
@export var patrol_radius: float = 100.0


@onready var detection_area: Area2D = $DetectionArea
@onready var detection_shape: CollisionShape2D = $DetectionArea/CollisionShape2D
@onready var coin_position: Marker2D = $CoinPosition


# Currently targeted or carried coin
var current_coin: RigidBody2D
var carried_coin: RigidBody2D
var max_carry_number: int = 1
var available_coin: Array = []
var heart_position: Vector2


# Patrol variables
var patrol_direction: int = 1
var patrol_timer: float = 0.0
var is_paused: bool = false
var current_patrol_radius: float
var has_reversed: bool = false

# pixels/sec² — by default Godot’s 2D gravity
@export var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
# Prevent them from accelerating forever
@export var max_fall_speed: float = 800.0


func _ready() -> void:
	heart_position = get_tree().current_scene.get_node("Heart").global_position
	home_position = global_position
	# set up detection area
	detection_shape.shape.radius = detection_radius
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)

	# randomize initial patrol radius
	current_patrol_radius = patrol_radius * randf_range(0.95, 1.05)
	# start with random pause or walk
	_decide_next_action()
	add_to_group("foxlings")
	add_to_group("collectors")


func _physics_process(delta: float) -> void:

	velocity.y += gravity * delta
	if velocity.y > max_fall_speed:
		velocity.y = max_fall_speed

	match current_state:
		State.IDLE:
			patrol(delta)
			check_for_coin(sign(velocity.x))
		State.MOVING_TO_COIN:
			if current_coin == null or not is_instance_valid(current_coin):
				current_state = State.RETURNING_HOME
				current_coin = null
				return
			move_towards(current_coin.global_position, delta)
			if global_position.distance_to(current_coin.global_position) < 10.0:
				pick_up_nearest_coin()
		State.RETURNING_HOME:
			return_home(delta)
		State.DEPOSITING_COIN:
			deposit_coin(delta)


func return_home(delta: float) -> void:

	var to_home = home_position - global_position
	var distance = abs(to_home.x)
	if distance < 10.0:  # Close enough to home
		current_state = State.IDLE
		velocity.x = 0  # Stop moving

		# Reset patrol variables when arriving home
		has_reversed = false
		current_patrol_radius = patrol_radius * randf_range(0.95, 1.05)
		_decide_next_action()  # Start a new patrol action
	else:
		# Move back toward home
		var direction = sign(to_home.x)
		check_for_coin(direction)
		velocity.x = direction * speed * 0.5  # Slow down while returning
	move_and_slide()


func patrol(delta: float) -> void:
	patrol_timer -= delta
	if patrol_timer <= 0.0:
		_decide_next_action()

	if not is_paused:
		velocity.x = patrol_direction * speed * 0.5  # Slow down while patrolling

		# Check boundaries with some randomness
		var distance_from_home: float = abs(global_position.x - home_position.x)
		# print("Distance from home: ", distance_from_home, " Current patrol radius: ", current_patrol_radius)
		if distance_from_home >= current_patrol_radius and not has_reversed:
			patrol_direction *= -1  # Reverse direction
			current_patrol_radius = patrol_radius * randf_range(0.95, 1.05)  # Randomize radius
			has_reversed = true
		elif distance_from_home < current_patrol_radius * 0.9:
			has_reversed = false  # Reset reverse flag when within 90% of radius
	else:
		velocity.x = 0  # Stop moving while paused
		patrol_timer = max(patrol_timer, 0.0)  # Ensure timer doesn't go negative

	move_and_slide()


func check_for_coin(direction: float) -> void:
	
	if available_coin.size() > 0 and carried_coin == null:
				print("Available coin detected")
				var nearest_coin = find_nearest_coin()
				if nearest_coin != null:
					print("Found coin at: ", nearest_coin.global_position)
					current_coin = nearest_coin
					current_state = State.MOVING_TO_COIN


func pick_up_nearest_coin() -> void:
	var nearest_coin = find_nearest_coin()
	if nearest_coin != null and carried_coin == null:
		carried_coin = nearest_coin
		current_coin = null
		# Disable physics on the coin
		carried_coin.freeze = true
		carried_coin.gravity_scale = 0
		if carried_coin.has_node("CollisionShape2D"):
			carried_coin.get_node("CollisionShape2D").disabled = true
		# Remove from current parent
		if carried_coin.get_parent():
			carried_coin.get_parent().remove_child(carried_coin)
		# Add to foxling and position relative to coin_position
		add_child(carried_coin)
		carried_coin.global_position = coin_position.global_position
		carried_coin.visible = true
		current_state = State.DEPOSITING_COIN


func deposit_coin(delta) -> void:
	if carried_coin != null:
		# move towards the heart
		move_towards(heart_position, delta)
		if global_position.distance_to(heart_position) < 30.0:
			# Reached the heart
			coin_deposited.emit(carried_coin)
			carried_coin.queue_free()
			carried_coin = null
			current_state = State.RETURNING_HOME


func move_towards(target_position: Vector2, delta: float) -> void:
	var direction = (target_position - global_position).normalized()
	velocity.x = direction.x * speed
	move_and_slide()

func _decide_next_action() -> void:
	# 30% chance to pause
	pass

func _on_detection_area_body_entered(body: Node) -> void:
	if body.is_in_group("coin") and body not in available_coin:
		available_coin.append(body)


func _on_detection_area_body_exited(body: Node) -> void:
	if body in available_coin:
		available_coin.erase(body)
	if body == current_coin:
		current_coin = null
		current_state = State.RETURNING_HOME


func find_nearest_coin() -> RigidBody2D:
	if available_coin.is_empty():
		return null
	
	var nearest_coin: RigidBody2D = null
	var shortest_distance: float = INF
	
	for coin in available_coin:
		# Check if coin still exists (might have been collected by another foxling)
		if not is_instance_valid(coin):
			continue
			
		var distance = global_position.distance_to(coin.global_position)
		if distance < shortest_distance:
			shortest_distance = distance
			nearest_coin = coin
	
	return nearest_coin

# func _physics_process(delta: float) -> void:
#     match current_state:
#         State.IDLE:
#             if available_coin.size() > 0 and carried_coin == null:
