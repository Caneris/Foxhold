extends Node2D

@export var enemy_scenes : Array[PackedScene] = []
@export var spawn_interval : float = 2.0
@export var spawn_points_path : Array[NodePath] = []
@export var enemy_container_path : NodePath
@export var spawn_timer_one_shot : bool

var spawn_points : Array[Marker2D]
var enemy_container : Node2D
var spawn_timer : Timer


func _ready() -> void:
	initiate_timer()
	initiate_node_paths()


func initiate_timer() -> void:
	spawn_timer = Timer.new()
	add_child(spawn_timer)
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.wait_time = spawn_interval
	spawn_timer.one_shot = spawn_timer_one_shot
	spawn_timer.start()


func initiate_node_paths() -> void:
	
	# initiate spawn points
	for path in spawn_points_path:
		var m := get_node_or_null(path)
		if m is Marker2D:
			spawn_points.append(m)
	
	# initiate enemy container
	enemy_container = get_node_or_null(enemy_container_path)

func _on_spawn_timer_timeout() -> void:
	print("time out")
	
