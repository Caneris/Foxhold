extends CharacterBody2D

@export var heart_path : NodePath
@export var speed : float = 100.0
@export var heart_range : float = 50.0
@export var heart_range_speed : float = 100.0
@export var attack_range : float = 30.0
@export var attack_damage : int = 1
@export var attack_interval : float = 2.0
@export var max_health : int = 10

# pixels/sec² — by default Godot’s 2D gravity
@export var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
# Prevent them from accelerating forever
@export var max_fall_speed: float = 800.0


var heart_node : Node2D
var attack_cooldown : float = 0.0

@onready var sight: RayCast2D = $Sight
@onready var health_bar: ProgressBar = %HealthBar


func _ready() -> void:
	# Cache Heart instance
	heart_node = get_node(heart_path)
	sight.collide_with_areas = true
	initiate_health(max_health)


func _input(event: InputEvent) -> void:
	var event_is_mouseclick : bool = (
		event is InputEventMouseButton and 
		event.button_index == MOUSE_BUTTON_LEFT and
		event.is_pressed()
	)
	
	if event_is_mouseclick:
		health_bar.value -= 2


func initiate_health(value) -> void:
	health_bar.max_value = max_health
	health_bar.value = value


func _physics_process(delta: float) -> void:
	if not heart_node:
		return
	
	# insert gravity
	velocity.y += gravity * delta
	if velocity.y > max_fall_speed:
		velocity.y =max_fall_speed
	
	# always aim at the art
	var to_heart := heart_node.global_position - global_position
	var dist := to_heart.length()
	var dir := Vector2(sign(to_heart.x), 0)
	
	# point a fixed-length ray at the heart
	sight.target_position = dir * attack_range
	sight.force_raycast_update()
	
	var col := sight.get_collider()
	
	if sight.is_colliding() and col.is_in_group("heart"):
		velocity.x = 0.0
		_try_attack(delta)
	else:
		velocity.x = dir.x * speed
		move_and_slide()
	
func _try_attack(delta) -> void:
	if attack_cooldown <= 0.0:
		print("attack the heart")
		attack_cooldown = attack_interval
	else:
		attack_cooldown -= delta


#func _physics_process(delta):
	#if not heart_node:
		#return
#
	#var to_heart = heart_node.global_position - global_position
	#var dist = to_heart.length()
#
	#if dist > attack_range:
		## Move toward the Heart
		#velocity = to_heart.normalized() * speed
		#move_and_slide()
	#else:
		## In range: stop and try to attack
		#velocity = Vector2.ZERO
#
		## Point the RayCast2D (“Sight”) at the Heart,
		## but only as far as attack_range
		#var dir = to_heart.normalized()
		#$Sight.cast_to = dir * attack_range
		#$Sight.force_raycast_update()
#
		## If the ray hits and that collider is in group “heart”, attack
		#if $Sight.is_colliding():
			#var col = $Sight.get_collider()
			#if col.is_in_group("heart"):
				#_try_attack(delta)
#
#func _try_attack(delta):
	#if attack_cooldown <= 0.0:
		## Deal damage
		#if heart_node.has_method("take_damage"):
			#heart_node.take_damage(attack_damage)
		## Play a quick attack tween
		#_play_attack_tween()
		#attack_cooldown = attack_interval
	#else:
		#attack_cooldown -= delta
#
#func _play_attack_tween():
	## Pop-scale + red flash to emphasize the hit
	#var t = create_tween()
	#t.tween_property(self, "scale", scale * 1.2, 0.1)\
	 #.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	#t.tween_property(self, "scale", scale, 0.1)\
	 #.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	#t.tween_property(self, "modulate", Color(1,0.5,0.5), 0.05)\
	 #.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	#t.tween_property(self, "modulate", Color(1,1,1), 0.1)\
	 #.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
