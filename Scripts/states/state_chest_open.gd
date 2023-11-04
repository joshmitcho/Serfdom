# state_chest_open.gd
extends PlayerState


func enter(_msg := {}) -> void:
	get_tree().paused = true

func handle_input(_event):
	if Input.is_action_just_pressed("shift_toolbar"):
		Inventory.shift_toolbar()
		return
	
	if Input.is_action_just_pressed("use_item") and Inventory.does_cursor_have_item():
		Inventory.drop_item()
		return
	
	if Input.is_action_just_pressed("menu"):
		Inventory.chest_closed.emit()
		state_machine.transition_to("IdleMove")

func exit(_msg := {}) -> void:
	get_tree().paused = false
