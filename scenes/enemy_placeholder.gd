extends CharacterBody2D

@export var heart_path : NodePath
@export var speed : float = 100.0
@export var attack_range : float = 24.0
@export var attack_damage : int = 1
@export var attack_intervall : float = 1.0

var heart_node : Node2D
var attack_cooldown : float = 0.0

func _ready() -> void:
	# Cache Heart instance
	heart_node = get_node(heart_path)

func _physics_process(delta: float) -> void:
	if not heart_node:
		return
	
	var to_heart := heart_node.global_position - global_position
	var dist = to_heart.length()
	
	
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
