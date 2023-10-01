# placeable.gd
extends Destroyable
class_name Placeable


func initialize(p_name: StringName = "name"):
	sfx_pitches.shuffle()
	play_pitched_sfx(hit_sfx_player, Compendium.sfx_axe)
	object_name = p_name
	
	animator.animation = object_name
	animator.set_frame_and_progress(0, 0)
	
	compatible_tool_type = StringName("axe")
	
	hit_sfx = null
	die_sfx = [Compendium.sfx_axchop]
	
	num_drops = 1
	drop_types = [object_name]


func take_hit(_power: int):
	super.die()

