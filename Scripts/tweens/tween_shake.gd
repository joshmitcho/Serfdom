#tween_shake.gd
extends Node
class_name ShakeTween

var host_sprite
var stop_threshold
var tween_duration
var recovery_factor

# Options
@export var pivot_below: bool = true  # Whether the rotation pivot is below the sprite
@export var x_max = 2  # Maximum amount of x position movement
@export var r_max = 10  # Maximum amount of rotation

const TRANSITION_TYPE = Tween.TRANS_SINE

signal tween_completed

# Run the animation
func start(sprite, threshold = 0.1, duration = 0.02, recovery = 0.3):
	
	host_sprite = sprite
	stop_threshold = threshold
	tween_duration = duration
	recovery_factor = recovery
	
	# Multiple shakes
	var x = x_max
	var r = r_max
	while x > stop_threshold:
		
		# Left
		var tween = _tilt_left(x, r)
		await tween.finished

		x *= recovery_factor
		r *= recovery_factor
		
		_recenter()
		
		# Right
		tween = _tilt_right(x, r)
		await tween.finished

		x *= recovery_factor
		r *= recovery_factor
		
		_recenter()
	
	# Complete
	tween_completed.emit()


func _tilt_left(x, r) -> Tween:
	var tween = create_tween()
	
	# Position
	tween.tween_property(
		host_sprite, "position:x",
		-x, tween_duration).set_trans(TRANSITION_TYPE).set_ease(Tween.EASE_OUT)
	
	# Rotation
	if pivot_below:
		r = -r 
	tween.tween_property(
		host_sprite, "rotation_degrees",
		r, tween_duration).set_trans(TRANSITION_TYPE).set_ease(Tween.EASE_OUT)
	
	return tween


func _tilt_right(x, r) -> Tween:
	var tween = create_tween()
	
	# Position
	tween.tween_property(
		host_sprite, "position:x",
		x, tween_duration).set_trans(TRANSITION_TYPE).set_ease(Tween.EASE_OUT)
		
	# Rotation
	if not pivot_below:
		r = -r 
	tween.tween_property(
		host_sprite, "rotation_degrees",
		r, tween_duration).set_trans(TRANSITION_TYPE).set_ease(Tween.EASE_OUT)
	
	return tween


func _recenter():
	var tween = create_tween()
	
	# Position
	tween.tween_property(
		host_sprite, "position:x",
		0, tween_duration).set_trans(TRANSITION_TYPE).set_ease(Tween.EASE_IN)
	
	# Rotation
	tween.tween_property(
		host_sprite, "rotation_degrees",
		0, tween_duration).set_trans(TRANSITION_TYPE).set_ease(Tween.EASE_IN)
	
	return tween

