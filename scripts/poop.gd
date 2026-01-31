extends Area2D

@export var fall_speed: float = 150.0
@export var damage: float = 2.0
@export var splat_scene: PackedScene

var has_hit: bool = false

func _ready() -> void:
    area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
    position.y += fall_speed * delta

func _on_area_entered(area: Area2D) -> void:
    if has_hit:
        return
    if area.is_in_group("heart"):
        has_hit = true
        area.take_damage(damage)
        _spawn_splat()
        queue_free()

func _spawn_splat() -> void:
    if splat_scene:
        var splat = splat_scene.instantiate()
        splat.global_position = global_position
        splat.emitting = true
        get_tree().current_scene.add_child(splat)