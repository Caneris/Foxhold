extends CharacterBody2D

enum State { IDLE, MOVING_TO_GOLD, CARRYING_GOLD, RETURNING_HOME }
var current_state: State = State.IDLE

@export var speed: float = 100.0
@export var detection_radius: float = 50.0
@export var patrol_radius: float = 100.0

@onready var detection_area: Area2D = $DetectionArea
@onready var detection_shape: CollisionShape2D = $DetectionArea/CollisionShape2D
@onready var gold_position: Marker2D = $GoldPosition

var home_position: Vector2
var current_gold: RigidBody2D
var carried_gold: RigidBody2D
var max_carry_number: int = 1
var available_gold: Array = []

func _ready() -> void:
    home_position = global_position
    detection_shape.shape.radius = detection_radius
    detection_area.body_entered.connect(_on_detection_area_body_entered)
    detection_area.body_exited.connect(_on_detection_area_body_exited)


func _on_detection_area_body_entered(body: Node) -> void:
    if body.is_in_group("Gold") and body not in available_gold:
        available_gold.append(body)


func _on_detection_area_body_exited(body: Node) -> void:
    if body in available_gold:
        available_gold.erase(body)


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
