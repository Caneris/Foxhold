extends CharacterBody2D
class_name BaseFoxling
## Base class for all foxling types. Handles shared movement, patrol, and gravity.

# Movement
@export var speed: float = 100.0
@export var patrol_radius: float = 100.0

# Gravity
@export var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
@export var max_fall_speed: float = 800.0

var game_world: Node2D

# Home position (set on spawn)
var home_position: Vector2

# Patrol variables
var patrol_direction: int = 1
var patrol_timer: float = 0.0
var is_paused: bool = false
var current_patrol_radius: float
var has_reversed: bool = false


func _ready() -> void:
	home_position = global_position
	# Randomize initial patrol radius
	current_patrol_radius = patrol_radius * randf_range(0.95, 1.05)
	# Start with random pause or walk
	_decide_next_action()
	add_to_group("foxlings")
	
	# Call child-specific setup
	_on_foxling_ready()


## Override this in child classes for additional setup
func _on_foxling_ready() -> void:
	pass


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_process_state(delta)
	if is_on_floor() and Engine.get_physics_frames() % 60 == 0:
		# print y position for debugging
		print("Foxling Y Position: ", global_position.y)


## Apply gravity - called every frame
func _apply_gravity(delta: float) -> void:
	velocity.y += gravity * delta
	if velocity.y > max_fall_speed:
		velocity.y = max_fall_speed


## Override this in child classes to handle state machine
func _process_state(_delta: float) -> void:
	pass


## Shared patrol behavior - walk back and forth near home
func patrol(delta: float) -> void:
	patrol_timer -= delta
	if patrol_timer <= 0.0:
		_decide_next_action()

	if not is_paused:
		velocity.x = patrol_direction * speed * 0.5  # Half speed while patrolling

		# Check boundaries with some randomness
		var distance_from_home: float = abs(global_position.x - home_position.x)
		if distance_from_home >= current_patrol_radius and not has_reversed:
			patrol_direction *= -1  # Reverse direction
			current_patrol_radius = patrol_radius * randf_range(0.95, 1.05)
			has_reversed = true
		elif distance_from_home < current_patrol_radius * 0.9:
			has_reversed = false  # Reset reverse flag when within 90% of radius
	else:
		velocity.x = 0  # Stop moving while paused
		patrol_timer = max(patrol_timer, 0.0)

	move_and_slide()


## Decide whether to pause or walk
func _decide_next_action() -> void:
	# 30% chance to pause
	if randf() < 0.3:
		is_paused = true
		patrol_timer = randf_range(0.5, 2.0)  # Pause for 0.5-2 seconds
	else:
		is_paused = false
		patrol_timer = randf_range(1.0, 3.0)  # Walk for 1-3 seconds


## Return home - move back toward home_position
## Returns true when arrived home
func return_home(_delta: float) -> bool:
	var to_home = home_position - global_position
	var distance = abs(to_home.x)
	
	if distance < 10.0:  # Close enough to home
		velocity.x = 0
		# Reset patrol variables when arriving home
		has_reversed = false
		current_patrol_radius = patrol_radius * randf_range(0.95, 1.05)
		_decide_next_action()
		move_and_slide()
		return true
	else:
		# Move back toward home at half speed
		var direction = sign(to_home.x)
		velocity.x = direction * speed * 0.5
		move_and_slide()
		return false


## Move toward a target position at full speed
func move_towards(target_position: Vector2, _delta: float) -> void:
	var direction = (target_position - global_position).normalized()
	velocity.x = direction.x * speed
	move_and_slide()