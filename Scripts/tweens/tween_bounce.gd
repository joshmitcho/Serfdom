extends Node
# Create a sequence of tweens to make a host sprite bounce up and down

# Options
@export var drop_height: float = 25.0  # Determines bounce height
@export var start_at_top = false  # Toggle between starting at the top or bottom

# Parameters
var tween_duration = 0.1  # Duration of each tween
const RECOVERY_FACTOR = 0.5  # Amount of height retained on each bounce
const STOP_THRESHOLD = 1

# Variables
var active_tween: Tween
var host_sprite 

# Signals
signal completed

# Run the animation
func play(sprite, height_variance: int = 0):
	
	host_sprite = sprite
	
	drop_height += height_variance
	tween_duration *= (height_variance / drop_height) + 1
	
	# Initial drop
	if start_at_top:
		active_tween = _drop_down()
		await active_tween.finished
	
	# Multiple bounces
	var bounce_height = drop_height * RECOVERY_FACTOR
	while bounce_height > STOP_THRESHOLD:
		
		# Bounce up
		active_tween = _bounce_up(bounce_height)
		await active_tween.finished
		
		# Drop down
		active_tween = _drop_down()
		await active_tween.finished
		
		bounce_height = bounce_height * RECOVERY_FACTOR
	
	completed.emit()


func _bounce_up(height) -> Tween:
	var y_end = -height  # Invert height to get the y position
	
	var tween = create_tween()
	tween.tween_property(
		host_sprite, "position:y",
		y_end, tween_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	return tween


func _drop_down() -> Tween:
	var tween = create_tween()
	tween.tween_property(
		host_sprite, "position:y",
		0, tween_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	return tween
