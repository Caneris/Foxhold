extends CharacterBody2D


# State management
enum State { IDLE, MOVING_TO_GOLD, CARRYING_GOLD, RETURNING_HOME }
var current_state: State = State.IDLE
var home_position: Vector2


@export var speed: float = 100.0
@export var detection_radius: float = 50.0
@export var patrol_radius: float = 100.0


@onready var detection_area: Area2D = $DetectionArea
@onready var detection_shape: CollisionShape2D = $DetectionArea/CollisionShape2D
@onready var gold_position: Marker2D = $GoldPosition


# Currently targeted or carried gold
var current_gold: RigidBody2D
var carried_gold: RigidBody2D
var max_carry_number: int = 1
var available_gold: Array = []


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
            check_for_gold(sign(velocity.x))
        State.MOVING_TO_GOLD:
            if current_gold == null or not is_instance_valid(current_gold):
                current_state = State.RETURNING_HOME
                current_gold = null
                return
            move_towards(current_gold.global_position, delta)
            # if global_position.distance_to(current_gold.global_position) < 10.0:
            #     # Pick up the gold
            #     carried_gold = current_gold
            #     current_gold = null
            #     carried_gold.visible = false
            #     carried_gold.get_node("CollisionShape2D").disabled = true
            #     gold_position.add_child(carried_gold)
            #     carried_gold.position = Vector2.ZERO
            #     current_state = State.RETURNING_HOME
        State.RETURNING_HOME:
            return_home(delta)


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
        check_for_gold(direction)
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


func check_for_gold(direction: float) -> void:
    
    if available_gold.size() > 0 and carried_gold == null:
                print("Available gold detected")
                var nearest_gold = find_nearest_gold()
                if nearest_gold != null:
                    print("Found gold at: ", nearest_gold.global_position)
                    current_gold = nearest_gold
                    current_state = State.MOVING_TO_GOLD

func move_towards(target_position: Vector2, delta: float) -> void:
    var direction = (target_position - global_position).normalized()
    velocity.x = direction.x * speed
    move_and_slide()

func _decide_next_action() -> void:
    # 30% chance to pause
    pass

func _on_detection_area_body_entered(body: Node) -> void:
    if body.is_in_group("coin") and body not in available_gold:
        available_gold.append(body)


func _on_detection_area_body_exited(body: Node) -> void:
    if body in available_gold:
        available_gold.erase(body)
    if body == current_gold:
        current_gold = null
        current_state = State.RETURNING_HOME


func find_nearest_gold() -> RigidBody2D:
    if available_gold.is_empty():
        return null
    
    var nearest_gold: RigidBody2D = null
    var shortest_distance: float = INF
    
    for gold in available_gold:
        # Check if gold still exists (might have been collected by another foxling)
        if not is_instance_valid(gold):
            continue
            
        var distance = global_position.distance_to(gold.global_position)
        if distance < shortest_distance:
            shortest_distance = distance
            nearest_gold = gold
    
    return nearest_gold

# func _physics_process(delta: float) -> void:
#     match current_state:
#         State.IDLE:
#             if available_gold.size() > 0 and carried_gold == null:
