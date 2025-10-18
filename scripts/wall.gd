extends Area2D


@export var max_health: int = 100
var is_destroyed: bool = false
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = %HealthBar
var damage_tween: Tween  # Add this line


func _ready() -> void:
    _set_destroyed(false)
    health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    initiate_health(max_health)


func initiate_health(value: int) -> void:
    health_bar.max_value = max_health
    health_bar.value = value


func take_damage(amount: int):
    if is_destroyed:
        return  # Can't damage a destroyed wall
    
    health_bar.value = max(health_bar.value - amount, 0)

    # Kill any existing tween before creating a new one
    if damage_tween:
        damage_tween.kill()
    
    # Reset to base color first, then flash
    animated_sprite.modulate = Color(1, 1, 1, 1)
    
    damage_tween = create_tween()
    damage_tween.tween_property(animated_sprite, "modulate", Color(3.0, 3.0, 3.0, 1), 0.1)
    damage_tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1, 1), 0.1)

    if health_bar.value <= 0:
        _set_destroyed(true)


func _set_destroyed(destroyed: bool):
    is_destroyed = destroyed
    $CollisionShape2D.set_deferred("disabled", destroyed)

    if destroyed:
        $AnimatedSprite2D.play("destroyed")
    else:
        $AnimatedSprite2D.play("default")  # or "intact"/"normal"


func repair(amount: int):
    health_bar.value = min(health_bar.value + amount, max_health)

    if is_destroyed and health_bar.value > 0:
        _set_destroyed(false)


func rebuild():
    if is_destroyed:
        health_bar.value = max_health
        _set_destroyed(false)
