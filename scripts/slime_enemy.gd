extends BaseEnemy
class_name SlimeEnemy
## Ground enemy that walks toward Heart/Walls and attacks them.

@onready var sight: RayCast2D = $Sight

var pending_damage: int = 0


func _on_enemy_ready() -> void:
	# Randomize attack range slightly
	attack_range += randfn(0, 2)
	
	# Setup sight raycast
	sight.collide_with_areas = true
	
	# Calculate attack interval from animation
	if animated_sprite.sprite_frames.has_animation("attack"):
		var frame_count = animated_sprite.sprite_frames.get_frame_count("attack")
		var fps = animated_sprite.sprite_frames.get_animation_speed("attack")
		attack_interval = frame_count / fps
	
	# Connect animation signals
	animated_sprite.animation_finished.connect(_on_animation_finished)
	animated_sprite.frame_changed.connect(_on_animation_frame_changed)


func _process_movement(delta: float) -> void:
	if not heart_node:
		return
	
	var to_heart := heart_node.global_position - global_position
	var dir := Vector2(sign(to_heart.x), 0)
	
	# Point ray toward heart
	sight.target_position = dir * attack_range
	sight.force_raycast_update()
	
	var col := sight.get_collider()
	
	if col and col.is_in_group("heart"):
		velocity.x = 0.0
		_try_attack(delta)
	elif col and col.is_in_group("wall"):
		if col.is_destroyed:
			velocity.x = dir.x * speed
		else:
			velocity.x = 0.0
			_try_attack(delta)
	else:
		velocity.x = dir.x * speed
	
	move_and_slide()


func _try_attack(delta: float) -> void:
	if attack_cooldown <= 0.0:
		attack_cooldown = attack_interval
		animated_sprite.play("attack")
		pending_damage = attack_damage
	else:
		attack_cooldown -= delta


func _on_animation_frame_changed() -> void:
	if animated_sprite.animation == "attack" and animated_sprite.frame == 7 and pending_damage > 0:
		var col = sight.get_collider()
		if col and col.has_method("take_damage"):
			col.take_damage(pending_damage)
		pending_damage = 0


func _on_animation_finished() -> void:
	if animated_sprite.animation == "attack":
		animated_sprite.play("default")