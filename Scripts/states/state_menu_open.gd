# state_menu_open.gd
extends PlayerState


func enter(_msg := {}) -> void:
	get_tree().paused = true

func handle_input(_event):
	if Input.is_action_just_pressed("menu"):
		Inventory.toggle_menu.emit(0)
		if not MainUI.is_open:
			state_machine.transition_to("IdleMove")
		return
	
	if Input.is_action_just_pressed("crafting_menu") and not Inventory.does_cursor_have_item():
		Inventory.toggle_menu.emit(1)
		if not MainUI.is_open:
			state_machine.transition_to("IdleMove")
		return
	
	if Input.is_action_just_pressed("shift_toolbar"):
		Inventory.shift_toolbar()
		return
	
	if Input.is_action_just_pressed("use_item") and Inventory.does_cursor_have_item():
		Inventory.drop_item()
		return

func exit(_msg := {}) -> void:
	get_tree().paused = false
