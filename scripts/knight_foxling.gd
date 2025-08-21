extends CharacterBody2D

# Combat stats
@export var damage: int = 5
@export var attack_range: float = 50.0
@export var attack_cooldown: float = 1.0
@export var enemy_slow_amount: float = 0.5  # 50% speed

# Movement
@export var speed: float = 150.0
@export var patrol_radius: float = 100.0
@export var sight_range: float = 60.0
@onready var sight: RayCast2D = $Sight

# State management
enum State { IDLE, CHASING, ATTACKING, RETURNING }
var current_state: State = State.IDLE
var home_position: Vector2
var current_target: CharacterBody2D
var attack_timer: float = 0.0

# Search after killing an enemy
const SEARCH_DELAY: float = 0.5
var search_timer: float = 0.0
var is_searching: bool = false

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
            check_for_enemies(patrol_direction)
        State.CHASING:
            chase_enemy(delta)
        State.RETURNING:
            # check_for_enemies()
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



func check_for_enemies(check_direction: float) -> void:
    
    sight.target_position = Vector2(check_direction * sight_range, 0)
    sight.force_raycast_update()

    var collider = sight.get_collider()
    if collider and collider.is_in_group("enemy"):
        current_target = collider
        current_state = State.CHASING
    # Find nearest one
    # Set as current_target and switch to CHASING


func search_for_enemies() -> void:

    # get current direction
    var direction = sign(velocity.x)
    if is_searching:
        check_for_enemies(direction)
        search_timer -= get_process_delta_time()
        if search_timer <= 0.0:
            is_searching = false
            current_state = State.IDLE
            _decide_next_action()
    else:
        # Start searching for enemies
        is_searching = true
        search_timer = SEARCH_DELAY
        print("Searching for enemies...")  # Debug message

func chase_enemy(delta: float) -> void:
    # Check if target still exists
    if not is_instance_valid(current_target):
        current_state = State.RETURNING
        current_target = null
        return
    
    var to_enemy = current_target.global_position - global_position
    var distance = to_enemy.length()
    
    # Lost sight - return home
    if distance > sight_range*2.0:
        current_state = State.RETURNING
        current_target = null
        return
    
    # Move toward enemy
    var direction = sign(to_enemy.x)
    velocity.x = direction * speed

    # Chase until at attack range
    if distance > attack_range:
        velocity.x = direction * speed
    else:
        velocity.x = 0  # Stop at attack distance
    
    
    # Attack if in range and cooldown ready
    if distance <= attack_range and attack_timer <= 0:
        # Deal damage and apply slow
        current_target.take_damage(damage)
        if current_target.has_method("apply_slow"):
            current_target.apply_slow(enemy_slow_amount, 2.0)  # slow for 2 seconds
        attack_timer = attack_cooldown

    attack_timer -= delta
    sight.target_position = Vector2(direction * sight_range, 0)
    move_and_slide()
    # Move toward current_target
    # If in attack_range, switch to ATTACKING
    # If enemy dead or out of sight, switch to RETURNING

# func attack_enemy(delta: float) -> void:
#     print("Attacking enemy")
#     pass
#     # Apply slow to enemy
#     # Deal damage if attack_timer <= 0
#     # Continue chasing if enemy moves away

func return_home(delta: float) -> void:

    search_for_enemies()
    var to_home = home_position - global_position
    var distance = abs(to_home.x)
    print("Returning home, distance: ", distance)
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
        check_for_enemies(direction)
        velocity.x = direction * speed * 0.5  # Slow down while returning
    move_and_slide()