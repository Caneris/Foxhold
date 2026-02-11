extends Area2D
class_name BirdEnemy
## Flying enemy that patrols above the heart and attacks by dropping poop.

enum State { ASCENDING, PATROLLING, ATTACKING }

# Movement
@export var fly_speed: float = 80.0
@export var bob_amplitude: float = 8.0
@export var bob_frequency: float = 3.0

# Combat
@export var poop_scene: PackedScene
@export var poop_cooldown: float = 4.0
@export var poop_threshold: float = 30.0

# Health
@export var max_health: int = 5
@export var damage_per_click: int = 1

# Drops
@export var drop_items: Array[PackedScene]

# State
var current_state: State = State.ASCENDING
var target_height: float
var base_y: float
var time_elapsed: float = 0.0
var turn_left: float
var turn_right: float
var target_x: float  # Target during ASCENDING
var move_direction: int = 1
var poop_timer: float = 0.0
var is_turning: bool = false
var left: bool = false
var right: bool = false

var distance_to_target: float

# References
var heart_node: Node2D
var main_scene: Node2D
var heart_x: float

@onready var debug_label: Label = %Label

@onready var health_bar: ProgressBar = %HealthBar
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

signal enemy_died


func _ready() -> void:
	main_scene = get_tree().current_scene
	heart_node = get_tree().current_scene.get_node("%Heart") as Area2D
	heart_x = heart_node.global_position.x

	# Randomize patrol height (10-30% of 360 screen height)
	target_height = randf_range(0, 50)

	# Calculate turning points and initial target based on spawn position
	turn_left = heart_x - randf_range(140, 160)
	turn_right = heart_x + randf_range(140, 160)

	# Set initial target based on spawn side (fly across the heart)
	if left:
		target_x = turn_right
		move_direction = 1
	elif right:
		target_x = turn_left
		move_direction = -1

	_setup_health()
	_setup_input()
	animated_sprite.play("default")


func _setup_health() -> void:
	health_bar.max_value = max_health
	health_bar.value = max_health
	health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_node("Control").mouse_filter = Control.MOUSE_FILTER_IGNORE


func _setup_input() -> void:
	input_pickable = true
	input_event.connect(_on_input_event)


func _process(delta: float) -> void:
	if poop_timer > 0:
		poop_timer -= delta

	if move_direction == 1:
		distance_to_target = abs(global_position.x - turn_right)
	elif move_direction == -1:
		distance_to_target = abs(global_position.x - turn_left)

	if health_bar.value <= 0:
		die()
		return

	match current_state:
		State.ASCENDING:
			_state_ascending(delta)
		State.PATROLLING:
			_state_patrolling(delta)
		State.ATTACKING:
			_state_attacking()
	
	debug_label.text = "D: %.2f | dir: %d | x: %.1f | tR: %.1f" % [distance_to_target, move_direction, position.x, target_x]


func _state_ascending(delta: float) -> void:
	# Move up toward target height
	global_position.y = move_toward(global_position.y, target_height, 3*fly_speed * delta)

	# Move toward target turning point (not heart directly)
	var dir_to_target = sign(target_x - global_position.x)
	move_direction = dir_to_target
	global_position.x += dir_to_target * fly_speed * delta

	# Flip sprite based on movement direction
	animated_sprite.flip_h = dir_to_target > 0

	# Transition when reached target height
	if global_position.y <= target_height + 10:
		base_y = global_position.y
		current_state = State.PATROLLING

	print("Ascending...")


func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _state_patrolling(delta: float) -> void:
	time_elapsed += delta

	# Horizontal movement
	global_position.x += move_direction * fly_speed * delta

	# Bob up and down
	# global_position.y = base_y + sin(time_elapsed * bob_frequency) * bob_amplitude

	# Check turning points
	print("is_turning: %s" % is_turning)
	if not is_turning:
		if global_position.x >= turn_right and move_direction == 1:
			move_direction = -1
			animated_sprite.flip_h = false
			is_turning = true
			print("turning")
		elif global_position.x <= turn_left and move_direction == -1:
			move_direction = 1
			animated_sprite.flip_h = true
			is_turning = true
			print("turning")
	else:
		var away_form_edges: bool = global_position.x < turn_right - 50 and global_position.x > turn_left + 50
		if away_form_edges:
			is_turning = false

	# Check if above heart and can poop
	if heart_node:
		var above_heart = abs(global_position.x - heart_x) < poop_threshold
		if above_heart and poop_timer <= 0:
			current_state = State.ATTACKING


func _state_attacking() -> void:
	_spawn_poop()
	poop_timer = poop_cooldown
	print("Pooped!")
	current_state = State.PATROLLING


func _spawn_poop() -> void:
	if not poop_scene:
		return
	var poop = poop_scene.instantiate()
	poop.global_position = global_position
	main_scene.add_child(poop)


func _on_input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		take_damage(damage_per_click)


func take_damage(amount: int) -> void:
	health_bar.value = max(health_bar.value - amount, 0)


func drop_item() -> void:
	if drop_items.is_empty():
		return

	var dropped_item: RigidBody2D = drop_items.pick_random().instantiate()
	dropped_item.add_to_group("item")
	dropped_item.clicked.connect(main_scene._on_item_clicked)

	main_scene.add_child(dropped_item)
	dropped_item.global_position = global_position
	dropped_item.gravity_scale = 1.0
	dropped_item.linear_velocity = Vector2(randf_range(-100, 100), randf_range(-350, -250))


func die() -> void:
	enemy_died.emit()
	drop_item()
	queue_free()