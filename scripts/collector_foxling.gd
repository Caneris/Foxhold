extends BaseFoxling
class_name CollectorFoxling
## Collector foxling - patrols and collects coins to deposit at heart

signal coin_deposited(coin)

# Detection
@export var detection_radius: float = 50.0
@onready var detection_area: Area2D = $DetectionArea
@onready var detection_shape: CollisionShape2D = $DetectionArea/CollisionShape2D
@onready var coin_position: Marker2D = $CoinPosition

# Collector-specific state
enum State { IDLE, MOVING_TO_COIN, RETURNING_HOME, DEPOSITING_COIN }
var current_state: State = State.IDLE

# Coin tracking
var current_coin: RigidBody2D
var carried_coin: RigidBody2D
var available_coin: Array = []
var heart_position: Vector2


func _on_foxling_ready() -> void:
	heart_position = get_tree().current_scene.get_node("Heart").global_position
	
	# Set up detection area
	detection_shape.shape.radius = detection_radius
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	
	add_to_group("collectors")


func _process_state(delta: float) -> void:
	match current_state:
		State.IDLE:
			_state_idle(delta)
		State.MOVING_TO_COIN:
			_state_moving_to_coin(delta)
		State.RETURNING_HOME:
			_state_returning_home(delta)
		State.DEPOSITING_COIN:
			_state_depositing_coin(delta)


func _state_idle(delta: float) -> void:
	patrol(delta)
	_check_for_coin()


func _state_moving_to_coin(delta: float) -> void:
	# Check if coin still exists
	if current_coin == null or not is_instance_valid(current_coin):
		current_state = State.RETURNING_HOME
		current_coin = null
		return
	
	move_towards(current_coin.global_position, delta)
	
	# Close enough to pick up
	if global_position.distance_to(current_coin.global_position) < 10.0:
		_pick_up_coin()


func _state_returning_home(delta: float) -> void:
	_check_for_coin()
	
	if return_home(delta):
		current_state = State.IDLE


func _state_depositing_coin(delta: float) -> void:
	if carried_coin == null:
		current_state = State.RETURNING_HOME
		return
	
	move_towards(heart_position, delta)
	
	# Close enough to deposit
	if global_position.distance_to(heart_position) < 30.0:
		_deposit_coin()


func _check_for_coin() -> void:
	if available_coin.size() > 0 and carried_coin == null:
		var nearest_coin = _find_nearest_coin()
		if nearest_coin != null:
			current_coin = nearest_coin
			current_state = State.MOVING_TO_COIN


func _pick_up_coin() -> void:
	var nearest_coin = _find_nearest_coin()
	if nearest_coin == null or carried_coin != null:
		return
	
	carried_coin = nearest_coin
	current_coin = null
	
	# Disable physics on the coin
	carried_coin.freeze = true
	carried_coin.gravity_scale = 0
	if carried_coin.has_node("CollisionShape2D"):
		carried_coin.get_node("CollisionShape2D").disabled = true
	
	# Reparent coin to foxling
	if carried_coin.get_parent():
		carried_coin.get_parent().remove_child(carried_coin)
	add_child(carried_coin)
	carried_coin.global_position = coin_position.global_position
	carried_coin.visible = true
	
	current_state = State.DEPOSITING_COIN


func _deposit_coin() -> void:
	coin_deposited.emit(carried_coin)
	carried_coin.queue_free()
	carried_coin = null
	current_state = State.RETURNING_HOME


func _find_nearest_coin() -> RigidBody2D:
	if available_coin.is_empty():
		return null
	
	var nearest_coin: RigidBody2D = null
	var shortest_distance: float = INF
	
	for coin in available_coin:
		if not is_instance_valid(coin):
			continue
		
		var distance = global_position.distance_to(coin.global_position)
		if distance < shortest_distance:
			shortest_distance = distance
			nearest_coin = coin
	
	return nearest_coin


func _on_detection_area_body_entered(body: Node) -> void:
	if body.is_in_group("coin") and body not in available_coin:
		available_coin.append(body)


func _on_detection_area_body_exited(body: Node) -> void:
	if body in available_coin:
		available_coin.erase(body)
	if body == current_coin:
		current_coin = null
		current_state = State.RETURNING_HOME


# collector_foxling.gd
func cleanup() -> void:
	if carried_coin and is_instance_valid(carried_coin):
		carried_coin.reparent(get_tree().current_scene)
		carried_coin.freeze = false
		carried_coin.gravity_scale = 1
		if carried_coin.has_node("CollisionShape2D"):
			carried_coin.get_node("CollisionShape2D").disabled = false
		carried_coin = null