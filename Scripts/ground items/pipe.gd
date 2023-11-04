# pipe.gd
extends Placeable
class_name Pipe

@onready var particle_emitter: CPUParticles2D = $CPUParticles2D

var is_in_water: bool = false
var is_connected_to_water: bool = false


func irrigate(connected: bool):
	is_connected_to_water = connected
	if is_connected_to_water:
		particle_emitter.emitting = true
		await get_tree().create_timer(8).timeout
		particle_emitter.emitting = false
	else:
		particle_emitter.emitting = false

