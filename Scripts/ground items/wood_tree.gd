# wood_tree.gd
extends Destroyable
class_name WoodTree

@export_group("Shake Tween Parameters")
@export_range(0, 1, 0.01) var stop_threshold: float
@export_range(0, 1, 0.01) var subtween_duration: float
@export_range(0, 1, 0.05) var recovery_factor: float 

@onready var foliage_animator: AnimatedSprite2D = $FoliageAnimator
@onready var shadow_animator: AnimatedSprite2D = $ShadowAnimator

var is_stump: bool = false
var stump_health: int
var stump_hit_sfx: AudioStream
var stump_die_sfx: Array
var stump_num_drops: int
var stump_drop_types: Array
var days_in_stage: int = 0

const MATURE_STAGE: int = 2


func initialize(p_name: StringName = "name"):
	var stump_name = "stump_" + p_name.split("_")[-1]
	super.initialize(stump_name)
	object_name = p_name
	
	shadow_animator.offset.y = Compendium.all_destroyables[object_name][6]
	shadow_animator.animation = object_name
	foliage_animator.offset.y = Compendium.all_destroyables[object_name][6]
	foliage_animator.animation = object_name
	
	stump_health = Compendium.all_destroyables[stump_name][1]
	stump_hit_sfx = Compendium.all_destroyables[stump_name][2]
	stump_die_sfx = Compendium.all_destroyables[stump_name][3]
	
	var drop_odds = Compendium.all_destroyables[stump_name][4]
	stump_num_drops = int(drop_odds)
	if randf_range(0, 1) < (drop_odds - num_drops):
		stump_num_drops += 1
	stump_drop_types  = Compendium.all_destroyables[stump_name][5]
	#stump_animator.offset.y = Compendium.all_destroyables[stump_name][6]


func take_hit(power: int):
	shake_tween.start(shadow_animator, stop_threshold, subtween_duration, recovery_factor)
	if is_stump:
		shake_tween.start(animator, stop_threshold, subtween_duration, recovery_factor)
		play_pitched_sfx(stump_hit_sfx)
	else:
		shake_tween.start(foliage_animator, stop_threshold, subtween_duration, recovery_factor)
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
	foliage_animator.play()
	shadow_animator.play()
	
	is_stump = true
	total_damage = 0
	starting_health = stump_health
	
	play_pitched_sfx(die_sfx.pick_random())
	drop_items(false)
	drops = []
	await foliage_animator.animation_finished
	foliage_animator.hide()
	shadow_animator.hide()


func stump_die():
	is_dying = true
	animator.play()
	shadow_animator.play()
	$PhysicsCollider.set_collision_layer(0)
	$LightOccluder2D.occluder = null
	
	play_pitched_sfx(stump_die_sfx.pick_random())
	drop_items()


func grow_if_alive(season: int):
	if season == 3 or is_stump: #if winter or stump, skip growing
		return
	
	days_in_stage += 1
	var current_stage := int(object_name.split("_")[-1])
	if days_in_stage >= Compendium.TREE_INTERVALS[current_stage]:
		if current_stage == MATURE_STAGE:
			pass
		else:
			initialize("tree_" + str(current_stage + 1))
		days_in_stage = 0


func do_action():
	shake_tween.start(shadow_animator, stop_threshold, subtween_duration, recovery_factor)
	shake_tween.start(foliage_animator, stop_threshold, subtween_duration, recovery_factor)


func _physics_process(_delta):
	shadow_animator.self_modulate = DayNightModulate.shadow_modulate


func _on_invisibility_trigger_body_entered(body):
	if body is Player:
		var tween = create_tween()
		tween.tween_property(foliage_animator, "modulate", Color(1, 1, 1, 0.4), 0.15)


func _on_invisibility_trigger_body_exited(body):
	if body is Player:
		var tween = create_tween()
		tween.tween_property(foliage_animator, "modulate", Color.WHITE, 0.15)
