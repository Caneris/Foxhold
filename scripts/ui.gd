extends Control

@onready var break_timer_circle: TextureProgressBar = $BreakTimerCircle

func _on_countdown_started(duration : float) -> void:
	break_timer_circle.max_value = duration
	break_timer_circle.show()


func _on_countdown_updated(time_remaining : float) -> void:
	#print("UI received: ", time_remaining)
	break_timer_circle.value = time_remaining
