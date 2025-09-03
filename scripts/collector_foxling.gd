extends CharacterBody2D

enum State { IDLE, MOVING_TO_GOLD, CARRYING_GOLD, RETURNING_HOME }
var current_state: State = State.IDLE

@export var speed: float = 100.0
@export var detection_radius: float = 50.0

@onready var detection_area: Area2D = $DetectionArea
@onready var detection_shape: CollisionShape2D = $DetectionArea/CollisionShape2D
@onready var gold_position: Marker2D = $GoldPosition

var home_position: Vector2
var current_gold: RigidBody2D
var carried_gold: RigidBody2D
var available_gold: Array = []

