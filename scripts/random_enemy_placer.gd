extends Node2D


var spawn_count := 0
var next_group_at := randi_range(4, 5)  # first group between 4–5 spawns
var enemies : Array = []

# variables from main scene
var game_is_running : bool
var screen_size : Vector2
var camera_2d : Camera2D
var time_is_out : bool = false 

# timer variables for spawning targets, range for random countdown
@export var min_time : int = 2
@export var max_time : int = 4
var timer : Timer

# preload food types in list:
@export var item_scenes : Array[PackedScene]

func _ready() -> void:
	timer = Timer.new()
	add_child(timer)
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)

func clear_enemies() -> void:
	if len(enemies) > 0:
		for enemy in enemies:
			if enemy.is_inside_tree():
				enemy.queue_free()
		enemies.clear()

func place_enemy() -> void:
	var random_enemy : PackedScene = item_scenes.pick_random()
	var enemy_instance := random_enemy.instantiate()
	get_parent().add_child(enemy_instance)
	# var random_position := Vector2(0, 0)
	enemies.append(enemy_instance)
	enemy_instance.position = Vector2(
		screen_size.x + camera_2d.position.x + randf_range(0,50),
		randf_range(10, 100)
	)
	enemy_instance.get_node("AnimatedSprite2D").play("default")

func _start_random_timer():
	var random_wait : int = randi_range(min_time, max_time)
	timer.wait_time = random_wait
	time_is_out = false
	timer.start()

func _on_timer_timeout() -> void:
	time_is_out = true

func spawn_group(count: int) -> void:
	# choose a “row” Y-start so they’re roughly aligned
	var base_y := randf_range(20, 80)
	# a little horizontal jitter per bird
	var base_x := screen_size.x + camera_2d.position.x + randf_range(0, 50)
	
	for i in count:
		var inst = item_scenes.pick_random().instantiate()
		get_parent().add_child(inst)
		enemies.append(inst)
		inst.position = Vector2(
			base_x + i * randf_range(10, 20),
			base_y + randf_range(-10, 10)
		)
		inst.get_node("AnimatedSprite2D").play("default")

func _process(delta: float) -> void:
	if game_is_running and time_is_out:
		if spawn_count >= next_group_at:
			spawn_group( randi_range(2, 4) )  # e.g. cluster of 2–4
			spawn_count = 0
			next_group_at = randi_range(3, 5)
		else:
			place_enemy()
			spawn_count += 1
			
		_start_random_timer()
