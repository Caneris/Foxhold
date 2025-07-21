extends Area2D

signal coin_in_heart(coin)

@export var max_health : float = 20.0
@onready var health_bar: ProgressBar = %HealthBar


func _ready() -> void:
	initiate_health(max_health)
	body_entered.connect(_on_body_entered)

func take_damage(damage: float) -> void:
	print("heart takes " + str(damage) + " damage!")
	health_bar.value = max(health_bar.value - damage, 0)

func initiate_health(value: float) -> void:
	health_bar.max_value = max_health
	health_bar.value = value

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("coin"):
		coin_in_heart.emit(body)
