# placeable.gd
extends Destroyable
class_name Placeable


func initialize(p_name: StringName = "name"):
	sfx_pitches.shuffle()
	play_pitched_sfx(Compendium.sfx_axe)
	object_name = p_name
	
	animator.load_animation(object_name)
	animator.load_offset(-8)
	
	compatible_tool_type = StringName("axe")
	
	hit_sfx = null
	die_sfx = [Compendium.sfx_axchop]
	
	num_drops = 1
	drop_types = [object_name]


func take_hit(_power: int):
	super.die()

