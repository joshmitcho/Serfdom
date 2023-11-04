# wood_tree.gd
extends Destroyable
class_name WoodTree

@export_group("Shake Tween Parameters")
@export_range(0, 1, 0.01) var stop_threshold: float
@export_range(0, 1, 0.01) var subtween_duration: float
@export_range(0, 1, 0.05) var recovery_factor: float 

@onready var stump_animator = $StumpAnimatedSprite
var is_stump: bool = false
var stump_health: int
var stump_hit_sfx
var stump_die_sfx
var stump_num_drops: int
var stump_drop_types: Array


func initialize(p_name: StringName = "name"):
	super.initialize(p_name)
	
	var stump_name = "stump_" + object_name.split("_")[-1]
	stump_animator.animation = stump_name
	
	stump_health = Compendium.all_destroyables[stump_name][1]
	stump_hit_sfx = Compendium.all_destroyables[stump_name][2]
	stump_die_sfx = Compendium.all_destroyables[stump_name][3]
	
	var drop_odds = Compendium.all_destroyables[stump_name][4]
	stump_num_drops = int(drop_odds)
	if randf_range(0, 1) < (drop_odds - num_drops):
		stump_num_drops += 1
	stump_drop_types  = Compendium.all_destroyables[stump_name][5]
	stump_animator.offset.y = Compendium.all_destroyables[stump_name][6]


func take_hit(power: int):
	shake_tween.start(shadow_animator, stop_threshold, subtween_duration, recovery_factor)
	if is_stump:
		shake_tween.start(stump_animator, stop_threshold, subtween_duration, recovery_factor)
		play_pitched_sfx(stump_hit_sfx)
	else:
		shake_tween.start(animator, stop_threshold, subtween_duration, recovery_factor)
		play_pitched_sfx(hit_sfx)
	total_damage += power
	if total_damage >= starting_health:
		die()
		return


func die():
	if is_stump:
		stump_die()
	else:
		fell()


func fell():
	animator.play()
	shadow_animator.play()
	
	is_stump = true
	total_damage = 0
	starting_health = stump_health
	
	play_pitched_sfx(die_sfx.pick_random())
	drop_items(false)
	drops = []
	await animator.animation_finished
	animator.hide()


func stump_die():
	is_dying = true
	animator.play()
	shadow_animator.play()
	$PhysicsCollider.set_collision_layer(0)
	$LightOccluder2D.occluder = null
	
	play_pitched_sfx(stump_die_sfx.pick_random())
	drop_items()


func do_action():
	shake_tween.start(shadow_animator, stop_threshold, subtween_duration, recovery_factor)
	shake_tween.start(animator, stop_threshold, subtween_duration, recovery_factor)

func _on_invisibility_trigger_body_entered(body):
	if body is Player:
		var tween = create_tween()
		tween.tween_property(animator, "modulate", Color(1, 1, 1, 0.4), 0.15)

func _on_invisibility_trigger_body_exited(body):
	if body is Player:
		var tween = create_tween()
		tween.tween_property(animator, "modulate", Color.WHITE, 0.15)
