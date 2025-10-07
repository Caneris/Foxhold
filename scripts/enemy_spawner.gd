extends Node2D

@export var enemy_scene : PackedScene
#@export var spawn_interval : float = 1.0
@export var spawn_interval_min : float = 1.0
@export var spawn_interval_max : float = 1.0

@export var break_interval : float = 5.0
@export var spawn_points_path : Array[NodePath] = []
@export var enemy_container_path : NodePath
@export var spawn_timer_one_shot : bool
@export var break_timer_one_shot : bool

var spawn_points : Array[Marker2D]
var enemy_container : Node2D
var spawn_timer : Timer

var wave_number : int = 0
var n_base : int = 5
var n_this_wave : int
var n_current : int = 0
var n_spawned : int = 0
var enemy_growth_rate : float = 0.2

var break_timer : Timer

signal wave_countdown_started(duration)
signal countdown_updated(time_remaining)
signal wave_starting


func _ready() -> void:
	initiate_spawn_timer()
	initiate_break_timer()
	initiate_node_paths()
	start_wave()


func _process(delta: float) -> void:
	if not break_timer.is_stopped():
		var time_left : float = break_timer.time_left
		#print("Time left: ", time_left)  
		countdown_updated.emit(time_left)


func start_wave() -> void:
	if not break_timer.is_stopped():
		break_timer.stop()
	wave_number += 1
	n_this_wave = roundi(n_base * (1+enemy_growth_rate)**(wave_number - 1))
	print("n this wave: " + str(n_this_wave))
	wave_starting.emit()
	spawn_timer.start()

func initiate_spawn_timer() -> void:
	spawn_timer = Timer.new()
	add_child(spawn_timer)
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.wait_time = randf_range(spawn_interval_min, spawn_interval_max)
	spawn_timer.one_shot = spawn_timer_one_shot


func initiate_break_timer() -> void:
	break_timer = Timer.new()
	add_child(break_timer)
	break_timer.timeout.connect(_on_break_timer_timeout)
	break_timer.wait_time = break_interval
	break_timer.one_shot = break_timer_one_shot


func initiate_node_paths() -> void:
	# initiate spawn points
	for path in spawn_points_path:
		var m := get_node_or_null(path)
		if m is Marker2D:
			spawn_points.append(m)
	
	# initiate enemy container
	enemy_container = get_node_or_null(enemy_container_path)

func _on_spawn_timer_timeout() -> void:
	if n_spawned < n_this_wave:
		var spawn_index : int = randi_range(0, 1)
		spawn_enemy(spawn_index)
		spawn_timer.wait_time = randf_range(spawn_interval_min, spawn_interval_max)
	else:
		spawn_timer.stop()


func _on_break_timer_timeout() -> void:
	start_wave()


func spawn_enemy(spawn_index) -> void:
	n_current += 1
	n_spawned += 1
	var enemy := enemy_scene.instantiate()
	enemy_container.add_child(enemy)
	enemy_container.move_child(enemy, 0)
	enemy.global_position = spawn_points[spawn_index].global_position
	
	# animate spawned enemy (default of animated sprite is "default")
	var animated_sprite := enemy.get_node_or_null("AnimatedSprite2D")
	if animated_sprite is AnimatedSprite2D:
		animated_sprite.play("default")
		
		# Make the sprite point towards the heart
		var heart = get_node_or_null("../Heart") # Adjust path as needed
		if heart:
			var direction = (heart.global_position - enemy.global_position).normalized()
			# flip the sprite based on X direction
			animated_sprite.flip_h = direction.x >= 0
	
	# connect death signal
	enemy.enemy_died.connect(_on_enemy_died)


func _on_enemy_died() -> void:
	print("enemy died signal")
	n_current -= 1
	var n_remaining : int = n_this_wave - n_spawned + n_current
	if n_remaining == 0:
		print("wave complete")
		_wave_complete()


func _wave_complete() -> void:
	wave_countdown_started.emit(break_timer.wait_time)
	break_timer.start()
	n_spawned = 0
