extends BaseFoxling
class_name KnightFoxling
## Knight foxling - patrols and attacks enemies

# Combat stats
@export var damage: int = 5
@export var attack_range: float = 10.0
@export var attack_cooldown: float = 1.0
@export var enemy_slow_amount: float = 0.5  # 50% speed reduction

# Detection
@export var sight_range: float = 60.0
@onready var sight: RayCast2D = $Sight

# Knight-specific state
enum State { IDLE, CHASING, SEARCHING, RETURNING }
var current_state: State = State.IDLE
var current_target: CharacterBody2D
var attack_timer: float = 0.0

# Search after killing an enemy
const SEARCH_DELAY: float = 0.5
var search_timer: float = 0.0
var is_searching: bool = false


func _on_foxling_ready() -> void:
	# Add some randomness to attack range
	attack_range = attack_range + randfn(0, 2.0)
	
	add_to_group("knights")
	
	# Set up sight raycast
	sight.collide_with_areas = false
	sight.collide_with_bodies = true


func _process_state(delta: float) -> void:
	attack_timer -= delta
	
	match current_state:
		State.IDLE:
			_state_idle(delta)
		State.CHASING:
			_state_chasing(delta)
		State.SEARCHING:
			_state_searching()
		State.RETURNING:
			_state_returning(delta)


func _state_idle(delta: float) -> void:
	patrol(delta)
	_check_for_enemies(patrol_direction)


func _state_chasing(delta: float) -> void:
	# Check if target still exists
	if not is_instance_valid(current_target):
		current_state = State.SEARCHING
		current_target = null
		return
	
	var to_enemy = current_target.global_position - global_position
	var distance = to_enemy.length()
	
	# Lost sight - return home
	if distance > sight_range * 2.0:
		current_state = State.RETURNING
		current_target = null
		return
	
	# Move toward enemy
	var direction = sign(to_enemy.x)
	
	# Chase until at attack range
	if distance > attack_range:
		velocity.x = direction * speed
	else:
		velocity.x = 0  # Stop at attack distance
	
	# Attack if in range and cooldown ready
	if distance <= attack_range and attack_timer <= 0:
		_attack_enemy()
		attack_timer = attack_cooldown

	# Keep sight pointed at enemy
	sight.target_position = Vector2(direction * sight_range, 0)
	move_and_slide()


func _state_searching() -> void:
	# Get current direction of the raycast
	var direction = sign(sight.target_position.x)
	
	if is_searching:
		_check_for_enemies(direction)
		search_timer -= get_process_delta_time()
		if search_timer <= 0.0:
			is_searching = false
			current_state = State.RETURNING
			_decide_next_action()
	else:
		# Start searching for enemies
		is_searching = true
		search_timer = SEARCH_DELAY


func _state_returning(delta: float) -> void:
	# Check for enemies while returning
	var direction = sign((home_position - global_position).x)
	_check_for_enemies(direction)
	
	# Return home - if arrived, switch to IDLE
	if return_home(delta):
		current_state = State.IDLE


func _check_for_enemies(check_direction: float) -> void:
	sight.target_position = Vector2(check_direction * sight_range, 0)
	sight.force_raycast_update()

	var collider = sight.get_collider()
	if collider and collider.is_in_group("enemy"):
		current_target = collider
		current_state = State.CHASING


func _attack_enemy() -> void:
	if not is_instance_valid(current_target):
		return
	
	# Deal damage
	current_target.take_damage(damage)
	
	# Apply slow if enemy supports it
	if current_target.has_method("apply_slow"):
		current_target.apply_slow(enemy_slow_amount, 2.0)