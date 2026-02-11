extends CharacterBody2D
class_name BaseEnemy
## Base class for all enemy types. Handles health, damage, drops, and shared systems.

# Movement
@export var speed: float = 80.0
@export var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
@export var max_fall_speed: float = 800.0

# Health
@export var max_health: int = 10
@export var damage_per_click: int = 3

# Combat
@export var attack_damage: int = 1
@export var attack_range: float = 6.0
var attack_interval: float = 1.0
var attack_cooldown: float = 0.0

# Drops
@export var drop_items: Array[PackedScene]

# Slowdown
var original_speed: float
var is_slowed: bool = false
var slowdown_timer: Timer

# References
var heart_node: Node2D
var main_scene: Node2D

# Child nodes - expected in scene
@onready var health_bar: ProgressBar = %HealthBar
@onready var click_area: Area2D = $Area2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

signal enemy_died


func _ready() -> void:
	main_scene = get_tree().current_scene
	heart_node = get_tree().current_scene.get_node("%Heart") as Area2D
	
	_setup_health()
	_setup_click_area()
	_setup_slowdown_timer()
	
	original_speed = speed
	
	# Child-specific setup
	_on_enemy_ready()


## Override in child classes for additional setup
func _on_enemy_ready() -> void:
	pass


func _physics_process(delta: float) -> void:
	if health_bar.value <= 0:
		die()
		return
	
	_apply_gravity(delta)
	_process_movement(delta)


## Override in child classes for movement behavior
func _process_movement(_delta: float) -> void:
	pass


func _apply_gravity(delta: float) -> void:
	velocity.y += gravity * delta
	velocity.y = min(velocity.y, max_fall_speed)


func _setup_health() -> void:
	health_bar.max_value = max_health
	health_bar.value = max_health
	health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_node("Control").mouse_filter = Control.MOUSE_FILTER_IGNORE


func _setup_click_area() -> void:
	click_area.input_pickable = true
	click_area.input_event.connect(_on_click_area_input)


func _setup_slowdown_timer() -> void:
	slowdown_timer = Timer.new()
	slowdown_timer.one_shot = true
	slowdown_timer.timeout.connect(_on_slowdown_timeout)
	add_child(slowdown_timer)


func _on_click_area_input(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		take_damage(damage_per_click)


func take_damage(amount: float) -> void:
	health_bar.value = max(health_bar.value - amount, 0)


func apply_slow(slowdown_factor: float = 0.3, duration: float = 1.5) -> void:
	if not is_slowed:
		is_slowed = true
		speed = original_speed * slowdown_factor
		slowdown_timer.wait_time = duration
		slowdown_timer.start()


func _on_slowdown_timeout() -> void:
	speed = original_speed
	is_slowed = false


func drop_item() -> void:
	if drop_items.is_empty():
		return
	
	var dropped_item: RigidBody2D = drop_items.pick_random().instantiate()
	dropped_item.add_to_group("item")
	dropped_item.clicked.connect(main_scene._on_item_clicked)
	
	main_scene.add_child(dropped_item)
	dropped_item.position = global_position
	dropped_item.gravity_scale = 1.0
	dropped_item.linear_velocity = Vector2(randf_range(-100, 100), randf_range(-350, -250))


func die() -> void:
	enemy_died.emit()
	drop_item()
	queue_free()