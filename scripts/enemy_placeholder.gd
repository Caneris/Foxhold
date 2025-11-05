extends CharacterBody2D

@export var heart_path : NodePath
@export var speed : float = 100.0
@export var attack_range : float = 3
@export var attack_damage : int = 1
var attack_interval : float # Changed to match animation duration, get frame count / fps in ready function
@export var max_health : int = 10
@export var damage_per_click: int = 5
@export var drop_items : Array[PackedScene]

# slowdown variables
var original_speed: float
var is_slowed: bool = false
var slowdown_timer: Timer


# pixels/sec² — by default Godot’s 2D gravity
@export var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
# Prevent them from accelerating forever
@export var max_fall_speed: float = 800.0


var heart_node : Node2D
var attack_cooldown : float = 0.0
var main_scene : Node2D

@onready var sight: RayCast2D = $Sight
@onready var health_bar: ProgressBar = %HealthBar
@onready var click_area: Area2D = $Area2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D  # Add this line

signal enemy_died


var pending_damage: int = 0

func _ready() -> void:

	attack_range = attack_range + randfn(0, 2)

	main_scene = get_tree().current_scene
	# Cache Heart instance
	heart_node = get_tree().get_root().get_node("Main/Heart") as Area2D
	sight.collide_with_areas = true
	initiate_health(max_health)
	
	# ignore mouse on the entire Control/HealthBar
	$Control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	click_area.input_pickable = true
	click_area.input_event.connect(_on_click_area_input)

	# setup slowdown timer variables
	original_speed = speed
	slowdown_timer = Timer.new()
	add_child(slowdown_timer)
	slowdown_timer.one_shot = true
	slowdown_timer.timeout.connect(_on_slowdown_timeout)

	# Connect to animation signals
	animated_sprite.animation_finished.connect(_on_animation_finished)
	animated_sprite.frame_changed.connect(_on_animation_frame_changed)

	if animated_sprite.sprite_frames.has_animation("attack"):
		var frame_count = animated_sprite.sprite_frames.get_frame_count("attack")
		var fps = animated_sprite.sprite_frames.get_animation_speed("attack")
		attack_interval = frame_count / fps
	else:
		attack_interval = 1.0  # Default to 1 second if animation not found


func apply_slow(slowdown_factor: float = 0.3, duration: float = 1.5) -> void:
	if not is_slowed:
		is_slowed = true
		speed = original_speed * slowdown_factor
		slowdown_timer.wait_time = duration
		slowdown_timer.start()


func _on_slowdown_timeout() -> void:
	speed = original_speed
	is_slowed = false


func take_damage(damage: float) -> void:
	health_bar.value = max(health_bar.value - damage, 0)


func drop_item() -> void:
	var dropped_item : RigidBody2D = drop_items.pick_random().instantiate()
	# var item_animated_sprite : AnimatedSprite2D = dropped_item.get_node("AnimatedSprite2D")
	
	dropped_item.add_to_group("item")
	dropped_item.clicked.connect(main_scene._on_item_clicked)
	
	main_scene.add_child(dropped_item)
	dropped_item.position = global_position
	
	dropped_item.gravity_scale = 1.0
	# choose a random pop vector
	var vx = randf_range(-100, 100)
	var vy = randf_range(-350, -250)
	# apply_impulse(relative_offset, impulse_vector)
	dropped_item.linear_velocity = Vector2(vx, vy)

func die() -> void:
	
	enemy_died.emit()
	# drop item
	drop_item()
	# play death animation, spawn particles, sound, etc.
	queue_free()


func _on_click_area_input(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	var event_is_mouseclick : bool = (
		event is InputEventMouseButton and 
		event.button_index == MOUSE_BUTTON_LEFT and
		event.is_pressed()
	)
	
	if event_is_mouseclick:
		health_bar.value -= damage_per_click


func initiate_health(value) -> void:
	health_bar.max_value = max_health
	health_bar.value = value


func _physics_process(delta: float) -> void:
	if not heart_node:
		return
	
	if health_bar.value == 0:
		die()
	
	# insert gravity
	velocity.y += gravity * delta
	if velocity.y > max_fall_speed:
		velocity.y =max_fall_speed
	
	# always aim at the art
	var to_heart := heart_node.global_position - global_position
	# var dist := to_heart.length()
	var dir := Vector2(sign(to_heart.x), 0)
	
	# point a fixed-length ray at the heart
	sight.target_position = dir * attack_range
	sight.force_raycast_update()
	
	var col := sight.get_collider()
	
	if sight.is_colliding() and col.is_in_group("heart"):
		velocity.x = 0.0
		_try_attack(delta)
	elif sight.is_colliding() and col.is_in_group("wall"):
		print("Wall in the way")
		velocity.x = 0.0
		_try_attack(delta)
	else:
		velocity.x = dir.x * speed
		move_and_slide()
	
func _try_attack(delta) -> void:
	if attack_cooldown <= 0.0:
		attack_cooldown = attack_interval
		# animated_sprite.stop() 
		animated_sprite.play("attack")
		pending_damage = attack_damage  # Store damage to apply later
	else:
		attack_cooldown -= delta

func _on_animation_frame_changed() -> void:
	# Apply damage between frame 7 and 8 (when frame becomes 7)
	if animated_sprite.animation == "attack" and animated_sprite.frame == 7 and pending_damage > 0:
		var col = sight.get_collider()
		if col and col.has_method("take_damage"):
			col.take_damage(pending_damage)
		pending_damage = 0

func _on_animation_finished() -> void:
	if animated_sprite.animation == "attack":
		animated_sprite.play("default")  # Return to default animation after attack