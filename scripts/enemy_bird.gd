extends Area2D

@export var min_speed : float = 25.0
@export var max_speed : float = 75.0
var speed : float

var velocity := Vector2.ZERO

func _ready() -> void:
	speed = randf_range(min_speed, max_speed)
	velocity = Vector2(-speed, 0)
	set_process(true)

func _process(delta: float) -> void:
	position += velocity * delta
