# state_use_item.gd
extends PlayerState

signal tool_used(tool: String, tool_offsets: Array, power: int)
signal place_attempted(placeable: Item, offset: Vector2i)

var facing_offsets: Array[Vector2i]

func enter(_msg := {}) -> void:
	var facing_string = player.animator.animation.split("_")[-1]
	var current_item = Inventory.get_current_item()
	
	# if you're placing an object / planting a crop
	if current_item is Item and current_item.is_placeable:
		place_attempted.emit(current_item, player.facing)
		state_machine.transition_to("IdleMove")
		return
	
	var tool_type = Inventory.get_current_tool_type()
	var animName = tool_type.to_lower() + "_" + facing_string
	if tool_type == "":
		state_machine.transition_to("IdleMove")
		return
	elif tool_type == StringName("pail") and current_item.power <= 0:
		animName = "empty_" + animName
	
	player.animator.stop()
	player.animator.play(animName)
	player.tool_animator.show()
	player.tool_animator.stop()
	player.tool_animator.play(animName)
	
	await get_tree().create_timer(0.4).timeout
	
	facing_offsets = [player.facing, Vector2i.ZERO]
	if abs(player.facing.x) + abs(player.facing.y) == 2:
		facing_offsets.append(Vector2i(player.facing.x, 0))
		facing_offsets.append(Vector2i(0, player.facing.y))
	
	tool_used.emit(tool_type, facing_offsets, current_item.power)
	
	await player.animator.animation_finished
	if Input.is_action_pressed("use_item"):
		state_machine.transition_to("UseItem")
		return
	
	state_machine.transition_to("IdleMove")
