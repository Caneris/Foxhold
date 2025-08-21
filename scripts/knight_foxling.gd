extends CharacterBody2D

# Combat stats
@export var damage: int = 5
@export var attack_range: float = 50.0
@export var attack_cooldown: float = 1.0
@export var enemy_slow_amount: float = 0.5  # 50% speed

# Movement
@export var speed: float = 150.0
@export var patrol_radius: float = 100.0
@export var sight_range: float = 30.0
@onready var sight: RayCast2D = $Sight

# State management
enum State { IDLE, CHASING, ATTACKING, RETURNING }
var current_state: State = State.IDLE
var home_position: Vector2
var current_target: CharacterBody2D
var attack_timer: float = 0.0

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
    home_position = global_position
    # Randomize initial patrol radius
    current_patrol_radius = patrol_radius * randf_range(0.95, 1.05)
    # Start with random pause or walk
    _decide_next_action()
    add_to_group("foxlings")
    add_to_group("knights")

    # set up sight raycast
    sight.collide_with_areas = false  # Only detect bodies
    sight.collide_with_bodies = true

func _physics_process(delta: float) -> void:
    # attack_timer -= delta

    velocity.y += gravity * delta
    if velocity.y > max_fall_speed:
        velocity.y = max_fall_speed
    
    match current_state:
        State.IDLE:
            patrol(delta)
            check_for_enemies()
        State.CHASING:
            chase_enemy(delta)
        State.ATTACKING:
            attack_enemy(delta)
        State.RETURNING:
            return_home(delta)

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
    # Check for enemies while patrolling

func _decide_next_action() -> void:
    # 30% chance to pause
    if randf() < 0.3:
        is_paused = true
        patrol_timer = randf_range(0.5, 2.0)  # Pause for 0.5-2 seconds
    else:
        is_paused = false
        patrol_timer = randf_range(1.0, 3.0)  # Walk for 1-3 seconds



func check_for_enemies() -> void:
    
    sight.target_position = Vector2(patrol_direction * sight_range, 0)
    sight.force_raycast_update()

    var collider = sight.get_collider()
    if collider and collider.is_in_group("enemy"):
        current_target = collider
        current_state = State.CHASING
    # Find nearest one
    # Set as current_target and switch to CHASING

func chase_enemy(delta: float) -> void:
    print("Chasing enemy")
    pass
    # Move toward current_target
    # If in attack_range, switch to ATTACKING
    # If enemy dead or out of sight, switch to RETURNING

func attack_enemy(delta: float) -> void:
    pass
    # Apply slow to enemy
    # Deal damage if attack_timer <= 0
    # Continue chasing if enemy moves away

func return_home(delta: float) -> void:
    pass
    # Move back to home_position
    # If reached home, switch to IDLE