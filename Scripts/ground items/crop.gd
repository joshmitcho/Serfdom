# crop.gd
extends Placeable
class_name Crop

signal crop_planted()

var does_regrow: bool = false
var regrow_time: int

enum Stage {SEED, GROWING_1, GROWING_2, GROWING_3, READY, AFTER, DEAD}
var stage: Stage = Stage.SEED
var days_watered: int = 0

var lifecycle: Dictionary

func initialize(p_name: StringName = "name"):
	sfx_pitches.shuffle()
	play_pitched_sfx(hit_sfx_player, Compendium.sfx_plant_seed.pick_random())
	
	object_name = p_name
	
	animator.animation = object_name
	animator.set_frame_and_progress(0, 0)
	
	compatible_tool_type = StringName("sickle")
	
	hit_sfx = null
	die_sfx = [Compendium.sfx_cut]
	
	var drop_odds = Compendium.all_crops[object_name][0]
	num_drops = int(drop_odds)
	if randf_range(0, 1) < (drop_odds - num_drops):
		num_drops += 1
	drop_types = [object_name]
	
	lifecycle[Stage.GROWING_1] = Compendium.all_crops[object_name][1]
	lifecycle[Stage.GROWING_2] = Compendium.all_crops[object_name][2]
	lifecycle[Stage.GROWING_3] = Compendium.all_crops[object_name][3]
	lifecycle[Stage.READY] = Compendium.all_crops[object_name][4]
	
	regrow_time = Compendium.all_crops[object_name][5]
	if regrow_time != -1:
		does_regrow = true
	
	TimeManager.new_day.connect(grow_if_watered)


func take_hit(_power: int):
	if stage == Stage.READY:
		super.die()
		return
	if stage == Stage.DEAD:
		num_drops = 0
		super.die()
		return
	if stage != Stage.SEED:
		$ShakeTween.start(animator)
	play_pitched_sfx(hit_sfx_player, Compendium.sfx_hoe)


func _on_body_entered(_body):
	if stage != Stage.SEED:
		$ShakeTween.start(animator, 0.1, 0.02, 0.3)


func grow_if_watered():
	if not get_parent().is_tile_watered(position):
		return
	if stage == Stage.READY:
		return
	days_watered += 1
	
	if does_regrow and stage == Stage.AFTER:
		if (days_watered - lifecycle[Stage.READY]) % regrow_time == 0:
			stage = Stage.READY
	else:
		for key in lifecycle:
			if days_watered >= lifecycle[key]:
				stage = key
	animator.set_frame_and_progress(stage, 0)
