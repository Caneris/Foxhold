extends StaticBody2D


@export var max_health: int = 100
var current_health: int
var is_destroyed: bool = false


func take_damage(amount: int):
    if is_destroyed:
        return  # Can't damage a destroyed wall
    
    current_health -= amount
    if current_health <= 0:
        current_health = 0
        _set_destroyed(true)


func _set_destroyed(destroyed: bool):
    is_destroyed = destroyed
    $CollisionShape2D.set_deferred("disabled", destroyed)
    
    if destroyed:
        $AnimatedSprite2D.play("destroyed")
    else:
        $AnimatedSprite2D.play("default")  # or "intact"/"normal"


func repair(amount: int):
    current_health = min(current_health + amount, max_health)
    
    if is_destroyed and current_health > 0:
        _set_destroyed(false)


# add also similar to repair a rebuild function, to rebuild when destroyed
func rebuild():
    if is_destroyed:
        current_health = max_health
        _set_destroyed(false)