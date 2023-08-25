# state_use_tool.gd
extends PlayerState

signal tool_used(tool: String, tool_offsets: Array, power: int)
signal place_attempted(placeable: Item, offsets: Array)

var is_static: bool

func enter(msg := {}) -> void:
	is_static = msg["is_static"]

	var facing_string = player.animator.animation.split("_")[-1]
	var current_item = Inventory.get_current_item()
	
	# if you're placing an object / planting a crop
	if is_instance_of(current_item, Item) and current_item.is_placeable:
		emit_signal("place_attempted", current_item, [player.facing, Vector2i.ZERO])
		state_machine.transition_to("IdleMove")
		return
	
	var tool_type = Inventory.get_current_tool_type()
	if tool_type == "":
		state_machine.transition_to("IdleMove")
		return
	
	var animName = tool_type.to_lower() + "_" + facing_string
	
	player.animator.stop()
	player.animator.play(animName)
	player.tool_animator.visible = true
	player.tool_animator.stop()
	player.tool_animator.play(animName)
	
	await get_tree().create_timer(0.4).timeout
	
	emit_signal("tool_used", tool_type, [Vector2i.ZERO, player.facing], current_item.power)
	
	await player.animator.animation_finished
	if Input.is_action_pressed("use_tool"):
		state_machine.transition_to("UseTool", {"is_static": is_static})
		return
	
	state_machine.transition_to("IdleMove")
