# crop.gd
extends Placeable
class_name Crop

signal crop_planted()

var growing_season: int = 0
var does_regrow: bool = false
var regrow_time: int

enum Stage {DEAD, SEED, GROWING_1, GROWING_2, GROWING_3, READY, AFTER}
var stage: Stage = Stage.SEED
var days_watered: int = 0

var lifecycle: Dictionary

func initialize(p_name: StringName = "name"):
	sfx_pitches.shuffle()
	play_pitched_sfx(Compendium.sfx_plant_seed.pick_random())
	
	object_name = p_name
	
	animator.animation = object_name
	animator.set_frame_and_progress(stage, 0)
	
	compatible_tool_type = StringName("sickle")
	
	hit_sfx = null
	die_sfx = [Compendium.sfx_cut]
	
	var crop_info = Compendium.all_crops[object_name]
	
	var drop_odds = crop_info[0]
	num_drops = int(drop_odds)
	if randf_range(0, 1) < (drop_odds - num_drops):
		num_drops += 1
	drop_types = [object_name]
	
	lifecycle[Stage.GROWING_1] = crop_info[1]
	lifecycle[Stage.GROWING_2] = crop_info[2]
	lifecycle[Stage.GROWING_3] = crop_info[3]
	lifecycle[Stage.READY] = crop_info[4]
	
	regrow_time = crop_info[5]
	if regrow_time != -1:
		does_regrow = true


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
	play_pitched_sfx(Compendium.sfx_hoe)


func _on_body_entered(_body):
	if stage != Stage.SEED:
		$ShakeTween.start(animator, 0.1, 0.02, 0.3)


func grow_if_watered(season: int):
	if season != growing_season:
		stage = Stage.DEAD
		animator.set_frame_and_progress(stage, 0)
		return
	
	if not get_parent().is_crop_watered(position):
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
